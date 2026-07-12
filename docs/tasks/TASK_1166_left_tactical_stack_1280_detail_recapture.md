# TASK_1166 - Left Tactical Stack 1280 Detail Recapture

## Ziel / Problem
TASK_1165 hat die strukturelle Detail-Lesbarkeit des linken taktischen Stacks verbessert. Jetzt braucht der reale exportierte 1280x720-Host/Client-Blick wieder einen belastbaren Beleg, damit wir nicht nur headless-Metadaten vertrauen.

## Sinnhaftigkeit / Ursache
Der linke Stack ist eine Spielerflaeche. Der vorherige TASK_1164-Befund kam aus sichtbaren Host-/Client-Fensterbildern; deshalb muss auch der Detail-Polish wieder an echten Release-Artefakten haengen. Kombinierte Desktop-Captures bleiben unzuverlaessig, separate Fensterbilder sind die belastbare Quelle.

## Umfang
- Read-only Recapture-Snapshot fuer TASK_1166.
- Verknuepfung mit TASK_1165 Detail-Polish-Snapshot.
- Pruefung des aktuellen Release-Provenance-Commits gegen Branch-HEAD.
- Pruefung des bestehenden Host/Client-FirstContact-Manifests und der separaten Fensterbilder.
- Keine weitere Layout-Aenderung in diesem Task.

## Nicht-Ziele
- Kein neuer HUD-Polish.
- Kein neues Multiplayer-System.
- Keine Commands, Effects, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.
- Kein Ersatz fuer eine menschliche subjektive Sichtabnahme.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1165_left_tactical_stack_1280_detail_polish.md`
- `scripts/tools/capture_release_host_client_entry_playtest.ps1`
- `scripts/tools/release_runtime_start_check.ps1`

## Akzeptanzkriterien
- `get_left_tactical_stack_1280_detail_recapture_snapshot()` liefert Schema `sternenbuergerchen.left_tactical_stack_1280_detail_recapture.v1`.
- Snapshot liest TASK_1165 als Quelle und verlangt `left_stack_detail_polish_ready`.
- Release-Provenance ist vorhanden, gueltig und zeigt auf den aktuellen Git-HEAD.
- FirstContact-Manifest ist vorhanden, `gate = pass`, `release_gate = pass`, `deployment_converged = true`, `first_fire_converged = true`.
- Host- und Client-Fensterbilder sind separate Dateien, geschrieben und groesser als Null.
- Snapshot bleibt read-only und erzeugt keine Gameplay- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1166_left_tactical_stack_1280_detail_recapture.gd`
- `docs/tasks/TASK_1166_left_tactical_stack_1280_detail_recapture.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1166_left_tactical_stack_1280_detail_recapture.gd`
- Regressionen: TASK_1165, TASK_1164, TASK_222, `git diff --check`.
- Bei fehlendem oder veraltetem Manifest: `powershell -ExecutionPolicy Bypass -File scripts\tools\export_runtime_release.ps1` und danach `powershell -ExecutionPolicy Bypass -File scripts\tools\capture_release_host_client_entry_playtest.ps1 -FirstContact -StopRunningReleaseProcesses`.

## Risiken / offene Punkte
Der Snapshot kann belegen, dass die richtigen Release-Artefakte existieren und zum aktuellen Commit gehoeren. Er ersetzt nicht den menschlichen Blick auf die erzeugten Fensterbilder. Wenn der Blick noch unruhig ist, wird daraus TASK_1167 als gezielter Visual-Follow-up geschnitten.
