# TASK_616 - Host Client Visible UI Real Run Review

## Ziel / Problem
Der GUI-basierte TASK_615-Real-Run zeigt zwei echte Sternenbuergerchen-Fenster. Der Host rendert die Mission-Welt, der Client zeigt HUD/Fireteam-Karten, aber die eigentliche Terrain-/Weltflaeche bleibt schwarz.

## Sinnhaftigkeit / Ursache
Der sichtbare Zwei-Fenster-Lauf ist der naechste Beleg fuer Multiplayer-Spielgefuehl. Wenn der zweite Prozess nur UI, aber keine Welt zeigt, kann man Authority, Sync, Dropship-/Fireteam-Status und Performance nicht sinnvoll als Spieler beurteilen. Der Terrain-View nutzt aus Performancegruenden `SubViewport.UPDATE_ONCE`; bei sichtbaren Multi-Window-Starts kann dieser erste Renderimpuls zu frueh kommen, bevor Groesse/Fenster/Map-Inhalt stabil sichtbar sind.

## Umfang
- `TerrainMap3DView` bekommt nach Start, Map-Render und SubViewport-Resize ein kurzes Bootstrap-Redraw-Fenster.
- Das Redraw faellt danach automatisch wieder auf `UPDATE_ONCE` zurueck.
- Der Real-Run-Capture-Helper fokussiert/positioniert gestartete Host-/Client-Fenster direkt nach dem Prozessstart, nicht erst nach der Wartezeit.
- TASK_616 dokumentiert den Real-Run-Befund und die Grenze: kein Multiplayer-State wird im UI erzeugt.
- Der laufende HTML-Zwischenbericht wird mit TASK_616 aktualisiert.
- Ein Verifier prueft Task, Contract, Bericht und den Redraw-Guard statisch.

## Nicht-Ziele
- Kein Netcode-Rewrite.
- Keine neue Gameplay-Wahrheit in UI, Tooling, Manifest oder Bericht.
- Kein per-frame Dauer-Rendern als Standard.
- Kein Schliessen fremder Godot-/Editor-Prozesse.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_615_host_client_real_run_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- TASK_616-Taskdatei dokumentiert den Client-World-Blackout aus dem GUI-Capture.
- `TerrainMap3DView` behaltet den sparsamen `UPDATE_ONCE`-Normalfall, nutzt aber fuer Bootstrap/Resize/Map-Render kurz `UPDATE_ALWAYS`.
- Der Redraw-Guard ist zeitlich begrenzt und benutzt keine SceneTree-Vollscans.
- Der laufende HTML-Bericht nennt TASK_616 als erledigten Zwischenstand und empfiehlt eine echte sichtbare Re-Capture-Pruefung.
- TASK_616-Verifier laeuft gruen.

## Betroffene Dateien
- `docs/tasks/TASK_616_host_client_visible_ui_real_run_review.md`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/tests/task_616_host_client_visible_ui_real_run_review.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_616_host_client_visible_ui_real_run_review.gd`
- Regression: `task_615_host_client_real_run_findings.gd`
- Regression: `task_614_host_client_two_window_real_run_review.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- Regression: `task_598_homebase_progression_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Guard stabilisiert den sichtbaren Render-Impuls, ersetzt aber keinen finalen menschlichen Spielgefuehltest.
- Falls ein spaeterer Real-Run trotz Guard schwarz bleibt, liegt die Ursache tiefer im Client-World-Initialisierungspfad und muss in einem separaten Runtime-Diagnostic-Task untersucht werden.
