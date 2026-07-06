# TASK_825 - Release First GO Recent Movement Trace

## Ziel / Problem
Der sichtbare Release-Pfad kommt inzwischen von `Einzelspieler` bis in die Mission. Im integrierten ersten GO-/Firefight-Smoke faellt aber die Bewegungslesbarkeit nach `GO` aus, wenn die erste kurze Bewegung bereits abgeschlossen ist, bevor Kontakt- und Feuerfeedback gelesen werden.

## Sinnhaftigkeit / Ursache
Der `FireteamMovementController` entfernt abgeschlossene Bewegungen korrekt aus seinem aktiven Runtime-State. Fuer den Spieler bleibt direkt nach `GO` trotzdem wichtig, wohin der Befehl ging und dass die Bewegung gerade ausgefuehrt oder abgeschlossen wurde. Der Readability-Snapshot darf deshalb eine kurze, read-only Spur aus Order-Plan, Visualized Waypoint oder Phase-Execution liefern, ohne die autoritative Movement-Ausfuehrung kuenstlich aktiv zu halten.

## Umfang
- `TASK_813` wieder gruen machen.
- Den First-Move-Execution-Snapshot um einen read-only Recent-Movement-Trace ergaenzen, wenn kein aktiver Movement-State mehr existiert.
- Keine Gameplay-State-Verlaengerung im `FireteamMovementController`.
- Keine neue Movement- oder Combat-Logik.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein neuer Missionsflow.
- Kein Umbau der Fireteam-Movement-Architektur.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/tasks/TASK_813_station_reentry_release_candidate_first_go_firefight_actionability_smoke.md`
- `docs/tasks/TASK_541_mission_first_move_execution_feedback_pass.md`

## Akzeptanzkriterien
- `TASK_813` passiert wieder komplett.
- Wenn aktive Movement-State-Daten fehlen, liefert der Execution-Snapshot eine `recent_trace`-Movement-Spur fuer das ausgewaehlte Fireteam.
- Die Spur ist eindeutig read-only und setzt keine Gameplay-Wahrheit.
- Der isolierte `TASK_541`-Execution-Test bleibt gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_541_mission_first_move_execution_feedback_pass.gd`
- `scripts/tests/task_813_station_reentry_release_candidate_first_go_firefight_actionability_smoke.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_813_station_reentry_release_candidate_first_go_firefight_actionability_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_541_mission_first_move_execution_feedback_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
Die Spur ist bewusst nur ein UI-/Review-Lesevertrag. Folgearbeit bleibt ein echter sichtbarer Release-Run bis `GO`, um Timing, HUD-Dichte und Gefuehl im Fenster zu beurteilen.
