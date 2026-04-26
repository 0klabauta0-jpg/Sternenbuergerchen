# TASK_129 - Deckungsbewusste Pfade mit HPA und Subgoal-Vorbereitung

## Ziel
Fireteams sollen bei Bewegungsbefehlen nicht nur kurze, sondern taktisch sinnvollere Pfade nutzen: offene, feindnahe und stark exponierte Tiles werden teurer, gedeckte oder weniger sichtbare Tiles werden bevorzugt. Die bestehende HPA-/A*-Pipeline bleibt die Grundlage.

## Status: IMPLEMENTIERT

## Voraussetzung
- `TASK_126 - HPA Navigation Foundation`
- `TASK_127 - HPA Pathfinder Integration`
- `TASK_128 - Navigation Budgeting und Debug`

## Kontext
- `TerrainRegistry` und `TerrainTileData` liefern bereits Walkability, Hoehen, Surface-Kosten, Cover-Werte und LOS-Blocker.
- `SimulationRoot` ist autoritative Bewegungsstelle und nutzt HPA im Move-Pfad.
- Fireteam-Befehle wie `move`, `defend`, `take`, `engage` und `flank` sollen spaeter unterschiedliche Risikogewichte setzen koennen.
- Der erste Schritt soll keine neue Navigation-Architektur einfuehren, sondern die vorhandenen Kosten erweitern.

## Umfang
1. Einen kleinen Exposure-/Cover-Kostenvertrag einfuehren:
   - Exposure pro Tile aus bekannten Kontakt-/Gefahrenpositionen oder statischen Test-Feindpunkten ableiten.
   - Bestehendes `cover_value` als Kostenreduktion beruecksichtigen.
   - Kostenformel parametrisierbar halten: `base_cost + surface + height + exposure_weight - cover_weight`.
2. HPA-/TerrainPathfinder-Kostenpfad erweitern:
   - Pfadfindung bleibt ueber Grid/HPA.
   - Kosten duerfen Walkability-Regeln nicht umgehen.
   - Diagonal- und Corner-Cutting-Regeln bleiben identisch.
3. HPA-Kanten optional mit Cover-/Exposure-Meta annotieren:
   - zunaechst nur einfache `mean_exposure`, `min_cover` oder vergleichbare Debugwerte.
   - keine vollstaendige Subgoal-Graph-Implementierung in diesem ersten Slice.
4. Command-/Behavior-Gewichte anbinden:
   - `move`: neutral bis leicht vorsichtig.
   - `defend`: Cover staerker gewichten.
   - `take`/`engage`: moderate Exposure-Vermeidung.
   - `flank`: Exposure vermeiden, aber keine extremen Umwege erzwingen.
   - spaetere `rush`-Profile koennen Exposure fast ignorieren.
5. Debug- und Vergleichsverifier:
   - Plain-HPA-Pfad vs. cover-aware Pfad.
   - Pfadlaenge, Exposure-Summe, Cover-Summe und Query-Kosten vergleichen.

## Nicht-Ziele
- Kein ORCA/RVO.
- Keine lokale Kollisionsvermeidung.
- Keine echte Subgoal-Graph-Architektur in diesem Task.
- Kein Theta*/JPS-Refactor.
- Keine neue UI-Pflichtanzeige.
- Keine echte Ballistik oder physikbasierte Gefahrensimulation.

## Architekturregeln
- Gameplay-Wahrheit und Positions-Commit bleiben in `SimulationRoot`.
- Pfadkosten gehoeren in Terrain-/Navigation-Code, nicht in UI oder Visualizer.
- Debugwerte sind rein lesend und abschaltbar.
- Keine SceneTree-Vollscans im Hotpath.
- Teure Exposure-Berechnung muss cachebar oder budgetierbar sein.

## Akzeptanzkriterien
- [x] Cover-aware Pfadkosten koennen fuer eine Testkarte aktiviert/deaktiviert werden.
- [x] Ein Testfall zeigt geringere Exposure-Summe als Plain-HPA bei akzeptabler Mehrlaenge.
- [x] Pfade betreten weiterhin keine nicht-walkable Tiles.
- [x] HPA-Pfade funktionieren mit und ohne Exposure-Kosten.
- [x] Command-Typ oder Behavior-Profil kann die Risikogewichtung beeinflussen.
- [x] Debug-Snapshot nennt Pfadlaenge, Exposure-Summe und Cover-Summe.
- [x] Bestehende HPA-, Blocker-, Area- und Fireteam-Movement-Tests bleiben gruen.

## Erwartetes Ergebnis
- Fireteams wirken taktischer, weil sie Deckung und offene Feuerlinien in der Routenwahl beruecksichtigen.
- Die bestehende HPA-Pipeline bleibt erhalten.
- Spaetere Subgoal-/Any-Angle-Optimierung hat Messdaten und klare Anschlussstellen.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_129_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_128_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_127_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_125_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_110_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_123_verifier.gd`

## Dateien
- `scripts/terrain/terrain_pathfinder.gd`
- `scripts/terrain/hpa_pathfinder.gd`
- `scripts/terrain/hpa_navigation_graph.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/task_129_verifier.gd`

## Ergebnis
- `TerrainPathfinder` akzeptiert optionale Cover-/Exposure-Kosten und kann Pfade mit `path_length_grid`, `exposure_sum`, `cover_sum`, Mittelwerten und Gesamtkosten auswerten.
- `HPAPathfinder` reicht diese Kostenoptionen an lokale Segmente weiter; Portal-Kanten tragen erste statische Cover-Metadaten als Subgoal-Anschlussstelle.
- `SimulationRoot` baut Navigation-Kostenoptionen aus Command-Typ, `source_command_type`, Hazard-Grids/-Positionen und optionalen Overrides.
- Der Navigation-Debug-Snapshot enthaelt jetzt die letzten Pfadmetriken inklusive Pfadlaenge, Exposure-Summe und Cover-Summe.

## Risiken
- Zu hohe Exposure-Gewichte koennen Fireteams unnatuerlich lange Umwege laufen lassen.
- Dynamische Kontakte koennen Pfade zu oft invalidieren; TASK_128-Budgeting muss deshalb vorher stehen.
- Cover-aware Kosten duerfen keine zweite taktische KI werden, sondern nur Pfadkosten beeinflussen.
