# TASK_512 - Mission Controller Boundary Slice

## Ziel / Problem
Der Review-Report markiert `scripts/tests/mission_tactical_sandbox_controller.gd` als produktiven, zu breiten Legacy-Controller. Besonders Fireteam-Dropship-/Runtime-Status wird direkt im Controller fuer HUD, Selection und GO-Gates gemischt.

## Sinnhaftigkeit / Ursache
Der sichtbare Spiel-Flow ist inzwischen stabil genug, um erste kleine Grenzen aus dem Legacy-Controller zu ziehen. Der erste Schnitt soll nicht das Verhalten umbauen, sondern den lesenden Fireteam-Runtime-Status normalisieren: eingeboarded, deployed, am Boden sichtbar, als Mini-Card displayable und runtime-aktiv.

## Umfang
- Kleinen Mission-Helper unter `scripts/mission/` anlegen.
- Bestehende Controller-Funktionen weiter anbieten, aber intern an den Helper delegieren.
- Displayable-Fireteam-Berechnung so umbauen, dass Units fuer die Mini-Card-Liste einmal gruppiert werden statt pro Fireteam wiederholt.
- Fokus-Verifier fuer den Helper und die Controller-Anbindung anlegen.

## Nicht-Ziele
- Kein kompletter Mission-Controller-Refactor.
- Keine neue Gameplay-Wahrheit ausserhalb von `SimulationRoot` oder Runtime-State.
- Keine Aenderung an Dropship-Command-/Effect-Authority.
- Keine UI-Neugestaltung.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/dev/combat_loop_authority_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/tasks/TASK_503_mission_dropship_fireteam_hud_truth.md`
- `docs/tasks/TASK_511_export_runtime_package_hygiene.md`

## Akzeptanzkriterien
- Fireteam-Dropship-/Runtime-Lesestatus liegt in einem Mission-Helper, nicht mehr nur als verstreute Controller-Privatlogik.
- Embarked Fireteams bleiben aus der linken Ground-HUD-Liste, deployed Fireteams erscheinen wieder.
- Runtime-active-Gates bleiben kompatibel: im Deferred-Activation-Modus zaehlen deployed Units, im Legacy-Modus sichtbare Units.
- Der Helper speichert keine Gameplay-Wahrheit und enqueued keine Commands/Effects.
- Verifier prueft Helper-Verhalten, Controller-Anbindung und bestehende HUD-Regression.

## Betroffene Dateien
- `scripts/mission/mission_fireteam_runtime_state.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_512_mission_controller_boundary_slice.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_512_mission_controller_boundary_slice.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_503_mission_dropship_fireteam_hud_truth.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Controller bleibt gross; dieser Task ist nur der erste Boundary-Slice.
- Weitere gute Folge-Slices bleiben Dropship-Mission-State, Fireteam-Execution-Adapter und Mission-Result/Objective-Boundary.
