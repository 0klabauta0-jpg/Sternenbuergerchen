# TASK_333 - Navigation Fallback Budget Contract Alignment

## Ziel
Navigation-Budgets, Export-Defaults und Fallback-Pfade sollen zusammenpassen. Der Task verhindert stille Pathfinding-Spikes, besonders wenn Ziele nicht direkt erreichbar sind.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_217 - Navigation Pathfinding LOS Performance Pass
- TASK_222 - Performance Regression Gate and Manual Profile Checklist

## Kontext
Der Performance-Budget-Contract fuehrt Navigation als budgetierten Bereich. Gleichzeitig kann ein Fallback wie `_find_nearest_reachable_walkable_grid` in `SimulationRoot` bei schlechten Zielen viele Tiles sortieren und mehrere Pfadversuche ausloesen. Zusaetzlich soll geprueft werden, ob Export-Defaults und Budget-Contract denselben Zielwert meinen oder ob Szenen-Overrides die Differenz bewusst setzen.

## Umfang
1. Budget-Audit:
   - `data/performance_budget_contract.json`, Export-Defaults und Szenen-Overrides fuer Navigation vergleichen.
   - Abweichungen dokumentieren oder korrigieren.
2. Fallback-Messung:
   - Zaehler fuer Fallback-Aufrufe, Kandidatenmenge und Pfadversuche erfassen.
   - Schlechte Zielpunkte in einem Headless-Test abdecken.
3. Fallback-Optimierung:
   - Wenn moeglich HPA-/Komponenten-/Reachability-Daten nutzen, bevor viele volle Pfadversuche gestartet werden.
   - Fallback hart budgetieren oder abbrechen, wenn der Contract sonst verletzt wird.
4. Diagnose:
   - Budget-Ueberschreitungen als Report-/Warnhinweis sichtbar machen, nicht still verschlucken.

## Nicht-Ziele
- Kein kompletter Pathfinding-Neubau.
- Keine neue Navigation-Architektur.
- Keine Balance-Aenderung an Bewegungsreichweiten.
- Keine Aenderung an Terrain-Semantik.

## Akzeptanzkriterien
- [x] Navigation-Export-Defaults und Budget-Contract sind konsistent oder die Abweichung ist dokumentiert.
- [x] Unreachable-/Bad-Target-Faelle erzeugen keine unbudgetierten Mehrfachpfad-Spikes.
- [x] Fallback-Diagnose ist im Report sichtbar.
- [x] Navigation- und Performance-Gates bleiben gruen.

## Erwartete Dateien
- `scripts/core/simulation_root.gd`
- `data/performance_budget_contract.json`
- optional `scripts/navigation/**`
- `scripts/tests/task_333_navigation_fallback_budget_contract_alignment.gd`
- `docs/reports/navigation_fallback_budget_contract_alignment.md`
- `docs/tasks/TASK_333_navigation_fallback_budget_contract_alignment.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_333_navigation_fallback_budget_contract_alignment.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_217_navigation_pathfinding_los_performance_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd`
- [x] `git diff --check`

## Risiken
- Zu aggressive Budgetierung kann Units an schlechten Zielpunkten scheinbar nicht reagieren lassen. Tests muessen deshalb sowohl Budget als auch nachvollziehbares Feedback pruefen.

## Naechster Schritt
Falls mehrere Fallbacks haeufig auftreten, folgt ein eigener Terrain-/Command-Targeting-Task statt weiterer Navigation-Mikrofixes.
