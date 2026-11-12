# 7 Days to Die (`sevendtd`)

Dedicated server from the `didstopia/7dtd-server` image, ports 26900 tcp+udp and 26901-26903 udp. The web
dashboard (8080) and telnet (8081) are not published.

| | |
|---|---|
| Image | `didstopia/7dtd-server` (the module pins no tag; the dashboard offers latest) |
| Memory | `runtime.ram: 8g` (the game wants 4g at least, 8g to 16g recommended) |
| Data | `<games_root>/7DaysToDie/server-files` (game install) and `.../server-data` (saves, config) |
| Backup | tars `server-data` to `/app/.local/share/7DaysToDie/backups`; restore puts back `Saves/` only |
| Players | read from the log: `Player connected, entityid=…, name=…` and `Player … disconnected after …` |
| Ready | `GameServer.LogOn successful` |
| Policy needs | image `docker.io/didstopia/7dtd-server`, those five ports, `exec: true` (backup) |

**Verified:** the file is valid, the signature matches, and `sample.log` replays correctly. `sample.log` is written by
hand from the documented log format, **not** captured from a real server, so confirm the ready and player patterns on
a first real session (`docker logs <container> > real.log`, then `crowsnest module check sevendtd --log real.log`).
The backup and restore commands and the image's environment names are likewise untested against a running server.
