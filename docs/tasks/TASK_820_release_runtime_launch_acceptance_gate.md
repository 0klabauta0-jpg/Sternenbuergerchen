# TASK_820 - Release Runtime Launch Acceptance Gate

## Ziel / Problem
Der gepruefte Release-Launcher aus TASK_819 startet die richtige EXE, aber der nachgelagerte Startcheck meldet danach naturgemaess wieder `release_process_already_running`. Dadurch bleibt ein erfolgreicher, bewusst gestarteter Playtest-Lauf optisch bei `review`, obwohl genau dieser Prozess erwartet ist.

## Sinnhaftigkeit / Ursache
Ein laufender Release-Prozess ist vor dem Start ein Warnsignal, nach einem erfolgreichen `-Launch` aber ein Erfolgskriterium. Der Launcher muss deshalb zwischen erwarteter neuer EXE und unerwarteten Altprozessen unterscheiden.

## Umfang
- TASK_819-Manifest erweitert um Launch-Acceptance-Daten.
- Erwarteter gestarteter Prozess wird anhand der Prozess-ID gegen den Nachcheck abgeglichen.
- `release_process_already_running` wird nur dann als Action-Warnung unterdrueckt, wenn ausschliesslich der erwartete Launch-Prozess laeuft.
- Unerwartete weitere Release-Prozesse bleiben Review-Warnung.

## Nicht-Ziele
- Kein automatischer Fenster-Sichttest.
- Keine Taskleisten-Reparatur.
- Keine Gameplay-, UI-, Mission- oder Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_819_release_runtime_checked_launcher.md`
- `docs/tasks/TASK_818_station_reentry_release_candidate_playable_build_acceptance.md`
- `docs/dev/export_runtime_package_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Default-Lauf ohne `-Launch` bleibt nicht-mutierend und darf weiter `review` melden, wenn alte Prozesse laufen.
- Lauf mit `-StopRunningReleaseProcess -CleanTempFiles -Launch` kann `pass` melden, wenn nur der neu gestartete Prozess laeuft und keine Action-Warnungen bleiben.
- Manifest enthaelt `launch_acceptance_task_id`, `expected_launched_process_running`, `unexpected_running_processes` und `action_warnings`.
- Der Launcher beendet weiterhin nur Prozesse aus dem vertraglichen Release-Pfad.

## Betroffene Dateien
- `scripts/tools/start_release_runtime_checked.ps1`
- `docs/tasks/TASK_820_release_runtime_launch_acceptance_gate.md`
- `docs/dev/export_runtime_package_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/start_release_runtime_checked.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/start_release_runtime_checked.ps1 -StopRunningReleaseProcess -CleanTempFiles -Launch`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/release_runtime_start_check.ps1`
- `git diff --check`

## Risiken / offene Punkte
- Der Playtest ist nach Launch noch nicht visuell bestanden; das Fenster muss weiter angeschaut werden.
- Mit `-StopRunningReleaseProcess` wird ein vorhandenes Release-Fenster bewusst beendet.
- Nach erfolgreichem Launch bleibt der Prozess laufen, damit der Spieler direkt testen kann.
