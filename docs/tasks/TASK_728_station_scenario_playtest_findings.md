# TASK_728 - Station Scenario Playtest Findings

## Ziel / Problem
TASK_727 sammelt sichtbare F6-/Host-Client-Playtestnotizen, aber diese Notizen brauchen einen stabilen Findings-Schritt: Was ist offen, was braucht gezielten Polish, und wann ist der kleine Stationslauf gut genug fuer den naechsten spielbaren Slice?

## Sinnhaftigkeit / Ursache
Ohne Findings-Gate koennen offene Playtestnotizen, technische Manifestdaten und echte menschliche Beobachtungen durcheinandergeraten. TASK_728 verhindert, dass ein offener Sichtlauf als Abnahme gelesen wird, und mappt echte Issue-Flags direkt auf kleine Folgeaufgaben.

## Umfang
- Read-only Analyzer `StationScenarioPlaytestFindings`.
- Verifier fuer offene, blockierte, issue-lastige und saubere Playtestnotizen.
- Manifest `tmp/station_scenario_playtest_findings.json`.
- Status-, Roadmap-, Contract- und Handbuch-Update.

## Nicht-Ziele
- Kein neuer sichtbarer F6-Lauf.
- Kein automatisches Behaupten einer menschlichen Abnahme.
- Kein HUD-, Performance-, Sync- oder Combat-Polish in diesem Task.
- Keine Modernisierung alter Harnesses; TASK_728 benennt sie nur als moeglichen Follow-up.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_727_station_scenario_f6_host_client_playtest_notes.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Fehlende oder ungueltige TASK_727-Notizen blockieren.
- Offene TASK_727-Notizen melden `needs_visible_playtest`.
- Notizen mit Issue-Flags melden `needs_targeted_polish` und liefern konkrete Action Items.
- Saubere erledigte Notizen melden `ready_for_next_playable_slice`.
- Snapshot und Manifest bleiben `read_only = true` und `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `scripts/mission/station_scenario_playtest_findings.gd`
- `scripts/tests/task_728_station_scenario_playtest_findings.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_728_station_scenario_playtest_findings.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_727_station_scenario_f6_host_client_playtest_notes.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
Der aktuelle lokale Stand bleibt erwartbar `needs_visible_playtest`, weil TASK_727 noch keinen echten menschlichen Workbench-Export enthaelt. TASK_728 ist damit die saubere Weiche fuer den naechsten echten Lauf oder gezielten Polish, nicht dessen Ersatz.
