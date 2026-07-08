# BUGFIX - Release Singleplayer EXE Stale FOB Transfer Actionability Guard

## Ziel / Problem
Der sichtbare Release-Pfad `EXE -> Einzelspieler` kann auf einem alten Homebase-Bild landen: `Operation: FOB Transfer`, `Start blockiert`, leere Flightdeck-/Payload-Anzeige und STOP-Readiness. Das blockiert den Spieler direkt nach dem Klick.

## Sinnhaftigkeit / Ursache
Der bestehende Normal-Click-Guard repariert Mission, Drop-Quelle, Roster, Dropship, Pilot und Payload. Die Actionability-Pruefung akzeptierte aber noch jeden Zustand, der technisch genug Payload/Flightdeck hatte. Dadurch konnte ein stale `fob_transfer`-/FOB-Drop-Fragment im sichtbaren Release-Start zu spaet auffallen.

## Umfang
- Release-Singleplayer-Actionability verlangt explizit `grid_sweep`.
- Release-Singleplayer-Actionability verlangt explizit `homebase_direct`.
- Bestehender Reparaturpfad bleibt zustandserhaltend und nutzt weiter die vorhandenen Bootstrap-/Homebase-Direct-Funktionen.
- Regressionstests sichern den normalen Klickpfad und die Sofort-/Post-Show-Reparatur.

## Nicht-Ziele
- Kein Entfernen von `fob_transfer` fuer echte FOB-Workflows.
- Kein neues Save-System.
- Keine UI-seitige Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/BUGFIX_release_singleplayer_normal_click_homebase_guard.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`

## Akzeptanzkriterien
- Der normale Singleplayer-Klick landet nicht in `Operation: FOB Transfer`.
- Der sichtbare Release-Normalstart ist erst actionable, wenn Mission `grid_sweep` und Drop-Quelle `homebase_direct` sind.
- `Start Mission` ist nach Repair aktiv.
- Der Fix mutiert keine Mission-Wahrheit im HUD.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/bugfix_release_singleplayer_normal_click_homebase_guard.gd`
- `scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `docs/tasks/BUGFIX_release_singleplayer_exe_stale_fob_transfer_actionability_guard.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_release_singleplayer_normal_click_homebase_guard.gd`
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_827_release_homebase_save_override_guard.gd`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/start_release_runtime_checked.ps1 -StopRunningReleaseProcess -CleanTempFiles -Launch -LaunchArguments "--release-singleplayer"`
- `git diff --check`

## Risiken / offene Punkte
Ein alter laufender Prozess oder eine andere manuell gestartete EXE kann weiterhin wie derselbe Fehler aussehen. Der vertragliche Release-Ordner ist `C:\dev\Sternenbuergerchen_rel`; die Taskleisten-Verknuepfung muss auf diese EXE zeigen.
