# TASK_778 - Station Reentry Firefight Visual Playtest Packet

## Ziel / Problem
TASK_777 macht den ersten Feuerwechsel headless als Tension-Moment lesbar. Jetzt braucht der naechste sichtbare Review einen reproduzierbaren Startpunkt: Welche Szene wird gestartet, welche Workbench wird geoeffnet, welche Firefight-Details muessen im Fenster geprueft werden und welche Verifier gehoeren zum Paket?

## Sinnhaftigkeit / Ursache
Headless-Gates beweisen Contracts, aber nicht, ob der Spieler im echten Fenster Trace, Impact, Unit-Badge, HUD-Text und naechsten Griff wahrnimmt. Das Paket macht aus TASK_777 eine konkrete visuelle Pruefroutine, ohne den menschlichen Sichtentscheid zu behaupten.

## Umfang
- PowerShell-Tool fuer ein lokales Firefight-Visual-Playtest-Paket.
- Manifest unter `tmp/station_reentry_firefight_visual_playtest_packet.json`.
- Paket enthaelt:
  - Scenario- und Workbench-Pfade
  - erwartete Firefight-Readability-Fragmente
  - manuelle Pflichtchecks fuer Trace, Impact, Badge, HUD, Metriken und Screenshot/JSON-Export
  - Start-/Capture-/Verifier-Kommandos
  - klare Read-only-/No-Gameplay-Mutation-Grenzen
- Status, Roadmap, Contract und HTML-Handbuch aktualisieren.

## Nicht-Ziele
- Kein automatischer Sichtentscheid.
- Kein neues Capture-System.
- Kein Combat-, Damage-, Suppression-, Ammo- oder KI-Verhalten.
- Kein Starten sichtbarer Fenster im Verifier.
- Keine Gameplay-Wahrheit aus dem Paket.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_777_station_reentry_firefight_tension_feel_pass.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`
- `scripts/tools/prepare_station_reentry_host_client_playtest_export.ps1`
- `scripts/tools/prepare_station_reentry_playtest_run.ps1`

## Akzeptanzkriterien
- Das Tool schreibt ein JSON-Manifest mit stabilem TASK_778-Schema.
- Das Manifest ist `ready_to_capture_station_reentry_firefight_visual`, wenn Szenario und Workbench existieren.
- Das Manifest bleibt read-only und erzeugt keine Navigation, Commands, FireEvents oder DamageEvents.
- Required-Checks enthalten mindestens Firefight gestartet, FireTrace sichtbar, Impact/Fokus sichtbar, Unit-Badge sichtbar, Combat-HUD/Next-Decision sichtbar, Metriken konsistent, Screenshot gespeichert und Workbench-JSON exportiert.
- Commands enthalten Launch, Capture, Workbench-URI, TASK_777-Verifier und TASK_778-Verifier.
- Der HTML-Bericht exportiert den TASK_778-Manifestpfad und manuelle Firefight-Visual-Checks.

## Betroffene Dateien
- `scripts/tools/prepare_station_reentry_firefight_visual_playtest_packet.ps1`
- `scripts/tests/task_778_station_reentry_firefight_visual_playtest_packet.gd`
- `docs/tasks/TASK_778_station_reentry_firefight_visual_playtest_packet.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_778_station_reentry_firefight_visual_playtest_packet.gd`
- Regression: TASK_777
- `git diff --check`

## Risiken / offene Punkte
TASK_778 bereitet den sichtbaren Review vor, ersetzt ihn aber nicht. Der naechste sinnvolle Schritt ist TASK_779, der echte Workbench-/Screenshot-Findings auswertet.
