# TASK_750 - Station Homebase Host/Client Recapture Packet

## Ziel / Problem
Nach TASK_749 ist die Homebase-Follow-up-Zeile spielnaeher, aber noch nicht im echten Host/Client-Fensterlauf nach Cargo-Ende, Debrief und Return-to-Homebase beurteilt. TASK_750 macht diesen Lauf ohne Ratespiel startbar und pruefbar.

## Sinnhaftigkeit / Ursache
Die bisherigen Headless-Smokes belegen Contracts, Bounds und Microcopy. Fuer Spielgefuehl, Lesbarkeit, HUD-Ueberdeckung, Host/Client-Kontext und Performance braucht es trotzdem den sichtbaren Fensterblick. Der vorhandene Launcher/Capture-Pfad kann Fenster starten und Screenshots machen, aber der Homebase-Abschluss nach TASK_749 braucht ein eigenes Paket mit den richtigen Erwartungen.

## Umfang
- Neuer Helper `prepare_station_homebase_host_client_recapture.ps1` schreibt ein read-only Packet.
- Packet nennt Szenario, Workbench, Launch-/Capture-Kommandos, erwartete TASK_749-Homebase-Zeile und Pflichtchecks.
- Verifier prueft Tool, Packet, Doku, Bericht und read-only-Grenzen.
- Keine automatische menschliche Abnahme behaupten: `manual_review_required = true`, `manual_review_done = false`.

## Nicht-Ziele
- Kein automatischer kompletter Cargo->Debrief->Homebase-Klickbot.
- Kein Runtime-UI-Polish.
- Kein neuer Multiplayer-/Netcode.
- Keine Gameplay-State-Mutation.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_749_station_homebase_followup_microcopy_polish.md`
- `docs/tasks/TASK_747_station_scenario_homebase_visible_readiness_review.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`

## Akzeptanzkriterien
- Packet liegt unter `tmp/station_homebase_host_client_recapture_packet.json`.
- `schema = sternenbuergerchen.station_homebase_host_client_recapture_packet.v1`.
- `status = ready_to_run_homebase_recapture`, wenn TASK_747/TASK_749-Manifeste und Workbench vorhanden sind.
- Packet enthaelt Launch- und Capture-Kommandos mit `station_route_one_screen_multiplayer_drill`.
- Packet erwartet die sichtbare Homebase-Zeile `Naechste Sortie: Fireteam bereitstellen | danach: Loadout pruefen, Dropship beladen, Start freigeben`.
- Packet fordert Abwesenheit der alten Debug-Marker `Next sortie`, `Review gains`, `Stage fireteam`, `Assign loadout`, `Load dropship`, `Start next sortie`.
- Pflichtchecks umfassen Cargo-Ende, Debrief, Return-Homebase, Summary, Next-Sortie-Line, Host/Client-Kontext, HUD-Blocking, Performance und Workbench-Export.
- `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_navigation = false`, `creates_command = false`.

## Betroffene Dateien
- `scripts/tools/prepare_station_homebase_host_client_recapture.ps1`
- `scripts/tests/task_750_station_homebase_host_client_recapture_packet.gd`
- `docs/tasks/TASK_750_station_homebase_host_client_recapture_packet.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [x] `powershell -ExecutionPolicy Bypass -File scripts/tools/prepare_station_homebase_host_client_recapture.ps1`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_747_station_scenario_homebase_visible_readiness_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_749_station_homebase_followup_microcopy_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_750_station_homebase_host_client_recapture_packet.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
TASK_750 ist ein Recapture-Paket, kein abgeschlossener Sichtentscheid. Der naechste sinnvolle Schritt ist, den echten Host/Client-Lauf auszufuehren, die Workbench zu exportieren und daraus konkrete Findings oder einen kleinen Panel-Polish abzuleiten.
