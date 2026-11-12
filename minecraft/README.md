# Minecraft (`minecraft`)

Java edition, `itzg/minecraft-server` (vanilla, Paper, Fabric and Forge print the same server lines). Port 25565/tcp.
The world is saved on stop; a backup pauses writes over RCON (`rcon-cli`, enabled by the image) and tars `world/`;
restore puts `world/` back.

| | |
|---|---|
| Image | `itzg/minecraft-server` (a `stable` tag is offered next to `latest`) |
| Memory | `runtime.ram: 3g`; the Java heap is the `memory` option (2G default) |
| Needs from the policy | image `docker.io/itzg/minecraft-server`, port `25565/tcp`, `exec: true` (backup) |
| Players | read from the log (`<name> joined the game` / `left the game`) |
| Ready | `Done (…s)! For help, type "help"` |

The EULA must be accepted with the `eula` option (`TRUE`). **Verified:** the markers against `sample.log` (a
documented-format session) and `sample-real-26.3.log` (a real 26.3 start-up, no players). Backup and restore were
written for the image's layout and tested in CrowsNest's own tests, not on a long-running server.

Moved here from CrowsNest's bundled modules; CrowsNest keeps a test copy.
