# Don't Starve Together (`dontstarve`)

Dedicated server images that print the master shard's log to the container log (`jamesits/dst-server`,
`mathielo/dst-dedicated-server`). Online and players are read from that log (`sample.log`).

This module has **no `runtime:` section**, so it is not offered on the Games page: it is for a game defined in
`config.yaml` (and its compose file) that names it, `module: dontstarve`. Install it into `modules_dir` (see the
main README), restart, and the game gets its status and player count. If you run a caves shard, point the game at
the master shard's container only.

**Verified:** the patterns replay correctly against `sample.log`, which is written from the documented log format,
not captured from a server. Confirm on a real session.

Moved here from CrowsNest's bundled modules; CrowsNest keeps a test copy.
