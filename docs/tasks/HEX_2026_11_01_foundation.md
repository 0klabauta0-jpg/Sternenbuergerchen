# HEX_2026_11_01 - Verbindlicher Wechsel auf Hexfelder

## Nutzerentscheidung
Am 01.11.2026 entscheidet der Nutzer ausdruecklich: "ich moechte auf hex tiles
umsteigen". Das ersetzt die vorherige Ueberlegung, den neuen Grafikdurchgang
zunaechst auf dem Quadratgraphen zu belassen. Der Umbau gehoert zu
SternenBuergerchen; InselKrieg bleibt eine gelesene Grafikreferenz.

## Ziel dieses integrierbaren Schritts
Ein echter sechsfach verbundener Hex-Untergrund fuer den neuen nativen Basis-
Ausschnitt: Koordinaten, Roundtrip/Picking, Wegfindung, Bewegung, Hoehen,
sichtbare Feldform und Auswahl muessen denselben Vertrag verwenden.
Die neue Grafikfamilie richtet sich weiterhin nach den freigegebenen 2D-Basis-
und Citizen-Bildern. Bestehende Karten bleiben explizit lesbare Legacy-Inhalte.

## Koordinaten und Kompatibilitaet
- Versionierter Topologiebezeichner `hex_axial_v1`, Koordinaten `(q,r)`.
- Pointy-Top: Abstand benachbarter Mittelpunkte 1 Grafikzelle;
  `x=q+0.5*r`, `z=sqrt(3)/2*r`, Hexradius `1/sqrt(3)`.
- Nachbarn `(1,0),(1,-1),(0,-1),(-1,0),(-1,1),(0,1)`.
- Cube-Rundung fuer Auswahl; Hexdistanz und Hexlinien fuer Graph/Abfragen.
- Bestehende Karten ohne Feld `grid_topology` bleiben `square8` mit bisherigen
  Positionen und Pfaden. Keine stille Neuinterpretation gespeicherter Karten.
- Bestehende API-Defaults duerfen fuer alte Aufrufer kompatibel bleiben; neue
  Basis-/Hex-Inhalte waehlen `hex_axial_v1` ausdruecklich.

## Besitz und Umfang
- MapData speichert die Topologie als Kartentatsache, Registry und Pathfinder
  konsumieren denselben Wert. Grafik liest ihn, erzeugt ihn nicht selbst.
- A*/HPA benutzen im Hexmodus sechs Nachbarn und passende Heuristik.
- SimulationRoot bleibt Autoritaet fuer Bewegung. Im Hexmodus muessen gleich
  lange sichtbare Strecken gleich lang im Bewegungsmass sein; die alte
  isometrische Projektionsverzerrung darf nicht uebernommen werden.
- Neue native Hexfelder, Auswahlringe und Picking folgen derselben Geometrie.
- Neue Basisgebaeude stehen ausserhalb der lauffaehigen Hexfelder oder sperren
  ihre belegten Hexfelder im Preview-Datensatz. Keine versteckten Visualblocker.
- Alte Quadrat-/Editor-/Missionpfade werden nicht als bereits migriert behauptet.
  Weitere Migration von Altinhalten, Wand-/Deckungsvarianten, LOS/FOW, Editor-
  Werkzeugen, Save/Multiplayer wird mit konkreten Folgebefunden fortgefuehrt.

## Akzeptanz und lokale Pruefung
- Positive/negative Hexkoordinaten und Grenzrundung, sechs gleich entfernte
  Nachbarn, symmetrische Distanzen und Linien.
- A*/HPA-Wege um Hindernisse sowie Hoehen-/Rampenregeln; Legacy-Regressionen.
- Gleich lange Hexbewegungen in allen sechs Richtungen durch SimulationRoot.
- Hex-Picking/Markierung und native Gesamt-/Nahansicht; menschlicher Massstab.
- Load/Save speichert die Topologie; alte Daten bleiben positions-/pfadgleich.
- Struktur-/Verhaltenspruefungen und echte native Bildpruefung getrennt.
- HTML-Workbench nennt den tatsaechlich erreichten Migrationsstand.

## Befund aus dem Altpfad
Der synthetische Richtungsprobe misst auf gleich langen sichtbaren Diagonalen
unterschiedliche Laufzeiten. Der Befund bleibt als Baseline; die Hexbewegung
benutzt ein passendes physisches Streckenmass. Das ist kein Anlass, nebenbei
alle bestehenden Quadratmissionen oder Gameplay-Geschwindigkeiten umzuschreiben.
