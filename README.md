# crowsnest-modules

Game modules for [CrowsNest](https://github.com/fiddler110/CrowsNest). A module is one YAML file that teaches
CrowsNest to run one game server: its container, ports, settings form, when it counts as online, who is connected,
and (optionally) how to back it up and restore it. There is no code in a module.

**Every module lives in its own folder here and is complete on its own**, so you can take one, several or all of them.

```
crowsnest-modules/
├── README.md              this file
├── sevendtd/              one module = one folder, named after the module's id
│   ├── module.yaml        the module (the only file CrowsNest needs)
│   ├── module.yaml.sig    its signature (only needed if you want CrowsNest to verify who published it)
│   ├── sample.log         a log of the game's startup and some joins/leaves, to test the module against
│   └── README.md          what was tested, what the module needs from the operator's policy
├── _template/             a starting point for a new module (copy it; scripts skip folders starting with _)
├── scripts/               check.sh, sign.sh, install.sh
└── keys/                  your signing key (git-ignored; never commit it)
```

Contents: [Using a module](#using-a-module-operators) · [Writing a module](#writing-a-module-authors) ·
[Signing and publishing](#signing-and-publishing) · [The scripts](#the-scripts) · [When it doesn't work](#when-it-doesnt-work)

---

## Using a module (operators)

A module does nothing until three things are true: it is **installed**, your **policy allows** what it asks for, and a
**game is added** from it. CrowsNest's own guide is `docs/writing-modules.md`; this is the short version.

### 1. Get it into CrowsNest

`modules_dir` must be set in `config.yaml` (the quickstart uses `/app/data/modules`). Pick one way:

**A. From its address (checked and pinned; recommended).** Publish or find the module at an https address (see
[Publishing](#signing-and-publishing); for this repo on GitHub that is
`https://raw.githubusercontent.com/<owner>/<repo>/<branch-or-tag>/sevendtd/module.yaml`), then either run

```sh
docker compose exec crowsnest crowsnest module install https://…/sevendtd/module.yaml
```

which lists everything the module would do (image, ports, environment, backup command, anything that loosens
isolation) and asks you to type its id, or use **Games, Game modules from a source** in the dashboard, which shows the
same list and asks for your password. Either way the exact bytes are pinned by sha256 in `modules.lock.json`; if the
file changes later it stops loading until you approve it again (`module update <id>`, or **Check for update** in the
dashboard, which shows what the new version adds and removes).

To have CrowsNest check *who* published it, add the publisher's public key to `config.yaml` (the publisher gives you
the line; this repo's is in [keys](#signing-and-publishing)):

```yaml
managed:
  trusted_keys:
    - {name: publisher, public_key: "<base64 public key>"}
```

With a key listed, the signature at `<address>.sig` must verify (the install says "signed by the trusted key …"), the
dashboard can only install signed modules, and an update that drops the signature is refused. The panel only fetches
https from **public** addresses (a LAN, loopback or Tailscale address is refused).

**B. By hand, from a clone.** For a file you have read and trust, copy the folder(s) you want:

```sh
git clone https://github.com/<owner>/<repo> && cd crowsnest-modules
scripts/install.sh /path/to/modules_dir sevendtd            # one
scripts/install.sh /path/to/modules_dir sevendtd othergame  # several
# which is just:  mkdir -p <modules_dir>/sevendtd && cp sevendtd/module.yaml <modules_dir>/sevendtd/
```

Copies made this way are not pinned and not signature-checked. Needs the `crowsnest` binary on PATH (or
`CROWSNEST=/path`) to validate first; copying the file yourself needs nothing.

Then **restart CrowsNest**: modules load at start. The log says `modules: "<id>" not loaded: …` with the reason if one
was left out.

### 2. Let the policy allow it

The dashboard only creates what `policy.yaml` permits; a module cannot widen it. The module's folder README lists what
that module needs. In general: its **image** (Docker Hub images fully qualified, e.g. `docker.io/didstopia/7dtd-server`)
in `images:` beside `@modules`, its **ports** in `ports:`, `exec: true` if it has a `backup:`, and an *exception*
naming the one container if it asks for anything beyond the envelope (extra networks, seccomp options). A module
installed from an address also needs its switch turned on under **Games** (your password is asked). The Games page
**Preview** says exactly which rule a game fails.

### 3. Add a game and check it works

Games, pick the module, choose an id (it becomes the container name), fill in the options (secrets are stored
separately), Preview, Enable. Start it: it should read *starting*, then *online* when the ready line appears, and the
player count should follow joins and leaves. If not, capture the container's log and replay it:

```sh
docker logs <container> > real.log
crowsnest module check /path/to/modules_dir/<id> --log real.log
```

---

## Writing a module (authors)

Start from `_template/`: `cp -r _template mygame`, then edit. **The folder name is the module id**, and `id:` inside
`module.yaml` must match it (lowercase letters, digits and dashes).

### What a module folder contains

| File | Needed | Purpose |
|---|---|---|
| `module.yaml` | **yes** | the module itself |
| `module.yaml.sig` | to be signed | ed25519 signature over the exact bytes of `module.yaml` (`scripts/sign.sh`) |
| `sample.log` | **strongly recommended** | real (or faithfully hand-written, say which) log of one start-up, a join and a leave; `scripts/check.sh` replays it so a broken pattern is caught |
| `README.md` | recommended | the exact image/tag and game version tested, what is verified and what is not, what the operator's policy must allow |

A module can **only describe**: an image, ports, data folders, environment, log patterns, one backup/restore command.
It cannot run anything on the host or ask for host networking, capabilities or privileges; the guard checks every
container against the operator's `policy.yaml` whatever the module says. Keep it that way: don't ask for exceptions
unless the game truly needs them, and say so in the README if you do.

### `module.yaml`, section by section

The authoritative key list is `internal/modules/manifest.go` in CrowsNest. **Unknown keys are errors** (a typo cannot
silently switch something off). Look at the `sevendtd` module here, and at the bundled `minecraft`, `palworld` and
`valheim` modules in the CrowsNest repo, for working examples.

**Identity**

```yaml
api_version: 1            # always 1
id: mygame
name: My Game             # shown on the card
accent: "#38bdf8"         # optional card colour
description: "One or two sentences for the Games page."
```

**`runtime`**: how to run the container

```yaml
runtime:
  ram: 4g                 # typical use; start is refused when the host has less free. CrowsNest swaps in the measured peak after a run
  memory: 6g              # optional hard cap (the container is killed above it)
  image: example/mygame   # repository, NO tag. Omit to make the operator choose
  stable_tag: stable      # optional: the image's stable tag, offered next to latest
  stop_grace: 60s         # how long Docker waits for the server to save on SIGTERM; give it enough
  restart_cooldown: 30s   # optional: wait before a start that follows a stop
  data_dir: MyGame        # folder under the operator's games_root
  ports:                  # only what PLAYERS connect to; admin ports (RCON, REST, telnet) stay unpublished
    - {port: 7777, proto: udp, why: "players connect here"}
  data:
    - {path: /data}                    # <games_root>/MyGame mounted at /data
    - {path: /saves, sub: world}       # a subfolder: <games_root>/MyGame/world mounted at /saves
  env:
    - SERVER_NAME=${server_name}       # ${key} is replaced by the option of that name
```

One port line per protocol and per port (a range is several lines). Every game also gets five reserved options
without declaring them: `image`, `tag`, `ports`, `data_dir`, `ram`.

**`options`**: the settings form

```yaml
options:
  - {key: server_name, label: Server name, default: My CrowsNest server}
  - {key: admin_password, label: Admin password, secret: true, managed_required: true}
  - {key: rcon_addr, label: RCON address, derive: "{id}:25575"}
```

`default` pre-fills; `required: true` forces a value; `secret: true` keeps it out of every rendered file (stored
sealed and passed to the container as a variable, so use it for every password); `derive` fills a value from the game's
id when left empty (`{id}` is also its container name on the games network, `{env:key}` the variable a secret is
passed in); `managed_required: true` makes the dashboard demand it. `connect: [{label: Join password, option:
server_password}]` shows option values players need on the card.

**`status` and `players`**: online and who is on

```yaml
status:
  ready_log: 'Server is listening on port'      # this line = online; until then "starting"
players:
  type: log_markers
  join:  '\[INFO\] (\S+) connected'              # group 1 = the player
  leave: '\[INFO\] (\S+) disconnected'
  world: 'Loading world "([^"]+)"'               # optional, group 1 = world name
```

Match something that only appears once the server is truly ready, anchor join/leave so chat lines can't match, and
keep the ready line out of both. Other types: `source_rcon` (Source engine `status`), `http_json` (a REST API,
see `palworld`), `none` (online whenever the container runs; idle auto-stop then never stops it).

**`startup`**: the progress bar while booting (optional)

```yaml
startup:
  - {match: 'Loading config', pct: 30, label: Reading config}
  - {match: 'Server is listening on port', pct: 100, label: Server ready}
```

`startup_progress: {match: '…(\d+)%', from: 10, to: 85, label: 'Downloading ({pct}%)'}` maps a number in the log to a
range of the bar.

**`backup`** and restore (optional)

```yaml
backup:
  exec: ["/bin/sh", "-c", "mkdir -p /data/backups && tar czf /data/backups/manual-$(date +%Y%m%d-%H%M%S).tar.gz -C /data world"]
  dir: /data/backups      # where the command writes, directly in this folder (no subfolders); create it in the command
  before_stop: true       # also back up before every stop
  keep: 14                # optional: keep the newest N files (needs the image to have sh, find, sort, tail, cut)
  restore: ["/bin/sh", "-c", "set -e; rm -rf /data/world; tar xzf \"$CROWSNEST_RESTORE_FILE\" -C /data; chown -R \"$(stat -c %u:%g /data)\" /data/world"]
```

`exec` runs with `docker exec` in the running game; the policy needs `exec: true`. `restore` runs as the entrypoint of
a one-shot container of the game's image while the game is **stopped**, with the same folders (backups read-only) and
the chosen file in `$CROWSNEST_RESTORE_FILE`: remove the old saves, unpack exactly as `exec` made it, chown, `set -e`.
Restore only what the game cannot regenerate (never settings the options write on every start). **Test a restore on a
copy of a real world before publishing it.**

**Optional extras**: `host_setup:` (steps only the operator can do, shown beside the form), `rcon:` (raw admin
console), `api:` + `info:` + `actions:` + `pre_stop:` (a REST API: status fields, buttons, a save before stop),
`host_setup` and `connect`. `palworld` and `minecraft` in CrowsNest show each.

### Test it

```sh
scripts/check.sh mygame              # valid? replays sample.log? signature current?
crowsnest module check mygame --log real.log    # against a log captured from a real run
```

It shows when the game would have counted as ready, which startup steps fired, and each join and leave. If the READY
line never appears, the `ready_log` pattern is wrong: that is the usual bug, and a pattern that does not match real
output is why a hand-written `sample.log` must be labelled as such. Then install it into a test CrowsNest and start
a real game from it before calling it done.

---

## Signing and publishing

Signing lets operators who trust your key verify that **you** published these exact bytes. It does not review the
file (read it) and a signed module is no more trusted by the policy than an unsigned one.

```sh
crowsnest module keygen publisher            # writes publisher.key (SECRET) and prints the public key line
mkdir -p keys && mv publisher.key keys/      # keys/ is git-ignored; back it up, never commit it
scripts/sign.sh                              # signs every module (or: scripts/sign.sh mygame); re-run after EVERY edit
scripts/check.sh                             # confirms every .sig matches its file
```

The signature is ed25519 over `crowsnest-module-v1\n` plus the exact bytes of `module.yaml`, base64 on one line, stored
as `module.yaml.sig` beside it. **Any edit, even whitespace, invalidates it**: commit the module and its `.sig`
together. Tell people your public key through a channel they already trust (your README, a release note); a key
pulled from the same place as the module proves nothing.

The public key for the modules in this repository:

```yaml
managed:
  trusted_keys:
    - {name: publisher, public_key: OzuKyYzMpWBZrFtKy9MMumlEY5isVbJI/MVrL4sJCyk=}
```

To publish: host the repo's files over https at stable addresses (GitHub raw URLs work; use a tag or a commit in the
URL so a file cannot change under people), with `module.yaml.sig` at the same address plus `.sig`. Optionally publish
the file's `sha256sum` so installers can pin it with `--sha256`. State what you tested (image and tag, game version,
which behaviours are verified), and treat a change to the image, ports or environment as something installers must
re-approve; note it in a changelog.

## The scripts

| Script | Does |
|---|---|
| `scripts/check.sh [module ...]` | validates each module, replays its `sample.log`, and confirms its `.sig` matches the current file (re-signs a copy with your key and compares). Exit code is non-zero on any failure |
| `scripts/sign.sh [module ...]` | validates then signs; key from `keys/publisher.key` or `KEY=path` |
| `scripts/install.sh <modules_dir> <module> ...` | validates and copies the named module folders into a CrowsNest `modules_dir` |

They need the `crowsnest` binary on PATH, or `CROWSNEST=/path/to/crowsnest`. Modules are named by folder (`sevendtd`) or path.

## When it doesn't work

| What you see | Likely cause |
|---|---|
| `check` fails with an unknown key or a YAML error | a typo; unknown keys are errors on purpose |
| `module.yaml changed since it was signed` | edited after signing: `scripts/sign.sh <module>` |
| install says `not signed by a trusted key` / dashboard refuses | the key is not in `managed.trusted_keys`, or the `.sig` is missing or stale |
| install says the address is refused | the panel only fetches https from public addresses |
| `modules: "x" not loaded: … changed` | file differs from its pinned hash: `crowsnest module update x` |
| Module not on the Games page | not installed in `modules_dir`, or CrowsNest not restarted |
| Preview says it falls outside the policy | add the image, port or exception to `policy.yaml` |
| Stuck on *starting* | `ready_log` never matches; replay a real log with `check --log` |
| *Online* with 0 players | `join`/`leave` don't match, or group 1 is not the player |
| Start refused for memory | `runtime.ram` is larger than the host's free memory |

## Modules here

| Folder | Game | Image | Status |
|---|---|---|---|
| `sevendtd` | 7 Days to Die | `didstopia/7dtd-server` | valid, signed, installs end to end; log patterns, backup and restore not yet run against a real server |
