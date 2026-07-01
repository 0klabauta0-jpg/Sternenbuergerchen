# TASK_765 - Station Reentry Dropship Boarding Bridge Polish

## Ziel / Problem
Nach dem Station-Return sind Reentry-Plan, Fireteam-Staging und Loadout-Check sichtbar. Der Dropship-/Boarding-Schritt bleibt aber noch nicht als eigener, lesbarer Brueckenschritt im Return-Panel sichtbar.

## Sinnhaftigkeit / Ursache
Der Reentry-Ziel-Slice verlangt nach Fireteam und Loadout den naechsten Griff: Dropship beladen, Boarding verstehen und Start erst nach echtem Payload-/Boarding-Stand freigeben. Diese Daten existieren bereits in Pre-Mission-Readiness und Homebase-Direct-Staging, werden aber im Return-Panel noch nicht kompakt zusammengefuehrt.

## Umfang
- Station-Return-Panel bekommt eine kompakte `Dropship`-/`Boarding`-Zeile.
- Die Zeile liest die `dropship`- und `boarding`-Items aus `get_pre_mission_readiness_snapshot()`.
- Die Zeile liest Payload-/Boarding-Zahlen aus `get_homebase_direct_staging_snapshot()`.
- Der Snapshot `get_station_homebase_return_panel_polish_snapshot()` exportiert Text, erwarteten Text, States, Details, Payload-/Boarding-Zahlen, Style-ID, Sichtbarkeit, Bounds und Read-only-Status.

## Nicht-Ziele
- Kein neuer Boarding-Fortschritt.
- Kein neuer Dropship-Start- oder Launch-Pfad.
- Keine Veraenderung an Boarding-Timing, Payload-Commit oder Mission-Command-Logik.
- Kein Ersatz fuer den sichtbaren Zwei-Fenster-Reentry-Playtest.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Das Station-Return-Panel zeigt eine sichtbare, kompakte Dropship-/Boarding-Zeile.
- Die Zeile nennt Dropship und Boarding.
- Die Zeile transportiert Dropship- und Boarding-State sowie boarded/total Operatoren, wenn ein Payload existiert.
- Die Zeile bleibt read-only und setzt keine Gameplay-Wahrheit, Navigation oder Commands.
- TASK_764/TASK_763/TASK_755-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_765_station_reentry_dropship_boarding_bridge_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_765_station_reentry_dropship_boarding_bridge_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_764_station_reentry_loadout_bridge_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_763_station_reentry_fireteam_staging_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_755_station_homebase_return_panel_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Zeile verbessert Lesbarkeit, ersetzt aber nicht die echte Bedienprobe mit Dropship-Payload und Boarding-Fortschritt.
- Der sichtbare Zwei-Fenster-Reentry-Playtest bleibt offen.
