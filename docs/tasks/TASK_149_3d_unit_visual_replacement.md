# TASK_149 - 3D Unit Visual Replacement

## Ziel
Die bisherigen 2D-Unit-Sprites im Missionsbild werden durch lesbare 3D-Unit-Visuals ersetzt oder eindeutig ueberlagert, ohne die autoritativen 2D-Unit-Positionen und Runtime-Systeme zu veraendern.

## Status: GEPLANT

## Voraussetzung
- `TASK_148 - 3D Primary Mission View`

## Kontext
- `TASK_143` hat bereits 3D-Unit-Placeholder, Selection, Debuglabels, Air-Schatten und Marker ueber `Terrain25DVisualProjection`.
- Fuer eine echte 3D-Missionsansicht reichen Placeholder nicht: Teams, Rollen, Auswahlstatus und Air/Ground muessen schnell lesbar sein.

## Umfang
1. 3D-Unit-Visualvertrag definieren:
   - Friendly/Enemy unterscheidbar.
   - FTL/Unit/Rolle unterscheidbar, mindestens per Farbe/Marker.
   - Air-Units mit Schatten und Altitude-Lesbarkeit.
2. Asset- oder Mesh-Auswahl:
   - einfache Kenney-Unit-GLBs oder stabile Primitive als V1, je nachdem was sauber importiert ist.
   - keine Animationen als Pflicht.
3. Bridge-Sync erweitern:
   - bestehende Projection-Helfer weiterverwenden.
   - 2D-Unit-Sprite optional ausblenden, autoritative `Node2D.global_position` bleibt bestehen.
4. Selection/Targeting pruefen:
   - Auswahlringe und Debuglabels liegen auf passender Hoehe.
   - Path Preview bleibt sichtbar.
5. Verifier:
   - Unit-Visuals werden fuer registrierte Units erzeugt.
   - Team-/Air-/Selection-Zustand ist sichtbar unterscheidbar.
   - 2D-Sprite-Fallback kann fuer Debug erhalten bleiben.

## Nicht-Ziele
- Keine Character-Animationen.
- Keine Full-3D-Unit-Simulation.
- Keine Umstellung der Unit-Logik von Node2D auf Node3D.
- Keine neue Combat- oder Trefferlogik.

## Architekturregeln
- `TestUnit`/Unit-State bleibt Gameplay-Datenquelle.
- 3D-Unit-Visuals sind Darstellung und duerfen keine Commands committen.
- Registries bleiben Lookup-Pfad, keine SceneTree-Vollscans im Hotpath.

## Akzeptanzkriterien
- [ ] Missionsunits erscheinen im 3D-Bild als lesbare 3D-Visuals.
- [ ] Team, Auswahl und Air/Ground sind unterscheidbar.
- [ ] 2D-Sprites koennen fuer Debug ausgeblendet werden.
- [ ] Verifier prueft Projektion und Visualzustand ohne Gameplay-Mutation.

## Erwartetes Ergebnis
Der wichtigste sichtbare Rest der alten 2D-Missionsoptik ist aus dem normalen Spielbild herausgenommen, waehrend die Runtime weiterhin stabil auf dem bestehenden Simulationspfad laeuft.

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_149_verifier.gd`
- [ ] Manuell Live-Mission starten und Units, Auswahl, Air-Schatten und Path Preview pruefen.

## Dateien (voraussichtlich)
- `scripts/tests/mission_live_2_5d_visual_bridge.gd`
- `scripts/terrain/terrain_2_5d_visual_projection.gd`
- `scenes/tests/mission_reactivity_test.tscn`
- `scripts/tests/task_149_verifier.gd`

## Risiken
- Schlechte Unit-Lesbarkeit waere schlimmer als schoene Modelle. V1 priorisiert taktische Erkennbarkeit vor finalem Look.
