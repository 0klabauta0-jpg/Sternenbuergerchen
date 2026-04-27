# TASK_138 - 2.5D Multi-Floor Foundation

## Ziel
Eine kleine Grundlage fuer mehrere begehbare Ebenen auf demselben Grid-Bereich schaffen, ohne bereits vollstaendige Innenraeume oder Full-3D-Gameplay einzufuehren.

## Status: GEPLANT

## Kontext
- Einfache Hoehen pro Tile reichen fuer Daechern, Plattformen und Graben oft aus.
- Mehrere Etagen brauchen aber einen separaten `floor_index`, damit zwei Positionen mit gleicher Grid-Koordinate logisch unterscheidbar bleiben.

## Umfang
1. Datenmodell fuer `MapFloorSlot` oder aequivalente Floor-Eintraege pro Grid vorbereiten.
2. Unit-/Command-Positionsvertrag um optionalen `floor_index` erweitern.
3. Registry-Lookups fuer `grid + floor_index` bereitstellen.
4. Uebergaenge zwischen Floors nur ueber explizite Links erlauben.
5. Minimaler Testaufbau mit Boden + Dach/Plattform auf gleicher X/Y-Zone.

## Nicht-Ziele
- Keine kompletten Gebaeudeinnenraeume.
- Keine Pathfinding-Optimierung fuer grosse Multi-Floor-Maps.
- Keine UI fuer Etagenfilter.
- Keine echte vertikale Formationslogik.

## Akzeptanzkriterien
- [ ] Eine Position kann `grid_position` und `floor_index` tragen.
- [ ] Zwei Floor-Slots am gleichen Grid werden logisch getrennt behandelt.
- [ ] Movement wechselt Floors nur ueber erlaubte Links.
- [ ] LOS kann Floor-Hoehen aus TASK_136 lesen.
- [ ] Verifier prueft Boden/Dach-Trennung und erlaubten Floor-Wechsel.

## Risiken
- Multi-Floor kann schnell Auswahl, Kamera und Editor verkomplizieren; dieser Task bleibt bewusst nur Daten- und Runtime-Grundlage.
- Bestehende Systeme muessen `floor_index = 0` als Default behalten.
