# Campaign active continue — integration evidence, 2026-11-12

The production path (no `CAMPAIGN_ACTIVE_TEST_ONLY` or orbit opt-in) saved
through `GlobalEscapeMenu.save_current_mission_slot`, reconstructed the real
campaign via Continue, completed the satellite interaction and return using
real commands, flew home and uploaded the chip. It then saved a newer home
checkpoint and verified that Continue selected home while the obsolete active
file remained byte-identical. `production_continue.log`: **80 passed, 0 failed**;
runner 1/1 PASS. Godot 4.6.2 headless, isolated APPDATA, default orbit path,
Glut 1a native 512×256 map. No actor, position, game clock or progress patches.
Two existing scene UID warnings resolved through text paths.

`regression_report.json`: **10/10** checks passed, including campaign menu
routing and foreign shell-slot protection, legacy home checkpoint, preparation
continue, local flight/fleet/surface, systems/navigation and planned-order
guards. The earlier integrated owner bundle passed 9/9. `home_write_failure.log`
records a real failed home write against a file-as-directory fixture and checks
that the existing active file remains byte-identical. Its reproducible probe is
`scripts/tests/campaign_home_failure_preserve_verifier.gd`; it requires a copy
of an isolated real profile containing both checkpoints and POLISA_TEST_PROFILE.

Scope: one stable, landed, legacy-ground campaign mission, unchanged roster and
home layout, with all original crew deployed. The HUD escape menu routes Save
to the campaign owner; five-minute autosave attempts the same guarded path.
Movement, planned orders, combat, unsupported interactions, multiple locations,
active shuttles, changed home layouts and active orbit/transit remain guarded.
Orbit capability remains disabled by default, and local in-flight file
save/continue is **not** established by the owner-level tests. The visual
appearance, multiplayer, broad performance, 5-minute wall-clock interval and
other mission states are not accepted by this evidence. The continuation and
stale-file fallback above used ordinary user entry, not test capability flags.
