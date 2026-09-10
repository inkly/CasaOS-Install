# Changelog

All notable changes to the CasaOS fork installer are documented here.

## [0.4.61] - 2026-09-10

Components: CasaOS-AppManagement `v0.4.31`, CasaOS-UI `v0.4.47`. Unchanged from v0.4.60: CasaOS `v0.4.48`, Gateway `v0.4.22`, UserService `v0.4.21`, MessageBus `v0.4.20`, LocalStorage `v0.4.32`.

### Fixed

- **An app written by hand is no longer shown as stopped while it runs.** The app grid builds its answer starting from `unknown` and fills the status in at the end — but gave up in between when the store info could not be read, which is the case for any compose file with no `x-casaos` section. The status fold was never reached, so the card was greyed out and the icon dimmed on a stack whose containers were all up. Store info is presentation; its absence is not a reason to stop answering what the app is doing.
- **The installation progress bar moves.** Layers were counted only when the daemon announced `Pulling fs layer` and `Pull complete`. A layer this host already has is announced as `Already exists` instead of that pair, so an image already on disk counted nothing at all: the fraction was zero divided by zero, and what came out of it survived both bounds and reached the dashboard as zero. The bar sat at 0 from the first frame to the last, on exactly the installs that finish fastest. The arithmetic across a stack's images was wrong too — the first image of two was capped at half and the bar then restarted from zero for the second.
- **A check that could not verify an app now says which app, and why.** "Apps that could not be checked: 3" is something to worry about and nothing to do. The reason was there all along, one per app, and the dashboard was reducing it to a count. Three are named at a time, so one unreachable registry behind twenty apps does not fill the screen.
- The storage widget's **Free up** button shows that it is working. Reclaiming is synchronous and reports the bytes it actually freed, so until the daemon had finished walking the layers the button looked like it had done nothing.

## [0.4.60] - 2026-09-10

Components: CasaOS-AppManagement `v0.4.30`, CasaOS-UI `v0.4.46`. Unchanged from v0.4.59: CasaOS `v0.4.48`, Gateway `v0.4.22`, UserService `v0.4.21`, MessageBus `v0.4.20`, LocalStorage `v0.4.32`.

Everything here comes from one box, reported in one sitting: a stack somebody wrote by hand is not a second-class app, and an update is not a reason to lose your seat.

### Fixed

- **An update no longer costs two logins.** The update dialog is opened outside the router view, so closing it unmounts the component — and its upgrade-log poll went on running anyway, because unlike the system-package dialog it had no unmount hook. The installer restarts the user service, which generates its signing key in memory at every start, so the browser's tokens stop verifying; that orphaned poll took a 401, the refresh behind it failed, and you were sent to the login page. You signed in, a session was created — and the same poll, now carrying a valid token, finally read `CasaOS upgrade successfully` and cleared the session it never knew about. The dashboard appeared and was taken away about two hundred milliseconds later, and the reload that followed destroyed the page and the poll with it, which is why the second attempt always worked. Landing on the login page after an update is correct: the old tokens really are dead. Landing there twice was not.
- A failed token refresh no longer leaves the page unable to make another request. It kept the refresh flag raised with its queue full, so every later 401 was parked behind a refresh that would never be attempted again and hung for as long as the page lived — which is why the poll above never reported its own error and never stopped itself.
- Signing in navigates as soon as the session is stored. It used to fetch the system version first, for a router-guard cache nothing else read: when that call failed the throw skipped the navigation and left you on the login page, signed in and unable to tell. The guard's other half went with it — it deleted the access token on arrival whenever that cache was missing, so the only way to fill it was the login it sent you back to.
- **The Containers tab works for the stacks it was added for.** A compose file written by hand carries no `x-casaos` section, and the endpoint read the main service out of it — so the tab answered ``extension `x-casaos` not found`` instead of showing the containers, on exactly the multi-service stacks the tab exists for. Which service leads is a question about the compose file and has an answer without the extension: what `x-casaos.main` names, and otherwise the alphabetically first service. `GET /compose/{id}` had the same failure on the same apps.
- **A hand-written stack can be updated at all.** It has no catalogue entry, and that ended the decision before it reached the registry answer — so the card wore the update badge, drawn from that answer, and the button replied "is up to date" in the same breath. Neither is a failure to answer: both mean the update is a re-pull of the tags the app already names, which is what the update now does. Pressing the button through anyway used to fail with the same missing-extension error.
- **A hand-written stack opens with the name it already has.** App Name is required and is filled from the `x-casaos` section, so the field was blank on every service tab: the settings could not be saved until a name was invented, and renaming started from an empty box rather than the name on the card. The app grid has always shown the compose project name for these apps; the editor now starts from the same one, and a title the compose already carries is left alone.

## [0.4.59] - 2026-09-10

Components: CasaOS-AppManagement `v0.4.29`, CasaOS-UI `v0.4.45`. Unchanged from v0.4.58: CasaOS `v0.4.48`, Gateway `v0.4.22`, UserService `v0.4.21`, MessageBus `v0.4.20`, LocalStorage `v0.4.32`. The core no longer ships with every distribution release: `FORK_RELEASE_VERSION` is the distribution the binary was built for, a floor, and `/var/lib/casaos/fork-release` — which the installer writes on every install and upgrade — is what the dashboard reads.

### Added

- **A Containers tab** in the app settings panel: a row per container of every service, with its state in words, Docker health, image, published host ports, uptime and, once it has stopped, its exit code. Replicas of a scaled service each get a row instead of the first one standing in for all of them.
- **Automatic update checks**, every six hours and once three minutes after start, remembered across a restart. Hours rather than minutes because a sweep is one round trip per distinct image and registries rate-limit anonymous callers by IP. Checking is not applying: nothing here recreates a container on its own.
- **Reclaiming the disk old app versions hold**, from the Storage widget. Hidden until there is something to free; names the count and the size before anything is pressed; only ever images no app runs any more, never the image of a stopped app.
- **A CPU limit** in the compose editor, writing `deploy.resources.limits.cpus`. CPU Shares is a relative weight and changes nothing while the host has spare capacity, so it could not express "at most two cores".
- **Timestamps on log lines**, from the daemon rather than from the moment the line was read, plus a 100 / 1000 / whole-log selector and a Download button. The whole log turns the five-second polling off rather than repeating a multi-megabyte round trip.
- **Pull and recreate for a container CasaOS did not install.** Such a container had no action at all.
- `UpWaitTimeout` under `[app]` in `app-management.conf`, the deadline an app is given to report itself running or healthy after it is started. Five minutes remains the default.

### Fixed

- **Editing an app's compose file no longer loses the edit.** Compose calls an app up only once every service is running-or-healthy, which a one-shot init container — a `db-migrate`, a `chown` sidecar — can never be: it exits 0 and compose answers `container X exited (0)` within a poll or two. That was read as a failed apply and the backup went back over the file that had just been saved, on a stack that was running. The daemon is asked what is actually there now: containers running or exited cleanly is an app that settled and the new file stays; a non-zero exit, a restart loop or no answer is still a failure that rolls back. A stack that is merely slow — a VPN handshake plus two services chained on `service_healthy` with 60-second start periods — is covered by the same change and by the new deadline setting.
- **And a bad edit is still a bad edit.** Everything compose does before it touches a container — resolving an image that does not exist, creating a network or a volume, refusing a duplicate `container_name` — fails with the previous definition's containers still running and healthy, and asking them whether the app came up would read the old app as proof that the new one worked. Creating and starting are now two steps: a create that fails is rolled back like any other failed apply, and only what compose actually created answers for the new definition.
- **A finished update could take the app manager down.** Events are published from goroutines that read the property map while the request that started them is still writing to it, and `app:updated` is written at the very end of a recreate. A concurrent map read and write is a Go runtime fatal, not a recoverable error: the process dies and every app on the box stops being managed until it restarts. The window was small and the trigger was the ordinary success path.
- **An update is decided service by service.** The decision read the main service's tag alone, then refused to trust the registries unless every other image matched the catalogue exactly — so a catalogue that bumped only a sidecar was invisible, and a container added by hand threw the whole answer away. The rule that holds is "no service goes backwards and something really changes".
- **The check asks the containers what they run**, not the local image store what a tag points at. The two diverge the moment anything pulls without a successful recreate — a rolled-back update, or another tool pulling on its own — after which the app is permanently up to date while its containers go on running the image they were created from.
- An app is no longer called up to date on half of it. A two-service stack with one image on Docker Hub and one on a registry that was down reported itself current, and the registry nobody could reach was never mentioned.
- A badge no longer outlives the app it was about. Uninstalling a badged app and installing it again under the same name brought the badge back, on an app whose button then refused to act on it — and persisting the cache had made that permanent rather than something a restart cleared. Saving the cache also used one fixed temporary path, so two checks finishing together could publish half a file and blank every badge on the next start.
- A failed container recreate no longer leaves a stray copy behind. The replacement is created under a derived name before the original is touched; when the stop of the original failed, that copy stayed, and the next recreate found its name taken by a container nobody asked for.
- A recreate no longer fails on a container whose volume was written the way people write them. The clone carries the volumes the container's own configuration does not already name, and `-v films:/media/` is kept as typed while the daemon reports that mount point as `/media` — so the volume was carried twice and the daemon refused the whole thing.
- A failed App Store update is reported as one. The update answers immediately and finishes in the background, so the outcome only ever arrives over the message bus; the card read a missing property as "nothing to report" and opened a green "is the latest version!" toast either way. A recreate whose pull had failed was likewise announced as "No newer image was pulled", an unreachable registry arriving as proof that nothing newer exists.
- A failed recreate says so whichever of its two events arrives first. The error is published from a goroutine and the end-of-update from a defer, so the order is a race, and the card dropped whichever came second: a recreate whose pull worked and whose clone then failed reported nothing at all, and the spinner just stopped.
- The compose editor no longer refuses every stack whose project name is not also one of its service names — a rule the backend never had, which made those files permanently unapplicable.
- Logs and the terminal follow the container row they were opened on, instead of showing the whole stack interleaved under one service's name, and the terminal will not open on a container that has gone away since the row was drawn.
- The container list endpoint reports every container of every service; an adopted container now says which compose project owns it, so a stack deployed by Portainer or Dockge is not offered operations that would clone one of its containers out of the project — and, having nothing else it can be offered, no longer carries a menu button that opens onto an empty box.
- A dangling-image prune counts each image's unique bytes rather than its total size, so the figure named before the button is pressed is the one actually freed.

## [0.4.58] - 2026-09-09

Components: CasaOS `v0.4.48`, CasaOS-AppManagement `v0.4.28`; CasaOS-UI `v0.4.44`, Gateway `v0.4.22`, UserService `v0.4.21`, MessageBus `v0.4.20`, LocalStorage `v0.4.32` unchanged.

### Fixed

- The update badge and the update button agree. An app could wear the badge and answer "is up to date" when you pressed the button, at the same moment, because the two were answering different questions: the badge reported what the registries said, and the button reports what an update would actually write, which for an app with a catalogue entry is the catalogue's compose. An image that has moved somewhere the catalogue will not follow is not an update anyone can take, so it is no longer advertised as one. The count reported after a check moves with it.
- An app whose database container had died showed a green dot. The status of a whole app was the state of its main service's first container and nothing else. Every container of every service counts now, the worst state winning, and a state we do not recognise outranks every state we do.
- The container terminal no longer opens blank and silent. Opening it upgrades the connection, which hijacks it, and the handler then answered a failed `docker exec` with a response nobody was reading: an image with no shell, a container that is not running, any failure at all showed as an empty black box. The reason is written to the terminal now.
- A failed container recreate could destroy both the old container and the replacement. When the replacement would not start, the original was restarted and the replacement removed, and then the code carried on into the step that removes the original "if the replacement started successfully". It had not. When the original had been stopped rather than running, nothing was restored at all. No feature reaches this path today, which is why nobody hit it.

## [0.4.57] - 2026-09-09

Components: CasaOS `v0.4.47`, which carries this distribution's tag in the version the dashboard falls back to and is otherwise identical to v0.4.46. Unchanged from v0.4.56: AppManagement `v0.4.27`, CasaOS-UI `v0.4.44`, Gateway `v0.4.22`, UserService `v0.4.21`, MessageBus `v0.4.20`, LocalStorage `v0.4.32`.

### Fixed

- An upgrade no longer stops because a repository of the host's own has gone stale. Refreshing the package lists gave every repository configured on the machine a vote on whether CasaOS may upgrade, and the script runs with errors fatal: a Debian box whose `bullseye-security` Release file had passed its expiry — that mirror stopped updating, nothing to do with this machine — got `apt-get update` exit 100, and the upgrade ended there with `CasaOS upgrade failed` and nothing else attempted. None of those repositories belong to CasaOS. The refresh reports the failure as a notice and the install carries on with the lists the host already has; if a package it actually needs is missing, the next step still says so, naming the package.

## [0.4.56] - 2026-09-09

Components: CasaOS `v0.4.46`, CasaOS-AppManagement `v0.4.27`, CasaOS-UI `v0.4.44`; Gateway `v0.4.22`, UserService `v0.4.21`, MessageBus `v0.4.20`, LocalStorage `v0.4.32` unchanged.

### Fixed

- "Check then update" could install an older version than the one running. Two faults had to line up. The button never checked: it calls the update endpoint with no `force` parameter, the contract says `force` defaults to false, and the generated binding leaves it nil when the query string omits it — but the handler only ran its check when `force` was explicitly false, so an absent one meant "update anyway", and an update writes the store's compose over the local one whatever version it holds. And the check would not have stopped it: it reported an update whenever the store's tag *differed* from the installed one, in either direction, so a catalogue behind the running app read as an available update. An absent `force` now means not forced, and the check only says yes when the store's tag is genuinely newer. `--force` still applies the store's compose in either direction, which is the way to downgrade on purpose.
- Version comparison read `ls99` as newer than `ls124`. Version ordering compares a build suffix letter by letter, and linuxserver.io — most of what a home server runs — tags every image `<upstream>-ls<build>` and crosses that boundary at every hundredth build. Digit runs are compared as numbers now.
- An image on a registry with a port, like `registry.local:5000/app:2.0`, had its tag read as `5000/app:2.0`. Nothing could order that, so the comparison fell through to "any difference is an update" and the catalogue's older version was installed. The tag is what follows the last colon after the last slash.
- A malformed authentication challenge from a registry could stop the app service. The header is written by the registry, and a directive with no value — which a proxy in front of one produces — read past the end of the parsed pair. It also truncated any authentication URL carrying a query string.
- No call to a registry had an overall deadline. The existing timeouts cover connecting and the TLS handshake, not waiting for a reply, so a registry that answered and then went quiet held its connection for the life of the process.
- An image pinned by digest, and a single-segment repository on a private registry, asked their registry for a URL it could not answer, so neither could ever be checked. A digest is a reference in its own right, and `library/` is Docker Hub's implied namespace and nobody else's.
- The version the dashboard falls back to when `/var/lib/casaos/fork-release` is missing now carries the distribution tag. That marker holds the distribution release, so the fallback has to move with the distribution rather than with the core component; the core ships with every release for that reason, and the installer stops and reinstalls every service on each run anyway.

### Added

- `POST /image-updates` asks each installed app's registry what its tag points at now and compares that with the digest of the copy on disk, and the dashboard's apps menu gains **Check for image updates** to run it. This sees an app that came from no app store, which the store's upgradable list cannot, and a tag republished under the same name, which is what `latest` does every time. Registries are asked once per distinct image, eight at a time. An image no answer can be obtained for — never pulled, built locally, registry unreachable, credentials this host does not have — is reported with its reason and keeps the answer it had, rather than counted as up to date.
- Apps with a newer image carry a badge beside their icon on the dashboard, served from the cache that check fills and never computed while the grid loads.

### Changed

- An app that came from no app store can be updated. Updating one used to look for a catalogue entry, find none and fail, so the dashboard hid the button; anything imported as a compose file was installed once and then frozen. For those the update is a pull of the tags the app already names, through the same path that puts the compose file and the `.env` back if the app fails to come up.

## [0.4.55] - 2026-09-07

Components: CasaOS `v0.4.45`, AppManagement `v0.4.26`, Gateway `v0.4.22`, UserService `v0.4.21`, MessageBus `v0.4.20`, LocalStorage `v0.4.32`; CasaOS-UI `v0.4.43` unchanged.

### Changed

- The six components moved their Go module path from `github.com/IceWhaleTech/CasaOS-*` to `github.com/inkly/CasaOS-*`. The path is compiled into the binary, so it is what a log line, a stack trace and `go version -m` report on a running box. Only module paths were rewritten: the App Store catalogue URL, the icon CDN, issue links, upstream credits and the per-file copyright notices are untouched, and so are every filesystem path, systemd unit name, API route and the `x-casaos` compose key.
- All six now depend on `github.com/inkly/CasaOS-Common v0.4.22`, a fork of upstream `v0.4.21` that changes nothing but its own module path. Before this, each pinned a different IceWhale alpha of it, from `v0.4.4-alpha2` to `v0.4.11-alpha4` — immutable on the module proxy, so nothing was at risk of breaking, but nothing in the JWT helpers the services authenticate each other with could be fixed either.
- Gateway, UserService and MessageBus consequently declare `go 1.21` instead of `go 1.20`, because the forked library declares 1.21. The release pipelines already took their Go version from each module's own `go.mod` and needed no change.
- The shared library brings in `orca-zhang/ecache`, whose package initialiser starts a goroutine that sleeps in a loop for the lifetime of the process. It exists on import alone; no component calls the cache it backs.
- Six coverage jobs read their Go version from `go.mod` instead of repeating it in a literal, and five debug release configs no longer name IceWhaleTech as the owner of the draft they would create.

### Fixed

- The dashboard no longer offers an update that is already installed on a box whose `/var/lib/casaos/fork-release` marker is missing. The version the core falls back to in that case is meant to hold the distribution release, which is what the installer writes to that file and what `version.json` announces; it held the core component's own tag, and the two had drifted from equal to eleven releases apart.
- AppManagement's pin in `release/components.env` is named `CASAOS_APP_MANAGEMENT_TAG`, like the five others, rather than `_VERSION`. Adding the expected `_TAG` line beside the odd `_VERSION` one would have built a green bundle that published an installer downloading the previous release of AppManagement: the stale variable still fills its placeholder, the new one matches none, and the unfilled-placeholder guard sees nothing wrong.

## [0.4.54] - 2026-09-07

Components: CasaOS `v0.4.44`, CasaOS-UI `v0.4.43`, AppManagement `v0.4.25`, Gateway `v0.4.21`, UserService `v0.4.20`, LocalStorage `v0.4.31`; MessageBus `v0.4.19` unchanged.


### Fixed

- Building the release bundle locally aborted with `Not a gzip tarball` on a perfectly good archive whenever the output directory was a Windows drive-letter path. The App Store seed is checked where it is kept rather than in the staging directory, and GNU tar reads a path containing a colon as a remote `host:path`. The archive is handed to tar on standard input now, so tar never parses the path at all. The release runner is Linux and was never affected; the local rebuild that verifies a bundle before every release was.
- The compatibility overlay had a different digest depending on which tar packed it, for the same tree: 259 bytes, all of them the `devmajor` and `devminor` header fields that tar 1.34 writes as octal zeros and tar 1.35 leaves null in `ustar` format. It is packed as `gnu` now, where both versions leave them null, so the release runner and a machine rebuilding the release to check it produce the same archive.

### Changed

- Four components generate their message-bus client from this distribution's own tag instead of IceWhale's live `main` branch, and LocalStorage's coverage job no longer runs a reusable workflow hosted in an IceWhale repository.
- The App Store seed the installer downloads is now an asset of the installer's own release. It is still IceWhale's snapshot, fetched from their release when the bundle is built, republished unchanged and pinned by the digest of the copy we serve. This mirrors a snapshot and changes nothing about who curates the catalogue: AppManagement still polls IceWhale's live store feed, the apps and their icons are still theirs. What it removes is the install-time dependency on IceWhale's release still existing — until now, the day that asset went away every new install failed at `wget`.

### Removed

- The geo-IP call five components made on every install and upgrade: `__get_download_domain` curled `ipconfig.io/country` and `ifconfig.io/country_code` to pick a download mirror by country, at the top of the migration script, before it knew whether a migration applied. The download domain is a constant now.
- The dashboard's last two npm dependencies published by IceWhale. The App Store and compose client is generated from this distribution's own OpenAPI document and committed; the other had no import site.
- The geo-IP call `install.sh` made on every install and upgrade. `Get_Download_Url_Domain` curled `ipconfig.io/country`, falling back to `ifconfig.io/country_code`, as the first step of the run, to decide whether the App Store catalogue should be read from GitHub or from IceWhale's Aliyun mirror. Its only remaining reader was that one substitution: the mirror is now chosen explicitly with `CASA_DOWNLOAD_DOMAIN` on the install line, and nothing is contacted to guess it.
- IceWhale's `update.sh` and the stale `casaos-tags`, both at the repository root. `update.sh` installed IceWhale's `v0.4.4` component bundle from their releases; `casaos-tags` pinned component versions frozen since `v0.4.31`. Nothing in this repository reads either and the release workflow publishes neither, so the only channel that ever served them was GitHub Pages under the `CNAME` IceWhale committed in 2021 - a domain this distribution does not own.
- IceWhale's CasaOS-CLI package. It placed `/usr/bin/casaos-cli` and a bash completion, and nothing in the distribution ever invoked either: no service, setup script, migration script, systemd unit or dashboard call. It was the second of the two IceWhale release assets a new install could not come up without. On a box that already has it, the file stays where it is; it is no longer listed in the install manifest, so `casaos-uninstall` no longer removes it.

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
