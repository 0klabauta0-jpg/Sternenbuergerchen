# TASK_170 - Performance and Warning Budget Gate

## Ziel
Die bekannten Godot-Warnungs- und Performance-Risiken werden in ein kleines Gate gegossen: keine stillen 2.5D-Fallbacks, keine RID/ObjectDB-Leaks in Smokes, und klare Budgets fuer Render-/Navigation-/Snapshot-Pfade.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_128_navigation_budgeting_und_debug.md`
- Lies `docs/tasks/TASK_131_navigation_benchmark_harness.md`
- Lies `docs/tasks/TASK_159_2_5d_editor_and_mission_primary_view.md`
- Lies `docs/tasks/TASK_160_tactical_mission_playability_smoke.md`
- Lies `docs/reviews/strategic_review_ui_assets_multiplayer_2026_05_03.md`
- Pruefe den Git-Status

## Kontext
- Der 2.5D-Primary-Pfad hat bereits Snapshot-Zaehler fuer Missing Assets und Fallbacks.
- RID/ObjectDB-Leaks wurden zuletzt behoben, sollen aber nicht wieder unbemerkt auftauchen.
- Navigation und 3D-Rendering haben bereits Debug-/Benchmark-Ansaetze.

## Umfang
1. Warning-Gate definieren:
   - Headless-Smokes duerfen keine RID/ObjectDB-Leaks melden.
   - Primary-3D-Smokes duerfen keine Sprite3D-/Box-/Capsule-Fallbacks nutzen, wenn GLB vorhanden ist.
   - Missing-Asset-Zaehler muessen bei erwarteten Testmaps 0 sein.
2. Performance-Budget dokumentieren:
   - 2.5D-Render-Snapshot-Dauer
   - Navigation-New-Path-Queries pro Tick
   - Snapshot-Build-/Apply-Zaehler
3. Kleinen Verifier oder Harness erweitern:
   - TASK_159/TASK_160-Werte zusammenfassen.
   - klare Fehlermeldung bei Budgetbruch.
4. Optional: `docs/dev/`-Notiz fuer lokale Godot-Version und erwartete Warnungen.

## Nicht-Ziele
- Kein globales Profiler-System.
- Kein CI-Aufbau, falls nicht bereits vorhanden.
- Kein Performance-Refactor ohne Messwert.

## Architekturregeln
- Messung darf keine Gameplay-Wahrheit veraendern.
- Debug-Snapshots bleiben read-only.
- Fallbacks im Primary-Pfad bleiben sichtbar statt still.

## Akzeptanzkriterien
- Ein schneller Gate-Verifier prueft Warnungs-/Fallback-/Budgetwerte.
- Bestehende TASK_159/TASK_160-Verifier bleiben gruen.
- Verifier-Output nennt konkrete Zaehler bei Fehlern.
- Dokumentation sagt, welche Godot-Warnungen akzeptiert sind und welche nicht.

## Lokale Pruefung
- [x] Neuer Gate-Verifier: `godot_console.exe --headless --path . --script scripts/tests/task_170_performance_warning_gate_verifier.gd`
- [x] Warning-Wrapper: `powershell -ExecutionPolicy Bypass -File scripts/tests/run_task_170_warning_gate.ps1`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_159_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_131_verifier.gd`

## Ergebnis
- `TerrainMap3DView.get_render_snapshot()` enthaelt jetzt reine Diagnosezaehler fuer Snapshot-Requests und Apply-Pfade von Order-, Contact-, Dropship- und Mission-Status-Payloads.
- `scripts/tests/task_170_performance_warning_gate_verifier.gd` prueft Live-Primary-View, Render-Spike und Navigation-Budget in einem schnellen Gate. Der Output nennt konkrete Render-, Fallback-, Snapshot- und Navigation-Zaehler.
- `scripts/tests/run_task_170_warning_gate.ps1` fuehrt den Gate-Verifier aus und blockiert bekannte Godot-Exit-Leak-Muster wie `ObjectDB instances leaked`, `RID allocations ... leaked` und `Resources still in use at exit`.
- `docs/dev/performance_warning_gate.md` dokumentiert akzeptierte Ausgaben, blockierte Warnungen und die aktuellen Budgetwerte.

## Risiken
- Zu harte Zeitbudgets koennen auf langsameren Maschinen false positives erzeugen. Anfangs tolerant messen, dann nach lokalen Werten schaerfen.
- Godot-Versionen koennen Warnungstexte aendern; Gate sollte wichtige Muster robust erkennen.
