# TASK_760 - Station Reentry Playtest Run Packet

## Ziel / Problem
TASK_759 definiert den naechsten spielbaren Ziel-Slice `station_reentry_playtest`, aber der Lauf ist noch nicht reproduzierbar startbar. Es braucht ein klares Run-Packet mit Szenario, Workbench, Start-/Capture-Kommandos, Runbook und Multiplayer-Pflichtchecks.

## Sinnhaftigkeit / Ursache
Der Review-Block soll wieder ins Spielen fuehren. Ein Run-Packet reduziert Reibung: Der naechste sichtbare F6-/Host-Client-Lauf kann mit denselben Erwartungen gestartet, gecaptured und in der bestehenden Workbench bewertet werden.

## Umfang
- Neuer Helper `scripts/tools/prepare_station_reentry_playtest_run.ps1`.
- Der Helper schreibt `tmp/station_reentry_playtest_run_packet.json`.
- Das Packet nennt TASK_759 als Quelle, den Ziel-Slice `station_reentry_playtest`, Szenario, Workbench, Start-/Capture-Kommandos, Runbook-Schritte und Multiplayer-Checks.
- Reports, Contract, Status, Roadmap und Verifier werden aktualisiert.

## Nicht-Ziele
- Kein automatischer Start ohne `-LaunchWindows`.
- Kein menschlicher Sichttest wird als erledigt markiert.
- Keine Runtime-UI-Aenderung.
- Keine Commands, Navigation oder Gameplay-Mutation.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_759_station_slice_next_playtest_target.md`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Packet-Schema ist `sternenbuergerchen.station_reentry_playtest_run_packet.v1`.
- Packet nennt `task_id = TASK_760`, `source_task_id = TASK_759` und `target_id = station_reentry_playtest`.
- Status ist `ready_to_run_station_reentry_playtest`, wenn Szenario und Workbench vorhanden sind.
- Packet enthaelt Start-/Capture-/Workbench-Befehle.
- Packet enthaelt Runbook-Schritte und Multiplayer-Checks aus TASK_759.
- Packet bleibt read-only und meldet `manual_review_done = false`.

## Betroffene Dateien
- `scripts/tools/prepare_station_reentry_playtest_run.ps1`
- `scripts/tests/task_760_station_reentry_playtest_run_packet.gd`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/prepare_station_reentry_playtest_run.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_760_station_reentry_playtest_run_packet.gd`
- Regressionen: TASK_759, TASK_758
- `git diff --check`

## Risiken / offene Punkte
TASK_760 macht den Reentry-Lauf startbar, ersetzt aber keinen sichtbaren Playtest. Danach muss die Workbench wirklich ausgefuellt oder ein konkreter Reentry-Polish aus einem echten Capture geschnitten werden.
