# TASK_422 - GO Continue Fireteam HUD Cleanup

## Ziel / Problem
Im Playtest bleibt ein Fireteam nach einem erreichten Move-Wegpunkt trotz `GO` stehen. Zusaetzlich ist der alte sichtbare `Plan`-/Return-to-Plan-Fallback noch im Command-Matrix-Button und im `#17 SELECTED FIRETEAM`-Statusblock sichtbar, obwohl `GO` diese Recovery-/Fortsetzungsrolle uebernehmen soll.

## Sinnhaftigkeit / Ursache
`GO` soll der einzige sichtbare Fortsetzungsbutton fuer Wegpunktketten und Recovery sein. Der interne Plan-Mechanismus bleibt erhalten, aber die UI soll keinen zweiten sichtbaren Plan-Knopf und keinen separaten Ready/Plan/SUPP-Block mehr zeigen. Suppression soll stattdessen direkt an der Fireteam-Mini-Karte sichtbar sein.

## Umfang
- `GO` kann einen aktiven, bereits erreichten Move-Wegpunkt abschliessen und den naechsten Wegpunkt starten.
- Der sichtbare `Plan`-Button in der Command-Matrix wird wieder zu einem leeren Reserve-Slot.
- Der `#17`-Statusblock mit `READY`, `Plan` und separatem `SUPP`-Balken wird nicht mehr erzeugt.
- Die taktischen C/N/A-Buttons und Fireteam-Mitgliedskarten in `#17` bleiben erhalten.
- Die Fireteam-Mini-Karte traegt einen sichtbaren Suppression-Balken.

## Nicht-Ziele
- Kein Entfernen der internen Plan-/Recovery-Datenstrukturen.
- Kein Entfernen von `return_selected_fireteams_to_plan()` als interner/Kompatibilitaets-Pfad.
- Kein Umbau der Fireteam-Movement-Controller-Architektur.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_418_fireteam_mini_card_suppression_explainer.md`
- `docs/tasks/TASK_419_go_next_action_and_npc_speed.md`
- `docs/tasks/TASK_420_waypoint_completion_area_followup_hotfix.md`

## Akzeptanzkriterien
- [x] `GO` auf einem erreichten aktiven Move-Wegpunkt entfernt den erledigten Wegpunkt und aktiviert den naechsten.
- [x] `PlanCommandMatrixButton` wird im sichtbaren Command-Grid nicht mehr erzeugt; Slot `16.20` bleibt Reserve.
- [x] `FireteamStatusPanel` unter `#17` wird entfernt bzw. nicht mehr erzeugt.
- [x] Die Fireteam-Mini-Karte besitzt einen sichtbaren `MiniSuppressionBar` mit Wert und Threshold aus `_suppression_state_by_fireteam`.
- [x] Bestehende Waypoint- und Suppression-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/ui/mission_command_hierarchy_contract.gd`
- `scripts/tests/task_418_fireteam_mini_card_suppression_explainer.gd`
- `scripts/tests/task_422_go_continue_fireteam_hud_cleanup.gd`
- `docs/tasks/TASK_422_go_continue_fireteam_hud_cleanup.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_422_go_continue_fireteam_hud_cleanup.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_420_waypoint_completion_area_followup_hotfix.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_418_fireteam_mini_card_suppression_explainer.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_419_go_next_action_and_npc_speed.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der interne Return-to-Plan-Pfad bleibt fuer Ad-hoc/Suppression erhalten, ist aber nicht mehr als eigener Button sichtbar. Falls spaeter ein expliziter Recovery-Button gewuenscht ist, sollte er kontextuell und nicht dauerhaft sichtbar sein.
- Der Mini-Karten-Balken bleibt kompakt; ein manueller Godot-Fenster-Check soll bestaetigen, dass er bei 0% und unter Kontakt optisch klar genug ist.
