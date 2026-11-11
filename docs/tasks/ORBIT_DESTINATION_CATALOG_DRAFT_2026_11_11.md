# Orbit Destination Catalog V3-Draft (nur Datenvorbereitung)

## Ziel / Ursache
Die neue Orbitvorgabe benoetigt spaeter genau ein gemeinsames Orbitziel je Stern, Planet und Mond. Heute produktiv bleiben V2 und drei Marker. Dieser Slice kompiliert ausschliesslich einen abgetrennten, validierten V3-Draft aus einem uebergebenen gueltigen heutigen V2-Katalog.

## Scope / Nicht-Ziele
Nur neuer scripts/mission/orbit_destination_catalog.gd, eigene Task, eigener Contract und kleine QA. Kein Fleet/Travel/Root/Grid/UI-/star_system.json-Edit, kein Produktparserwechsel, Runtimezustand, Save-/Restorepfad oder Movementhelper. Keine stille Umdeutung aktueller UIcommands. Aliasdaten dienen ausschliesslich spaeterer expliziter Offline-/Savemigration.

## API / Datenregel
build_v3_draft(legacy_definition) liefert einen Deepcopy-Draft mit version=3 und klarem draft-Flag, eine V2->V3-Markeraliastabelle und daraus abgeleitete Body->Orbit-/Areaindizes. Alle fuenf bisherigen Orbit-IDs, deren orbit_1-Koordinaten und alle location_orbits bleiben erhalten. Je physischem Body genau ein Marker orbit_1. Lokale body_map_id kommt ausschliesslich aus OrbitApproachLayout.build(body.id); lokales Mass 512x256, strategisches Mass unveraendert 256x256.

Abgestimmte Sunregel: neue ID sun_orbit, Name aus Glut plus Sternorbit. Einziger Marker ist sun.hex +(-r,0) mit r=ceil(sun.radius)+1, heute r=6 und (58,128). Orbit-/Markerposition werden per GRID.normalized kanonisch abgeleitet. Bounds, Radiusabstand und Kollisionsfreiheit mit bestehenden Markern sind Pflicht; bei Konflikt klarer Reject, keine Such-/Verschiebereparatur. Sun.surface_location_id bleibt leer, keine neue Surfacebindung.

Stationkind station erhaelt keinen eigenen Koerperorbit oder Bodyareaindex. Polisa bleibt Ortsbindung an polisa_orbit, dessen Koerper Glut2 ist. Unbekannte Nonstation-Bodies werden abgewiesen statt still entfernt. Bestehende Bodypositionen, Namen und Locationreferenzen werden nicht verschoben; nur Suns bislang leere orbit_id wird auf sun_orbit referenziert.

## Quellen / Arbeitsbasis
9813c7dcd im gemeinsamen isolierten Integrationstask; Pflichtdocs und orbital_approach_contract. Reine vorhandene GRID-Geometrie und OrbitApproachLayout duerfen gelesen werden. Keine Instanziierung eines Runtimeowners zur Validation und keine zirkulaeren Loads. Der heutige Produktvalidator akzeptiert V2, daher ist der Draft kein produktiver Ersatz.

## Akzeptanz / kleine lokale Pruefung
8-10 Datenchecks: Deepcopy/Quellgleichheit, eindeutige sechs Bodyorbits/ein Marker, erhaltene alte Koordinaten und Locations, Sungeometrie ohne Surface, Stationausschluss/Polisa, kanonische lokale IDs/Masse, migrationsbeschraenkte Aliase, fehlerhafte/ungebundene Bodies und Sunbounds/-kollision, frische Ausgaben. Einzelcompile, keine GPU-/Native-/alte Suite, kein Commit oder Sharedstatusedit.

## Risiken / offen
Produktive Umstellung erst mit vollstaendigem Warp->lokaler Flug->Saum->Oberflaeche und expliziter Markermigration. Aliasdaten sind keine Runtimeauflosung veralteter Commands. Draftindizes sind abgeleitete Daten, keine zweite Ziel- oder Flugwahrheit. V3-Produktparser, UI, Replay-/Savevertrag und Sternflug bleiben Folgearbeit.

## Ergebnis / eingefrorene Evidenz
Der reale heutige JSON-Katalog besteht nach Reviewkorrektur 11 gezielte Datenchecks, 0 Fehler. Helper-Einzelcompile unter Godot 4.6.2: Exit 0. Artefakte: output/native_glut_maps/orbit_destination_catalog_draft_20261111/{check.gd,check.log,compile.log,README.md,SHA256SUMS.txt}. Zahlen aus JSON werden ganzzahlig geprueft, nicht faelschlich als bereits typisierte GDScript-Integer verlangt. Keine vorhandene Produktdatei geaendert; keine produktive Verdrahtung, keine grossen Tests, kein Commit.

### Reviewkorrektur: Rohwerte vor 32-Bit-Cast
Ein zusaetzlicher gezielter Regressioncheck umfasst q+2^32, grid_size.x+2^32, ring_radius+2^32 und V3-Sonnenradius+2^32. RED: 11 Checks, 1 Fehler (raw_wrap_red.log); GREEN nach enger Katalogkorrektur: 11/0 und Compile Exit 0. Rohzeile und daraus berechnete Offsetspalte muessen vor Vector2i-Casts innerhalb der strategischen 256x256-Domaene liegen. Groessenpaare werden roh direkt mit dem erwarteten Wert verglichen. Koerperradius und Legacy-Ringradius sind vor ceil/Multiplikation auf maximal max(GRID.SIZE)=256 begrenzt. Keine Produkt-JSON-, Runtime- oder andere Produktdateiaenderung.
