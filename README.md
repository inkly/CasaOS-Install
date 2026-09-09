# CasaOS Installer

This is the installer for the **inkly distribution of CasaOS**: a maintained release of the personal-cloud OS after upstream [IceWhaleTech/CasaOS](https://github.com/IceWhaleTech/CasaOS) stopped shipping in 2025. It builds on [alvins82's fork](https://github.com/alvins82/CasaOS-Install), which kept CasaOS installable on Docker 29 and Ubuntu 26, and adds authenticated shares, a Compose editor, TLS, and a release pipeline that runs entirely in CI.

CasaOS is a trademark of IceWhale. This distribution uses the name to describe what it is a release of, not to suggest any endorsement.

## Install

```bash
curl -fsSL https://github.com/inkly/CasaOS-Install/releases/latest/download/install.sh | sudo bash
```

Supported architectures: amd64, arm64 and arm/v7. The installer detects the distribution and architecture at run time. Ubuntu 26 is supported but not required.

Running the same command on an existing install upgrades it. Installs made from alvins82's or IceWhale's installers can be migrated the same way; the in-app updater then follows this distribution's releases. Do not use `get.casaos.io/update` afterwards: it installs IceWhale's frozen component bundle.

Every package the installer downloads is verified against a SHA-256 digest before extraction, and every one of them is downloaded from an inkly release. The digests are written into `install.sh` at release time from the checksums each component publishes, or — for the dashboard and the App Store seed, whose releases publish no checksums — computed from the package as published; none is typed by hand. The uninstall script the installer downloads is verified the same way, against the digest of the copy shipped in the release.

## What is in v0.4.58

**The dot on an app card tells the truth, the update badge means what the button will do, and the terminal explains itself instead of coming up blank.**

An app whose database container had died showed a green dot. The status of a whole app was the state of its main service's first container and nothing else, so anything that failed alongside it was invisible. Every container of every service counts now, the worst state winning, and a state we do not recognise outranks every state we do.

An app could wear the update badge and answer "is up to date" when you pressed the button, at the same moment. The two were answering different questions: the badge reported what the registries said, and the button reports what an update would actually write, which for an app with a catalogue entry is the catalogue's compose. An image that has moved somewhere the catalogue will not follow is not an update anyone can take, and is no longer advertised as one.

Opening a container terminal upgrades the connection, which hijacks it, and the code then answered a failed `docker exec` with a reply nobody was reading. An image with no shell, a container that is not running, any failure at all: an empty black box and no explanation. The reason is written to the terminal now.

And one that nothing reaches yet, fixed before anything does: a failed container recreate could destroy both the old container and the replacement. When the replacement would not start, the original was restarted and the replacement removed, and the code then carried on into the step that removes the original "if the replacement started successfully" — which it had not. Where the original had been stopped rather than running, nothing was restored at all.

## What is in v0.4.57

**An upgrade no longer stops because a repository of your own machine has gone stale.**

Before installing anything, the installer refreshes the system's package lists so it can find the handful of tools it needs. That step gave every repository configured on the host a vote on whether CasaOS may upgrade, and any failure ended the run. A Debian machine whose `bullseye-security` mirror stopped publishing — so its index had passed its expiry date — saw the whole upgrade stop with `CasaOS upgrade failed`, on a machine where nothing was wrong with CasaOS and every package it needed was already installed.

None of those repositories belong to this distribution. The refresh is best effort now: a failure is reported as a notice and the install continues with the lists the machine already has. If a package it genuinely needs is missing, the next step still stops and names it, which is a message you can act on.

Everything else is unchanged from v0.4.56.

## What is in v0.4.56

**The update button no longer installs an older version than the one you are running, and you can see which apps have a newer image without opening every app's menu.**

"Check then update" could roll an app back, and two separate faults had to line up. The button never checked: it calls the update endpoint without a `force` parameter, and the handler only ran its up-to-date check when `force` was explicitly false, so an absent one meant "update anyway". And the check would not have stopped it, because it reported an update whenever the App Store's tag *differed* from the installed one, in either direction — a catalogue entry sitting behind the running app read as an available update, and taking it was a downgrade. An absent `force` now means not forced, and the check only says yes when the store's tag is genuinely newer.

Three more ways the version comparison got it wrong, each found by reviewing the fix rather than by trusting it. Build suffixes were compared letter by letter, so `ls99` read as newer than `ls124` — and linuxserver.io, which is most of what a home server runs, crosses that boundary at every hundredth build. An image on a registry with a port had its tag read as `5000/app:2.0`, which nothing can order, so the comparison fell through to "any difference is an update". And an image pinned by digest had no tag at all to compare.

The apps menu gains **Check for image updates**. It asks each installed app's registry what its tag points at now and compares that with the copy on disk, and the apps whose image has moved carry a badge next to their icon afterwards. This sees what the App Store's own list cannot: an app nobody publishes a catalogue entry for, and a tag republished under the same name, which is what `latest` does every time. An image that cannot be checked — never pulled, built locally, registry unreachable — is reported separately with the reason and keeps whatever answer it had, rather than being counted as up to date.

**An app that came from no app store can be updated at all now.** Updating one used to look for a catalogue entry, find none and fail, so the dashboard hid the button; anything imported as a compose file was installed once and then frozen. For those the update is a pull of the tags the app already names, through the same path that puts the compose file and the `.env` back if the app fails to come up.

Two things that only ever hurt: a malformed authentication challenge from a registry could stop the app-management service, and no call to a registry had a deadline, so one that answered and then went quiet held its connection for the life of the process.

## What is in v0.4.55

**Every binary this distribution installs is now built from its own source paths, and the shared library the services authenticate each other with is finally one this distribution can patch.**

The six Go modules were still called `github.com/IceWhaleTech/CasaOS-*`. That name is not cosmetic: it is compiled into the binary, so every log line, every stack trace and every `go version -m` record on a running box named a project that has not shipped since 2024. They are `github.com/inkly/CasaOS-*` now. Nothing else moved with them — the App Store catalogue, the icon CDN, the issue links, the upstream credits and the per-file copyright notices are untouched, and so are `/etc/casaos`, `/var/lib/casaos`, the systemd unit names, the API routes and the `x-casaos` key every installed app carries in its compose file.

CasaOS-Common was the last component nobody here had forked, and it is the one that matters most: it holds the JWT helpers the six services use to authenticate each other. Each component pinned a different IceWhale alpha of it, from `v0.4.4-alpha2` to `v0.4.11-alpha4`. Nothing was broken — those versions are immutable on the Go module proxy and would keep building even if the upstream repository vanished — but a bug in shared authentication code was not something this distribution could fix. It is forked now, at upstream `v0.4.21` and unchanged apart from its own module path, and all six components are unified on it. One visible consequence, in the interest of stating it: that library pulls in a small cache whose package initialiser starts a goroutine that sleeps in a loop for the lifetime of the process, in every daemon, for a cache none of them call.

The in-app updater also stops offering an update that is already installed. The version the dashboard falls back to when `/var/lib/casaos/fork-release` is missing was set to the core component's own tag rather than the distribution's, and the two had drifted eleven releases apart.

## What is in v0.4.54

**Nothing this distribution installs asks a third party where you are, and the dashboard takes no package from IceWhale.**

Five of the six components shipped a migration script that called `ipconfig.io/country`, falling back to `ifconfig.io/country_code`, to pick a download mirror by country. The call sat at the top of the script, so it ran on every install and every upgrade — before the script had even decided whether a migration applied, which on a current box it does not. Two third parties therefore learned the country of every machine this distribution was installed on, in a distribution whose whole point is that it removed the phone-home beacon. The call is gone, in all five, and the download domain is a constant: not a setting either, because what it points at is downloaded and run as root without verification.

The dashboard's App Store and compose client used to come from `@icewhale/casaos-appmanagement-openapi` on npm, published by IceWhale, and until this week it was requested as `latest` — whatever the registry served at build time. It is now generated from this distribution's own OpenAPI document and committed to the repository: the same operations, argument for argument, plus the two `.env` routes the published package never had. A second IceWhale package, which no file imported, is gone. Four components also stopped generating their message-bus client from IceWhale's live `main` branch at build time, and one stopped running a reusable CI workflow hosted in an IceWhale repository.

What stays, deliberately: the App Store catalogue and its icons are still IceWhale's, and so is the cloud-drive OAuth redirect. Forking the catalogue means taking over the review of compose files that run as root, and it is still maintained daily at IceWhale's expense.

## What is in v0.4.53

**The two-factor QR code is scannable again; dashboard only.**

On the two-factor enrolment screen the QR code rendered as a 192x28 band of noise, impossible to scan. The account panel is mounted inside the top bar's dropdown, and Bulma caps any image inside a navbar item at 1.75rem: the height was clamped to 28 pixels while the `width="192"` attribute held the width, so the code came out five to seven times wider than tall. The cap is lifted for that image, which is square again at its natural size, and its quiet zone went from one module to the four the QR specification asks for. Verified by decoding the rendered pixels back to the enrolment URL in both themes, at desktop and mobile widths, and at 1.25x, 1.5x and 2x display scaling. Every other component is where v0.4.52 left it.

## What is in v0.4.52

**A disk without SMART data is no longer shown as damaged, a machine without sensors shows no CPU wattage, and the uninstall script is digest-checked.**

On a virtual machine — a QEMU disk under Proxmox, for instance — the storage widget showed a red "Damaged" tag while the storage manager's Disk tab called the same disk healthy. LocalStorage read smartctl's `smart_status.passed` as a plain yes/no, so a disk that has no SMART at all was counted as failed on one path and forced healthy on another. It now reports a three-state `smart_status` — passed, failed, unavailable — computed by one helper for every path: the system-status feed, `/v1/disks` and the storage list. A disk is failed only when SMART says so (or smartctl reports DISK FAILING); a disk smartctl cannot query, one in standby, or one with no SMART is unavailable. The dashboard shows "Healthy", "Damage" or "No SMART data" in the widget and "Healthy", "Damage" or "N/A" in the Disk tab, and keeps working against an older LocalStorage. On the same machine the system-status dial printed "0.0W / 0°C"; it prints nothing when neither a power counter nor a temperature sensor answers.

`install.sh` copied the uninstall script it downloads from the release to `/usr/bin/casaos-uninstall` without a check, although `checksums.txt` carried its digest; it is now verified like the ten packages, against a digest written into `install.sh` at release time. LocalStorage v0.4.30 and CasaOS-UI v0.4.41 move; every other component is where v0.4.51 left it.

## What is in v0.4.51

**Every package the installer downloads is digest-checked, and a failed app start after a `.env` change rolls back.**

Up to v0.4.50 `install.sh` verified a SHA-256 digest on three of the ten packages it downloaded: the CasaOS core, AppManagement and the compatibility overlay. It now verifies all nine before anything is extracted or any service stopped: the six inkly components against the `checksums.txt` their releases publish, the dashboard and the App Store seed — whose releases publish none — against a digest computed from the package as published at release time. The digests are written into `install.sh` by the release workflow; a package whose digest does not match stops the install with `Checksum verification failed`. The release workflow also fails, instead of writing an empty digest, when a checksum cannot be fetched, and the compatibility overlay is built reproducibly, so its digest no longer depends on the machine that packed it.

In AppManagement, a `.env` or compose change whose app then fails to start puts the previous `docker-compose.yml` and `.env` back and starts the previous app from them; before, the new files stayed on disk while the previous containers were gone. Every other component is where v0.4.50 left it.

## What is in v0.4.50

**The dashboard points at this distribution, and stops talking to the upstream blog; dashboard only.**

The contact bar at the bottom right keeps two links: the feedback icon opens the issues of [inkly/CasaOS](https://github.com/inkly/CasaOS/issues), the GitHub icon opens that repository. The Discord link, the in-app feedback form — which built a prefilled issue for IceWhale's repository — and the share dialog are gone, and so are the two remaining Discord invitations, in the smart-home block and in the app installer's AutoFill hint, which point at the issues now.

The news feed from the upstream blog is removed: the brand bar fetched an RSS feed from blog-casaos.zimaspace.com and scrolled the latest posts, behind a "Show news feed from CasaOS Blog" switch in the settings menu and a consent dialog after the first login. The switch, the dialogs, the setting and the RSS dependency are gone; nothing in the dashboard contacts that blog any more. Every other component is where v0.4.49 left it.

## What is in v0.4.49

**One fix, to the update dialog; dashboard only.**

After an update on v0.4.48 the user landed on the login page, signed in on the new services, saw the home page with the changelog, and was thrown back to the login page a second or two later. The update dialog signed out through the router, whose guard awaits an API call before it navigates; started while the services restarted, that call settled only after the next login, and the guard then removed the fresh tokens. The upgrade rotates the token keys, so the session is over either way: the dialog now clears it locally and reloads the page, into the UI just installed, once `/v1/users/status` answers again, or after two minutes regardless; each probe is given three seconds, and the reload happens once. Every other component is where v0.4.48 left it.

## What is in v0.4.48

**Two-factor authentication on the account, a `.env` per installed app, and a lint gate on the dashboard.**

The account panel has a new "Two-factor authentication" row, On or Off, that opens the enrolment: the password, then the QR code and the key as text with a Copy button, then the code from the authenticator app to enable it, then eight single-use recovery codes, shown once with a Copy button. From then on a login answers with a five-minute pre-auth token and the login page swaps the password form for a code step: the 6-digit code from the app, or a recovery code through the link under the field, with a Back link to the password step. The pre-auth token is held in the page's component only; nothing is written to local storage until the code is verified, and the session is then stored by the same path a password login uses. Code and password checks are limited to five a minute per user, right or wrong; a code is accepted once; and every write the routes make to the 2FA columns is a compare-and-set on the row as read, so concurrent requests cannot enable, disable or replay twice. Turning it off asks for the password or a code from the app, one or the other. If the authenticator and the recovery codes are both lost, `casaos-user-service -ru -user <name>` resets the password and clears 2FA. The QR code is drawn in the browser by `qrcode` 1.5.4, loaded only by the enrolment screen. The strings are in English and French.

An installed app may now keep its secrets in a `.env` next to its `docker-compose.yml`. An Environment tab in the app's settings, beside Settings and Compose, edits it through `GET`/`PUT /v2/app_management/compose/{id}/env`: `PUT` replaces the whole file, an empty file deletes it, and applying re-creates the app so the new values apply. A reference to one of its keys — `${KEY}`, `$KEY`, `${KEY:-default}` — or to a key the runtime defines (`$AppID`, `${TZ}`, `$PUID`, `${PGID}`) now survives every settings round trip and the App Store update as written, where before the first save or update baked the resolved value into the compose file and every later `.env` edit was a no-op. Before Apply, the editor checks that every line is blank, a `#` comment or a key line as compose-go's dotenv parser takes one, and asks the server for a dry run before the real apply; a `.env` that defines a key the runtime sets itself (`TZ`, `PUID`, `PGID`, `AppID`) is refused with the key named. When the compose file does not load or the pull fails after a `.env` change, the previous `.env` is put back together with the previous `docker-compose.yml`.

ESLint is a CI gate for the dashboard. `pnpm lint` runs `eslint .`, and the ci workflow runs the lint before the tests and the build, so a pull request with a lint error fails. The lint had been red across the tree since the Vue 3 migration — 39 564 errors — because @antfu/eslint-config's defaults, 2-space and script-first, met a tab-indented, template-first tree. The config now follows what the tree does, each option chosen by counting its violations and keeping the one with fewer; one `eslint --fix --fix-type layout` pass then reformatted 204 files, and the production build before and after — with named ids and mangling disabled so that only the source-dependent hashes had to be normalised — is byte-identical for 369 of the 370 emitted files; the 370th is the static `public/js/custom.js`, which gained a final newline. What is left for a human stays visible as warnings, not turned off: 0 errors, 472 warnings at the gate. Also fixed: a login attempted while the server could not be reached showed no message; it now falls back to the request error's own message.

Four follow-ups to the v0.4.47 dark theme and Vue 3 move, found on a real box: the network graph was empty (apexcharts 4 rejects a chart created before its first sample); the app card menu and the file browser's menus had lost their styling (Buefy 3.1 no longer copies a dropdown's class onto the menu it moves under `<body>`); the Appearance list in the settings panel was unreadable in the dark theme; and after an update the browser kept running the previous UI until a manual reload — the update dialog now reloads the page once it has signed out.

In the core, the unused `httper.OasisGet` helper, which fetched a bearer token from IceWhale's `api.casaos.io` for its own requests, is removed with the `ServerApi` and `Handshake` lines of the sample configuration; a `casaos.conf` that still has them keeps working.

The new features did not run on a live CasaOS. They were verified with unit tests, httptest and a served bundle with API stubs; if something on your box behaves differently from v0.4.47, say so in an issue and downgrade with the previous installer while it is looked at.

## What is in v0.4.47

**A dark theme, and the dashboard on Vue 3.**

Appearance is a new row in the dashboard's settings: light, dark, or follow the system — the default when nothing has been chosen. The choice is kept in the browser and applied before the first paint, so there is no flash, and the login and welcome pages honour it. The glass cards and widgets were already dark and stay identical in both themes; what changes is the chrome over them: the top bar, modals, dropdowns, forms, toasts, the file browser, the App Store, the storage manager ([CasaOS #938](https://github.com/IceWhaleTech/CasaOS/issues/938), the most-requested feature upstream never shipped).

Under it, the dashboard moved from Vue 2.7 — end of life since December 2023 — to Vue 3.5, with Buefy 3.1 and Bulma 1.0, keeping the same components and the same look. The light theme was compared declaration by declaration against v0.4.46 and did not move. Three things were fixed on the way that only a browser could show: every link had darkened with Bulma 1's contrast defaults, the focus ring of switches and the placeholder of empty selects had vanished, and the storage widget's disk summary showed only the disk name in 28 languages.

This is the largest change the dashboard has had since the fork. It was exercised in a served build against stubbed APIs, not on a live CasaOS; if something on your box behaves differently from v0.4.46, say so in an issue and downgrade with the previous installer while it is looked at.

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
| [CasaOS](https://github.com/inkly/CasaOS) | v0.4.48 |
| [CasaOS-UI](https://github.com/inkly/CasaOS-UI) | v0.4.44 |
| [CasaOS-AppManagement](https://github.com/inkly/CasaOS-AppManagement) | v0.4.28 |
| [CasaOS-Gateway](https://github.com/inkly/CasaOS-Gateway) | v0.4.22 |
| [CasaOS-UserService](https://github.com/inkly/CasaOS-UserService) | v0.4.21 |
| [CasaOS-MessageBus](https://github.com/inkly/CasaOS-MessageBus) | v0.4.20 |
| [CasaOS-LocalStorage](https://github.com/inkly/CasaOS-LocalStorage) | v0.4.32 |

The installer downloads every package from an inkly release. The App Store seed — the snapshot a new box needs for its store to be populated before the first refresh — is IceWhale's, mirrored into our release at release time and pinned by the digest of the copy we serve; nothing about the catalogue changes, AppManagement keeps polling IceWhale's live store feed and IceWhale keeps curating it. IceWhale's CasaOS-CLI is no longer installed: nothing in the distribution ever called it. The exact commits behind a release are in its `components.lock` asset.

## How a release is made

Nothing is built on a workstation.

1. Each component is tagged and its own workflow publishes tarballs and, except the dashboard, a `checksums.txt`.
2. Those tags and commits are pinned in [`release/components.env`](release/components.env).
3. This repository is tagged. Its workflow checks out the six components at the pinned commits, packages their setup scripts as the compatibility overlay, fetches the published digest of every package that has one, mirrors the App Store seed, computes the digest of the dashboard and of the mirrored seed from the packages themselves and of the uninstall script it ships, writes every tag and digest into `install.sh`, and publishes the result. It refuses to produce an installer with a placeholder left unfilled.

`scripts/build-release-bundle.sh` is that step. It can be run locally: `WORKSPACE_ROOT` names the directory holding the six component checkouts at the pinned commits, `CHECKSUMS_BASE_URL` is where the six components' `checksums.txt` and the dashboard tarball are downloaded from, and `UPSTREAM_BASE_URL` is where the App Store seed tarball is downloaded from. Both default to GitHub; a `file://` URL pointing at a local tree laid out as `<repo>/releases/download/<tag>/` exercises the whole chain before any release exists.

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
