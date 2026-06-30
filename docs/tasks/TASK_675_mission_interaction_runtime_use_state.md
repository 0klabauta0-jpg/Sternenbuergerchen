# TASK_675 - Mission Interaction Runtime Use State

## Ziel / Problem
Nach TASK_674 sind Door-/Computer-/Hold-Interaction-Points im Szenario gebunden. Es fehlt der naechste lesbare Runtime-Schritt: Welche Interaction ist anhand aktueller Fireteam-Positionen nahe, bedienbar, blockiert, in Arbeit, unterbrochen oder abgeschlossen?

## Sinnhaftigkeit / Ursache
Ohne Runtime-Use-State sieht die Mission zwar, welche Marker gebunden sind, aber nicht, ob ein Fireteam dort gerade sinnvoll handeln kann. Spaetere UI-Buttons, Door-Animationen oder Computer-Hold-Feedback brauchen diese Information, duerfen aber keine zweite Gameplay-Wahrheit im HUD erzeugen.

## Umfang
- `MissionInteractionRuntimeUseState` als read-only Mission-Contract-Helper anlegen.
- Aktiven Binding-Snapshot, Terrain-Markerpositionen, Fireteam-Anker und optionale Interaction-Runtime-States zusammenfuehren.
- `MissionTacticalSandboxController.get_mission_interaction_runtime_use_state_snapshot()` als on-demand Fassade anbieten.
- Doku, Roadmap, Status und HTML-Handbuch fortschreiben.
- Verifier fuer direkte Helper-Faelle und Controller-Integration anlegen.

## Nicht-Ziele
- Kein Use-Button.
- Keine Door-Animation.
- Kein Computer-Hack-Minispiel.
- Keine SimulationRoot-Mutation.
- Kein HUD-Hotpath-Refresh.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_674_mission_interaction_point_bindings.md`
- `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`
- `docs/dev/runtime_script_layout_contract.md`

## Akzeptanzkriterien
- Der Runtime-Use-State liefert `usable`, `out_of_range`, `blocked`, `in_progress`, `interrupted`, `complete` oder `unknown`.
- Naehe wird aus Terrain-Markerpositionen und aktiven Fireteam-Ankern abgeleitet.
- Cargo-Hold ist am Alpha-Spawn nutzbar, solange AA nicht als Szenario-Abhaengigkeit blockiert.
- Cargo-Hold bleibt blockiert, solange `disable_air_defense` nicht komplett ist.
- Komplettierte Runtime-Gates melden die betroffenen Interactions als `complete`.
- Snapshot und Controller-Fassade setzen `ui_sets_gameplay_truth = false`.
- Der Verifier `scripts/tests/task_675_mission_interaction_runtime_use_state.gd` laeuft gruen.

## Betroffene Dateien
- `scripts/mission/mission_interaction_runtime_use_state.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_675_mission_interaction_runtime_use_state.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_675_mission_interaction_runtime_use_state.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_675_mission_interaction_runtime_use_state.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_674_mission_interaction_point_bindings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Snapshot ist noch keine Interaktionsausfuehrung. Als naechstes braucht es entweder ein kleines UI-Feedback/Use-Command oder echte Runtime-State-Produzenten fuer Hold-/Operate-Fortschritt.
