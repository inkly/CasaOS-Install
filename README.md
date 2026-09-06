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

## What is in v0.4.46

**The dashboard is fully translated into French.** Everything this distribution added since the fork, from the system package updates and merged storage to the Compose editor, the share accounts and the Time Machine shares, was still shown in English on a French dashboard: seventy-six strings, now translated.

## What is in v0.4.45

**The "App launching" row looks like the rest of the settings panel.** It had no icon, no title line and none of the spacing its neighbours share, so it sat against the panel's edge as a bare label and button. It now has the same structure, and its description line shows the current mode: apps open inside CasaOS, or in a new tab. The settings panel and the App launching dialog are translated into French.

**The upgrade log reads line by line on the dashboards that still render it as Markdown.** Every host installed before v0.4.44 makes one update through a dashboard that turns the log's line breaks into spaces. The installer now ends each log line with a Markdown hard break when its output is not a terminal, which those dashboards render as a line break and which is invisible in the log itself.

## What is in v0.4.44

The in-app update is usable from start to finish.

**The update dialog shows what the release changes.** It used to show only a link to the GitHub release, whose page was itself empty. The release manifest now carries the release's changelog section, the dialog renders it, and the same text is the body of the GitHub release. The v0.4.43 release was updated in place the same way.

**The upgrade log is readable, and the update finishes.** Run from the dashboard, the installer wrote to a log file as if to a terminal: colour codes on every line and wget's dot progress by the thousand. The dialog then fed that log to a Markdown renderer, which merged the lines into paragraphs. Colours and the progress bar are now used only on a terminal, and the dashboard shows the log as text that follows its own tail. The dialog also waited for a "CasaOS upgrade successfully" line that the previous updater wrote and this installer never did, so an in-app update never reached its end in the dashboard; the installer writes it now, and "CasaOS upgrade failed" when it fails.

## What is in v0.4.43

Only the dashboard changes in this release, and none of it is a feature: it is the groundwork for moving the dashboard to Vue 3, landed and shipped on the current stack first so that the move itself carries as little as possible.

**The dashboard is 58% smaller.** Its production build had never been built for production: `.env.production` set `NODE_ENV=prod` while the build tool tests for `production`, so every release since the fork shipped Vue's development build — warnings, the devtools hook, none of the production optimisations. The emitted JavaScript drops from 31.3 MB to 13.0 MB.

**The build no longer writes the build machine's environment into the bundle.** The webpack config replaced the tool's own definitions with `JSON.stringify(process.env)`, so the JavaScript served to browsers carried the user name and home directory of whoever built it — a CI build carries the runner's. Only the four values the code reads are defined now.

**Fifteen dependencies are gone.** Eight were unused; seven were abandoned Vue 2 libraries with no successor, each replaced by a few dozen lines we own — the socket plugin, the tooltips, the memory slider, the breakpoint mixin, the animation directive, the share links and the CodeMirror wrapper. Two visible differences came with that, both deliberate: the "start sharing your files" hint waits for its close button rather than vanishing on any click, and the contact bar's tooltips are anchored so the last one stays inside the window.

**Fixed on the way:** an app's memory limit that is not one of the slider's marks no longer displays as 256 MB; leaving the drop page within a second of opening it no longer throws; the dashboard has its first component mount tests, 18 of them, where it had none.

## What is in v0.4.42

**The in-app updater works again — and this release is the one that repairs it.**

Until now the dashboard's update panel polled the release feed of [alvins82's fork](https://github.com/alvins82/CasaOS-Install), not this one. Four files shipped by CasaOS still carried his URLs, and one of them — the setup script inside this installer's compatibility overlay — wrote them into `/etc/casaos/casaos.conf` on every install, where CasaOS prefers them over its built-in addresses. A host installed from here therefore watched a feed whose newest release was older than what it was running, said it was up to date for good, and would have fetched the other fork's installer had the update ever fired.

An installation made before this release cannot repair itself, because the broken setting is exactly what the updater reads. Run the install command once by hand:

```bash
curl -fsSL https://github.com/inkly/CasaOS-Install/releases/latest/download/install.sh | sudo bash
```

After that the updater follows this distribution on its own, and CasaOS carries a test that fails if a shipped file and the built-in addresses ever disagree again.

Also in this release: the gateway's health check retried forever when a listener never answered — the countdown ran through an unsigned integer and the last decrement wrapped around — so a failed reload left it probing once a second instead of returning the error. And every component repository now has a README that describes what it actually does.

## What is in v0.4.41

**Security**
- The file manager API required no token from loopback, and loopback is not the same as root: any unprivileged local process, or a store app running with `network_mode: host`, could read, write and delete any file on the host as root. It is now behind the same token as the rest, like the Samba and package routes since v0.4.40. Reported upstream as [CasaOS #2566](https://github.com/IceWhaleTech/CasaOS/pull/2566), whose path-traversal framing is wrong and whose sanitizer is not adopted: it would break browsing `/mnt` and `/media`, i.e. every USB drive and cloud mount.

**Sharing**
- A share can be marked as a Time Machine destination. It gets Apple's SMB extensions and smbd advertises it over mDNS, so Macs on the network offer it as a backup disk. Only that share is touched, and a host missing Samba's `vfs_fruit` module is told so instead of getting a share that refuses every connection ([CasaOS #1030](https://github.com/IceWhaleTech/CasaOS/issues/1030)).

**Apps**
- A `$` in an environment variable no longer doubles on every save: `$2a$12$...` became `$$2a$$12$$...` and then `$$$$2a$$$$...`, breaking password hashes and any value containing a dollar sign ([CasaOS #1988](https://github.com/IceWhaleTech/CasaOS/issues/1988)).
- App Store entries declaring an empty architecture list are shown rather than hidden, and the category counts now match the apps actually listed on the host.
- The App Store no longer stops rendering when no category has any app, which happened with only a third-party store registered.

**Network**
- The gateway can bind its public port to one address instead of every interface (`address=` in `/etc/casaos/gateway.ini`), so the dashboard can be kept off an untrusted network without a firewall rule.

**Logging**
- journald no longer receives an access-log line for the internal status posts the services exchange every 5 seconds - about 17 000 lines a day of noise that buried real requests. The telemetry rate is unchanged, so the dashboard graphs keep updating ([CasaOS #2211](https://github.com/IceWhaleTech/CasaOS/issues/2211)).
- The updater panel showed the version twice over, `vv0.4.40`.

## What is in v0.4.40

The first release cut from this account, kept here because it is what v0.4.41 builds on. Compared with alvins82's v0.4.39:

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
| [CasaOS](https://github.com/inkly/CasaOS) | v0.4.42 |
| [CasaOS-UI](https://github.com/inkly/CasaOS-UI) | v0.4.33 |
| [CasaOS-AppManagement](https://github.com/inkly/CasaOS-AppManagement) | v0.4.21 |
| [CasaOS-Gateway](https://github.com/inkly/CasaOS-Gateway) | v0.4.20 |
| [CasaOS-UserService](https://github.com/inkly/CasaOS-UserService) | v0.4.18 |
| [CasaOS-MessageBus](https://github.com/inkly/CasaOS-MessageBus) | v0.4.19 |
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
