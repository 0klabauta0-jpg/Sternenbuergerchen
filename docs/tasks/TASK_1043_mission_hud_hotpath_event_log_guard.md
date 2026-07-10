# TASK_1043 - Mission HUD Hotpath Event Log Guard

## Ziel / Problem

Der echte Homebase-zu-First-Contact-Ablauf stottert, weil der wiederkehrende Mission-HUD-Refresh das volle `get_command_feedback_snapshot()` baut, nur um das Tactical Event Log zu fuettern. Dieser Snapshot umfasst historisch gewachsene Release-, Test-, Szenario- und Diagnosefelder, die das Event Log nicht benoetigt.

## Ursache

`MissionTacticalSandboxController._process()` ruft alle `0.35` Sekunden `_update_ui()` auf. `_refresh_tactical_event_log_panel()` ruft darin `get_command_feedback_snapshot()` und danach den TASK-883-Sync auf. Die lokale Diagnose hat fuer diesen Teil rund `405 ms` und fuer den gesamten `_update_ui()`-Durchlauf rund `1 s` gezeigt. Das Panel besitzt bereits einen Render-Signatur-Guard, bekommt aber die teure Payload vorher trotzdem neu gebaut.

## Umfang

- Einen kleinen, read-only Live-Snapshot fuer das Tactical Event Log bereitstellen.
- Nur die unmittelbaren Panel-Daten bauen: ausgewaehlte Fireteams, Event-Log-Display, Combat-/CONTACT-FIRE-Quelle und vorhandene Visual-Polish-Metadaten.
- Den bestehenden TASK-883-Sync und die CONTACT-FIRE-First-Regel beibehalten.
- Den wiederkehrenden Panel-Refresh auf den kleinen Snapshot umstellen.
- Den grossen Command-Feedback-Snapshot als expliziten Debug-/Test-/Report-Pfad erhalten.

## Nicht-Ziele

- Kein neues Gameplay-, Combat-, Movement- oder Multiplayer-System.
- Kein Umbau der Event-Log-Visuals oder der Command-Matrix.
- Kein grosser Controller-Extract aus `scripts/tests/`.
- Kein pauschales Timing-Limit, das auf anderer Hardware flakey waere.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_480_mission_ui_hotpath_feedback_guard.md`
- `docs/tasks/TASK_883_release_first_exchange_real_window_hud_source_sync_fix.md`

## Akzeptanzkriterien

- `_refresh_tactical_event_log_panel()` ruft nicht mehr `get_command_feedback_snapshot()` auf.
- `get_live_tactical_event_log_feedback_snapshot()` liefert nur read-only Event-Log-relevante Daten und keine neue Gameplay-Wahrheit.
- Normale Tactical-Events und die bestehende CONTACT-FIRE-First-Darstellung bleiben im Panel sichtbar.
- Der volle `get_command_feedback_snapshot()` bleibt fuer explizite Inspektions- und Regressionpfade erhalten.
- TASK_1043, TASK_366 und TASK_883 sind gruen; die direkte Flow-Probe erreicht den aktiven Missionszustand weiterhin.
- Der komplette TASK-542-Flow wird als Restprofil dokumentiert und nach dem folgenden Runtime-Surface-Guard erneut ausgefuehrt.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1043_mission_hud_hotpath_event_log_guard.gd`
- `scripts/tests/task_883_release_first_exchange_real_window_hud_source_sync_fix.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script res://scripts/tests/task_1043_mission_hud_hotpath_event_log_guard.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_366_tactical_event_log_hud_panel.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_883_release_first_exchange_real_window_hud_source_sync_fix.gd`
- `godot_console.exe --headless --path . --script res://tmp/task_542_flow_probe.gd`
- TASK-542 als nachfolgender Gesamtflow-Regressionstest
- `git diff --check`

## Risiken / offene Punkte

Die Controller-Hotpath-Diagnose zeigte neben dem Event Log weitere teure HUD-Teile. TASK_1043 schneidet den groessten klar abgegrenzten Fehlpfad; falls der Full-Refresh danach noch sichtbar stottert, folgt ein weiterer Task fuer die verbleibenden Runtime-Surfaces mit gemessener Ursache.
