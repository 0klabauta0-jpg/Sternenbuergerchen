# TASK_781 - Station Reentry Firefight Command Surface Recapture

## Ziel / Problem
TASK_780 erzeugt einen read-only Follow-up-Presenter fuer den ersten Firefight. Jetzt braucht der sichtbare Fensterlauf ein Recapture-Paket: Sind Folgezeile, primaerer Griff und Quick-Actions im echten HUD/Command-Bereich erkennbar?

## Sinnhaftigkeit / Ursache
Ein Contract kann sagen, dass `HOLD`, `FLANK`, `SUP` oder `HOLD FIRE` die naechsten sinnvollen Griffe sind. Fuer ein angenehmes Spielgefuehl muss aber im Fenster pruefbar sein, ob der Spieler diese Griffe wirklich findet, ohne dass die Anzeige heimlich Commands ausfuehrt.

## Umfang
- PowerShell-Tool fuer ein lokales TASK_781-Recapture-Paket.
- Manifest unter `tmp/station_reentry_firefight_command_surface_recapture.json`.
- Paket enthaelt:
  - Scenario- und Workbench-Pfade
  - TASK_780-Interaction-Manifest als Quelle
  - erwartete Interaction-Line, primaere Aktion und Quick-Action-Labels
  - manuelle Sichtchecks fuer HUD/Command-Surface, Host/Client-Gleichstand und No-Auto-Command
  - Start-/Capture-/Verifier-Kommandos
- Status, Roadmap, Contract und HTML-Handbuch aktualisieren.

## Nicht-Ziele
- Kein automatischer Sichtentscheid.
- Kein neues Command-UI-System.
- Kein Ausfuehren von HOLD/FLANK/SUP/RETREAT.
- Keine Combat-, Damage-, Navigation- oder Multiplayer-Authority-Mutation.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_780_station_reentry_firefight_interaction_polish.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`
- `scripts/tools/prepare_station_reentry_firefight_visual_playtest_packet.ps1`
- `scripts/tools/prepare_station_reentry_host_client_playtest_export.ps1`

## Akzeptanzkriterien
- Das Tool schreibt ein JSON-Manifest mit stabilem TASK_781-Schema.
- Das Manifest ist `ready_to_capture_firefight_command_surface`, wenn Szenario, Workbench und TASK_780-Manifest bereit sind.
- Das Manifest bleibt read-only und erzeugt keine Navigation, Commands, FireEvents oder DamageEvents.
- Required-Checks enthalten mindestens Interaction-Line sichtbar, Primary-Action sichtbar, Quick-Actions sichtbar, HOLD/FLANK/SUP sichtbar, No-Auto-Command sichtbar, Selected-Fireteam konsistent, Command-Matrix erreichbar, Host/Client gleich, Screenshot gespeichert und Workbench-JSON exportiert.
- Commands enthalten Launch, Capture, Workbench-URI, TASK_780-Verifier und TASK_781-Verifier.
- Der HTML-Bericht exportiert den TASK_781-Manifestpfad und manuelle Command-Surface-Checks.

## Betroffene Dateien
- `scripts/tools/prepare_station_reentry_firefight_command_surface_recapture.ps1`
- `scripts/tests/task_781_station_reentry_firefight_command_surface_recapture.gd`
- `docs/tasks/TASK_781_station_reentry_firefight_command_surface_recapture.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_781_station_reentry_firefight_command_surface_recapture.gd`
- Regression: TASK_780, TASK_779
- `git diff --check`

## Risiken / offene Punkte
TASK_781 bereitet den sichtbaren Recapture vor, ersetzt ihn aber nicht. Der naechste sinnvolle Schritt ist TASK_782, der echte Command-Surface-Findings aus Screenshot und Workbench-JSON auswertet.
