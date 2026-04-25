# Area Orders - Recherche und naechste Baustellen

## Kurzfazit
Gebietsmarker sind der richtige naechste Schritt fuer das Spielgefuehl. Fireteams sollen nicht nur zu Punkten laufen, sondern Zonen sichern, beobachten, annaehern, binden und bei Kontakt anders reagieren. Die aktuelle V1 baut dafuer den Daten- und Testpfad.

## Quellenbasis
- UNITAF Force Manual, Bounding Overwatch: https://unitedtaskforce.net/handbook/group/103/bounding-overwatch
- FM 3-21.8, Tactical Movement, Bounding/Traveling Overwatch: https://www.marines.mil/Portals/1/Publications/FM%203-21.8%20%20The%20Infantry%20Rifle%20Platoon%20and%20Squad_3.pdf
- FM 3-21.8, Defensive Operations, Sectors of Fire/Positions: https://www.marines.mil/Portals/1/Publications/FM%203-21.8%20%20The%20Infantry%20Rifle%20Platoon%20and%20Squad_5.pdf

## Beobachtungen fuer Spielsysteme
- Bewegung unter erwarteter Gefahr braucht wechselnde Rollen: ein Element bewegt, ein anderes deckt oder wartet.
- Defensive Gebiete brauchen Sektoren statt nur Haltepunkte: Units verteilen sich, decken Richtungen und behalten Luecken im Blick.
- Angriff auf ein Gebiet sollte ueber Annaherung, Kontaktaufnahme und Druck funktionieren, nicht ueber einen direkten Mittelpunkt-Move.
- Karten-/Terrainqualitaet ist Gameplay: Blocker, Cover, Wege und Sichtlinien muessen beim Setzen und Ausfuehren von Befehlen lesbar werden.

## Sinnvolle Folge-Tasks
1. **Area Sector Arcs**
   - Verteidigungsgebieten 1-3 Sicherungssektoren geben.
   - In `#17` anzeigen: `VERTEIDIGEN | Sektor NW | 3 Felder | wartet auf Kontakt`.
   - Optional spaeter: Sektor per Drag drehen.

2. **Bounding / Raupenbewegung als expliziter Modus**
   - Move-/Attack-Areas koennen `normal`, `vorsichtig`, `raupenartig`, `sturm` ausfuehren.
   - Mindestens ein Mitglied/Element bleibt kurz in Overwatch, waehrend ein anderes bewegt.
   - GO fuehrt den naechsten Bound weiter, statt den ganzen Plan neu zu starten.

3. **Attack Area Phasen ohne globales Phasensystem**
   - Pro Area lokaler Status: `Annaeherung`, `Kontakt suchen`, `Unterdruecken`, `Eindringen`, `Sichern`.
   - Zielprioritaet bevorzugt Gegner im markierten Gebiet und Gegner, die den Approach blockieren.

4. **Area Objective State**
   - Gebiete koennen `unbekannt`, `umkaempft`, `gesichert`, `verloren`, `geraemt` sein.
   - Mission-UI zeigt nicht nur Wegpunkte, sondern aktuelle Kontrolle und Kontaktlage.

5. **Walkability-/Path-Debug Overlay**
   - Bei Zielsetzung anzeigen: Originaltile, Ersatz-Ziel, nicht-walkable Grund und geplanter A*-Pfad.
   - Editor- und Mission-Ansicht sollten denselben TerrainRegistry-Bericht nutzen.

6. **Map Validator fuer 64x64- und spaetere Karten**
   - Prueft Spawn-to-Objective-Erreichbarkeit, Blockercluster, Wasser-/Cover-Kanten und Patrol-Routen.
   - Gibt Warnungen aus, bevor eine Karte im Testlauf Zeit frisst.

7. **Editor-Palette fuer Isometric Assets**
   - Katalogisierte City-/Landscape-Assets nach Gruppen anzeigen.
   - Tile-Typen mit Walkability, Cover, LOS und Surface-Kosten sichtbar machen.
   - Vorerst nur kuratierte Asset-Auswahl, nicht blind alle Varianten in Gameplay werfen.
