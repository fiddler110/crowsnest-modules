# Source engine (`source`)

One module for the Source and GoldSrc family: TF2, CS2, CS:S, CS 1.6, L4D, L4D2, DoD:S, HL2DM and similar. Players
come from RCON `status` (`status-sample.txt` shows the three output shapes it understands). Bots are never counted.

This module has **no `runtime:` section**, so it is not offered on the Games page. Each game is defined in
`config.yaml` (and its compose file) with `module: source` and its own `rcon_addr` and `rcon_password_env` options:

```yaml
- id: tf2
  display_name: Team Fortress 2
  container_name: tf2
  module: source
  options:
    rcon_addr: "tf2:27015"
    rcon_password_env: TF2_RCON_PASSWORD
```

Install the module into `modules_dir` (see the main README) and restart. Without `rcon_addr` the game still starts
and stops, but the player count stays unknown. The server needs RCON on and reachable from the panel over the games
network.

**Verified:** the parsing against `status-sample.txt` (written from the documented formats) in CrowsNest's tests;
not against servers I run.

Moved here from CrowsNest's bundled modules; CrowsNest keeps a test copy.
