# Versioned orbit catalog/display readiness — frozen

Source base562373d13. Product edits only: scripts/core/strategic_hex_grid.gd, scripts/mission/orbit_destination_catalog.gd, scripts/ui/star_map_screen.gd, scripts/ui/star_map_canvas.gd. Own task ORBIT_CATALOG_DISPLAY_READINESS_2026_11_11.md and new orbit_catalog_display_readiness_contract.md. No JSON/Adapter/Travel/Fleet/Root/EXE edit. No staging or commit by this agent.

GRID V2 constants remain five orbits and three marker IDs. New orbits_for_version returns copies for2/3, empty otherwise. Explicit Product builder shares existing strict Draft geometry but removes Draft status and never returns alias data. Product/Draft validators are mutually exclusive. UI reads body_id links and marker records from the owner catalog, not a second hardcoded target list. V2's previous four-row order and all fifteen catalog marker coordinates remain; valid Glut2/Polisa fills the previously omitted fifth row. V3 product shows six singleton targets including Sun. Sun has no surface/approach/landing; station has no extra orbit. Existing command IDs and semantics stay. UI checks are structural display filtering, never gameplay authority.

check.log: ORBIT_CATALOG_DISPLAY_RESULT checks=10 failures=0 live_catalog_switched=false. Actual Screen/Canvas plus actual pure builders/Grid; controlled fullsnapshot/command Callables. Scenarios: copied version maps/V2 constants; existing Draft path/source unchanged; explicit Product geometry/alias exclusion and reciprocal validator rejection; false-draft/migration/raw-wrap rejection; V2 marker preservation and added Polisa row; V3 generic captions/targets/station exclusion; no Sun approach; existing jump command; no unchanged control rebuild/copied definitions; Draft display reject and V2 restoration/source file equality.

Four individual --check-only logs (Grid, Catalog, Screen, Canvas): Godot4.6.2 Exit0, banner only. Commands from worktree root:

```powershell
godot_console --headless --path . --script output/native_glut_maps/orbit_catalog_display_readiness_20261111/check.gd
godot_console --headless --path . --script scripts/core/strategic_hex_grid.gd --check-only
godot_console --headless --path . --script scripts/mission/orbit_destination_catalog.gd --check-only
godot_console --headless --path . --script scripts/ui/star_map_screen.gd --check-only
godot_console --headless --path . --script scripts/ui/star_map_canvas.gd --check-only
```

Default user-data directory; no save/profile write or isolated-profile canary claim. No GPU/native visual, battle, broad matrix or aesthetic acceptance. Existing runtime still selects live V2. Separate Product/Runtime migration and activation remain Parent/Source work. SHA256SUMS records exact working-file bytes and read-only JSON dependency.
