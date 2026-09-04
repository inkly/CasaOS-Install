# CasaOS Installer

This is the installer for the **inkly distribution of CasaOS**: a maintained release of the personal-cloud OS after upstream [IceWhaleTech/CasaOS](https://github.com/IceWhaleTech/CasaOS) stopped shipping in 2025. It builds on [alvins82's fork](https://github.com/alvins82/CasaOS-Install), which kept CasaOS installable on Docker 29 and Ubuntu 26, and adds authenticated shares, a Compose editor, TLS, and a release pipeline that runs entirely in CI.

CasaOS is a trademark of IceWhale. This distribution uses the name to describe what it is a release of, not to suggest any endorsement.

## Install

```bash
curl -fsSL https://github.com/inkly/CasaOS-Install/releases/latest/download/install.sh | sudo bash
```

Supported architectures: amd64, arm64 and arm/v7. The installer detects the distribution and architecture at run time. Ubuntu 26 is supported but not required.

Running the same command on an existing install upgrades it. Installs made from alvins82's or IceWhale's installers can be migrated the same way; the in-app updater then follows this distribution's releases. Do not use `get.casaos.io/update` afterwards: it installs IceWhale's frozen component bundle.

Every package the installer downloads is verified against a SHA-256 digest before extraction. The digests are written into `install.sh` at release time from the checksums each component publishes; none is typed by hand.

## What is in v0.4.40

The first release cut from this account. Compared with alvins82's v0.4.39:

**Sharing**
- Samba shares can be restricted to an account. Accounts are created from the dashboard and are separate from the CasaOS login (Samba needs its own password database); they have no shell and cannot log in to the host. A share can be converted between guest and account access at any time. Every share was world-readable and world-writable before this, with files created as root — and Windows 10 and 11 refuse guest SMB entirely, so shares had stopped working for many users.

**Apps**
- The `docker-compose.yml` of an installed app can be edited from its settings, with server-side validation before anything is applied. This also covers editing labels, which had no UI.
- Opening apps inside CasaOS is now a setting, with a per-app list of exceptions. The default matches the previous behaviour.

**Network**
- The gateway serves HTTPS when a certificate and key are configured in `/etc/casaos/gateway.ini`. Certificates are supplied by the administrator; there is no ACME, which belongs in a reverse proxy.

**Security**
- Routes that act as root on the host — system package updates, Samba account management, share creation — now require a token even from loopback. Any local process, including a container on the host network, could reach them without one.
- The dashboard no longer sends an MD5 of the machine's MAC address to a third party on every load.

**Under the hood**
- Gateway, MessageBus and UserService are built from this distribution's own releases. Their Go-side fixes had never shipped: the previous installer still pulled upstream binaries frozen in 2024, with only their setup scripts patched in an overlay.
- The uninstaller is a release asset instead of being fetched from `get.casaos.io` with TLS verification disabled. rclone is no longer redirected to that server either.
- The test suite of the dashboard is runnable again (vitest was declared but never installed), and a storage test that silently wrote a database into the source tree now uses memory.
- Gateway health checks no longer panic when a service is unreachable — every branch of that check was inverted.

## Components

| Component | Release |
|---|---|
| [CasaOS](https://github.com/inkly/CasaOS) | v0.4.40 |
| [CasaOS-UI](https://github.com/inkly/CasaOS-UI) | v0.4.31 |
| [CasaOS-AppManagement](https://github.com/inkly/CasaOS-AppManagement) | v0.4.20 |
| [CasaOS-Gateway](https://github.com/inkly/CasaOS-Gateway) | v0.4.18 |
| [CasaOS-UserService](https://github.com/inkly/CasaOS-UserService) | v0.4.18 |
| [CasaOS-MessageBus](https://github.com/inkly/CasaOS-MessageBus) | v0.4.18 |
| [CasaOS-LocalStorage](https://github.com/inkly/CasaOS-LocalStorage) | v0.4.29 |

CasaOS-CLI and the App Store are still taken from IceWhaleTech, who continue to maintain them. The exact commits behind a release are in its `components.lock` asset.

## How a release is made

Nothing is built on a workstation.

1. Each component is tagged and its own workflow publishes tarballs and a `checksums.txt`.
2. Those tags and commits are pinned in [`release/components.env`](release/components.env).
3. This repository is tagged. Its workflow checks out the six components at the pinned commits, packages their setup scripts as the compatibility overlay, fetches each component's published digests, writes every tag and digest into `install.sh`, and publishes the result. It refuses to produce an installer with a placeholder left unfilled.

`scripts/build-release-bundle.sh` is that step; it can be run locally with `CHECKSUMS_BASE_URL` pointing at a directory of checksum files to exercise the whole chain before any release exists.

## Uninstall

```bash
sudo casaos-uninstall
```

## History

This distribution started from alvins82's v0.4.39. His release notes are kept here because his work is what made CasaOS installable again on current systems:

<details>
<summary>alvins82's fork changelog (v0.4.26 – v0.4.39)</summary>

- **2026-08-20 — [v0.4.39](https://github.com/alvins82/CasaOS-Install/releases/tag/v0.4.39):** No functional code changes; re-pins components to the commits merged into fork `main`: CasaOS LocalStorage `v0.4.28` (republish after [PR #10](https://github.com/alvins82/CasaOS-LocalStorage/pull/10) merge, byte-identical sources to v0.4.27) and CasaOS AppManagement `v0.4.19` at the merge commit (first tagged release of the AppManagement fork). Core packages and the v0.4.39 overlay are republished.
- **2026-08-20 — [v0.4.38](https://github.com/alvins82/CasaOS-Install/releases/tag/v0.4.38):** Supersedes v0.4.37 by fixing a crash loop found in the first reboot test: the AppManagement recovery sweep called `SetStatus` with a cron context carrying no event properties, panicking on a nil map. Bumps CasaOS AppManagement to `v0.4.19` (commit `bd428f9`), which attaches event properties in the sweep and adds a defensive guard in `SetStatus`. Core packages are republished unchanged.
- **2026-08-20 — [v0.4.37](https://github.com/alvins82/CasaOS-Install/releases/tag/v0.4.37):** Published the full fork bundle with CasaOS LocalStorage `v0.4.27`, which restores all persisted merge mounts during the before-docker init step, and AppManagement `v0.4.18`, which starts apps that were abandoned because storage was not ready at boot while respecting apps the user stopped. Core packages are republished unchanged from v0.4.36.
- **2026-08-20 — [v0.4.36](https://github.com/alvins82/CasaOS-Install/releases/tag/v0.4.36):** Published the full fork bundle with CasaOS LocalStorage `v0.4.26`, which keeps restoring merge mounts until their source disks appear, fails loudly with the offending entries when a merge mount point is not empty, and surfaces the last restore failure in the merge status endpoint. Core and AppManagement packages are republished unchanged from v0.4.35.
- **2026-08-15 — [v0.4.35](https://github.com/alvins82/CasaOS-Install/releases/tag/v0.4.35):** Supersedes v0.4.34 with exact 64-character SHA-256 values for every architecture, including the amd64 and arm/v7 AppManagement packages.
- **2026-08-15 — [v0.4.34](https://github.com/alvins82/CasaOS-Install/releases/tag/v0.4.34):** Corrected the SHA-256 values used to verify the fork packages and republished the compatibility overlay with the matching release marker. This fixes upgrades that stopped during package verification after v0.4.33.
- **2026-08-15 — [v0.4.33](https://github.com/alvins82/CasaOS-Install/releases/tag/v0.4.33):** Published the full fork bundle with CasaOS core `v0.4.28` and CasaOS UI `v0.4.30`. It fixes shutdown and restart handling by using explicit systemd power actions, keeping the UI from reloading after shutdown, and surfacing power-command failures. PRs: [CasaOS #26](https://github.com/alvins82/CasaOS/pull/26), [CasaOS-UI #15](https://github.com/alvins82/CasaOS-UI/pull/15).
- **2026-08-14 — [v0.4.32](https://github.com/alvins82/CasaOS-Install/releases/tag/v0.4.32):** Published the full fork bundle with CasaOS LocalStorage `v0.4.25`, which restores persisted mergerfs mounts before creating default `/DATA` directories so updates and restarts retain the configured merged storage. PR: [CasaOS-LocalStorage #9](https://github.com/alvins82/CasaOS-LocalStorage/pull/9).
- **2026-08-14 — [v0.4.31](https://github.com/alvins82/CasaOS-Install/releases/tag/v0.4.31):** Published the full fork bundle with CasaOS core `v0.4.27`, CasaOS UI `v0.4.29`, and CasaOS LocalStorage `v0.4.24`. It adds host-level SMB zeroconf discovery through mDNS/DNS-SD and Windows Web Service Discovery, with optional Avahi/wsdd dependencies handled without blocking installation or upgrades.
- **2026-08-13 — [v0.4.30](https://github.com/alvins82/CasaOS-Install/releases/tag/v0.4.30):** Published the full fork bundle with CasaOS core `v0.4.26`, CasaOS UI `v0.4.29`, and CasaOS LocalStorage `v0.4.24`. It creates missing `Documents`, `Downloads`, `Gallery`, and `Media` directories in external merged storage while preserving system `AppData` behavior. PR: [CasaOS-LocalStorage #7](https://github.com/alvins82/CasaOS-LocalStorage/pull/7).
- **2026-08-13 — [v0.4.29](https://github.com/alvins82/CasaOS-Install/releases/tag/v0.4.29):** Published the full fork bundle with CasaOS core `v0.4.26`, CasaOS UI `v0.4.29`, and CasaOS LocalStorage `v0.4.23`. It includes the Files App Store-style dialog, one-surface dashboard scrolling, corrected hidden-files icons, storage-volume rename controls, and the matching LocalStorage rename API. PRs: [CasaOS #21](https://github.com/alvins82/CasaOS/pull/21), [CasaOS-UI #11](https://github.com/alvins82/CasaOS-UI/pull/11), [CasaOS-UI #12](https://github.com/alvins82/CasaOS-UI/pull/12), [CasaOS-UI #13](https://github.com/alvins82/CasaOS-UI/pull/13), [CasaOS-UI #14](https://github.com/alvins82/CasaOS-UI/pull/14), [CasaOS-LocalStorage #6](https://github.com/alvins82/CasaOS-LocalStorage/pull/6).
- **2026-08-13 — [v0.4.26](https://github.com/alvins82/CasaOS-Install/releases/tag/v0.4.26):** Added in-dashboard system package updates, accurate nested filesystem usage and disk ownership, and the persistent widget search setting. This bundle pins CasaOS core `v0.4.25`, CasaOS UI `v0.4.28`, and CasaOS LocalStorage `v0.4.22`. PRs: [CasaOS #16](https://github.com/alvins82/CasaOS/pull/16), [CasaOS #17](https://github.com/alvins82/CasaOS/pull/17), [CasaOS #18](https://github.com/alvins82/CasaOS/pull/18), [CasaOS #19](https://github.com/alvins82/CasaOS/pull/19), [CasaOS #20](https://github.com/alvins82/CasaOS/pull/20), [CasaOS-UI #8](https://github.com/alvins82/CasaOS-UI/pull/8), [CasaOS-UI #9](https://github.com/alvins82/CasaOS-UI/pull/9), [CasaOS-UI #10](https://github.com/alvins82/CasaOS-UI/pull/10), [CasaOS-LocalStorage #5](https://github.com/alvins82/CasaOS-LocalStorage/pull/5).

</details>

## Licence

The CasaOS components are published under the Apache License 2.0 and keep their upstream copyright notices. The dashboard repository has never carried a licence file of its own; it is distributed here as part of CasaOS releases, as upstream distributed it.
