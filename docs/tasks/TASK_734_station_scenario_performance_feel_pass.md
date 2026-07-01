# TASK_734 - Station Scenario Performance Feel Pass

## Ziel / Problem
Nach TASK_733 ist der Stations-HUD lesbarer, aber der Review-Pfad nennt weiter Performance/Reaktionsgefuehl als offenen Playtest-Risikopunkt. Der naechste Schritt soll verhindern, dass die neuen Route-/Cue-/Overlap-Snapshots den sichtbaren Stationsdrill wieder traege oder textlastig machen.

## Sinnhaftigkeit / Ursache
Ein echter FPS-/Profiler-Lauf bleibt manuell. Fuer den Arbeitsstand brauchen wir aber ein kleines, robustes Headless-Gate: wiederholte Command-Feedback-Snapshots duerfen nicht explodieren, und die sichtbare ACT-Flaeche muss weiterhin im Budget bleiben.

## Umfang
- Neuer read-only Snapshot `get_station_scenario_performance_feel_pass_snapshot()`.
- Verifier misst wiederholte `get_command_feedback_snapshot()`-Abrufe in der Station-Testszene.
- Gate prueft Snapshot-Budget, Cue-/Overlap-Vertrag, ACT-Zeichenbudget und sichtbaren Linecount.
- Status-, Roadmap-, Contract- und Handbuch-Update.

## Nicht-Ziele
- Kein echter Godot-Profiler-Ersatz.
- Kein neues Rendering-, Mission-, Combat- oder Multiplayer-System.
- Kein automatisches Ausfuellen des TASK_727-Workbench-Exports.
- Kein Maschinen-spezifisches FPS-Versprechen.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_733_station_scenario_hud_overlap_pass.md`
- `docs/tasks/TASK_732_station_scenario_route_cue_polish.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/performance/performance_regression_gate.md`
- `data/performance_budget_contract.json`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Snapshot bleibt read-only: `read_only = true`, `ui_sets_gameplay_truth = false`.
- Wiederholte Command-Feedback-Snapshots bleiben unter dem breiten Snapshot-Budget.
- ACT-Line bleibt innerhalb Zeichenbudget und `visible_line_count <= max_visible_line_count`.
- Route bleibt im Identity-Body entdoppelt, Cue bleibt in ACT sichtbar.
- Snapshot meldet `ready_for_visible_playtest = true`, wenn alle Headless-Gates gruen sind.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_734_station_scenario_performance_feel_pass.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_734_station_scenario_performance_feel_pass.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_733_station_scenario_hud_overlap_pass.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_732_station_scenario_route_cue_polish.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
TASK_734 prueft strukturelles Reaktionsgefuehl im Headless-Lauf. Echte FPS, GPU-Kosten, Host/Client-Netzwerkstutter und subjektives Spielgefuehl bleiben im TASK_727-Fensterlauf bzw. Godot-Profiler offen.
