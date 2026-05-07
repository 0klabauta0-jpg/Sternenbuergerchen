# LZ Security Air Asset Playability Smoke

## Purpose
TASK_279 links the tactical planning, communication, air-asset threat, explosion feedback and meta recovery loops in one headless smoke. The smoke is intentionally small: it verifies integration contracts and readable feedback, not final balance.

## Fixture
- Map fixture: `res://maps/test_lz_air_asset_threat_fixture.json`
- Size: 32x32.
- Markers: `lz_secure`, `lz_risky`, `enemy_at_team`, `objective_point`.
- Enemy AT role: `rocket_launcher`, `heavy_weapon_role = anti_armor`.

## Smoke Matrix
| Path | Setup | Expected result |
| --- | --- | --- |
| success path | Two Fireteams create a coordinated take-area plan, LZ security is high, AT contact receives first valid shot. | Air asset shows warning/lock only, integrity remains full, role communication and map role markers stay visible. |
| threat path | Enemy AT has LOS, range, FoW visibility and low LZ security. | Warning includes cause, `air_asset_threatened` communication, and tactical breakout. |
| loss path | The same threat fires again after warning with lethal damage. | `air_asset_explosion` VFX/SFX payload, crashed AirAssetStatus, destroyed communication, destroyed breakout, and SimulationRoot status. |
| meta path | Mission result carries crashed AirAssetStatus into MetaLayerFlow. | Debrief shows replacement ETA, Homebase/FOB block launch/boarding, `softlock_guard` clears after recovery timer. |

## Authority Boundary
- Air asset gameplay status is written through `SimulationRoot` effects.
- TacticalController exposes status and communication as snapshots only.
- Recovery is a `MetaLayerFlow` state, not UI truth.
- Required snapshot fields remain present: `runtime_authority`, `ui_sets_gameplay_truth = false`, `terminal_state`, `vfx_events`, `sfx_events`.

## Readability Notes
- The first eligible AT contact is a warning. The player gets a response window before damage.
- The loss path must emit both communication and breakout records, so the failure is explained as an Enemy-AT/LZ-security problem.
- Homebase and FOB must show unavailable/replacement state and prevent a lost craft from starting another mission.

## Local Check
- `godot_console.exe --headless --path . --script scripts/tests/task_279_lz_security_air_asset_tactical_playability_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- `git diff --check`
