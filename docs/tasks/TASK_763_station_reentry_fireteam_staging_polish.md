# TASK_763 - Station Reentry Fireteam Staging Polish

## Ziel / Problem
Nach dem Station-Return nennt das Homebase-Return-Panel den Reentry-Plan, aber der erste konkrete Handgriff bleibt zu abstrakt: Der Spieler muss sofort erkennen, ob ein Fireteam schon bereitsteht, ob es bereits im Dropship liegt und wie viele Operatoren betroffen sind.

## Sinnhaftigkeit / Ursache
TASK_762 hat den Ablauf `Fireteam -> Loadout -> Dropship -> Start -> Preview vor GO` sichtbar gemacht. Fuer einen echten Reentry-Playtest fehlt nun eine kleine, lesbare Fireteam-Staging-Zeile, die an die vorhandenen Homebase-Direct-Staging-Daten andockt, ohne neue Gameplay-Wahrheit im HUD zu erzeugen.

## Umfang
- Station-Return-Panel bekommt eine kompakte `Fireteam-Staging`-Zeile.
- Die Zeile liest aus `get_homebase_direct_staging_snapshot()`.
- Der Snapshot `get_station_homebase_return_panel_polish_snapshot()` exportiert Text, Style-ID, Staging-Zahlen, Sichtbarkeit, Bounds und Read-only-Status.
- Der bestehende Reentry-Plan aus TASK_762 bleibt erhalten.

## Nicht-Ziele
- Kein neuer Dropship-Commit-Pfad.
- Keine Veraenderung an Boarding-, Loadout-, Start- oder Mission-Command-Logik.
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
- Das Station-Return-Panel zeigt eine sichtbare, kompakte Fireteam-Staging-Zeile.
- Die Zeile nennt Fireteam und Operatoren.
- Die Zeile bleibt read-only und setzt keine Gameplay-Wahrheit, Navigation oder Commands.
- Der Snapshot enthaelt stabile TASK_763-Felder und Checks.
- TASK_762/TASK_755-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_763_station_reentry_fireteam_staging_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_763_station_reentry_fireteam_staging_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_762_station_reentry_targeted_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_755_station_homebase_return_panel_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der sichtbare Zwei-Fenster-Reentry-Playtest bleibt offen.
- Die Zeile verbessert Orientierung, ersetzt aber nicht die eigentliche Bedienprobe mit Fireteam, Loadout, Dropship, Start und Mission-Preview.
