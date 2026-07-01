# TASK_764 - Station Reentry Loadout Bridge Polish

## Ziel / Problem
Nach dem Station-Return sieht der Spieler jetzt Reentry-Plan und Fireteam-Staging, aber der Loadout-Schritt ist noch nicht als eigener, lesbarer Brueckenschritt im Return-Panel sichtbar.

## Sinnhaftigkeit / Ursache
Der Reentry-Ziel-Slice lautet: Homebase-Return-Panel lesen, Fireteam bereitstellen, Loadout pruefen, Dropship beladen, Start freigeben und erste Mission-Entscheidung mit Preview treffen. TASK_763 macht Fireteam-Staging sichtbar; TASK_764 macht den naechsten Loadout-Pruefpunkt sichtbar, indem er die bestehende Pre-Mission-Readiness liest.

## Umfang
- Station-Return-Panel bekommt eine kompakte `Loadout-Check`-Zeile.
- Die Zeile liest den `loadout`-Eintrag aus `get_pre_mission_readiness_snapshot()`.
- Der Snapshot `get_station_homebase_return_panel_polish_snapshot()` exportiert Text, erwarteten Text, State, Detail, Style-ID, Sichtbarkeit, Bounds und Read-only-Status.
- Der bestehende Reentry-Plan und die TASK_763-Fireteam-Staging-Zeile bleiben erhalten.

## Nicht-Ziele
- Kein neuer Loadout-Apply-Pfad.
- Keine automatische Empfehlungsauswahl.
- Keine Veraenderung an Dropship-, Boarding-, Start- oder Mission-Command-Logik.
- Kein Ersatz fuer den sichtbaren Zwei-Fenster-Reentry-Playtest.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/mission_briefing_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Das Station-Return-Panel zeigt eine sichtbare, kompakte Loadout-Check-Zeile.
- Die Zeile nennt Loadout und transportiert einen Readiness-State.
- Die Zeile bleibt read-only und setzt keine Gameplay-Wahrheit, Navigation oder Commands.
- Der Snapshot enthaelt stabile TASK_764-Felder und Checks.
- TASK_763/TASK_762/TASK_755-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_764_station_reentry_loadout_bridge_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_764_station_reentry_loadout_bridge_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_763_station_reentry_fireteam_staging_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_762_station_reentry_targeted_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_755_station_homebase_return_panel_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Zeile zeigt Loadout-Lesbarkeit, ersetzt aber nicht die eigentliche Bedienprobe im Loadout-Panel.
- Der sichtbare Zwei-Fenster-Reentry-Playtest bleibt offen.
