# TASK_736 - Station Scenario Command Feedback Polish

## Ziel / Problem
Der Stationsdrill hat nach TASK_734/TASK_735 stabile Headless-Gates, aber die naechste Handlungszeile wirkt noch zu technisch. Beispiel aus dem Performance-Manifest: `CUE AA: AA sichern | BLUE 3859m`.

## Sinnhaftigkeit / Ursache
Fuer einen angenehmen sichtbaren Playtest soll die Command-Feedback-Zeile nicht nur kurz sein, sondern auch wie eine Spieleranweisung lesen: welches Fireteam, was tun, wie weit. Diese Politur nutzt den bestehenden read-only Route-Cue-Pfad und erzeugt keine neue Gameplay-Wahrheit.

## Umfang
- `StationScenarioRouteCuePolish` formuliert Out-of-Range- und Usable-Cues handlungsorientierter.
- Distanz wird menschenlesbar formatiert (`220m`, `3.9km`) statt roh als lange Meterzahl.
- Future-Progress-Zeilen wie `CARGO blockiert` bleiben als Source erhalten, werden aber aus der knappen ACT-Zeile entdichtet, solange die Cue gerade einen frueheren Schritt wie AA erklaert.
- Der Cue-Snapshot exportiert `distance_text`, `feedback_style_id` und Lesbarkeitsflags.
- Neuer Verifier `task_736_station_scenario_command_feedback_polish.gd`.
- Status-, Roadmap-, Contract- und Handbuch-Update.

## Nicht-Ziele
- Kein echter TASK_727-Fensterlauf.
- Kein neues Objective-, Door-, Cargo- oder Command-System.
- Kein UI-State und keine Gameplay-Mutation im HUD.
- Kein Balancing von Distanzen oder Map-Markern.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_732_station_scenario_route_cue_polish.md`
- `docs/tasks/TASK_734_station_scenario_performance_feel_pass.md`
- `docs/tasks/TASK_735_station_scenario_current_report_sync_guard.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Out-of-Range-Cue nennt Fireteam, Handlungsverb und formatierte Distanz.
- Kilometerdistanzen werden gekuerzt, z. B. `3.9km`.
- Usable-Cue nennt Fireteam vor Aktion und `GO`.
- Der Mission-Control-ACT-Pfad spiegelt die neue Cue-Zeile.
- Die ACT-Zeile wiederholt keine Future-Cargo-Blockade neben einer aktiven AA-Cue.
- Snapshot bleibt `read_only = true`, `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `scripts/mission/station_scenario_route_cue_polish.gd`
- `scripts/tests/task_736_station_scenario_command_feedback_polish.gd`
- `scripts/tests/task_732_station_scenario_route_cue_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_736_station_scenario_command_feedback_polish.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_734_station_scenario_performance_feel_pass.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_733_station_scenario_hud_overlap_pass.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_732_station_scenario_route_cue_polish.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
TASK_736 verbessert die Headless-Command-Sprache. Ob sie im echten Fenster angenehm genug wirkt, bleibt weiterhin TASK_727-Workbench-/Sichttest-Arbeit.
