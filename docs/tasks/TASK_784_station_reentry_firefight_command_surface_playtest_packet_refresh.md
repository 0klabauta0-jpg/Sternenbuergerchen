# TASK_784 - Station Reentry Firefight Command Surface Playtest Packet Refresh

## Ziel / Problem
TASK_783 erzeugt eine polierte Command-Surface-Struktur, aber der sichtbare Playtest-/Recapture-Pfad verweist noch auf den alten TASK_781-Fokus. TASK_784 aktualisiert das Paket auf die neue Surface.

## Sinnhaftigkeit / Ursache
Der naechste echte Fensterlauf soll nicht allgemein fragen, ob die Command-Surface sichtbar ist, sondern gezielt pruefen: Interaction-Line, Primary-Lane, Quick-Action-Rail, Guard-Line, No-Auto-Command und Existing-Buttons aus TASK_783.

## Umfang
- PowerShell-Tool fuer ein lokales TASK_784-Playtest-Paket.
- Manifest unter `tmp/station_reentry_firefight_command_surface_playtest_packet_refresh.json`.
- Paket enthaelt:
  - Scenario- und Workbench-Pfade
  - TASK_783-Polish-Manifest als Quelle
  - erwartete Surface-Style-ID, Surface-Reihenfolge, Interaction-Line, Primary, Quick-Actions, Guard-Line und Summary-Line
  - manuelle Sichtchecks fuer polierte Surface, Primary-Lane, Quick-Action-Rail, Guard-Line, No-Auto-Command, Existing-Buttons, Host/Client-Gleichstand, Screenshot und Workbench-JSON
  - Start-/Capture-/Verifier-Kommandos
- Status, Roadmap, Contract und HTML-Handbuch aktualisieren.

## Nicht-Ziele
- Kein automatischer Sichtentscheid.
- Kein neues Command-UI-System.
- Kein Ausfuehren von HOLD/FLANK/SUP/HOLD FIRE.
- Keine Combat-, Damage-, Navigation- oder Multiplayer-Authority-Mutation.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_783_station_reentry_firefight_command_surface_polish.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`
- `scripts/tools/prepare_station_reentry_firefight_command_surface_playtest_packet_refresh.ps1`

## Akzeptanzkriterien
- Das Tool schreibt ein JSON-Manifest mit stabilem TASK_784-Schema.
- Das Manifest ist `ready_to_capture_polished_command_surface`, wenn Szenario, Workbench und TASK_783-Manifest bereit sind.
- Das Manifest bleibt read-only und erzeugt keine Navigation, Commands, FireEvents oder DamageEvents.
- Required-Checks enthalten mindestens polished surface sichtbar, Interaction-Line sichtbar, Primary-Lane sichtbar, Quick-Action-Rail sichtbar, Guard-Line sichtbar, No-Auto-Command sichtbar, Existing-Buttons sichtbar, Selected-Fireteam konsistent, Host/Client gleich, Screenshot gespeichert und Workbench-JSON exportiert.
- Commands enthalten Launch, Capture, Workbench-URI, TASK_783-Verifier und TASK_784-Verifier.
- Der HTML-Bericht exportiert den TASK_784-Manifestpfad und manuelle Playtest-Checks.

## Betroffene Dateien
- `scripts/tools/prepare_station_reentry_firefight_command_surface_playtest_packet_refresh.ps1`
- `scripts/tests/task_784_station_reentry_firefight_command_surface_playtest_packet_refresh.gd`
- `docs/tasks/TASK_784_station_reentry_firefight_command_surface_playtest_packet_refresh.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_784_station_reentry_firefight_command_surface_playtest_packet_refresh.gd`
- Regression: TASK_783, TASK_782, TASK_781
- `git diff --check`

## Risiken / offene Punkte
TASK_784 bereitet den neuen sichtbaren Review vor, ersetzt ihn aber nicht. Der naechste sinnvolle Schritt ist TASK_785, der echte Findings aus Screenshot und Workbench-JSON zur polierten Surface auswertet.
