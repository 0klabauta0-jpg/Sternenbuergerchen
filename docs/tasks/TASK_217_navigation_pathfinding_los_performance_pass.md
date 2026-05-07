# TASK_217 - Navigation Pathfinding LOS Performance Pass

## Ziel
Terrain, HPA/A*, LOS, Cover, Hoehenregeln und lokale Avoidance sollen unter Performance-Aspekten geprueft werden. Der Fokus liegt auf 32x32- und 64x64-Maps mit mehreren Fireteams, Enemy-Gruppen und Huegel-/Klippenstrukturen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_126 - HPA Navigation Foundation
- TASK_127 - HPA Pathfinder Integration
- TASK_128 - Navigation Budgeting und Debug
- TASK_129 - Deckungsbewusste Pfade mit HPA und Subgoal-Vorbereitung
- TASK_130 - Lokale Unit-Avoidance mit ORCA/RVO-Light
- TASK_131 - Navigation Benchmark Harness
- TASK_184 - Gameplay Hill Semantics Patch
- TASK_187 - NPC Minimum Spacing and Multiplayer Authority
- TASK_215 - Performance Deep Pass Baseline and Research

## Kontext
Navigation ist bereits budgetiert, aber neue Anforderungen wie Enemy-Team-Taktik, Mindestabstand, Huegelregeln, Medic-Bewegung, Overwatch und NPC-Gedanken koennen unbemerkt wieder viele Queries oder LOS-Checks erzeugen.

## Umfang
1. Benchmark-Matrix:
   - 32x32 offen.
   - 32x32 mit Huegel/Klippen/Sand.
   - 64x64 offen.
   - 64x64 mit Engpaessen/Deckung.
   - Viele kurze Befehle und Area Orders.
2. Query-Budget:
   - New path queries pro Tick.
   - Pending/delayed queries.
   - Average/P95/P99 query time.
   - Cache hit/miss und Invalidation.
3. LOS-/Cover-Kosten:
   - LOS-Checks pro Combat-Tick.
   - Cover-aware Pfade.
   - Hoehen-/Wand-/Klippenblocker.
   - Keine per-frame Raycast-Schleifen fuer statische Grid-Fragen, wenn Daten-/Tile-LOS reicht.
4. Local Avoidance:
   - Kosten bei Cluster, Dropship-Deploy, Enemy-Wave, Kontaktstop.
   - Keine Separation auf nicht-walkable Tiles.
   - Blockierte Paare diagnostisch, aber nicht spammy.
5. Update-Staggering:
   - Viele NPCs duerfen nicht alle im selben Tick komplette Neuberechnung erzwingen.
   - Command-/Tactic-Events sollen Queries ausloesen, nicht jeder Frame.
6. Verifier:
   - Breite Timing-Ausgabe.
   - Budgets tolerant starten und nach lokaler Baseline schaerfen.

## Nicht-Ziele
- Kein kompletter NavMesh-Wechsel.
- Kein C++/GDExtension.
- Kein Gameplay-Regelwechsel fuer Huegel.
- Keine clientseitige Pfadentscheidung fuer Multiplayer.

## Akzeptanzkriterien
- [x] Navigation-Benchmark deckt 32x32 und 64x64 inklusive Huegel/Deckung ab.
- [x] Pathfinding-Queries haben Median/P95/P99-Werte.
- [x] LOS-/Cover-Checks werden gezaehlt und budgetiert.
- [x] Avoidance-Kosten werden separat erfasst.
- [x] Neue Enemy-/Medic-/Area-Order-Pfade koennen keine Query-Flut pro Frame ausloesen.
- [x] Ein TASK_217-Verifier prueft Budgets, Delay-Verhalten und Cache-Diagnosen.

## Erwartete Dateien
- `scripts/tests/navigation_benchmark_harness.gd`
- `scripts/terrain/terrain_pathfinder.gd`
- `scripts/tactical/local_avoidance_resolver.gd`
- `docs/performance/navigation_pathfinding_los_profile_report.md`
- `scripts/tests/task_217_navigation_pathfinding_los_performance_pass.gd`
- `docs/tasks/TASK_217_navigation_pathfinding_los_performance_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_217_navigation_pathfinding_los_performance_pass.gd` (51/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_131_verifier.gd` (21/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_184_gameplay_hill_semantics_verifier.gd` (30/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_187_npc_minimum_spacing_and_multiplayer_authority.gd` (16/0)
- [x] `git diff --check`

## Umsetzung
- `navigation_benchmark_harness.gd` enthaelt jetzt 32x32-/64x64-Profilkarten fuer offen, Huegel/Deckung und Engpass/Deckung sowie Query-Flood-Staggering.
- Path-Batches liefern Median/P95/P99 fuer Query-Zeiten und Pfadlaengen.
- `TerrainPathfinder` zaehlt optionale Diagnosewerte fuer Exposure-, LOS- und Cover-Abfragen.
- Cache-Diagnose ist explizit als aktueller No-Cache-Befund sichtbar, damit ein spaeterer Cache nicht still eingefuehrt wird.
- `docs/performance/navigation_pathfinding_los_profile_report.md` dokumentiert Matrix, Budgets, Cache-Befund und Avoidance/Staggering.

## Risiken
- Enge Budgets koennen auf langsameren Maschinen false positives erzeugen.
- LOS und Cover duerfen nicht durch schnelle, aber falsche Approximationen kaputtoptimiert werden.

## Naechster Schritt
Nach TASK_217 prueft TASK_218 Simulation, Combat und AI-Ticks.
