# TASK_727 - Station Scenario F6/Host Client Playtest Notes

## Ziel / Problem
TASK_726 hat den Station-Route-Slice als One-Screen-Szenario und Runtime-Gate-Drill bereitgestellt. Der naechste Schritt ist kein weiterer Headless-Beweis, sondern eine saubere Notizschale fuer den sichtbaren F6-/Host-Client-Playtest.

## Sinnhaftigkeit / Ursache
Der Drill ist technisch `ready_for_f6_host_client_playtest`, aber Lesbarkeit, Tempo, HUD-Ueberdeckung, Teamkontext und Spielgefuehl muessen im echten Fenster beurteilt werden. Ohne strukturierte Notizen besteht das Risiko, dass technische Gruen-Zustaende als menschliche Abnahme gelesen werden.

## Umfang
- Read-only Analyzer `StationScenarioF6HostClientPlaytestNotes`.
- Interaktive HTML-Workbench fuer sichtbare F6-/Host-Client-Notizen.
- Verifier fuer Contract, Report, Status und Snapshot-Statuslogik.
- Status-, Roadmap-, Contract- und Handbuch-Update.

## Nicht-Ziele
- Kein echter automatisch behaupteter Playtest.
- Kein neues Combat-, Door-, Objective- oder Multiplayer-System.
- Kein Balancing der Bravo-/NPC-Werte.
- Keine Modernisierung alter Pre-Boot-Szenario-Harnesses wie TASK_707/TASK_714.

## Relevante Contracts / Dokumente
- `docs/dev/html_report_workbench_contract.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_726_one_screen_multiplayer_station_scenario_drill.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Der Analyzer konsumiert das TASK_726-Manifest read-only und blockiert bei fehlendem/ungueltigem Drill.
- Ohne menschlichen Export meldet der Snapshot `needs_visible_playtest`.
- Mit Playtest-Export und Issue-Flags meldet der Snapshot `needs_followup_polish`.
- Mit Playtest-Export ohne Issue-Flags meldet der Snapshot `ready_for_findings`.
- Die HTML-Workbench enthaelt `JSON exportieren`, Required-Checks und Notizfelder fuer Route, HUD, Performance, Host/Client-Sync und Teamkontext.
- UI-/Report-Daten setzen keine Gameplay-Wahrheit: `read_only = true`, `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `scripts/mission/station_scenario_f6_host_client_playtest_notes.gd`
- `scripts/tests/task_727_station_scenario_f6_host_client_playtest_notes.gd`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_727_station_scenario_f6_host_client_playtest_notes.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_726_one_screen_multiplayer_station_scenario_drill.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
TASK_727 ist Vorbereitung und Notiz-Infrastruktur. Er ersetzt keinen sichtbaren F6-/Host-Client-Lauf und keine menschliche Spielgefuehlentscheidung. Der naechste sinnvolle Slice ist TASK_728, der echte exportierte Notizen als Findings verdichtet oder konkrete UI-/Performance-/Sync-Polish-Arbeit daraus schneidet.
