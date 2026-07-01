# TASK_769 - Station Reentry Performance Feel Pass

## Ziel / Problem
Nach TASK_768 ist die erste Station-Reentry-Missionsentscheidung lesbar. Offen bleibt, ob dieser Reentry-Entscheid stabil und schnell genug wirkt: Preview, Route/Cue und HUD-Text duerfen nicht zu schwer oder zu lang werden, bevor der echte Zwei-Fenster-Playtest bewertet wird.

## Sinnhaftigkeit / Ursache
Der echte Godot-Profiler und der Host/Client-Fensterlauf bleiben manuell. Fuer den Arbeitsstand braucht es aber ein kleines Headless-Gate, das den Reentry-Preview-Snapshot, Textbudgets und eine wiederholte Snapshot-Messprobe zusammen bewertet, ohne neue Runtime-Wahrheit zu erzeugen.

## Umfang
- Neuer read-only Contract `StationReentryPerformanceFeelPass`.
- Neuer Controller-Snapshot `get_station_reentry_performance_feel_pass_snapshot()`.
- Verifier prueft Contract, Dokumente, Bericht und ein synthetisches TASK_768-Preview-Sample mit Budgetprobe.
- Der Reentry-Handbuchbericht markiert TASK_769 als aktuellen Performance-Feel-Schritt.

## Nicht-Ziele
- Kein echter FPS-/GPU-Profiler-Ersatz.
- Kein automatisierter Zwei-Fenster-Playtest.
- Kein neues HUD-System und kein per-frame Rebuild.
- Kein Gameplay-Commit und keine Command-Queue-Mutation.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/performance/performance_regression_gate.md`
- `data/performance_budget_contract.json`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_768_station_reentry_first_mission_preview_polish.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Snapshot bleibt `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_command = false`.
- TASK_768-Preview-Gate bleibt Quelle und muss `pass` sein.
- Selected-Order-Text enthaelt `PREVIEW`, ETA und Risiko und bleibt im Zeichenbudget.
- Station-Route oder Cue bleibt sichtbar und im Zeichenbudget.
- Wiederholte Snapshot-Messprobe bleibt unter dem breiten Projektbudget.
- Snapshot meldet `ready_for_visible_playtest = true`, wenn alle Headless-Gates gruen sind.

## Betroffene Dateien
- `scripts/mission/station_reentry_performance_feel_pass.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_769_station_reentry_performance_feel_pass.gd`
- `docs/tasks/TASK_769_station_reentry_performance_feel_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_769_station_reentry_performance_feel_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_768_station_reentry_first_mission_preview_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_769 ist ein Headless-Feel-Gate, kein Ersatz fuer den echten Godot-Profiler.
- Der sichtbare Host/Client-Reentry-Playtest und echte Netzwerk-Stutter-Bewertung bleiben offen.
