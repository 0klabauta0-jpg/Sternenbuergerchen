# Stationsanschlüsse und einfacher Mauerbau

## Ziel / Ursache
Native Nutzerprüfung am 13.11.2026: Die zum Lagerhaus ausgerichteten Wandachsen
passen jetzt. Sichtbare Fugen, falsche Eckverbinder und versetzte Türen stören
weiterhin. Die Rohrleitung wirkt zerbrochen, die grüne Linie ist nicht erklärt.
Der Mauerbau samt Tor soll einfach bedienbar sein.

## Umfang und Nicht-Ziele
- Freigegebenen Winkel und weißes Lagerhaus erhalten.
- Bündige Wandanschlüsse, passende Ecken und ausgerichtete Türen; vorhandene
  schmalere helle Wände mit gelbem Streifen als Kandidat prüfen.
- Boden unter Mauern und entlang der Baukante geteilte rot/helle Hexflächen.
- Vorhandenen Editor-/Baupfad nutzen; kein paralleler Gameplayzustand im UI.
- Aktualisierte Nutzerentscheidung: unnötige Rohrstrecken aus dem Stationscontent
  entfernen und ihre bisherigen Objektfakten konsistent zurücksetzen; grüne Linie
  identifizieren. Kein Aufwand für eine allgemeine Kenney-Rohr-/Hügelanpassung.
- Steinformen erhalten, Streuung weniger regelmäßig. Kleine reine Dekosteine
  ohne Deckung, LOS-Blockade oder Kollisions-/Navigationswirkung ergänzen.
- Vorhandene helle Flecken ausdrücklich vorerst behalten.
- Stilistische Neugestaltung übriger Objekte ist ausdrücklich ein späterer Auftrag.
- Nur praktisch benötigte Kenney-Teile auswählen. Katalog mit Quelle, Bild,
  tatsächlichem Einsatzort, Zweck, Anpassung und bekannten Mängeln im Websitebericht.

## Relevante Dokumente
`docs/dev/graphics_reference_revision_contract.md`,
`docs/dev/terrain_truth_visual_audit_contract.md`,
`docs/dev/mission_interaction_point_contract.md`,
`docs/tasks/REVIEW_COMPLETION_2026_11_13.md`.
Zielreferenz: `docs/qa/hex_surface_design_20261113/references/user_station_seams_corners_gate_feedback.png`
mit benachbartem SHA-/Entscheidungsmanifest.

## Akzeptanz
1. Gleiche Kamera: gerade freigegebene Achsen, bündige Ecken/Enden und zentrale
   Torblätter. Keine neue unsichtbare physische Wand oder freie scheinbare Lücke.
2. Teilböden sind eine Darstellung der autorisierten Bau-/Flächendaten. Freie,
   gesperrte und begehbare Türzellen behalten ihre tatsächliche Runtimewirkung.
3. Vorhandene Mauer-/Torwerkzeuge speichern und laden das Bauensemble korrekt;
   der tatsächliche geöffnete Türdurchgang bleibt per Rootbewegung passierbar.
4. Kleine Steinchen bleiben deterministisch, gebündelt und ohne neue Gameplayfakten;
   kein pro-Frame-Rebuild, keine Nutzung des Gameplay-Zufallsgenerators.
5. Hellflecken und ursprüngliche Binärassets bleiben erhalten. Vorher/nachher
   werden nativ geöffnet; technische Tests sind keine vollständige Stilabnahme.

## Betroffene Dateien / lokale Prüfung
Stationsvisualadapter, Terrainmodell-/Dekorationsprojektion, vorhandene Editor-
Commands und ihre Verifier. Konkrete Dateien werden beim jeweiligen Owner ergänzt.
Vorhandene Surface-/Cliff-/Stationbounds und Türtests plus gezielte Editor-
Roundtripregression. Keine Desktopübernahme; nur privater serieller Godot-Runner.

## Risiken / Stand
In Umsetzung. Der Mehrkarten-Netzwerkkoordinator wird separat fertiggestellt,
bevor derselbe Grafikowner die nächste Meshrevision beginnt. Eine sichtbare
Halbfläche darf keine halbe Gameplaybelegung vortäuschen; beides getrennt belegen.

## Einfacher Editorpfad: Mauer + Tor
Der bestehende Mauer-Ziehpfad bekommt ein benachbartes Werkzeug `M+T`:
ein Zug erstellt dieselbe zusammenhängende Segmentkette und ein mittiges Tor
auf zwei geraden inneren Zellen. Die Vorschau benennt die Torzellen vor dem Loslassen.
Kartenrand, fremde Objekte, Gebäudebelegung, unebener Boden sowie Marker-/
Interaktionskonflikte lehnen den gesamten Zug ab; keine halbe Mauer bleibt stehen.
Der Editor schreibt ausschließlich TerrainMapData und den bestehenden
MissionScenarioData-Interaktionsvertrag. Torrahmen und Torblatt erhalten ein
gemeinsames `door_cells`-Binding nach `mission_door_footprint.gd`.
Eine Undo-Aktion nimmt Zellen, neuen Marker und dieses Binding gemeinsam zurück;
Hex-Redo stellt sie gemeinsam wieder her. Andere Marker/Bindings bleiben erhalten.
Normales Mauerziehen und einzelne Türpinsel behalten ihr bisheriges Verhalten.
Kein neues Runtime-Türsystem, keine Änderung bestehender Stationskarten.

Dateien: `scripts/editor/map_editor.gd`, neuer reiner `wall_gate_authoring.gd`,
`scripts/tests/editor_wall_gate_verifier.gd`.
Prüfung: tatsächlicher Editorpfad mit Vorschau, Ablehnung ohne Mutation,
Undo/Redo, privates Map-/Scenario-Speichern und erneutes Laden; normalisiertes
zweizelliges Binding und echter Rootactor vor geschlossener/nach geöffneter Tür.
Risiko: Terrain- und Szenarioauthoring müssen zusammen zurückgenommen werden;
die Sichtprüfung der vorhandenen Modelle bleibt zusätzlich erforderlich.
Der reale Speicherpfad rundete bisher auch Hex-Marker auf ganze Weltkoordinaten.
Hex-Marker behalten deshalb jetzt ihre volle gespeicherte Präzision; sonst würde
ein korrekt zentriertes Torbinding nach Save/Load den unveränderten strengen
Footprint-Guard verletzen. Square8 behält sein bisheriges Rundungsverhalten.
Zusätzlicher Ownerhunk: TerrainMapData-Markerserializer, abgesichert durch den
bestehenden Hex-Foundation-Roundtrip und einen expliziten Square-Vergleich.

### Belegter Speicherblocker
Die echte 512×256-Kampagnenvorbereitung scheiterte im Lauf
`final_five_sorties/a39c8ec9fae24b119d43382054f4e80d` bei 1874/2161 Chunks am
unveränderten 256-MiB-Payloadlimit. Die Cachezählung dedupliziert Ressourcen korrekt.
Der neue Bruchsteinhelper hatte zwölf statt zwei Dreiecke je Höhenfläche erzeugt.
Er wird auf maximal vier breite Bruchfacetten reduziert; seltenes Fußgeröll bleibt
auf vier weitere Dreiecke begrenzt. Außenkanten, Height-/Rampendaten, Normalen,
Determinismus und sämtliche Gameplayfakten werden unverändert geprüft. Akzeptanz
erfordert die vollständige echte Kartenvorbereitung unter dem bestehenden Limit,
keine hochgesetzte Grenze oder umdefinierte Zählung.

Der zweite Vollversuch `12cb0e5f034c407085a1e59534ae729a` erreichte mit vier
Facetten 2076/2161 Chunks, überschritt aber weiterhin das unveränderte Limit.
Darum bleiben niedrige Stufen unter 1,25 Zellbreiten Höhe bei zwei Dreiecken;
die sichtbaren steilen Flächen behalten Bruchfacetten und seltenes Fußgeröll.
Es gibt keinen kameraabhängigen Rebuild und keine Änderung der Außenkontur.
Die vollständige Vorbereitung muss diesen engeren Kandidaten erneut belegen.

## Nutzerkorrektur: Rohrstrecken entfallen (13.11., nach nativer Prüfung)
Die zuvor gewünschte Rohranschlussreparatur ist ersetzt: In Station64/192
werden ausschließlich die authored `spacekit_pipe*`-Objekte entfernt, einschließlich
Warehouseanschluss und der zusätzlichen Übergangszellen. Die darunterliegenden
Terrainhöhen, Bodentypen und Rampen bleiben erhalten; Objektdeckung, Objekthöhe
und die von den Rohren gesetzte Begehbarkeit werden gemeinsam zurückgesetzt.
Es bleiben keine unsichtbaren Rohrblocker. Original-Warehouse, reservierte
Gebäudezellen, freigegebene Wandachsen, Türen und sonstige Props bleiben unverändert.

Akzeptanz: reproduzierbare/idempotente Inhaltsmigration mit konkreter Zellliste,
kein Pipeobjekt mehr in beiden Karten, alle betroffenen Zellen über tatsächliche
TerrainRegistry begehbar und ohne Pipe-Deckung/LOS/Objekthöhe. Die realen
Tür-/Stationsrouten und Map-Checkpoint-Fingerprints bleiben strikt geprüft.
Zusätzliche Dateien: `scripts/tests/remove_station_pipes_20261113.py`, beide
Stations-MapJSONs, `review_completion_station_layout_verifier.gd` und
`docs/qa/review_completion_20261113/station_pipe_removal.json`.

## Alle neun Station192-Ensembles
Der aktuelle Datenabgleich bestätigt 684 Wand-/Türobjekte in neun Anlagen;
die erste Revision erfasste davon nur die 76 zentralen Objekte. Die übrigen
acht Anlagen erhalten dieselbe begrenzte bijektive Zellenumordnung. Ursprung
und Ziel jedes verschobenen Records werden protokolliert; Marker/Patrouillen
folgen ihrem tatsächlichen Terrainrecord. Das zentrale Ensemble samt seiner
bestätigten Türroute, Gebäude-/Reservefakten und alle übrigen Zellen bleiben
unverändert. Keine neue Rohrstrecke und keine verlorenen Terrainfakten.

`station_module_layout.regions` dokumentiert alle neun geraden Quellregionen
einschließlich ihrer Außenwand-Mittellinien (`floor_boundary`). Die bisherigen
zentralen Felder bleiben kompatibel. Der Visualadapter liest diese Regionen
einmal; er verschiebt keine Gameplayzellen zur Laufzeit. Station64 hat dieselbe
einzelne explizite Region. Akzeptanz: alle 684 Module erfasst, echte Hexhüllen,
Gebäude und Marker erhalten, bestehende zentrale Route weiter bestanden sowie
native Sichtprüfung der äußeren Anlagen. Die frühere zentrale Prüfung allein
gilt ausdrücklich nicht als Abnahme der vollständigen großen Karte.

## Speicherblocker: gemessene Hauptursache statt Facettenvermutung
Der unveränderte echte 512×256-Start scheiterte nach den dokumentierten
Facettenreduktionen weiterhin bei 2111/2161 Chunks. Die isolierte Messung
`resource_payload_diagnostic/9a5850d25baa4fb080e6f20b10f841fd` klassifiziert jede
retinierte Ressource genau einmal nach Identität und stimmt exakt mit dem
unveränderten Cacheowner überein: 260723212 Byte Geometrie, davon 241986548 Byte
`TileGridLines3D` (92,8 Prozent) und nur 12348816 Byte `RegionalCliffFaces`.
Mit 7656148 Byte Deskriptoren waren 268379360 Byte des unveränderten
268435456-Byte-Limits belegt. Die Facettenversuche waren messbare Zwischenversuche,
aber nicht die dominante Ursache; allgemeine Meshindexierung wurde nicht eingebaut.

Der Consumer ersetzt das gecachte, vollständig sichtbare Hexgitter bereits beim
Restore durch seine eigene FoW-/Begehbarkeitsprojektion. Daher wird ausschließlich
diese ohnehin erneut erzeugte Geometrie im actorfreien statischen Prefill
weggelassen. Budget und Bytezählung bleiben gleich. Akzeptanz: tatsächlicher
Prefill-/Restorepfad mit identischen Livegridvertices und leerem unbekanntem FoW,
danach vollständiger 512×256-Start, Five-Sorties und die 17er-Startressourcenmatrix.
Enger Verifier: `review_completion_grid_cache_verifier.gd`; Umsetzung gespeichert,
Laufabnahme und Nachhermessung zu diesem Zeitpunkt noch offen.

## Unregelmäßige vorhandene Außenblocker
Die native Prüfung zeigt weiterhin regelmäßige Diagonalen der großen vorhandenen
Steine/Bäume. Kleine Dekokiesel ersetzen diese Korrektur nicht. Ausschließlich
`nature_rock_cover` und `nature_tree_blocker` außerhalb geschützter Anlagen werden
deterministisch in kleine unregelmäßige Gruppen versetzt, maximal sechs Hexfelder.
Vollständige Terrainrecords tauschen nur mit freiem, exakt gleichem Untergrund
und gleicher Höhe; Anzahl, Rotation, Deckung, LOS, Objekthöhe und echte Sperrwirkung
ziehen mit. Keine reine Visualverschiebung und kein Gameplayzufall.

Quell- und Zielzellen dürfen keine Rampen, Floors, Gebäude-/Reserveflächen,
Marker-/Patrouillen- oder Eintrittskorridore berühren. Gepufferte Schutzflächen
und sämtliche entfernten Rohrzellen (einschließlich ihrer Umordnung durch
`station_outer_layout_migration.json`) bleiben unverändert. Wand-/Door-/Computer-
Ensembles und alle `regions`-Metadaten bleiben erhalten.

Akzeptanz: reproduzierbarer Offlinehelper mit Vor-/Nachher-SHA und pro Bewegung
konkreten Zellen, unverändertes Terrain-Payloadmultiset, identischer Untergrund an
jeder Zelle, keine Änderung geschützter Zellen/Metadaten, idempotenter Wiederaufruf.
Ein kleiner Godot-Verifier prüft die tatsächlich geladenen TerrainRegistry-
Blocker an Quellen/Zielen. Native gleiche Kamera und bestehende Stations-/Tür-
Navigation bleiben eigene anschließende Gates, keine vorweggenommene Stilabnahme.
Dateien: beide Stations-MapJSONs, neuer `migrate_station_nature_clusters_20261113.py`,
`station_nature_clusters.json` und `station_nature_clusters_verifier.gd`.

### Gemessener Gridcache-Nachweis
Der unveränderte alte Produktpfad ergibt im neuen engen Test 11/1
(`grid_cache_red/e3bf4bd7e39a4c6588e98e81cfe916e2`); ausschließlich das
unnötig retained Grid ist rot. Der korrigierte tatsächliche Prefill-/Restorepfad
besteht 12/0 (`final_grid_cache/daf3c81345644a39896808159c3ba8f5`).
Vertexgleichheit, unbekanntes FoW, echte Rampen-/Plateaukonturen und
autoritative Türöffnung bleiben gleich; Cachebytes wachsen beim Liveupdate nicht.

Die Nachhermessung `resource_payload_diagnostic_after/6921251c0a1044e6986bfc6a8511aad4`
bereitet jetzt alle 2161/2161 Chunks der echten 512×256-Satellitenkarte vor:
24838972 Byte Gesamtpayload, davon 19106040 Geometrie und 5732932 Deskriptoren,
bei unverändertem Limit von 268435456 Byte. Es bleibt keine Gridmesh-Ressource
im statischen Cache. Diagnose 4/0, alle Quellen-/Profil-/Canaryguards grün.
Dies ist der begrenzte Cache-/Startvorbereitungsnachweis, keine allgemeine
RAM-/VRAM-/FPS-Messung; Five-Sorties und die 17er-Matrix laufen anschließend.

Die anschließende echte 17er-Startressourcenmatrix besteht 50/0
(`final_map_preparation/cecc2cb3269d470ea240045a951c1f45`, Kandidat3583).
A/B/C erreichen jeweils 2161/2161 Chunks: 24838972 / 32976980 / 29216552 Byte;
initiale Datenlade-/Prefillzeiten dieses Headlesslaufs 12,906 / 13,574 / 12,727s.
Jeder neue Consumer übernimmt die Ressourcengeometrie ohne Terrainneubau; die
übrigen14 Starts nutzen ihren tatsächlichen direkten Renderpfad. Alle Guards
grün. Der erste folgende Five-Lauf gelangt bis zum zweiten echten Ausflug
und besteht Kampf/Kistenbergung, endet aber bei der Händlerannäherung93/1;
die komplette Kampagnenabnahme bleibt deshalb offen, unabhängig vom behobenen
Speicherblocker. Diagnose erfolgt mit tatsächlichen Actor-/Root-/Maskendaten.

### Neuanlage-/Redo-Nachprüfung
Normale neue Hexkarten verwenden den bestehenden expliziten Hex-Höhenvertrag. Der Mauer-/Tor-Verifier erzeugt die Karte über den echten Editor-Neuanlagepfad; Undo/Redo, gespeicherte Marker und die reale Zwei-Zellen-Tür bleiben unverändert streng geprüft. Alte Square- oder implizite Hexkarten werden dabei nicht still migriert.

### Nativer Station192-Blocker: konstante Gebäudeparameter
Die echte äußere Stationsaufnahme `station_ensembles_after/c933f72485e241d1aa37f20ec1d3b228`
scheitert an der Compatibility-Grenze für Instanzuniforms. Die 18 gespeicherten
Gebäude besitzen je viele Meshteile; ihre unveränderlichen lokalen Verschleißbounds
belegen dennoch je einen Instanzuniformblock. Der neue Bodenmaskenshader besitzt
keine Instanzuniforms. Der Fehler beim Freigeben einer temporären Propquelle ist
ein Rendererflush, kein Beleg für einen Fehler dieser Propgeometrie.

Die beiden bestehenden abgeleiteten Exterior-TSCNs und ihr Livebuilder erhalten
deshalb normale, je Materialprofil und Bounds geteilte Materialparameter.
Shaderformel, Werte, Meshbytes, Transforms, Quellenmodelle und Gebäudeplatzierung
bleiben identisch. Keine erhöhte Renderergrenze und kein ausgeblendetes Gebäude.
Akzeptanz: reversible Textmigration mit Quellenhash/Geometrieidentität, echte
18-Prop-Instanziierung ohne Instanzuniforms, Bounds-/Materialteilungstest, danach
native Aufnahme der vier vorgesehenen Station192-Ensembles. Verbleibende feine
Höhenstreifen werden separat mit gleicher Kamera und ausschließlich deaktivierten
Floorcastern diagnostiziert; keine pauschale Schattenabschaltung.

### Winzige Kiesel auf freien Flächen
Die Nutzerkorrektur verlangt wenige Miniatursteine auch auf freien glatten
ariden Bodenflächen. Bisherige Kiesel ausschließlich am Fuß großer Blocker
erfüllen das nur teilweise. Dieselbe statische Chunk-/MultiMesh-Route wird um
sparsame koordinatendeterministische 1–2-Kieselgruppen auf freiem Ground/Sand/Rock
ergänzt. Floors, Straßen/Pads, Rampen, Höhengrenzen, Markerumfeld, belegte und
externe Gebäudezellen bleiben ausgeschlossen. Keine Collider, Cover-/LOS-Fakten,
Gameplayzufallswürfe oder pro-Frame-Streuung. Tatsächliche freie Stationszellen,
Negativfälle, unveränderte Kartenbytes und stabile Batch-/Meshidentitäten müssen
geprüft werden; die native Gesamtsicht entscheidet über Lesbarkeit.

### Belegter Reststreifen: dünne Floorcaster
Alle fünf Ensemblebilder `b0ebc1cdd4df49ae8a9e7658594fc1c6` und vier Schatten-
kontrollen `37d54f606c8a46faa61ed33e15ec4bda` wurden geöffnet (13/0). Die Floor-only-OFF-Kontrolle
beseitigt die feinen Linien auf heller Auflage und rot maskiertem Flooraußenrand;
Hexkontur, Wände und tatsächliches Klippen-/Rampenrelief bleiben sichtbar.
Nur die bereits auf 0,028 m abgeleiteten Hexfloor-Meshes werfen deshalb keinen
Selbstschatten mehr. Sie empfangen weiterhin Licht und fremde Schatten. Originale
Square-/massive Modelle, erhöhte eigenständige Pads, Sidehulls und Klippen-/
Rampencaster bleiben unverändert. Einzel-, Objekt- und MultiMeshroute brauchen
je einen positiven Test; gleicher nativer Stationsvergleich ist die Schlussprüfung.
