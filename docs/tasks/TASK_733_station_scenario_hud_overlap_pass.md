# TASK_733 - Station Scenario HUD Overlap Pass

## Ziel / Problem
Nach TASK_732 ist die naechste Stationshandlung als `CUE ...` sichtbar. In der Mission-Control-/ACT-Zeile stand aber weiterhin auch die komplette Route. Dadurch droht die knappe HUD-Flaeche wieder zu dicht zu werden, obwohl die Route bereits im Mission-Identity-Body steht.

## Sinnhaftigkeit / Ursache
Die Route-Line und die Cue-Line beantworten unterschiedliche Fragen. Der Identity-Body beantwortet "wo sind wir im Ablauf?", die ACT-Zeile soll "was jetzt?" beantworten. Beides in derselben kurzen ACT-Zeile ist redundant und nimmt Karten-/Leseflaeche.

## Umfang
- Mission-HUD-Density priorisiert die `CUE ...`-Zeile in der ACT-Flaeche.
- Die volle Route bleibt als Source-Snapshot erhalten und wird im Identity-Body angezeigt.
- Neuer read-only Review-Snapshot `get_station_scenario_hud_overlap_pass_snapshot()`.
- Verifier prueft Route-in-Identity, Cue-in-ACT, keine doppelte Route in ACT, Zeichenbudget und read-only-Vertrag.
- Status-, Roadmap-, Contract- und Handbuch-Update.

## Nicht-Ziele
- Kein neues HUD-Layout.
- Kein SceneTree-Rebuild und kein visueller FullHD-Abnahmeersatz.
- Kein automatisches Ausfuellen des TASK_727-Workbench-Exports.
- Keine Mission-, Door-, Cargo- oder Multiplayer-Mutation.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_732_station_scenario_route_cue_polish.md`
- `docs/tasks/TASK_727_station_scenario_f6_host_client_playtest_notes.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Mission-Control-/ACT-Line enthaelt die `CUE ...`-Zeile.
- Die komplette Route-Line bleibt im Identity-Body sichtbar und als Source im Density-Snapshot erhalten.
- Die ACT-Line enthaelt nicht gleichzeitig die volle Route-Line, wenn eine Cue-Line aktiv ist.
- Snapshot bleibt read-only: `read_only = true`, `ui_sets_gameplay_truth = false`.
- Zeichenbudget und `visible_line_count <= max_visible_line_count` bleiben eingehalten.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_733_station_scenario_hud_overlap_pass.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_733_station_scenario_hud_overlap_pass.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_732_station_scenario_route_cue_polish.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_730_station_scenario_targeted_playtest_polish.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
Der Pass reduziert Textdichte im HUD, ersetzt aber keinen echten Fensterblick. Wenn die Karte nach TASK_733 weiter verdeckt oder unruhig wirkt, sollte ein echter TASK_727-Workbench-Export die naechste konkrete Politur treiben.
