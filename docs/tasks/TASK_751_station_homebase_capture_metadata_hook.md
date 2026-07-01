# TASK_751 - Station Homebase Capture Metadata Hook

## Ziel / Problem
TASK_750 schreibt ein eigenes Host/Client-Homebase-Recapture-Paket, aber der allgemeine Zwei-Fenster-Capture-Helper schreibt diese neuen Erwartungen noch nicht in sein Capture-Manifest. Dadurch koennen echte Captures wieder nur alte Station-Route-Checks zeigen und der Homebase-Abschluss bleibt im Review-Kontext zu leicht uebersehbar.

## Sinnhaftigkeit / Ursache
Der Spielerpfad soll bis Cargo-Ende, Debrief und Homebase-Return multiplayerfaehig und sichtbar pruefbar werden. Dafuer muss jedes echte Host/Client-Capture-Manifest wissen, welche Homebase-Zeile seit TASK_749 erwartet wird und welche manuellen Checks TASK_750 verlangt.

## Umfang
- `capture_host_client_two_window_real_run.ps1` um TASK_750-Metadaten erweitern.
- Capture-Manifest nennt TASK_750, Paketpfad, erwartete Homebase-Zeile, alte Debug-Marker und Pflichtchecks.
- Review-Checks enthalten Homebase-Recapture-Pruefpunkte.
- Verifier prueft Script, Manifest-Felder, read-only-Grenzen, Status/Roadmap/Report.
- Dry-run des Capture-Scripts darf das Manifest aktualisieren, ohne sichtbare Fenster zu starten.

## Nicht-Ziele
- Kein neuer Screenshot-Algorithmus.
- Kein automatischer Cargo->Debrief->Homebase-Klickbot.
- Kein Runtime-UI-Polish.
- Kein echter menschlicher Sichtentscheid.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_750_station_homebase_host_client_recapture_packet.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `scripts/tools/capture_host_client_two_window_real_run.ps1`

## Akzeptanzkriterien
- Capture-Manifest enthaelt `station_homebase_host_client_recapture_task_id = TASK_750`.
- Capture-Manifest enthaelt `station_homebase_host_client_recapture_packet_path = tmp/station_homebase_host_client_recapture_packet.json`.
- Capture-Manifest enthaelt die erwartete TASK_749-Zeile.
- Capture-Manifest enthaelt alte Debug-Marker als verbotene sichtbare Fragmente.
- Capture-Manifest enthaelt manuelle Checks fuer Cargo-Ende, Debrief, Return-Homebase, Summary, Next-Sortie-Line, Host/Client-Kontext, HUD, Performance und Workbench-Export.
- Capture-Manifest bleibt `read_only = true`, `ui_sets_gameplay_truth = false`.
- `manual_review_required = true`, `manual_review_done = false` bleiben erhalten.

## Betroffene Dateien
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/tests/task_751_station_homebase_capture_metadata_hook.gd`
- `docs/tasks/TASK_751_station_homebase_capture_metadata_hook.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [x] `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_751_station_homebase_capture_metadata_hook.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_750_station_homebase_host_client_recapture_packet.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
TASK_751 verbessert die Beweiskette fuer echte Captures, ersetzt aber weiterhin keinen echten Fensterlauf und keine menschliche Findings-Auswertung.
