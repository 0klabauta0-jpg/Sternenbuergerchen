# TASK_766 - Station Reentry Start Permission Bridge Polish

## Ziel / Problem
Nach dem Station-Return sind Reentry-Plan, Fireteam-Staging, Loadout-Check und Dropship-/Boarding-Stand sichtbar. Die finale Startfreigabe bleibt aber noch nicht als eigener, lesbarer Brueckenschritt im Return-Panel sichtbar.

## Sinnhaftigkeit / Ursache
Der Reentry-Ziel-Slice endet vor dem echten Missionsstart mit der Frage: Darf ich jetzt starten, oder blockiert noch etwas? Diese Wahrheit existiert bereits in `PreMissionReadinessPresenter` und im Startbutton, wird aber im Return-Panel noch nicht kompakt mit dem restlichen Reentry-Pfad zusammengefuehrt.

## Umfang
- Station-Return-Panel bekommt eine kompakte `Startfreigabe`-Zeile.
- Die Zeile liest das `start`-Item und `can_start` aus `get_pre_mission_readiness_snapshot()`.
- Die Zeile gleicht sich mit dem bestehenden Startbutton-Text/-Disabled-State ab.
- Der Snapshot `get_station_homebase_return_panel_polish_snapshot()` exportiert Text, erwarteten Text, Start-State, Detail, `can_start`, Startbutton-Status, Style-ID, Sichtbarkeit, Bounds und Read-only-Status.

## Nicht-Ziele
- Kein neuer Startbutton.
- Keine neue Startfreigabe-Logik.
- Kein automatischer Missionsstart.
- Keine Veraenderung an Launch-, Payload-, Boarding- oder Mission-Command-Logik.
- Kein Ersatz fuer den sichtbaren Zwei-Fenster-Reentry-Playtest.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_765_station_reentry_dropship_boarding_bridge_polish.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Das Station-Return-Panel zeigt eine sichtbare, kompakte Startfreigabe-Zeile.
- Die Zeile nennt `Startfreigabe`.
- Die Zeile transportiert Start-State, Detail und `can_start`.
- Die Zeile stimmt mit dem vorhandenen Startbutton-Disabled-State ueberein.
- Die Zeile bleibt read-only und setzt keine Gameplay-Wahrheit, Navigation oder Commands.
- TASK_765/TASK_764/TASK_763/TASK_755-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_766_station_reentry_start_permission_bridge_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_766_station_reentry_start_permission_bridge_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_765_station_reentry_dropship_boarding_bridge_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_764_station_reentry_loadout_bridge_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_763_station_reentry_fireteam_staging_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_755_station_homebase_return_panel_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Zeile verbessert Lesbarkeit, ersetzt aber nicht die echte Bedienprobe mit Start und erster Mission-Entscheidung.
- Der sichtbare Zwei-Fenster-Reentry-Playtest bleibt offen.
