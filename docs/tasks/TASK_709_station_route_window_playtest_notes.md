# TASK_709 - Station Route Window Playtest Notes

## Ziel / Problem
TASK_708 schreibt ein sichtbares Stationsroute-Evidence-Paket, aber der echte Fensterblick ist noch nicht als Arbeitsbefund festgehalten. TASK_709 liefert eine kleine Workbench, mit der Door -> Computer -> Cargo im Godot-Fenster bewertet werden kann.

## Sinnhaftigkeit / Ursache
Headless-Evidence kann beweisen, dass Daten und Snapshots existieren. Sie kann aber nicht entscheiden, ob ein Spieler im echten Fenster sofort versteht, wo Door, Computer, Cargo und HUD-Feedback liegen. Dieser Task trennt deshalb technische Evidence von menschlichen Sichtnotizen.

## Umfang
- Read-only Snapshot-Service fuer Station-Route-Fensternotizen.
- HTML-Workbench mit Checkliste, Runbook, Notizen, Entscheidung und lokalem JSON-Export.
- Verifier fuer Task-Datei, Contract, Status, Roadmap, Workbench und Manifest-Contract.
- Aktueller Ist-Stand-/Handbuch-Refresh verweist auf TASK_709 und die Workbench.

## Nicht-Ziele
- Kein neuer Runtime-State.
- Kein Host/Client-Klicklauf.
- Keine Aenderung an Door-, Computer- oder Cargo-Gameplay.
- Kein behaupteter abgeschlossener menschlicher Sichtentscheid.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_708_station_route_visual_evidence.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`

## Akzeptanzkriterien
- Workbench enthaelt einen sichtbaren Button `JSON exportieren`.
- Required-Checks decken echten Fensterstart, Door-Lesbarkeit, Computer-/Cargo-Lesbarkeit, HUD-Overlap, Kamera und Performance-Gefuehl ab.
- Snapshot bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.
- `manual_window_review_done` bleibt false, bis ein Mensch den Sichtentscheid bewusst setzt.
- Verifier schreibt `tmp/station_route_window_playtest_notes.json` mit offenem Review-Status.

## Betroffene Dateien
- `docs/tasks/TASK_709_station_route_window_playtest_notes.md`
- `scripts/mission/station_route_window_playtest_notes.gd`
- `scripts/tests/task_709_station_route_window_playtest_notes.gd`
- `docs/reports/station_route_window_playtest_notes_2026_07_01.html`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_709_station_route_window_playtest_notes.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_708_station_route_visual_evidence.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Workbench macht den Sichtlauf besser dokumentierbar, ersetzt ihn aber nicht.
- Ein echter Host/Client-Fensterlauf bleibt eine Folgearbeit, sobald die Single-Window-Lesbarkeit akzeptiert ist.
