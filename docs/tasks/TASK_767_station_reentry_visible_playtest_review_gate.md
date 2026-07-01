# TASK_767 - Station Reentry Visible Playtest Review Gate

## Ziel / Problem
Nach TASK_762 bis TASK_766 ist der Reentry-Return-Pfad im Homebase-Panel lesbar. Der vorhandene Reentry-Findings-Analyzer routet offene Sichttests aber noch historisch auf TASK_761 zurueck und kann dadurch erledigte Brueckenpolishes mit dem aktuellen sichtbaren Playtest vermischen.

## Sinnhaftigkeit / Ursache
Der naechste echte Fortschritt ist jetzt der sichtbare Reentry-Lauf: Return-Panel lesen, Fireteam/Loadout/Dropship/Start pruefen, Mission starten und die erste Entscheidung mit Preview bewerten. Dieser Schritt braucht ein aktuelles Review-Gate, das TASK_766 als Voraussetzung behandelt und neue Befunde nicht auf alte Tasknummern zurueckwirft.

## Umfang
- Reentry-Findings-Routing wird auf den aktuellen TASK_767-Review-Gate-Stand aktualisiert.
- Offener sichtbarer Reentry-Playtest empfiehlt TASK_767 statt TASK_761.
- First-Order-/Performance-/Host-Client-Folgeflags routen auf neue Folgeaufgaben nach TASK_767.
- Status, Roadmap, Contract und HTML-Berichte nennen TASK_767 als aktuellen sichtbaren Review-Gate-Schritt.

## Nicht-Ziele
- Kein automatischer GUI-Playtest.
- Kein Start-Command.
- Kein Mission-/Combat-Rewrite.
- Keine Behauptung, dass die manuelle Sichtabnahme erledigt ist.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_761_station_reentry_visible_playtest_findings.md`
- `docs/tasks/TASK_766_station_reentry_start_permission_bridge_polish.md`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`

## Akzeptanzkriterien
- Reentry-Findings bleiben read-only.
- Ohne manuelle Reentry-Notizen bleibt der Status `needs_visible_reentry_playtest`.
- Der offene sichtbare Reentry-Playtest empfiehlt TASK_767.
- Vollstaendige saubere Reentry-Notizen routen auf eine Folgeiteration nach TASK_767.
- First-Order-/Performance-/Host-Client-Folgeflags routen nicht mehr auf TASK_766/TASK_767 zurueck.
- TASK_761/TASK_760/TASK_766-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/mission/station_reentry_playtest_findings.gd`
- `scripts/tests/task_761_station_reentry_visible_playtest_findings.gd`
- `scripts/tests/task_767_station_reentry_visible_playtest_review_gate.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`
- `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_767_station_reentry_visible_playtest_review_gate.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_761_station_reentry_visible_playtest_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_760_station_reentry_playtest_run_packet.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_766_station_reentry_start_permission_bridge_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der echte sichtbare Zwei-Fenster-Reentry-Playtest bleibt weiterhin eine manuelle Abnahme.
- TASK_767 macht das Routing aktuell und pruefbar, ersetzt aber keine visuelle Bewertung im Fenster.
