# TASK_768 - Station Reentry First Mission Preview Polish

## Ziel / Problem
Der Station-Reentry-Pfad ist bis Homebase-Return, Fireteam-Staging, Loadout, Dropship-Boarding und Startfreigabe lesbar. Der naechste echte Spielergriff ist aber die erste Mission-Entscheidung nach dem erneuten Start: Fireteam waehlen, Move-Ziel setzen, Preview/Gefahr lesen und erst danach GO druecken.

## Sinnhaftigkeit / Ursache
Die Preview-Systeme aus TASK_540 und TASK_567 existieren bereits, aber der Reentry-Folgepfad braucht einen eigenen, station-spezifischen Check. Der sichtbare Order-Text soll klar sagen, dass der Zustand nur Preview ist, damit der Spieler nicht denkt, der Befehl sei schon committed.

## Umfang
- Der Waypoint-Intent-Text nennt den geplanten Zustand explizit als `PREVIEW`.
- `get_station_reentry_first_mission_preview_polish_snapshot()` fasst Station-Kontext, First-Move-Threat-Preview, Ghost/Pfad, Distanz/ETA, Risk-Text und Route/Cue read-only zusammen.
- Ein Verifier prueft den Station-Szenario-First-Move-Pfad ohne GO auszufuehren.
- Der aktuelle Iststand-/Handbuchbericht wird als neue lokale HTML-Workbench fuer Reentry-Decision-Notizen bereitgestellt.

## Nicht-Ziele
- Kein neuer Combat-Resolver.
- Kein automatischer echter Zwei-Fenster-Playtest.
- Keine GO-Ausfuehrung im Preview-Snapshot.
- Keine neue Gameplay-Wahrheit im HUD.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/tasks/TASK_540_mission_first_move_decision_readability_pass.md`
- `docs/tasks/TASK_567_frontier_probe_first_move_threat_preview_readability_pass.md`
- `docs/tasks/TASK_767_station_reentry_visible_playtest_review_gate.md`

## Akzeptanzkriterien
- Die erste Station-Reentry-Missionsentscheidung zeigt vor GO `PREVIEW`, Distanz/ETA und Risiko.
- Primary3D meldet Ghost- und Pfad-Preview.
- Station-Route oder Cue bleibt sichtbar, waehrend die erste Move-Preview geplant ist.
- Der Snapshot bleibt read-only, setzt keine UI-Gameplay-Wahrheit und erzeugt keinen Command.
- Bestehende TASK_567/TASK_767-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_768_station_reentry_first_mission_preview_polish.gd`
- `docs/tasks/TASK_768_station_reentry_first_mission_preview_polish.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_768_station_reentry_first_mission_preview_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_567_frontier_probe_first_move_threat_preview_readability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_767_station_reentry_visible_playtest_review_gate.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der echte sichtbare Host/Client-Reentry-Playtest bleibt manuell offen.
- TASK_768 prueft den ersten Station-Missionsentscheid technisch und sprachlich; die Fensterlesbarkeit muss weiterhin ueber Workbench-Export oder Screenshot bewertet werden.
