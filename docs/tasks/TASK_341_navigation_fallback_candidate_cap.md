# TASK_341 - Navigation Fallback Candidate Cap

## Ziel
Der Navigation-Fallback fuer schlechte oder unerreichbare Zielpunkte soll nicht mehr alle Tiles einer grossen erreichbaren HPA-Komponente als Kandidaten durchsuchen. Die Kandidatensuche braucht eine harte, nachvollziehbare Obergrenze.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_217 - Navigation Pathfinding LOS Performance Pass
- TASK_333 - Navigation Fallback Budget Contract Alignment
- TASK_337 - Architecture Performance UX Followup Gate

## Kontext
TASK_333 hat die versteckte per-candidate-A*-Schleife entfernt und Budget-Diagnose ergaenzt. Die Review hat aber eine Restkante gefunden: Bei einem schlechten Ziel kann die Fallback-Suche weiterhin sehr viele erreichbare Komponententiles sammeln und bewerten. Das ist guenstiger als viele Pfadversuche, aber in grossen Maps weiterhin ein vermeidbarer Spike.

## Umfang
1. Fallback-Audit:
   - `_find_nearest_reachable_walkable_grid()`, HPA-Komponentenaufloesung und `_collect_hpa_reachable_component_tiles()` verfolgen.
   - Aktuelle Kandidatenmengen in grossen zusammenhaengenden Komponenten sichtbar machen.
2. Kandidaten-Cap:
   - Radius-/Ring-Suche, Distanz-Buckets oder einen bestehenden Terrain-/HPA-Index nutzen, um nahe Kandidaten zuerst zu betrachten.
   - Harte Maximalzahl fuer gesammelte und bewertete Kandidaten einfuehren.
   - Bei Cap-Treffern Diagnose setzen, aber keinen versteckten Mehrfachpfad starten.
3. Contract:
   - `data/performance_budget_contract.json` um klare Fallback-Kandidatenlimits oder Warnschwellen ergaenzen.
   - Debug-Snapshot meldet considered, capped, selected distance und Grund.
4. Regression:
   - Schlechte Ziele finden weiterhin nachvollziehbare nahe Fallbacks, wenn erreichbar.
   - Unerreichbare Ziele brechen sauber mit Feedback/Diagnose ab.

## Nicht-Ziele
- Kein kompletter Pathfinding-Neubau.
- Kein neues MAPF-/Avoidance-System.
- Keine Aenderung an Walkability-, Hoehen- oder Surface-Semantik.
- Keine Balance-Aenderung an Bewegungsreichweiten.

## Akzeptanzkriterien
- [x] Bad-Target-Fallbacks betrachten maximal die vertraglich erlaubte Kandidatenzahl.
- [x] Grosse HPA-Komponenten verursachen keine unbounded Tile-Sammlung im Fallback-Hotpath.
- [x] Debug-/Report-Daten zeigen Cap-Treffer und ausgewaehlten Fallback nachvollziehbar.
- [x] Navigation- und Performance-Gates bleiben gruen.

## Erwartete Dateien
- `scripts/core/simulation_root.gd`
- `data/performance_budget_contract.json`
- `scripts/tests/task_341_navigation_fallback_candidate_cap.gd`
- `docs/reports/navigation_fallback_candidate_cap.md`
- `docs/tasks/TASK_341_navigation_fallback_candidate_cap.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_341_navigation_fallback_candidate_cap.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_333_navigation_fallback_budget_contract_alignment.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_217_navigation_pathfinding_los_performance_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd`
- [x] `git diff --check`

## Risiken
- Ein zu kleines Cap kann Units bei schlechten Zielpunkten frueher blockieren. Der Task braucht deshalb Tests fuer "naher gueltiger Fallback wird gefunden" und "Cap wird sichtbar, aber nicht still".

## Naechster Schritt
Falls die Kandidatensuche trotz Cap unruhig bleibt, folgt ein separater Terrain-/Navigation-Index-Task statt weiterer Logik im `SimulationRoot`.
