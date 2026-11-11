# Explizite Hex-Rampen und Plateaus V1

Status: vom Nutzer am11.11.2026 bestaetigt, Umsetzung auf isoliertem
 task/native-glut-maps-20261110. Ersetzt die automatische H1-Verbindung
nur fuer Karten mit terrain_height_rules="explicit_hex_ramps_v1".
Alte Karten ohne diese Versionskennung behalten ihre bisherigen Regeln.

## Autoritative Daten
MapData besitzt die Regelkennung. Jedes Tile erhaelt beim Laden das abgeleitete
Boolfeld explicit_hex_ramps. Gespeichertes Feld ramp_direction=-1 bedeutet
Plateau;0..5 bezeichnet die AUFWAERTSrichtung gemaess HexGrid.DIRECTIONS.
height_level ist bei einer Rampe die UNTERE Ebene H; oberes Ende ist H+1.
Eine Rampe belegt genau eine volle Hexzelle. Sie ist KEINE Einbahnstrasse.
Gegenrichtung (direction+3)%6 erreicht das untere Ende, direction das obere.
Seitliche Rampenkanten besitzen die Mittel-Endpunkthoehe H+0.5. Dadurch
sind seitliche Uebergaenge nur zwischen passenden Rampen erlaubt; normale
Plateaus H/H+1 passen dort nicht. Zusammenhaengende Rampenbaender und
60-Grad-Ecken teilen Eck-/Kantenpunkte und werden ohne offene Fugen gebaut. H8 ist das hoechste Plateau, eine
Rampe vonH8 nachH9 ist ungueltig. Blocker/Unwalkable bleiben wirksam.

## Gemeinsamer Uebergang
An einer geteilten Kante muessen beide Endpunkthoehen uebereinstimmen.
Plateau besitzt an jeder Kante seine height_level. Rampen besitzen an der Laengsachse H/H+1 und seitlich H+0.5. Normaler H0/H1-Kontakt ist gesperrt,
auch wenn die Differenz nur1 ist. A*, HPA und tatsaechliche Bewegung muessen
denselben TerrainTileData-Vertrag lesen. Keine Freigabe aus UI/Visualmesh.
Runtime-Aufrufer verwenden `allows_registry_step` mit der beidseitig geprüften
Registrybegehbarkeit, damit Türübersteuerungen maßgeblich bleiben. Dieser
Einstieg teilt denselben Endpunkthöhenkern; Authoring-`allows_step` und
`endpoint_height` behalten ihre Raw-Walkabilitydefaults. Eine geöffnete Tür
gibt weder Rampenflanken noch falsche Endpunkthöhen oder H8→H9 frei.

## Standhoehe und Projektion
Logische Stand-/Sichthoehe im Rampenzentrum ist H+0.5. Renderinterpolation
zwischen den Enden folgt der linearen Ebene. Darstellung/Picking/Raster/FoW
lesen dasselbe gerichtete Profil; sie bestimmen keine Gameplaywahrheit.
Plateaus bleiben flach. Rampenkappen und Seiten sind geschlossen.
Details/Material duerfen Grenzen verdecken, aber keine Klippen als begehbar
vortaeuschen. Kein automatisches Klettern und keine neue Kletterfaehigkeit.

## Revision / Save / Cache
MapSave bewahrt ramp_direction und terrain_height_rules. Revisionen und
Terrain-/Geometriecache-Kontexte muessen beide Regeln erfassen. Interaktive
Aenderungen gehen weiterhin durch vorhandene Registry-/Map-Owner.
Kampagnenanker, IDs, Pad-/Ressourcen-/Objektfootprints bleiben erhalten.
A/B/C512x256, Sternkarte256x256. Keine zweite Sicht-/Belegungswahrheit.

## Abstimmung
Chat Tabletop-Faktoren fuer Performance pruefen hat bestaetigt, dass dort
kein Produktcode veraendert wurde. Er verlangt die gemeinsame Uebergangs-
quelle fuer A*/HPA/Bewegung, explizite Endpunkthoehen und Revisionierung.
Logische Rampenzentrumshoehe H+0.5 wird hiermit fuer Verbraucher festgelegt.
EinNPCproHex und zeitliche Feldreservierung sind dortige separate Arbeit;
der bestehende BottleneckResolver ist keine Voraussetzung dieser Umsetzung.

## Pruefung
Nur enge Kompilier-/Contractkontrolle und native Formkontrolle jetzt.
Grosse Gefechts-, A/B/C-Matrix-, Save-/Multiplayer-/Performanceabnahme spaeter
auf ausdruecklichen Nutzerwunsch. Ungemessene Spielbarkeit nicht behaupten.

Nutzerergaenzung: Der Editor zieht die gleichen Regeln mit: Richtung/Plateau,
Breitenpinsel, Ecken, Vorschau, Undo/Redo und Save; keine stillschweigende
Konvertierung alter nicht versionierter Karten.


Editorvorschau: Auf versionierten Hexkarten zeigt der Hoehenpinsel die geplanten
3D-Kappen fuer alle betroffenen Hexzellen inklusive unterer Hoehe und Richtung.
Raise/Lower/Exact und Richtungserhalt lesen dieselbe Patchplanung wie die Mutation;
die Vorschau verwendet nur fluechtige Kopien und das gemeinsame Regionalprofil.
Sie aendert keine Map-/Registry-/History-Wahrheit, besitzt keine Pickkollisionen
und verschwindet bei UI-, Werkzeug- oder Kartenwechsel. Kein Vollkartenrebuild
pro Frame; Neuaufbau nur bei Hover-/Parameter-/Dirtywechsel.
