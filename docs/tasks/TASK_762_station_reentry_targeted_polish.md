# TASK_762 - Station Reentry Targeted Polish

## Ziel / Problem
Nach der Rueckkehr zur Homebase ist der naechste Station-Sortie zwar technisch vorbereitet, aber der sichtbare Reentry-Moment nennt noch nicht kompakt den ganzen Spielerhandgriff bis zur ersten Missionsentscheidung. Der Spieler soll direkt sehen: Fireteam, Loadout, Dropship, Start, dann Preview vor GO.

## Sinnhaftigkeit / Ursache
TASK_761 trennt Reentry-Findings von der alten Station-Route. Der erste konkrete Polish soll die wahrscheinlichste Reibung reduzieren: Orientierung nach dem Return. Das ist ein sichtbarer UI-Readout, kein neuer Gameplay-State.

## Umfang
- Das bestehende Station-Return-Panel bekommt eine kompakte Reentry-Plan-Zeile.
- Die Zeile wird nur fuer Station-Reentry sichtbar.
- Der Snapshot `get_station_homebase_return_panel_polish_snapshot()` exportiert Text, Style-ID, Sichtbarkeit und Bounds.
- Status, Contract, Roadmap und HTML-Handbuch werden aktualisiert.

## Nicht-Ziele
- Kein neues Staging-/Loadout-/Dropship-System.
- Kein Start-Command und keine Navigation.
- Keine Gameplay-Mutation in der UI.
- Kein Ersatz fuer den echten sichtbaren Host/Client-Reentry-Playtest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_761_station_reentry_visible_playtest_findings.md`
- `docs/tasks/TASK_755_station_homebase_return_panel_polish.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Station-Return-Panel zeigt eine Reentry-Plan-Zeile.
- Reentry-Plan-Zeile lautet kompakt: `Reentry-Plan: Fireteam -> Loadout -> Dropship -> Start -> Preview vor GO`.
- Zeile ist sichtbar, im Follow-up-Panel und im MissionPanel.
- Snapshot meldet `reentry_plan_style_id = task_762_station_reentry_plan_v1`.
- Snapshot bleibt read-only, erzeugt keine Navigation und keine Commands.
- TASK_755-Return-Panel-Regression bleibt gruen.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_762_station_reentry_targeted_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_762_station_reentry_targeted_polish.gd`
- Regressionen: TASK_761, TASK_755, TASK_749
- `git diff --check`

## Risiken / offene Punkte
Das verbessert die Orientierung im Return-Panel, belegt aber noch keinen echten Zwei-Fenster-Reentry-Playtest. Wenn der sichtbare Lauf danach noch klemmt, sollten die TASK_761-Reentry-Flags einen konkreten Folgepolish schneiden.
