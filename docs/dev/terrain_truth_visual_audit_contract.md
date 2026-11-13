# Terrain Truth Visual Audit Contract

## Zweck
Dieser Contract beschreibt die Terrain-Wahrheit, Dev-UI-Diagnose und Mauer-/Kanten-LOS. TASK_454 hat die Regel auditierbar vorbereitet; TASK_456 schaltet sie im zentralen `LineOfSightSystem` als Runtime-LOS-Regel fuer Wandsegmente aktiv.

## Autoritaet
- Gameplay-Wahrheit bleibt bei `TerrainRegistry`, `TerrainTileData`, `LineOfSightSystem`, Pathfinder und Combat Resolver.
- `TerrainMap3DView`, MapEditor-Overlays und HTML-Reports sind Leseschichten.
- Terrain3D darf spaeter als Visual-/Authoring-Prototyp gegen eine Kopie der Drillmap getestet werden, aber nicht als zweite Pathing-/LOS-/Cover-Wahrheit.

Die Feuersektor-Vorschau verwendet die gemeinsame Blockersuche des
`LineOfSightSystem` mit wirksamen Registry-Overrides (einschliesslich Tueren).
Ihr abgeleiteter Cache ist an Registryidentitaet und Revision gebunden;
stationaere Linien werden bei Revision dirty. Ohne Runtime-Registry liest der
Editor die mutable Map ohne langlebigen Cache. Runtime-Reichweite, Welthoehen
und ausgeschlossene eigene Quell-/Zielzelle bleiben unveraendert; eine
Vorschaulinie darf auch an ihrer unbesetzten Endzelle abgeschnitten werden.

## Dauerhafte Dev-UI-Felder
Terrain-Debugansichten sollen diese Werte aus der Tile-Wahrheit anzeigen koennen:

- `tile_id`
- `type_id`
- `object_type_id`
- `surface_type`
- `height_level`
- `object_height`
- `walkable`
- `blocks_los`
- `cover_value`
- `object_rotation_degrees`
- `object_scale`
- `blocker_type`
- `wall_segment_count`

Die Werte duerfen gelesen, exportiert und in Snapshots angezeigt werden. Sie duerfen im Visual-Overlay keinen Gameplay-State mutieren.

## Boden- und Objektlayer
- Ein Objektlayer-Prop wie Busch/Fels/Technik sitzt auf einem Ground-/Surface-Tile.
- Ein Objektlayer darf Ground nicht unsichtbar zu einer zweiten Terrain-Wahrheit ersetzen.
- Fuer Authoring-Audits ist `type_id = ground_flat` plus nicht-leeres `object_type_id` der gewuenschte Normalfall fuer Props auf Boden.

## Mauer-/Kanten-LOS Zielregel
Vollblocker wie massive Felsen oder hohe Objekte duerfen weiterhin ganze Tiles blocken. Mauern und Zaunsegmente brauchen eine feinere Regel:

- Gerichtete Wandtypen werden als Kanten-/Segment-Blocker interpretiert.
- Sicht entlang einer Wand oder auf derselben Mauerseite bleibt frei.
- Sicht blockt, wenn der Sichtstrahl das Wandsegment wirklich kreuzt.
- Ein reiner Eckpunkt-Touch blockt nicht automatisch.
- Geschlossene Doppel-Ecken oder mehrere Segmente duerfen spaeter blocken, wenn der zusammengesetzte Segment-Schnitt eindeutig ist.

TASK_456 verwendet diese Regel im aktiven `LineOfSightSystem`-Pfad. Nicht-Wand-Blocker bleiben Whole-Tile-Blocker.

## Naechste Slices
1. TASK_455: Terrain-Truth-Visual-Audit im MapEditor-DBG-Overlay sichtbar machen.
2. TASK_456: Wandsegment-LOS in den zentralen Runtime-LOS-Pfad ueberfuehren und selektiven Tile-Truth-Inspector anzeigen.
3. Terrain3D-Visual-Prototyp auf Drillmap-Kopie bauen.
4. Danach erst Sequence-Workbench fuer Fireteam-Raupe/Bounding/Regroup schneiden.

## Sichtbare Overlay-Konvention
Das MapEditor-DBG-Overlay darf kompakte Diagnosekuerzel anzeigen:

- `W1`, `W2`: Wandsegment-Kandidat mit Segmentanzahl.
- `WT`: Wandtyp ohne segmentierbare Kante, aktuell Whole-Tile-Kandidat.
- `OBJ H1`: Objektlayer oder Objekt-Hoehe auf einem Ground-Tile.
- `LOS`: bestehender Whole-Tile-LOS-Blocker.
- `C60`, `H2`: Cover- und Hoehenwert aus der Tile-Wahrheit.

Wandsegmente werden als gelbe Kantenlinie ueber dem Tile gezeichnet. Diese Linie ist Diagnose und ersetzt nicht automatisch den aktiven `LineOfSightSystem`-Pfad.

## Selektiver Tile-Truth-Inspector
Der MapEditor darf fuer das aktuell ausgewaehlte Tile einen read-only Inspector anzeigen. Er soll die kompakten Overlaywerte in Klartext aufloesen:

- Grid, Tile-ID, `type_id`, `object_type_id`
- Boden-/Objektlayer-State
- Walkable, LOS, Cover, Hoehe, Objekt-Hoehe
- Objekt-Rotation und Objekt-Scale
- Blocker-Art und Wandsegmentanzahl
- aktuelle Runtime-LOS-Policy

Dieser Inspector liest dieselben Helper wie Overlay und LOS-Tests. Er darf keine Gameplay-Wahrheit schreiben.

## Regionale Hexoberfläche und Schatten

Dünne regionale Deckkappen empfangen Licht und Objekt-/Reliefschatten, werfen
aber in der produktiven Compatibility-Ansicht keine wiederholten Selbstschatten.
Die separaten RegionalCliffFaces-/RegionalRamps-Meshes und voll ausgeführten
erhöhten Hexsäulen behalten ihre Schatten. Gleichdicke Kappe und Vollsäule
dürfen keinen Batch teilen, der die Schattenklasse vom ersten Eintrag erbt.
Diese Visualregel verändert weder Kartenhöhe, LOS, Rampen noch Navigation.
Nachweis: review_completion_graphics_fixes.gd sowie geöffnete native
regional_actual/caps_no_shadow/all_terrain_no_shadow-Vergleiche.

## Sichtbare Hexflächen und importierte Bodenmodule

Das dauerhafte Raster folgt der tatsächlich dargestellten begehbaren Oberfläche:
Jede Rampenkante verwendet das gemeinsame Höhenprofil einschließlich ihrer
Kantenmitte; eine flache Kontur auf mittlerer Rampenhöhe genügt nicht. Importierte
Bodenmodule liefern ihre einmalig abgeleitete visuelle Stützhöhe. Kontur,
Auswahl und Figurenfuß verwenden dieselbe Projektion. Registry-Walkability und
die vorhandene Sichtbarkeitsprojektion bleiben die Filter; blockierte Möbel-
oder unbekannte Flächen erhalten keine suggerierte begehbare Kontur.

Zellgebundene Kenney-Floors erhalten eine gecachte, in sechs Hexrichtungen
aufgeteilte Laufzeit-Meshprojektion innerhalb ihrer eigenen Zelle. Ursprüngliche
Binärmeshes und UV-/Texturquellen bleiben erhalten. Nach ausdrücklicher
Nutzerkorrektur sind diese Boden-/Balcony-/Deckauflagen flach und zusammenhängend,
HELL mit gedeckten Strukturakzenten und dünnen Fugen statt dicken weißen Hexknöpfen.
Der dunkle KI-Entwurf ist nicht akzeptiert; das vorhandene weiße Lagerhaus samt
Perspektive bleibt die positive Referenz. Nur ihre
abgeleitete Modellhöhe und Materialkopie werden angepasst; logische Terrainhöhen
und Rampen bleiben erhalten. Figuren-/Konturstützhöhe liest diese neue dünne
Modellauflage. Verbundene
Wände, Türen und Korridore richten ihre orthogonalen Modellachsen entlang der
tatsächlichen Hexreihe aus, statt allein für die Hexkoordinaten geschert zu werden;
eigenständige Gebäude, Figuren, Möbel und Schiffe werden nicht global verzerrt.

Konturen werden je Renderchunk wiederverwendet. Registry-/Sichtänderungen
markieren betroffene Chunks und ihre Nachbarn; eine Lücke in konsumierbaren
Registry-Revisionen erfordert vollständigen Faktenabgleich. Unveränderte
Faktensignaturen erzeugen keinen neuen Mesh. Diagnosezähler liegen nur im
View-Readmodel, nicht in persistierten Scene-Metadaten.

Authored Wüstenstationen zeigen statt der bisherigen Bäume vorhandenes
Wüstengestein. Diese begrenzte Visualzuordnung verändert weder logische
Tiletypen noch Walkability, LOS oder Deckungswerte anderer Karten.

Die als Bodenbemalung verwendeten B/C-Pads werfen keine Selbstschatten ihrer
auf wenige Millimeter skalierten Auflagen. Die echte native Vierfachdiagnose
`pad_diagnostic/cf4ebee884eb4b5fab87ed3637f00c9d` trennt Caster und Inset:
Nur das Abschalten der Pad-Caster entfernt die Dreiecks-/Diagonalbänder.
Inset, Farben, Geometrie, Schattenempfang und externe Caster bleiben erhalten.

Die weitere Nutzerkorrektur priorisiert ruhige helle Metallauflagen und sichtbar
übergeordnete Hexkonturen gegenüber Bodenflecken und kontrastreichen Innenringen.
Aride Stationssteine teilen eine gedeckte Rost-/Ockerpalette. Statische Variation
darf die Silhouette innerhalb derselben Zelle variieren; keine verdeckten oder
verschobenen Gameplayblocker. Echte planare Kenneybodenquellen liegen auf derselben
abgeleiteten Oberkante wie dünne Volumenquellen, ohne künstliche Extrusion.

Die freigegebene Bruchsteinrichtung (`cliff_detail_proposal.png`, rechte Hälfte)
gestaltet nur statische sichtbare Klippenflächen: wenige facettierte Brüche und
Geröllstücke am bisherigen Fuß, unveränderte obere/untere Randkanten und Rampen.
Keine zusätzliche begehbare Oberfläche, Collision, LOS- oder RNG-Wahrheit. Meshes
bleiben im vorhandenen Chunk-/Resourcecache und teilen ihre Materialien.

Erhöhte vollständige Hexsäulen trennen bei deaktivierten Boden-Selbstschatten
die sichtbare Deckfläche von ihrem Schattenwerfer: Die vollständige sichtbare
Säule empfängt Schatten; eine geteilte, ausschließlich Schatten werfende
Seitenhülle ohne obere/untere Kappe erhält den Höhenwurf. Regionale echte
Klippen/Rampen bleiben eigene Caster. Keine globale Schattenabschaltung und
keine zusätzliche Gameplayoberfläche. H0 und dünne regionale Deckkappen brauchen
keine zweite Hülle. Native Stationsvergleiche prüfen Streifen und erhaltenes Relief.

Im ausdrücklich markierten `warehouse_axes_v1`-Stationsensemble schließt die
abgeleitete Wandspannweite die alten 10%-Lücken. Asymmetrische L-Quellen richten
ihre beiden vorhandenen Arme an den tatsächlichen Nachbarwänden aus. Ein Türblatt
wird innerhalb seines existierenden Blatt-/Rahmen-Zellverbandes an die Rahmenebene
gebunden; keine neuen Blockerzellen. Seine sichtbare Öffnung liest ausschließlich
`TerrainRegistry.source_runtime_visual_state` des vorhandenen Doorowners,
revisionsgebunden und ohne neue Collider/Savefakten. Nur das Blattkind wechselt
Sicht/Transform; die FoW-Sicht seines Elternknotens bleibt unangetastet.
Der originale Türsturz behält seine authored erhöhte Unterkante; der allgemeine
Prop-Bodennormalizer darf ihn nicht auf Blatthöhe absenken. Live-Blattzustände
werden erst nach statischem Chunkcapture projiziert, damit ein Cachehandoff
keine bereits halbierte Türgeometrie als neue Ausgangsform behandelt.

`station_module_layout.regions` kann mehrere ausdrücklich migrierte Ensembles
enthalten; ohne Liste bleibt das vorhandene einzelne Top-Level-Ensemble gültig.
Jedes `floor_boundary` benennt die vier Außenwand-Mittellinien in ursprünglichen
geraden Autorenzellkoordinaten. Eine gecachte reine Materialprojektion teilt
dort dieselbe dünne Bodenfläche in hellen Innenbereich und ariden Außenbereich.
UV-Quelle, Dreiecke, Stützhöhe, Konturen und Gameplayfakten bleiben vollständig
erhalten; keine abgeschnittene Auflage mit unsichtbarer Figurenstütze. Ganze
Kartenabnahme erfordert alle realen Ensembles, nicht nur dieselbe Assetfamilie.

### Statischer Vorbereitungscache und lebendes Hexgitter
Der versteckte, akteurfreie Karten-Prefill erstellt keine `TileGridLines3D`-
Geometrie. Die Konturen gehören zur jeweiligen View und hängen von tatsächlicher
Begehbarkeit sowie aktuellem FoW ab; die empfangende View erzeugt sie wie bisher
nach dem Wiederherstellen jedes Chunks. Der unveränderte Ressourcencache enthält
nur den weiterhin benötigten statischen Payload, und das 256-MiB-Budget wird nicht
erhöht oder anders gezählt. Der empfangene Chunk erfasst seine tatsächlich neu
erzeugte Linienzahl. Direkter Kartenstart und Cachehandoff müssen bei gleichem
Sicht-/Registryzustand dieselben Konturen liefern; unbekannte Zellen bleiben leer.
Der enge Nachweis ist `review_completion_grid_cache_verifier.gd`; der tatsächliche
512×256-Ressourcenlauf und die reale Kampagne bleiben zusätzliche Abnahmekriterien.
