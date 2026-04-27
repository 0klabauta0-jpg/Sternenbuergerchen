# TASK_141 - 2.5D Air Layer V1

## Ziel
Flieger als Sonder-Layer ueber dem 2.5D-Boden einfuehren, ohne das Bodengefecht auf Full-3D umzustellen.

## Status: GEPLANT

## Kontext
- 2.5D reicht fuer taktischen Bodenkampf mit Hoehen, Deckung und LOS.
- Flieger brauchen andere Regeln: eigene Flughoehe, weniger Bodenblocker, eigene Zielbarkeit und klare UI-/Debug-Signale.

## Umfang
1. Datenvertrag fuer `movement_layer = ground|air` und `altitude_band`.
2. Air-Units ignorieren normale Boden-Walkability, aber nicht Missionsgrenzen.
3. LOS/Targeting unterscheidet Boden-LOS, Air-LOS und AA-/Anti-Air-Regeln.
4. Navigation fuer Air V1 als einfache direkte Routen oder grobe Waypoints.
5. Darstellung mit Hoehenoffset, Schatten/Marker und Debugtext.

## Nicht-Ziele
- Keine Dogfight-Simulation.
- Keine echte 3D-Flugphysik.
- Keine komplexen Fahrzeuge.
- Kein Multiplayer-Air-Replication-Scope.

## Akzeptanzkriterien
- [ ] Air-Units bewegen sich ueber Bodenblocker hinweg.
- [ ] Air-Units bleiben innerhalb der Missionskarte.
- [ ] Boden- und Air-Targeting sind regelbasiert getrennt.
- [ ] Darstellung macht Hoehe/Layer lesbar.
- [ ] Verifier prueft Air-Movement ueber Blocker und Anti-Air-Gate.

## Risiken
- Flieger koennen Bodentaktik trivialisieren; V1 muss klare Gegenregeln wie AA, Sichtbarkeit und Missionsrollen behalten.
- Dieser Task sollte erst nach Boden-2.5D gestartet werden, damit Layer-Regeln nicht auf wackeliger Basis landen.
