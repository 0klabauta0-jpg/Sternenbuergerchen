# Polisa R04 — Stationskante, fünf Frontpads

Eingefrorener privater Kandidat nach der Nutzerkorrektur zu R03. R03 bleibt
als vorheriger Kandidat unverändert. Keine produktive Map/Visual/UI-Datei
durch diesen Agenten geändert; Root übernimmt Integration und echtes Kaufmenü.

## Gestaltung
- Zentraler48×32-Sammelraum mit blauer Globuskonsole und freiem Umlauf.
- Fünf24×24-Shops: Infanterie, Rüstung, Technik, Versorgung, Fracht.
  Jeder besitzt einen direkten breiten Zugang zum Sammelraum. Niedrige
  Front-/Innenwände erlauben den Blick auf Waren und alle drei R07-Displays
  aus derselben Kamera; Frachtkästen sind offen sichtbar.
- Genau fünf Pads vor dem Dockvorfeld:24×26 /32×40 /40×48 /32×40 /24×26.
  Keine hinteren Pads, kein polisa_pad_06. Reservehüllen mit je3Einheiten Rand.
- RingeDurchmesser52, um±30°angestellt, damit sie frontal als Ringe erkennbar
  bleiben. Ihre projizierten X-Hüllen liegen außerhalb sämtlicherPadrechtecke.
  Vier14×32Solarflächen mit deutlich längeren Auslegern.
- Stationursprung=(0,-64), hintere Wand beiZ=-88, begehbares Deck endet nach
  vorn beiZ≈23,4. Deklarierte256×256Offsetkarte mit Weltraumrahmen bisZ131,7:
  rund108Einheiten freies Vorfeld, keine fingierten begehbaren Weltraumtiles.

## Eine Authoringquelle
`layout.json` besitzt lokale Deck-/Wand-/Tür-/Möbel-/Pad-/Markerfakten und
genau einen `origin_plane`. `build_candidate.py` übersetzt Map-/Markerfakten
einmal; `place_presentation.props[0].center` erhält denselben Ursprung.
`layout_compiled.json` und `polisa_r04_visual.gd/.tscn` bleiben lokal.
Die eingefrorene private R03-Map dient als Metadatenbaseline; die zeitgleich
von Root bearbeitete Produktionskarte wird nicht als Source eingelesen.

Wichtig: `place_presentation.pads=[]`. Dieses Feld ist ein Renderer-Input für
FrontierOutpostPad, keine allgemeine Metadatensammlung. Eigene Padgeometrie
steht ausschließlich im Layout und Stationsvisual; Landungsanker in Markern.
Der unabhängige Reviewer fand die zusätzliche Standardpad-Erzeugung im ersten
Artlauf. Sie wurde entfernt und im finalen nativen Dressingbudget geprüft.

## Abgegrenzte Daten-/Geometrieprüfung
13.172Deckfelder,12.399begehbar in genau einer Komponente,773gesperrt.
Alle fünf Padmarker, erhaltenen spawn/return/service IDs und Raumzugänge
erreichbar; geschlossene Rückkante und Globusumlauf geprüft. KeinePad06.
StatischeStation17.948Dreiecke/10Meshes; R07-Displays22.472Dreiecke/6Meshes.
Ganzes PlaceReferenceDressing nativ exakt16sichtbareMeshes/40.420Dreiecke:
keine weiteren versteckten Standardpadmeshes.0CollisionObjects und0dynamische
Lichter. Keine eigenen Frame-Loops; Rüstung mittels bestehendem R07-Helper,
Idle einmalig gesetzt, Animation pausiert und Modelprocessing deaktiviert.
Keine neue Armor-/Waffen-/Schiffsrevision.

## Native Ansichten
Originale unter `output/native_glut_maps/polisa_r04_20261111/`:
- `polisa_r04_station_near.png`: alle fünf Shops samt Fracht und Globus,
  yaw0°, pitch58°, size66, Weltplane-Fokus(0,-60).
- `polisa_r04_whole_map.png`: vollständiger deklarierter Kartenrahmen,
  Stationskante, fünf Pads, Ringe/Solar und großes freies Vorfeld;
  yaw0°, pitch68°, size226, Weltplane-Fokus(0,20.8).

Beide finalen Bilder tatsächlich geöffnet. Nahaufnahme priorisiert alle
Shopinhalte und den Hub; die vollständigen Pad-/Ringausleger zeigt WholeMap.
Echtes Viewhexraster ist aktiv und im Shopgesamtmaßstab fein; kein zweites
visuelles Raster. Das Projekt liefert1280×720PNG, auch nach dem im privaten
Capture angefragten größeren Fenster. Finaler Lauf r04_final: Godot4.6.2,
D3D12Forward+, Exit0, Errors0, Warnings0, eigener absoluter APPDATA-Pfad,
versteckter Host. Erster Lauf/r01-Bilder bleiben als verworfene Vorrevision
mit noch zusätzlichen Standardpads und nicht angestellten Ringen erhalten.
Zwei Ansichten in zwei gezielten Artläufen, keine Gefechte oder Benchmarks.

## Root-Integration / normaler Kamerablick
Map: `output/native_glut_maps/polisa_r04_20261111/polisa_station_candidate.json`.
Scene/Script/compiled Layout zusammen erhalten oder Pfade kontrolliert umbiegen.
`layout.standard_camera` nennt den geprüften Shopblick: yaw0/pitch58/size66,
lokaler Fokus(0,4), global(0,-60), IsoVector2(3840,-1920).
View.configure_from_map unterstützt einen expliziten initial_focus. Die reine
initial_camera_size-Metadatenangabe setzt diesen Fokus nicht automatisch.
Marker- und Shopanker stehen mit Grid-/Weltkoordinaten in offline_checks.json.
Root bindet01..05inlocations an und entfernt06 aus den angebotenen Pads.
Kaufmenü/Services/NPCs bleiben vollständig bei vorhandenen Root-Ownern.

## Grenzen / Provenienz
Geometrische Reserve ist keine verifizierte Caterpillarhülle oder Landefreigabe.
Graphkonnektivität ist kein tatsächlicher Laufweg-/Reise-/Shop-/Save-PASS.
Der sichtbare Weltraumrahmen projiziert die deklarierte Mapgröße; er führt
keinen neuen Fluggrenzen- oder Kameralimit-Owner ein. Keine ästhetische
Nutzerabnahme, keine Main-/EXE-Integration, Commits oder Push durch diesen Agenten.
GPU nach finalem Lauf an Root freigegeben. Quellen-/Bildhashes in manifest.json.
R03 und dort dokumentierte Port-Olisar-Formreferenzen bleiben Herkunft; R04
übernimmt keine externenMeshes und verändert keine vorhandenen Armorquellen.
