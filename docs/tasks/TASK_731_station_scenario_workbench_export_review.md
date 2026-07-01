# TASK_731 - Station Scenario Workbench Export Review

## Ziel / Problem
Nach TASK_730 ist der Stationslauf sichtbarer, aber der echte TASK_727-Workbench-Export bleibt offen. Gleichzeitig routete TASK_728 aktive Follow-up-Flags noch auf alte TASK_729/TASK_730-Ziele, obwohl diese Tasks inzwischen erledigt sind.

## Sinnhaftigkeit / Ursache
Der naechste Fortschritt darf keine bestandene menschliche Abnahme behaupten. Er muss stattdessen klar pruefen, ob ein bewusster Workbench-Export vorliegt, und bei echten Findings auf neue Post-TASK_730-Folge-Slices zeigen.

## Umfang
- Neuer read-only Analyzer `StationScenarioWorkbenchExportReview`.
- Statuswerte fuer fehlenden/offenen Export, blockierte Manifeste, Follow-up-Auswahl und naechsten spielbaren Slice.
- Aktualisierte TASK_728-Follow-up-Routen von alten TASK_729/TASK_730-Zielen auf neue TASK_732+ Vorschlaege.
- Verifier fuer offene, issue-lastige und saubere Export-Szenarien.
- Status-, Roadmap-, Contract- und Handbuch-Update.

## Nicht-Ziele
- Kein automatisches Ausfuellen der TASK_727-Workbench.
- Kein bestandener menschlicher Sichttest.
- Kein neues Mission-, Door-, Cargo- oder Multiplayer-System.
- Kein UI-Polish ohne exportierte Findings.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_727_station_scenario_f6_host_client_playtest_notes.md`
- `docs/tasks/TASK_728_station_scenario_playtest_findings.md`
- `docs/tasks/TASK_730_station_scenario_targeted_playtest_polish.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Fehlender oder offener TASK_727-Export meldet `needs_workbench_export`.
- Ungueltige Schemas oder read-only-Verletzungen blockieren.
- Exportierte Issue-Flags werden zu neuen TASK_732+ Action Items.
- Saubere erledigte Notizen plus saubere TASK_728-Findings melden `ready_for_next_playable_slice`.
- Snapshots bleiben read-only: `read_only = true`, `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `scripts/mission/station_scenario_workbench_export_review.gd`
- `scripts/mission/station_scenario_playtest_findings.gd`
- `scripts/tests/task_731_station_scenario_workbench_export_review.gd`
- `scripts/tests/task_728_station_scenario_playtest_findings.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_731_station_scenario_workbench_export_review.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_728_station_scenario_playtest_findings.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_727_station_scenario_f6_host_client_playtest_notes.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
TASK_731 macht den offenen menschlichen Export sichtbarer und verhindert stale Routing. Das echte Spielgefuehl bleibt erst nach einem bewusst ausgefuellten TASK_727-Export belegt.
