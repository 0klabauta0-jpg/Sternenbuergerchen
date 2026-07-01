# TASK_738 - Station Scenario Identity Cue Visibility Polish

## Ziel / Problem
Der echte Zwei-Fenster-Capture nach TASK_737 zeigt oben links noch den vollen Route-Status mit `CARGO BLOCK | NEXT AA`, waehrend die neue Spieler-Cue `CUE AA: BLUE naeher ran | 3.9km` im ersten Blick nicht prominent genug ist.

## Sinnhaftigkeit / Ursache
Das Harness funktioniert: Host-/Client-Crops und Manifest werden geschrieben. Das Problem ist sichtbar im HUD: Der Identity-Body nutzt die volle technische Route als Display-Zeile. Dadurch konkurriert ein spaeter Cargo-Blocker mit der aktuellen AA-Handlung.

## Umfang
- Der Mission-Identity-Body zeigt die aktuelle Cue vor der neutralen Route.
- Die sichtbare Route wird als Sequenz ohne Future-Blocker dargestellt: `ROUTE AA > DOOR > COM > CARGO | NEXT AA`.
- Die volle Source-Route mit Gate-/Cargo-Status bleibt im Snapshot erhalten.
- Command-Feedback-Snapshot und Label-Metadaten exportieren Cue-Sichtbarkeit und Future-Blocker-Display-Guard.
- Verifier prueft Direkt-Snapshot und Szene bei Station-Szenario.

## Nicht-Ziele
- Kein Aendern von Runtime-Gates, Cargo-State, Objective-State oder Multiplayer-Authority.
- Kein automatisch bestandener menschlicher TASK_727-Playtest.
- Keine Scenario-Harness-Modernisierung, weil der Capture-Lauf funktioniert.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_727_station_scenario_f6_host_client_playtest_notes.md`
- `docs/tasks/TASK_737_station_scenario_visible_cue_run_packet_refresh.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Identity-Body-Text enthaelt `CUE AA: BLUE naeher ran | 3.9km`.
- Identity-Body-Text enthaelt `ROUTE AA > DOOR > COM > CARGO | NEXT AA`.
- Identity-Body-Text enthaelt nicht `CARGO BLOCK`, `CARGO BLOCKED` oder `CARGO blockiert`.
- Snapshot enthaelt die volle `route_line` weiterhin als Source-Daten.
- Snapshot bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_738_station_scenario_identity_cue_visibility_polish.gd`
- `docs/tasks/TASK_738_station_scenario_identity_cue_visibility_polish.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_738_station_scenario_identity_cue_visibility_polish.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_736_station_scenario_command_feedback_polish.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_733_station_scenario_hud_overlap_pass.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_730_station_scenario_targeted_playtest_polish.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
Der Patch verbessert die erste Blickzeile, ersetzt aber keinen echten TASK_727-Fensterlauf. Nach dem Fix sollte erneut gecaptured werden, um zu sehen, ob Cue und Route im echten 1280x720-Fenster angenehm lesen.
