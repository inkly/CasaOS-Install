# Changelog

All notable changes to the CasaOS fork installer are documented here.

## [0.4.53] - 2026-09-06

Components: CasaOS-UI `v0.4.42`; CasaOS `v0.4.43`, AppManagement `v0.4.24`, UserService `v0.4.19`, Gateway `v0.4.20`, MessageBus `v0.4.19`, LocalStorage `v0.4.30` unchanged.

### Fixed

- The QR code on the two-factor enrolment screen rendered as an unscannable 192x28 band: the account panel is mounted inside the top bar's dropdown, where Bulma caps an image at 1.75rem. It is square at its natural size again, with the four-module quiet zone the QR specification asks for.

## [0.4.52] - 2026-09-06

Components: LocalStorage `v0.4.30`, CasaOS-UI `v0.4.41`; CasaOS `v0.4.43`, AppManagement `v0.4.24`, UserService `v0.4.19`, Gateway `v0.4.20`, MessageBus `v0.4.19` unchanged.

### Fixed

- A disk without SMART data (a QEMU/Proxmox virtual disk, a device in standby or one smartctl cannot open) was shown as damaged in the storage widget while the Disk tab called it healthy. LocalStorage now sends a three-state `smart_status` (passed, failed, unavailable) from one helper on every path, and the dashboard shows "No SMART data" / "N/A" for it.
- The system-status dial printed "0.0W / 0°C" on a machine without power and temperature sensors; it prints nothing when neither answers.
- `install.sh` copied the uninstall script it downloads from the release to `/usr/bin/casaos-uninstall` without checking it, although the release's `checksums.txt` carried its digest and every package was verified. The download is now checked against a digest written into `install.sh` at release time from the shipped `casaos-uninstall`; a mismatch stops the install before anything is copied.

## [0.4.51] - 2026-09-06

Components: AppManagement `v0.4.24`; CasaOS `v0.4.43`, CasaOS-UI `v0.4.40`, UserService `v0.4.19`, Gateway `v0.4.20`, MessageBus `v0.4.19`, LocalStorage `v0.4.29` unchanged.

### Fixed

- In AppManagement, a `.env` or compose change whose app then fails to start puts the previous `docker-compose.yml` and `.env` back and starts the previous app from them; before, the new files stayed on disk while the previous containers were gone.
- Every package the installer downloads is now verified against a SHA-256 digest before extraction. Up to v0.4.50 only the CasaOS core, the AppManagement package and the compatibility overlay were checked; the Gateway, MessageBus, UserService and LocalStorage packages, the dashboard, CasaOS-CLI and the App Store were downloaded from their pinned tags and extracted without a check. The Gateway, MessageBus, UserService, LocalStorage and CasaOS-CLI digests come from the `checksums.txt` each of those releases publishes; the dashboard and App Store releases publish none, so their digests are computed from the published tarball when the release bundle is made, which pins the tarball as it was at that moment. The CasaOS-CLI and App Store tags moved from `install.sh` into `release/components.env`.
- The release bundle script now fails when a digest cannot be fetched; before, a fetch failure inside `sed`'s argument was ignored by `set -e` and would have left an empty digest in `install.sh`.

## [0.4.50] - 2026-09-06

Components: CasaOS-UI `v0.4.40`; CasaOS `v0.4.43`, AppManagement `v0.4.22`, UserService `v0.4.19`, Gateway `v0.4.20`, MessageBus `v0.4.19`, LocalStorage `v0.4.29` unchanged.

### Changed

- The dashboard's contact bar keeps two links, to the issues and the repository of inkly/CasaOS; the smart-home block and the app installer's AutoFill hint point at the issues instead of the upstream Discord.

### Removed

- The contact bar's Discord link, in-app feedback form and share dialog.
- The news feed from the upstream blog (an RSS feed fetched from blog-casaos.zimaspace.com), its settings switch, its consent dialogs and the RSS dependency.

## [0.4.49] - 2026-09-06

Components: CasaOS-UI `v0.4.39`; CasaOS `v0.4.43`, AppManagement `v0.4.22`, UserService `v0.4.19`, Gateway `v0.4.20`, MessageBus `v0.4.19`, LocalStorage `v0.4.29` unchanged.

### Fixed

- After an update the user was signed out again a second or two after signing in on the new services: the update dialog's sign-out went through the router guard, whose API call settled only after the next login. The dialog now clears the session locally and reloads the page once the backend answers, each probe bounded to three seconds, the reload once.

## [0.4.48] - 2026-09-06

Components: CasaOS `v0.4.43`, CasaOS-UI `v0.4.38`, AppManagement `v0.4.22`, UserService `v0.4.19`; Gateway `v0.4.20`, MessageBus `v0.4.19`, LocalStorage `v0.4.29` unchanged.

### Added

- Two-factor authentication on the account: a TOTP authenticator enrolled with the password and a code, eight single-use recovery codes, a code step on the login page fed by a five-minute pre-auth token, and a "Two-factor authentication" row in the account panel to turn it on or off. Code and password checks are limited to five a minute per user, a code is accepted once, and every write the routes make to the 2FA columns is a compare-and-set on the row as read. `casaos-user-service -ru -user <name>` resets the password and clears 2FA.
- A `.env` per installed app, edited from a new Environment tab through `GET`/`PUT /v2/app_management/compose/{id}/env`; `${KEY}` references to it, and to `AppID`, `TZ`, `PUID` and `PGID`, survive every settings save and App Store update instead of being baked into `docker-compose.yml`. A `.env` that defines a key the runtime sets itself is refused with a `400` naming the key; a compose whose typed field (`cpus`, `mem_limit`, `privileged`) holds a reference fails to load for editing with a `500` naming the field; a failed load or pull after a `.env` change restores the previous `.env` and `docker-compose.yml`.

### Changed

- ESLint is a CI gate for the dashboard: `pnpm lint` runs `eslint .`, the flat config follows the tree's conventions, one layout pass reformatted 204 files, and a production build with named ids and mangling disabled is byte-identical before and after for 369 of 370 emitted files; the ci workflow runs the lint before the tests and the build. 0 errors, 472 warnings.
- The core no longer carries the `httper.OasisGet` helper, which fetched a bearer token from IceWhale's `api.casaos.io`, nor the `ServerApi` and `Handshake` lines of the sample configuration; a `casaos.conf` that still has them keeps working.

### Fixed

- Four follow-ups to the v0.4.47 dark theme and Vue 3 move: the network graph was empty; the app card menu and the file browser's menus had lost their styling; the Appearance list in the settings panel was unreadable in the dark theme; after an update the browser kept the previous UI until a manual reload, so the update dialog now reloads the page once it has signed out.
- A login attempted while the server could not be reached showed no message; it now falls back to the request error's own message.
- Two lock copies go vet reported in the core's notification service.

## [0.4.47] - 2026-09-06

Components: CasaOS-UI `v0.4.37`; CasaOS `v0.4.42`, Gateway `v0.4.20`, AppManagement `v0.4.21`, MessageBus `v0.4.19`, UserService `v0.4.18`, LocalStorage `v0.4.29` unchanged.

### Added

- A dark theme for the dashboard: light, dark or follow the system, chosen in the settings panel.

### Changed

- The dashboard runs on Vue 3.5 with Buefy 3.1 and Bulma 1.0, same components, same look.

### Fixed

- Links back to the palette's blue; switch focus rings and select placeholders restored; the storage widget's disk summary no longer truncated to the disk name in 28 languages; the app installer's port field accepts ports again.

## [0.4.46] - 2026-09-06

Components: CasaOS-UI `v0.4.36`; CasaOS `v0.4.42`, Gateway `v0.4.20`, AppManagement `v0.4.21`, MessageBus `v0.4.19`, UserService `v0.4.18`, LocalStorage `v0.4.29` unchanged.

### Changed

- The dashboard is fully translated into French: the seventy-six strings of the system package updates, merged storage, the Compose editor, share accounts and Time Machine shares that were still shown in English.

## [0.4.45] - 2026-09-05

Components: CasaOS-UI `v0.4.35`; CasaOS `v0.4.42`, Gateway `v0.4.20`, AppManagement `v0.4.21`, MessageBus `v0.4.19`, UserService `v0.4.18`, LocalStorage `v0.4.29` unchanged.

### Fixed

- The "App launching" row of the settings panel has the shape of its neighbours: an icon, a title line and the panel's spacing, with the current mode as its description. The settings panel and the App launching dialog are translated into French.
- Dashboards before v0.4.34 render the upgrade log as Markdown and ran its lines together. The installer now ends each log line with a Markdown hard break when its output is not a terminal, so the one update every existing host makes through such a dashboard reads line by line.

## [0.4.44] - 2026-09-05

Components: CasaOS-UI `v0.4.34`; CasaOS `v0.4.42`, Gateway `v0.4.20`, AppManagement `v0.4.21`, MessageBus `v0.4.19`, UserService `v0.4.18`, LocalStorage `v0.4.29` unchanged.

### Fixed

- An in-app update never reached its end in the dashboard. The dialog waits for "CasaOS upgrade successfully" or "CasaOS upgrade failed" in the upgrade log, lines the previous updater wrote and this installer never did. It writes them now whenever its output is not a terminal.
- The upgrade log is readable. Run from the dashboard, the installer coloured every line and let wget print its dot progress into the log; colours and the progress bar are now used only on a terminal. The dashboard shows the log as text that follows its own tail instead of running it through the Markdown renderer.

### Changed

- The update dialog shows the release's changelog section, followed by the link to the release, instead of the link alone. The same section is the body of the GitHub release.

## [0.4.43] - 2026-09-05

Components: CasaOS-UI `v0.4.33`; CasaOS `v0.4.42`, Gateway `v0.4.20`, AppManagement `v0.4.21`, MessageBus `v0.4.19`, UserService `v0.4.18`, LocalStorage `v0.4.29` unchanged.

### Fixed

- The dashboard is built for production: its JavaScript drops from 31.3 MB to 13.0 MB and no longer carries Vue's development build.
- The dashboard bundle no longer embeds the environment of the machine that built it.
- The memory slider snaps to the nearest mark instead of showing 256 MB for a hand-edited limit; the drop page no longer throws when left within a second.

### Changed

- Fifteen dashboard dependencies removed; seven abandoned Vue 2 libraries replaced by code in the repository. Groundwork for Vue 3.

## [0.4.42] - 2026-09-04

Components: CasaOS `v0.4.42`, Gateway `v0.4.20`, CasaOS-UI `v0.4.32`, AppManagement `v0.4.21`, MessageBus `v0.4.19`, UserService `v0.4.18`, LocalStorage `v0.4.29`.

### Fixed

- The compatibility overlay no longer points an installed host at another fork's release feed. The setup script it carries wrote `alvins82/CasaOS-Install` URLs into `/etc/casaos/casaos.conf` on every install, so the dashboard updater polled that feed, believed the host was up to date, and would have installed that fork. Hosts installed before this release need one manual run of the install command to be repaired.
- The gateway's self health check retried forever instead of ten times when a listener never answered.

## [0.4.41] - 2026-09-04

Components: CasaOS `v0.4.41`, CasaOS-UI `v0.4.32`, AppManagement `v0.4.21`, Gateway `v0.4.19`, MessageBus `v0.4.19`, UserService `v0.4.18`, LocalStorage `v0.4.29`.

### Security

- The file manager API of CasaOS core now requires a token from loopback as well; UserService and LocalStorage are unchanged.

### Added

- A share can be marked as a Time Machine destination.
- The gateway can bind its public port to a single address.

### Fixed

- Environment values no longer gain a `$` on every save of an app's settings.
- The internal 5-second status posts no longer flood journald.
- The App Store survives having no populated category, shows apps with an empty architecture list, and counts categories the way it lists them.
- The updater panel no longer prints the version twice over.

## [0.4.40] - 2026-09-04

First release of the inkly distribution. Components: CasaOS `v0.4.40`, CasaOS-UI `v0.4.31`, AppManagement `v0.4.20`, Gateway `v0.4.18`, UserService `v0.4.18`, MessageBus `v0.4.18`, LocalStorage `v0.4.29`.

### Changed

- The installer is assembled by a workflow from the components' own releases; every SHA-256 it verifies is fetched from the component's published `checksums.txt`, and the build refuses to publish with a placeholder left unfilled.
- Gateway, MessageBus and UserService are downloaded from this distribution's releases instead of upstream tags frozen in 2024, so their Go-side fixes ship for the first time.
- The uninstaller is a release asset; it was fetched from `get.casaos.io` with TLS verification disabled. rclone is no longer redirected to that server.

### Added

- Authenticated Samba shares with account management and in-place conversion, a Compose editor for installed apps, configurable in-page app launching, HTTPS on the gateway with a supplied certificate, a token required on root-privileged routes even from loopback, the device fingerprint removed from the dashboard.
- Welcome banner names the distribution and credits upstream.

## [0.4.39] - 2026-08-20

### Changed

- No functional code changes since v0.4.38. Re-pin the component releases to the commits now merged into their fork `main` branches:
  - CasaOS LocalStorage `v0.4.27` → `v0.4.28` (commit `fc5bbd3`). This is a republish from `main` after the boot fixes were merged ([CasaOS-LocalStorage #10](https://github.com/alvins82/CasaOS-LocalStorage/pull/10)); the binary sources are byte-identical to v0.4.27, and the repository CHANGELOG now carries backfilled v0.4.26/v0.4.27 entries plus the v0.4.28 republish note.
  - CasaOS AppManagement `v0.4.19` commit pinned from PR-branch tip `bd428f9` to the merge commit `40f2a6f` (identical tree); this is also the commit of the first tagged release of the fork, [CasaOS-AppManagement v0.4.19](https://github.com/alvins82/CasaOS-AppManagement/releases/tag/v0.4.19).
- Republish the CasaOS core packages and the compatibility overlay with the matching `v0.4.39` release marker.

### Verification

- The republished core tarballs are byte-identical to the v0.4.38 release assets (digests verified against the installer's embedded constants, unchanged in v0.4.39).
- The AppManagement v0.4.19 tarballs are reused verbatim from v0.4.38 (digests unchanged); `git diff bd428f9 40f2a6f` on the AppManagement fork is empty.
- The v0.4.39 overlay differs from the v0.4.38 overlay only in the `fork-release` marker.
- The LocalStorage `v0.4.28` assets are published by the `alvins82/CasaOS-LocalStorage` release workflow from tag `v0.4.28`; `git diff v0.4.27 v0.4.28` on that fork shows only the CHANGELOG.md change.

## [0.4.38] - 2026-08-20

### Fixed

- Fix a crash loop found during the first reboot test of v0.4.37: the AppManagement storage recovery sweep called `SetStatus` with a bare cron context that carried no event properties, so `PropertiesFromContext` returned a nil map and `SetStatus` panicked with “assignment to entry in nil map”, restarting the service every ~5 seconds (NRestarts reached 42 before the service gave up).
- Bump CasaOS AppManagement to `v0.4.19` (commit `bd428f9`), which wraps the recovery sweep context with `common.WithProperties` before calling `SetStatus` and adds a defensive nil-map guard in `SetStatus` itself.
- Republish the CasaOS core packages and the compatibility overlay with the matching `v0.4.38` release marker.

### Verification

- The republished core tarballs are byte-identical to the v0.4.37 release assets (digests verified against the installer’s embedded constants).
- The AppManagement `v0.4.19` packages are cross-compiled for amd64, arm64, and arm/v7 with the same static build settings; a file-by-file diff against the v0.4.18 packages shows only the two `sysroot/usr/bin` binaries differ.
- The v0.4.38 overlay differs from the v0.4.37 overlay only in the `fork-release` marker.

## [0.4.37] - 2026-08-20

### Changed

- Bump CasaOS LocalStorage to `v0.4.27` (commit `3d66a74`), which restores all persisted mergerfs mounts during the before-docker `casaos-local-storage-first` init step so `/DATA` is ready before Docker starts, closing the boot window that left user apps unable to start.
- Bump CasaOS AppManagement to `v0.4.18` (commit `9462e3a`), which adds a periodic recovery sweep that starts apps left `exited` because merged storage was not mounted yet at boot and writes stop markers so apps the user explicitly stopped are never started back.
- Republish the CasaOS core packages and the compatibility overlay with the matching `v0.4.37` release marker.

### Verification

- The republished core tarballs are byte-identical to the v0.4.36 release assets (digests verified against the installer’s embedded constants and the v0.4.36 checksum manifest).
- The AppManagement `v0.4.18` packages are cross-compiled for amd64, arm64, and arm/v7 with the same static build settings; the tarball layout matches the v0.4.17 packages file for file.
- The v0.4.37 overlay differs from the v0.4.36 overlay only in the `fork-release` marker; the LocalStorage and AppManagement setup scripts are unchanged between the component versions.
- The LocalStorage `v0.4.27` assets were published by the `alvins82/CasaOS-LocalStorage` release workflow from tag `v0.4.27`.

## [0.4.36] - 2026-08-20

### Changed

- Bump CasaOS LocalStorage to `v0.4.26` (commit `3dd54c6`), which keeps restoring merge mounts every 30 seconds until their source disks appear, reports the offending entries when a merge mount point is not empty, and surfaces the last restore failure through the `merge/init` status endpoint.
- Republish the CasaOS core and AppManagement packages from the verified v0.4.35 bundle and the compatibility overlay with the matching `v0.4.36` release marker.

### Verification

- The republished core and AppManagement tarballs are byte-identical to the v0.4.35 release assets (digests verified against v0.4.35 checksums and the installer’s embedded constants).
- The v0.4.36 overlay differs from the v0.4.35 overlay only in the `fork-release` marker.
- The LocalStorage `v0.4.26` assets were published by the `alvins82/CasaOS-LocalStorage` release workflow from tag `v0.4.26`.

## [0.4.35] - 2026-08-15

### Fixed

- Correct the two truncated AppManagement SHA-256 constants in v0.4.34 and verify exact 64-character digests for amd64, arm64, and arm/v7.
- Publish the compatibility overlay with the matching `v0.4.35` release marker.

### Changed

- Keep the component pins from v0.4.34: CasaOS core `v0.4.28`, CasaOS UI `v0.4.30`, and LocalStorage `v0.4.25`.

### Verification

- Verify all package digests against the release bundle checksum manifest and independently validate the installer’s embedded architecture-specific values.

## [0.4.34] - 2026-08-15

### Fixed

- Correct the hardcoded SHA-256 values for the v0.4.33 fork packages so downloads pass verification during upgrades.
- Publish the compatibility overlay with the matching `v0.4.34` release marker.

### Changed

- Keep the component pins from v0.4.33: CasaOS core `v0.4.28`, CasaOS UI `v0.4.30`, and LocalStorage `v0.4.25`.

### Verification

- Verify all amd64, arm64, and arm/v7 package digests against the release bundle checksum manifest.

## [0.4.33] - 2026-08-15

### Changed

- Pin CasaOS core `v0.4.28` and CasaOS UI `v0.4.30` in the component lock.
- Record the exact merged CasaOS and CasaOS UI commits used by this full bundle.

### Fixed

- Include the systemd power-action fix and the matching UI shutdown/restart behavior ([CasaOS #26](https://github.com/alvins82/CasaOS/pull/26); [CasaOS-UI #15](https://github.com/alvins82/CasaOS-UI/pull/15)).

### Verification

- Rebuilt the platform-neutral amd64, arm64, and arm/v7 installer bundle.
- Preserved SHA-256 verification for all fork-owned installer assets.

## [0.4.32] - 2026-08-14

### Fixed

- Pin CasaOS LocalStorage `v0.4.25`, which restores persisted mergerfs mounts before creating default `/DATA` directories so upgrades and service restarts retain the configured merged storage ([CasaOS-LocalStorage #9](https://github.com/alvins82/CasaOS-LocalStorage/pull/9)).

### Changed

- Keep the CasaOS core, UI, and other component commits from `v0.4.31` while updating the LocalStorage component lock to merge commit `837e73d9383ffaa585bcf11ef1367d7b8440cfcc`.

### Verification

- Rebuilt the platform-neutral amd64, arm64, and arm/v7 installer bundle.
- Preserved SHA-256 verification for all fork-owned installer assets.

## [0.4.31] - 2026-08-14

### Added

- Publish a platform-neutral amd64, arm64, and arm/v7 bundle containing CasaOS core `v0.4.27` with host-level SMB zeroconf discovery through mDNS/DNS-SD and Windows Web Service Discovery.
- Install Avahi and wsdd opportunistically so discovery remains enabled by default where the distribution provides the packages without making installation or upgrades fail when it does not.

### Changed

- Pin CasaOS core commit `723bc2238447aee2b00e97dc15373a35f5ca7381` and tag `v0.4.27` in the component lock.
- Keep CasaOS UI `v0.4.29`, LocalStorage `v0.4.24`, and the unchanged component commits from `v0.4.30`.

### Fixed

- Configure only the mDNS and WS-Discovery firewall ports required for LAN discovery, without enabling SMB1 or legacy NetBIOS ports.

## [0.4.30] - 2026-08-13

### Added

- Publish the next platform-neutral amd64, arm64, and arm/v7 bundle with the merged-storage default-directory fix.

### Changed

- Pin CasaOS core `v0.4.26`, CasaOS UI `v0.4.29`, and CasaOS LocalStorage `v0.4.24` in the component lock.
- Keep the unchanged Gateway, UserService, MessageBus, AppManagement, CLI, and AppStore component commits from `v0.4.29`.

### Fixed

- Create missing `Documents`, `Downloads`, `Gallery`, and `Media` directories when external merged storage is created, while preserving system `AppData` behavior ([CasaOS-LocalStorage #7](https://github.com/alvins82/CasaOS-LocalStorage/pull/7)).

## [0.4.29] - 2026-08-13

### Added

- Publish a platform-neutral amd64, arm64, and arm/v7 bundle containing the latest CasaOS, UI, and LocalStorage releases.
- Add Files dialog, single-surface dashboard scrolling, corrected hidden-files icons, and storage-volume rename controls to the bundled user experience ([CasaOS #21](https://github.com/alvins82/CasaOS/pull/21); [CasaOS-UI #11](https://github.com/alvins82/CasaOS-UI/pull/11); [CasaOS-UI #12](https://github.com/alvins82/CasaOS-UI/pull/12); [CasaOS-UI #13](https://github.com/alvins82/CasaOS-UI/pull/13); [CasaOS-UI #14](https://github.com/alvins82/CasaOS-UI/pull/14)).

### Changed

- Pin CasaOS core `v0.4.26`, CasaOS UI `v0.4.29`, and CasaOS LocalStorage `v0.4.23` in the component lock.
- Keep the exact merged component commits for the release in the component metadata.

### Fixed

- Add protected storage-volume renaming and immediate filesystem-label refresh after a successful rename ([CasaOS-LocalStorage #6](https://github.com/alvins82/CasaOS-LocalStorage/pull/6)).

## [0.4.26] - 2026-08-13

### Added

- Publish a platform-neutral amd64, arm64, and arm/v7 bundle containing the merged CasaOS, UI, and LocalStorage updates.

### Changed

- Pin CasaOS core `v0.4.25`, CasaOS UI `v0.4.28`, and CasaOS LocalStorage `v0.4.22` in the component lock.
- Keep the exact component commits for CasaOS #20, CasaOS-UI #8–#10, and CasaOS-LocalStorage #5 in the release metadata.

### Fixed

- Ship in-dashboard system package updates with the backend terminal-state reconciliation fix ([CasaOS #20](https://github.com/alvins82/CasaOS/pull/20); [CasaOS-UI #10](https://github.com/alvins82/CasaOS-UI/pull/10)).
- Report accurate nested filesystem usage and disk ownership in Storage Manager ([CasaOS-LocalStorage #5](https://github.com/alvins82/CasaOS-LocalStorage/pull/5); [CasaOS-UI #9](https://github.com/alvins82/CasaOS-UI/pull/9)).
- Add the persistent widget search toggle and remove the sidebar clipping scrollbar ([CasaOS-UI #8](https://github.com/alvins82/CasaOS-UI/pull/8)).

## [0.4.25] - 2026-08-12

### Changed

- Pin CasaOS LocalStorage `v0.4.21`, which excludes system storage from merged `/DATA` branches.
- Pin CasaOS UI `v0.4.27`, which labels system storage as excluded and keeps system AppData available at `/DATA/AppData`.
- Publish a complete platform-neutral installer bundle for amd64, arm64, and arm/v7.

### Fixed

- Preserve the existing system data tree while moving `/DATA` onto external mergerfs storage.
- Keep the fork release marker and update manifest aligned so the CasaOS dashboard can discover and apply this release.

## [0.4.22] - 2026-08-12

### Changed

- Pin CasaOS UI `v0.4.26` for the qBittorrent top-level launch behavior.
