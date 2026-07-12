# TASK_1163 - Left Tactical Stack 1280 Release Recapture

## Ziel / Problem
TASK_1162 haertet die linke taktische Stack-Flaeche aus Fireteam-Mini-Cards und Ereignislog headless. Jetzt muss der Stand als echter exportierter 1280x720-Host/Client-FirstContact wieder aufgenommen werden, damit der Spielerblick nicht nur strukturell, sondern im Releasefenster belegbar ist.

## Sinnhaftigkeit / Ursache
Die Release-EXE kann hinter dem Git-Stand zurueckliegen. Ein gruener Headless-Vertrag beweist nicht, dass die exportierte PCK denselben Stand enthaelt oder dass die linke Spalte im echten Fenster ruhig genug wirkt. Der Recapture schliesst diese Luecke.

## Umfang
- Read-only Snapshot fuer TASK_1163, der TASK_1162 als Quelle und den bestehenden FirstContact-Harness benennt.
- Release-Export auf aktuellem Commit pruefen.
- `capture_release_host_client_entry_playtest.ps1 -FirstContact` laufen lassen.
- Host-/Client-Fensterbilder und Manifest als Evidence in Status/Roadmap dokumentieren.

## Nicht-Ziele
- Kein weiterer UI-Layout-Umbau in diesem Task.
- Kein neuer Capture-Harness.
- Keine neuen Commands, Effects, Combat-Regeln oder Multiplayer-Wahrheit.
- Keine subjektive Abnahme als Code-Wahrheit; Sichtbefunde werden als Folge-Task geschnitten.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1162_left_tactical_stack_1280_readability_focus_balance.md`

## Akzeptanzkriterien
- `MissionTacticalSandboxController` liefert `get_left_tactical_stack_1280_release_recapture_snapshot()`.
- Der Snapshot referenziert TASK_1162, `capture_release_host_client_entry_playtest.ps1`, `-FirstContact`, 1280x720 und die erwarteten Host-/Client-Fensterbilder.
- Der Snapshot bleibt read-only und erzeugt keine Commands, Effects, Fire-/Damage-Events oder Multiplayer-Wahrheit.
- Der Release-Startcheck ist nach Export auf dem aktuellen Commit gruen.
- Der FirstContact-Host/Client-Capture laeuft mit Gate `pass` und schreibt Host- und Client-Fensterbilder.
- Status/Roadmap benennen den sichtbaren Befund und den naechsten Task.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1163_left_tactical_stack_1280_release_recapture.gd`
- `docs/tasks/TASK_1163_left_tactical_stack_1280_release_recapture.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- Neuer Verifier: `scripts/tests/task_1163_left_tactical_stack_1280_release_recapture.gd`
- Regressionen: TASK_1162, TASK_1161, TASK_222, `git diff --check`.
- Release: `scripts/tools/export_runtime_release.ps1`, `scripts/tools/release_runtime_start_check.ps1 -JsonOnly`, `scripts/tools/capture_release_host_client_entry_playtest.ps1 -FirstContact -StopRunningReleaseProcesses`.

## Risiken / offene Punkte
Der Capture schreibt Belege und Gate-Status. Die endgueltige menschliche Sichtentscheidung bleibt ein Folgefund: Wenn links noch zu dicht wirkt, wird daraus TASK_1164 geschnitten.
