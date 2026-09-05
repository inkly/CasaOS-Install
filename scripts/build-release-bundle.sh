#!/usr/bin/env bash
#
# Assemble a CasaOS-Install release from components that have already been
# released by their own repositories.
#
# Nothing is compiled here. Each Go service and the dashboard publish their
# own tarballs and a checksums.txt from their own release workflow; this script
# fetches those checksums and writes them into install.sh, so the digests the
# installer verifies against are never typed by hand. Two consecutive releases
# once existed only to fix a mistyped digest - that is the failure this removes.
#
# What it produces, in OUTPUT_DIR:
#   install.sh            the installer with every tag and digest filled in
#   casaos-uninstall      the uninstaller, served from our release rather than
#                         from a third party's web server
#   linux-zz-casaos-compat-overlay-<tag>.tar.gz
#                         the setup scripts of the six components, plus the
#                         release marker read by the in-app updater
#   version.json          what the in-app updater polls: the tag and the
#                         CHANGELOG.md section of this release
#   release-notes.md      that same section, the body of the GitHub release
#   components.lock       the exact commits and tags this release was cut from
#   checksums.txt         digests of everything above
#
# Inputs:
#   release/components.env   tags and commits of every component
#   WORKSPACE_ROOT           directory holding the six component checkouts,
#                            each at the commit pinned in components.env
#                            (default: the parent of this repository)
#   GITHUB_OWNER             account the component releases live under
#                            (default: inkly)
#   CHECKSUMS_BASE_URL       where to fetch <repo>/releases/download/<tag>/checksums.txt
#                            from; defaults to GitHub under GITHUB_OWNER. A
#                            file:// URL pointing at a local tree lets the whole
#                            thing be exercised before any release exists.

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly INSTALLER_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "${INSTALLER_ROOT}/.." && pwd)}"
readonly COMPONENT_LOCK="${INSTALLER_ROOT}/release/components.env"
readonly GITHUB_OWNER="${GITHUB_OWNER:-inkly}"
readonly CHECKSUMS_BASE_URL="${CHECKSUMS_BASE_URL:-https://github.com/${GITHUB_OWNER}}"

# shellcheck source=../release/components.env
source "${COMPONENT_LOCK}"

readonly RELEASE_TAG="${CASAOS_RELEASE_TAG}"
readonly OUTPUT_DIR="${1:-${INSTALLER_ROOT}/dist}"
readonly OVERLAY_FILE="linux-zz-casaos-compat-overlay-${RELEASE_TAG}.tar.gz"

readonly COMPONENT_DIRS=(
    "CasaOS-Gateway:${CASAOS_GATEWAY_COMMIT}"
    "CasaOS-UserService:${CASAOS_USER_SERVICE_COMMIT}"
    "CasaOS:${CASAOS_COMMIT}"
    "CasaOS-LocalStorage:${CASAOS_LOCAL_STORAGE_COMMIT}"
    "CasaOS-MessageBus:${CASAOS_MESSAGE_BUS_COMMIT}"
    "CasaOS-AppManagement:${CASAOS_APP_MANAGEMENT_COMMIT}"
)

fail() {
    echo "$*" >&2
    exit 1
}

verify_repo_commit() {
    local repo_name="$1"
    local expected_commit="$2"
    local repo_path="${WORKSPACE_ROOT}/${repo_name}"
    local actual_commit

    [[ -d "${repo_path}/.git" ]] || fail "${repo_name} is not checked out at ${repo_path}."

    actual_commit="$(git -C "${repo_path}" rev-parse HEAD)"
    if [[ "${actual_commit}" != "${expected_commit}"* ]]; then
        fail "${repo_name} is at ${actual_commit}; expected ${expected_commit}."
    fi

    if ! git -C "${repo_path}" diff --quiet -- || ! git -C "${repo_path}" diff --cached --quiet --; then
        fail "${repo_name} has uncommitted tracked changes; refusing to package it."
    fi
}

for entry in "${COMPONENT_DIRS[@]}"; do
    verify_repo_commit "${entry%%:*}" "${entry#*:}"
done

readonly STAGING_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/casaos-release-bundle.XXXXXX")"
trap 'rm -rf "${STAGING_ROOT}"' EXIT

mkdir -p "${OUTPUT_DIR}"

# fetch_checksum <repo> <tag> <asset>
# Prints the SHA-256 of one asset as published by that repository's release.
fetch_checksum() {
    local repo="$1" tag="$2" asset="$3"
    local url="${CHECKSUMS_BASE_URL}/${repo}/releases/download/${tag}/checksums.txt"
    local sum

    sum="$(curl -fsSL "${url}" | awk -v a="${asset}" '($2 == a || $2 == "*" a) { print $1; exit }')"
    [[ -n "${sum}" ]] || fail "No digest for ${asset} in ${url}."
    [[ "${sum}" =~ ^[0-9a-f]{64}$ ]] || fail "Malformed digest for ${asset}: ${sum}"

    echo "${sum}"
}

create_archive() {
    local stage_dir="$1"
    local output_file="$2"

    find "${stage_dir}" -exec touch -t 202001010000 {} +
    COPYFILE_DISABLE=1 tar --format=ustar -C "${stage_dir}" -cf - build | gzip -n >"${output_file}"
}

package_overlay() {
    local stage_dir="${STAGING_ROOT}/overlay"
    local setup_dir="${stage_dir}/build/scripts/setup/script.d"

    mkdir -p "${setup_dir}"
    install -m 0755 "${WORKSPACE_ROOT}/CasaOS-Gateway/build/scripts/setup/script.d/01-setup-gateway.sh" "${setup_dir}/"
    install -m 0755 "${WORKSPACE_ROOT}/CasaOS-UserService/build/scripts/setup/script.d/02-setup-user-service.sh" "${setup_dir}/"
    install -m 0755 "${WORKSPACE_ROOT}/CasaOS/build/scripts/setup/script.d/03-setup-casaos.sh" "${setup_dir}/"
    install -m 0755 "${WORKSPACE_ROOT}/CasaOS-LocalStorage/build/scripts/setup/script.d/04-setup-local-storage.sh" "${setup_dir}/"
    install -m 0755 "${WORKSPACE_ROOT}/CasaOS-MessageBus/build/scripts/setup/script.d/05-setup-message-bus.sh" "${setup_dir}/"
    install -m 0755 "${WORKSPACE_ROOT}/CasaOS-AppManagement/build/scripts/setup/script.d/06-setup-app-management.sh" "${setup_dir}/"

    mkdir -p "${stage_dir}/build/sysroot/var/lib/casaos"
    printf '%s\n' "${RELEASE_TAG}" >"${stage_dir}/build/sysroot/var/lib/casaos/fork-release"

    create_archive "${stage_dir}" "${OUTPUT_DIR}/${OVERLAY_FILE}"
    echo "Packaged compatibility overlay as ${OVERLAY_FILE}"
}

# fill_installer <output install.sh>
# Every value install.sh needs at run time is a placeholder in the committed
# script and is written here from components.env and the published checksums.
fill_installer() {
    local target="$1"
    local key value

    install -m 0755 "${INSTALLER_ROOT}/install.sh" "${target}"

    while IFS='=' read -r key value; do
        [[ -n "${key}" && "${key}" != \#* ]] || continue
        sed -i "s|__${key}__|${value}|g" "${target}"
    done <"${COMPONENT_LOCK}"

    local overlay_sum
    overlay_sum="$(sha256sum "${OUTPUT_DIR}/${OVERLAY_FILE}" | awk '{ print $1 }')"
    sed -i "s|__CASAOS_COMPAT_OVERLAY_SHA256__|${overlay_sum}|g" "${target}"

    local arch
    for arch in amd64 arm64 arm-7; do
        local upper="${arch//-/}"
        upper="${upper^^}"

        sed -i "s|__CASAOS_APP_MANAGEMENT_SHA256_${upper}__|$(fetch_checksum CasaOS-AppManagement "${CASAOS_APP_MANAGEMENT_VERSION}" "linux-${arch}-casaos-app-management-${CASAOS_APP_MANAGEMENT_VERSION}.tar.gz")|g" "${target}"
        sed -i "s|__CASAOS_CORE_SHA256_${upper}__|$(fetch_checksum CasaOS "${CASAOS_TAG}" "linux-${arch}-casaos-${CASAOS_TAG}.tar.gz")|g" "${target}"
    done

    if grep -qE '__[A-Z][A-Z0-9_]*__' "${target}"; then
        echo "Unfilled placeholders remain in install.sh:" >&2
        grep -oE '__[A-Z][A-Z0-9_]*__' "${target}" | sort -u >&2
        exit 1
    fi

    bash -n "${target}"
}

# release_notes
# Prints the CHANGELOG.md section of this release: its "## [x.y.z]" heading
# up to the next release heading. The updater dialog renders it as Markdown.
release_notes() {
    local heading="## [${RELEASE_TAG#v}]"
    local notes

    notes="$(awk -v h="${heading}" '/^## /{p=(substr($0,1,length(h))==h)} p' "${INSTALLER_ROOT}/CHANGELOG.md")"
    [[ -n "${notes}" ]] || fail "CHANGELOG.md has no section for ${RELEASE_TAG}."

    echo "${notes}"
}

# json_string <text>
# Prints text as a JSON string literal.
# ponytail: escapes what Markdown prose contains; other control characters
# would need jq, which the local machines this runs on do not have.
json_string() {
    local s="$1"

    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\r'/\\r}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"

    printf '"%s"' "${s}"
}

write_version_manifest() {
    local notes
    notes="$(release_notes)"
    printf '%s\n' "${notes}" >"${OUTPUT_DIR}/release-notes.md"

    printf '{\n  "version": "%s",\n  "change_log": %s\n}\n' \
        "${RELEASE_TAG}" \
        "$(json_string "${notes}"$'\n\n'"https://github.com/${GITHUB_OWNER}/CasaOS-Install/releases/tag/${RELEASE_TAG}")" \
        >"${OUTPUT_DIR}/version.json"
}

write_checksums() {
    (
        cd "${OUTPUT_DIR}"
        sha256sum "${OVERLAY_FILE}" install.sh casaos-uninstall components.lock version.json >checksums.txt
        sha256sum install.sh >install.sh.sha256
    )
}

package_overlay
fill_installer "${OUTPUT_DIR}/install.sh"
install -m 0755 "${INSTALLER_ROOT}/casaos-uninstall" "${OUTPUT_DIR}/casaos-uninstall"
install -m 0644 "${COMPONENT_LOCK}" "${OUTPUT_DIR}/components.lock"
write_version_manifest
write_checksums

echo "Release bundle written to ${OUTPUT_DIR}"
