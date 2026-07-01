# TASK_752 - Station Homebase Recapture Workbench Prefill

## Ziel / Problem
TASK_750 und TASK_751 machen den Station-Homebase-Recapture startbar und schreiben die erwarteten Homebase-Felder in das allgemeine Host/Client-Capture-Manifest. Die TASK_727-Workbench zeigt diese Homebase-Erwartungen aber noch nicht direkt an.

## Sinnhaftigkeit / Ursache
Der naechste echte Fensterlauf soll nicht wieder zwischen Packet, Capture-Manifest und Handbuch hin- und herspringen muessen. Die Workbench ist der Ort fuer den menschlichen Review; dort muessen erwartete Homebase-Zeile, verbotene alte Debug-Marker und Pflichtchecks sichtbar/exportierbar sein.

## Umfang
- `StationScenarioF6HostClientPlaytestNotes` uebernimmt Homebase-Recapture-Felder read-only in `recapture_evidence`.
- Die TASK_727-HTML-Workbench zeigt TASK_750/TASK_751-Prefill-Daten fuer den Homebase-Recapture.
- Der aktuelle HTML-Statusbericht nennt TASK_752 und routet weiter zum echten Host/Client-Homebase-Lauf.
- Contract, Status, Roadmap und Verifier werden aktualisiert.

## Nicht-Ziele
- Kein echter Host/Client-Fenster-Sichtentscheid.
- Keine Runtime-UI-Aenderung.
- Keine Homebase-, MissionResult-, Staging-, Navigation- oder Command-Mutation.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_750_station_homebase_host_client_recapture_packet.md`
- `docs/tasks/TASK_751_station_homebase_capture_metadata_hook.md`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Die Workbench exportiert Homebase-Recapture-Packet-Pfad, Capture-Manifest-Pfad, erwartete TASK_749-Zeile, verbotene Debug-Marker und Pflichtchecks.
- Der Analyzer-Snapshot meldet `homebase_recapture_ready_for_workbench = true`, wenn TASK_751-Felder vorhanden sind.
- `manual_review_done` bleibt false, bis ein echter Workbench-Export/Playtest erfolgt.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben erhalten.

## Betroffene Dateien
- `scripts/mission/station_scenario_f6_host_client_playtest_notes.gd`
- `scripts/tests/task_752_station_homebase_recapture_workbench_prefill.gd`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_752_station_homebase_recapture_workbench_prefill.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_751_station_homebase_capture_metadata_hook.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_727_station_scenario_f6_host_client_playtest_notes.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_752 ist nur ein Review-Ergonomie-Schritt. Der echte sichtbare Host/Client-Homebase-Recapture und die Findings-Auswertung bleiben offen.
