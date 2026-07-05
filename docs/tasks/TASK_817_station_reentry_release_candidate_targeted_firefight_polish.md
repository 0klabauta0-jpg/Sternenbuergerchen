# TASK_817 - Station Reentry Release Candidate Targeted Firefight Polish

## Ziel / Problem
Der erste Feuerwechsel soll im sichtbaren HUD nicht nur einen Combat-Readout zeigen, sondern direkt einen kurzen naechsten Spielergriff mit Grund nennen.

## Sinnhaftigkeit / Ursache
TASK_814 liefert bereits `player_next_action_line` und `player_why_line`, diese waren aber vor allem Snapshot-/Review-Daten. Fuer ein angenehmeres Spielgefuehl muss der Spieler im Moment des ersten Feuerwechsels im HUD sofort lesen koennen: Was mache ich jetzt, und warum?

## Umfang
- Kurze sichtbare Decision-Zeile `NEXT ... | WHY ...` aus bestehenden Firefight-/Combat-HUD-Daten.
- Anzeige derselben Decision-Zeile in #17 Selected Fireteam und #18 Mission Control.
- Read-only Snapshot `get_release_candidate_targeted_firefight_polish_snapshot()`.
- Meta-Snapshot `MetaLayerFlow.get_release_candidate_targeted_firefight_polish_snapshot(...)`.
- Verifier laeuft den bestehenden Release-Singleplayer-Pfad bis zum ersten Firefight.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen Treffer-, LOS-, Cover-, Pathfinding- oder Damage-Regeln.
- Keine neue UI-Wahrheit im HUD.
- Kein Multiplayer-Authority-Umbau.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_816_station_reentry_release_candidate_visible_firefight_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- TASK_814-Firefight-HUD bleibt gruen.
- Eine kurze `NEXT ... | WHY ...`-Zeile wird aus bestehenden Firefight-Daten abgeleitet.
- Mission Control und Selected Fireteam zeigen dieselbe Decision-Zeile.
- Die Decision-Zeile bleibt innerhalb eines knappen Zeichenbudgets.
- Snapshot bleibt read-only und erzeugt keine Commands, Navigation, FireEvents, DamageEvents oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_817_station_reentry_release_candidate_targeted_firefight_polish.gd`
- `docs/tasks/TASK_817_station_reentry_release_candidate_targeted_firefight_polish.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_817_station_reentry_release_candidate_targeted_firefight_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_814_station_reentry_release_candidate_firefight_feel_hud_polish_review.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Zeile ist bewusst knapp. Feineres Styling oder ein groesseres Decision-Panel gehoert nur in einen Folgetask, wenn der echte Fensterblick zeigt, dass diese kleine Zeile nicht reicht.
