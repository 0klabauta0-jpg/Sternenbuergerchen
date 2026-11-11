# Orbit destination catalog V3 draft â€” frozen data slice

Source base: 9813c7dcd. New helper only; the existing V2 JSON, live three-marker parser/UI and all runtime owners remain untouched. No product caller was added.

`check.gd` reads the actual existing `data/singleplayer/star_system.json` and runs 11 scenario checks: mutation-free deep copy, six singleton targets and draft validation, preserved five IDs/first markers/bodies/location bindings, canonical Sun marker (58,128) without a surface, station exclusion and Polisa/Glut2 binding, canonical 512x256 local areas and unchanged strategic 256x256 grid, migration-only aliases, invalid unknown body/marker rejection, Sun collision/bounds rejection, and independent output ownership/source-file equality. Result: `ORBIT_DESTINATION_DRAFT_RESULT checks=11 failures=0 runtime_wired=false`.

`compile.log`: Godot 4.6.2 individual helper `--check-only`, Exit 0, engine banner only.

Commands from worktree root:

```powershell
godot_console --headless --path . --script output/native_glut_maps/orbit_destination_catalog_draft_20261111/check.gd
godot_console --headless --path . --script scripts/mission/orbit_destination_catalog.gd --check-only
```

Default user-data directory. This is pure in-memory data compilation and a source JSON read; no RuntimeOwner is instantiated and no profile/save write or isolated-profile canary is claimed. Autoload startup may print its normal debug banner. No GPU, native visual, battle, broad suite or performance acceptance. Alias tables are future explicit migration inputs, never permission to remap stale normal commands. Runtime V3/parser/Save migration and full Warp/local-flight/limb/surface wiring remain open.

SHA256SUMS.txt lists the new slice files and labels existing read-only dependencies separately. No commit or push.

Review regression: exactly one added scenario groups raw q, grid-size and ring-radius +2^32, plus V3 Sun radius +2^32. raw_wrap_red.log records the reproduced pre-fix rejection failure (11/1). Current check.log is GREEN 11/0. Raw coordinates must satisfy row and offset-column bounds before any Vector2i cast; raw size values compare directly to expected dimensions; radius and ring radius are bounded to the strategic map maximum256 before ceil/multiply/cast. No broader security matrix or runtime change.
