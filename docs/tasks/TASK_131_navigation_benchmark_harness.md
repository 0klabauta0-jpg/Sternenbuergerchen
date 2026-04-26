# TASK_131 - Navigation Benchmark Harness

## Ziel
Die seit TASK_126 bis TASK_130 gewachsene Navigation soll datenbasiert vergleichbar werden. Ein kleiner Benchmark-Harness misst globale Pfade, Cover-Kosten, Budgeting und lokale Avoidance in reproduzierbaren Szenarien, bevor weitere Optimierungen wie JPS oder D* Lite eingebaut werden.

## Status: IMPLEMENTIERT

## Voraussetzung
- `TASK_126 - HPA Navigation Foundation`
- `TASK_127 - HPA Pathfinder Integration`
- `TASK_128 - Navigation Budgeting und Debug`
- `TASK_129 - Deckungsbewusste Pfade mit HPA und Subgoal-Vorbereitung`
- `TASK_130 - Lokale Unit-Avoidance mit ORCA/RVO-Light`

## Kontext
- HPA/A* ist aktuell die autoritative globale Pfadgrundlage.
- Cover-aware Kosten und ORCA-Light sind optional und brauchen messbare Vergleichswerte.
- JPS und D* Lite sind interessante Optimierungen, aber nur sinnvoll, wenn lokale Messungen zeigen, wo unser aktueller Stack tatsaechlich kippt.

## Umfang
1. Benchmark-Szenarien als headless lauffaehige Test-/Toolskripte:
   - offene Karte mit vielen parallelen Queries.
   - Korridor/Engpass-Karte.
   - Cover-/Exposure-Testkarte.
   - optionale dynamische Tile-Flip-Testkarte als D* Lite-Vorbereitung.
2. Varianten vergleichbar schalten:
   - TerrainPathfinder direkt.
   - HPA-Pfadfinder.
   - HPA mit Cover-aware Kosten.
   - HPA plus lokaler Avoidance-Ausfuehrung.
   - optionaler JPS-Prototyp nur auf uniformen Testkarten.
3. Metriken sammeln:
   - Query-Zeit.
   - Pfadlaenge.
   - Exposure-/Cover-Summen.
   - Budget-Delays.
   - Mindestabstand/Kollisionsnaehe bei Movement.
   - Stuck-/Deadlock-Zaehler.
4. Ergebnisse als Dictionary/JSON-artige Summary ausgeben.
5. Keine Gameplay-Entscheidungen veraendern.

## Nicht-Ziele
- Keine produktive JPS- oder D* Lite-Integration.
- Kein NavigationServer-Umbau.
- Keine UI-Pflichtanzeige.
- Keine Massenschlacht-Optimierung fuer tausende Units.

## Architekturregeln
- Benchmarks lesen Systeme und rufen vorhandene APIs auf, aber committen keine neue Gameplay-Wahrheit.
- Keine SceneTree-Vollscans in produktiven Pfaden.
- Benchmark-Code darf unter `scripts/tests` liegen, produktive Utilities nur bei klarem Wiederverwendungswert.

## Akzeptanzkriterien
- [x] Benchmark laeuft headless.
- [x] Mindestens drei Szenarien liefern reproduzierbare Metriken.
- [x] HPA, Cover-aware HPA und Avoidance koennen getrennt verglichen werden.
- [x] Output nennt Query-Zeit, Pfadlaenge, Delay-/Stuck-Werte und Exposure/Cover, wo relevant.
- [x] Bestehende Task-128/129/130-Verifier bleiben gruen.

## Erwartetes Ergebnis
Wir wissen, welche Navigationsteile in welchen Szenarien teuer oder instabil werden. Folgeentscheidungen wie JPS, D* Lite oder CBS/MAPF werden datenbasiert statt nach Bauchgefuehl getroffen.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_131_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_130_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_129_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_128_verifier.gd`

## Dateien (voraussichtlich)
- `scripts/tests/task_131_verifier.gd`
- `scripts/tests/navigation_benchmark_harness.gd`

## Risiken
- Benchmarks koennen leicht zur zweiten Simulationslogik werden. Deshalb muessen sie vorhandene Systeme messen und nicht neue Bewegungspfade einfuehren.
