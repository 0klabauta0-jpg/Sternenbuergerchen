# TASK_964 - Release First Decision Loop Two Playtest

## Ziel / Problem
TASK_963 stellt die zweite Entscheidungszeile bereit, aber ein Spieler muss sie in den sichtbaren Mission-HUD-Flaechen lesen koennen. TASK_964 prueft deshalb, ob `HOLD / ADV / BACK` nicht nur im Command-Feedback existiert, sondern im Selected-Fireteam-Status und in Mission Control sichtbar ankommt.

## Sinnhaftigkeit / Ursache
Der Release-Slice soll sich wie ein kleiner spielbarer Ablauf anfuehlen. Dafuer reicht ein interner Snapshot nicht: Nach dem ersten Kontakt braucht der Spieler einen naechsten Griff auf dem Bildschirm. Gleichzeitig darf dieser Check keine zweite Gameplay-Wahrheit erzeugen.

## Umfang
- Read-only Analyzer `ReleaseFirstDecisionLoopTwoPlaytest`.
- Controller-Snapshot `get_release_first_decision_loop_two_playtest_snapshot()`.
- HUD-Zeilenhelper `_build_release_first_decision_loop_two_hud_line()`.
- Export in `get_command_feedback_snapshot()` als `release_first_decision_loop_two_playtest`, Gate und Status.
- Sichtbare Einbindung der TASK_963-Zeile in Selected-Fireteam-Status und Mission Control.

## Nicht-Ziele
- Kein Ausfuehren der zweiten Entscheidung.
- Kein neuer Command-, Movement-, Fire- oder Damage-Pfad.
- Kein grosses neues Missionssystem.
- Keine Multiplayer-Wahrheit im HUD.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_963_release_first_decision_next_playable_loop.md`

## Akzeptanzkriterien
- TASK_963-Source mit `visible_loop_line` fuehrt zu `gate = loop_two_playtest_passed`, wenn #17, #18 und Command Feedback die Zeile zeigen.
- Fehlende Mission-Control-Sichtbarkeit routet zu `TASK_965 - Release First Decision Loop Two Polish`.
- Snapshot bleibt read-only und erzeugt keine Commands, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.
- Die sichtbare Zeile nennt `HOLD`, `ADV` und `BACK`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_playtest.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_964_release_first_decision_loop_two_playtest.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_964_release_first_decision_loop_two_playtest.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_963_release_first_decision_next_playable_loop.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_962_release_first_decision_playtest_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_964 beweist Sichtbarkeit, nicht Spieltiefe. TASK_965 sollte bei Reibung die Zeilenplatzierung polieren oder danach die zweite Entscheidung als echten kleinen Spielzug anschliessen.
