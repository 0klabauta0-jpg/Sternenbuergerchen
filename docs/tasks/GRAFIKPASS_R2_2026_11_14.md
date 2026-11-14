# Grafikpass R2: Landepads, Straße, Trampelpfad, Klippen

## Ziel / Problem
Nutzerrückmeldung vom 14.11.2026 nach R1 („schon besser“), mit vier Vorgaben:
1. Es gibt zwei Wegarten: Trampelpfad und angelegter Weg. Der angelegte Weg ist
   eine richtige, geteerte Straße und ein eigenes Objekt (wie es das in der
   Heimatbasis schon gab). Der Trampelpfad darf in der Form frei spielen.
2. Landepads sind richtige Objekte und etwas erhöht, nicht in den Boden
   integriert.
3. Klippen bleiben hexkonform und gut bearbeitbar, sollen aber organisch wie
   Bruchstein aussehen.
4. Stilrichtung: etwas comichaft, verniedlichtes Star-Citizen-Vorbild.
   Lagergebäude gefallen; die aus Kenney-Mauern gelegte Station gefällt nicht.

## Sinnhaftigkeit / Ursache
- Pads waren seit dem Hex-Umbau bewusst zu Bodenfarbe abgeflacht
  (`pad.scale.y=.1`, Kommentar „no raised platform or invented navigation
  surface“, GM01 `_flat_apron`). Der Nutzer will das ausdrücklich zurück.
- Straßen wurden über die Splat-Maske als Fläche in den Boden gemalt und
  folgten den Hexkanten. Die Heimatbasis hatte bereits den „durchgehenden
  geteerten Weg“ (`HOMEBASE_VISUAL_COHERENCE_2026_11_12`), dort aber in
  Olivgrau.
- Schmale `sand`-Streifen auf festem Boden lasen als helle Hex-Bänder.
- Beschattete Klippenwände fielen fast auf Schwarz; das Bruchmuster war dort
  nicht lesbar.

## Umfang
Nur Darstellung.

**Landepads**
- `place_reference_dressing.gd`: Pads als niedriges Deck, `PAD_DECK_TOP = 0.12`,
  nur die beiden Deckkörper werfen Schatten.
- `frontier_outpost_pad.gd`: `use_raised_deck_shadows()`.
- `frontier_gm01_layout.gd`: beide GM01-Aprons tragen ein `RaisedLandingDeck`;
  der gemalte Apron darunter bleibt mit allen Ankern und Rechtecken bestehen.
  Neues Faktum `pad_decks`.
- `terrain_map_3d_view.gd`: `_configure_visual_deck_lift` trägt Zellen unter
  einem Deck ein; `_hex_grid_model_support_lift` liefert dort die Deckhöhe.
  Damit stehen Hexlinien, Auswahl, Einheiten und Schiffe auf dem Deck
  (derselbe Weg wie bei Brücken- und Stationsböden).

**Gebaute Straße**
- Neu `scripts/terrain/frontier_road_deck.gd`: ein statisches Objekt über alle
  flachen `road`-Zellen einer ariden Karte. Vereinigung abgerundeter Spuren
  zwischen Nachbarzellen, drei Lagen (Randstein, Randlinie, Asphalt), Höhe
  0,03 – unter dem Hexlinien-Offset, daher ohne Höhenänderung für Einheiten.
- `terrain_map_3d_view.gd`: `_sync_built_road_deck` in `render_map`; Zellen,
  die schon von einem authored Servicepfad überdeckt sind, werden ausgelassen.
- `frontier_art_dressing.gd`: die drei verbundenen Pfadlagen in Asphaltfarben
  (Heimatbasis und GM01).
- `frontier_ground.gdshader` / `frontier_art_profile.gd`:
  `road_paint_strength` – unter dem Straßenobjekt bleibt nur ein schwacher
  Staubrand.

**Trampelpfad**
- `frontier_ground.gdshader`: `trail_surface`. Schmale Sandstreifen werden mit
  einem zweiten, langsam mäandernden Maskenabgriff gezeichnet: fester Kern,
  lockerer Rand, Farbe näher am Umgebungsboden.
- `frontier_art_profile.gd`: `trail_surface` ist an, wenn Sand weniger als
  30 % der Zellen ausmacht.

**Klippen**
- `frontier_ground.gdshader`: Bruchsteinblöcke mit heller Ober- und dunkler
  Unterkante je Block; warmes Rücklicht auf sonnenabgewandten Wänden
  (`sun_direction_world`), damit sie Steinfarbe behalten.
- Bodendetail im ruhigen Modus von 0,42 auf 0,24 zurückgenommen.

## Betroffene Dateien
- `shaders/terrain/frontier_ground.gdshader`
- `scripts/terrain/frontier_art_profile.gd`
- `scripts/terrain/frontier_art_dressing.gd`
- `scripts/terrain/frontier_road_deck.gd` (neu)
- `scripts/terrain/frontier_outpost_pad.gd`
- `scripts/terrain/place_reference_dressing.gd`
- `scripts/terrain/frontier_gm01_layout.gd`
- `scripts/terrain/terrain_map_3d_view.gd` (geteilte Datei, in der
  Abstimmungsnotiz eingetragen)
- `scripts/tests/review_completion_hex_surface_verifier.gd` (Pad-Erwartung)
- `scripts/tests/grafikpass_r1_capture.gd`
- `docs/qa/grafikpass_r2_20261114/` (neu)

## Basis
Branch `task/claude-grafikpass-r1-20261114`, zweiter Commit auf R1
(`main` 03cdccc + R1).

## Nicht-Ziele
- Keine Änderung an Terrainhöhe, Begehbarkeit, Sichtlinien, Landeregeln,
  Wegfindung oder Kartendaten. `stand_height` der Pad-Zellen bleibt 0.
- Kein eigener Flächentyp „Pfad“ (wäre Daten/Regel, Bedien-Strang).
- Heimatbasis-Pads (`explorable_homebase.gd`, vom Bedien-Strang belegt).
- Stationswände aus Kenney-Teilen: nicht angefasst, siehe nächste Schritte.
- Grüne Karten, Orbitalstation, UI.

## Geänderte Testerwartung
`review_completion_hex_surface_verifier.gd`, `_test_painted_pad`: die beiden
Prüfungen „painted pad … remains below … contour“ und „removes self-shadow
casters“ schrieben die abgeflachte Variante fest. Sie sind durch die neue
Nutzervorgabe ersetzt: Deck liegt unter der angehobenen Hexkontur, Hub gleich
`PAD_DECK_TOP`, `stand_height` weiter 0, Nachbarzelle ohne Hub, nur Deckkörper
werfen Schatten. 246/0.

## Akzeptanzkriterien
1. Pads lesen als erhöhte Objekte mit Seitenfläche und Rampe; Hexlinien liegen
   auf dem Deck.
2. `road`-Zellen lesen als durchgehende geteerte Straße mit Randstein und
   runden Kurven.
3. Schmale Sandstreifen lesen als Trampelpfad mit unregelmäßigem Rand.
4. Beschattete Klippenwände zeigen Bruchsteinblöcke.
5. Grüne Karte bildgleich; kein Verifier fällt gegenüber R1/`main` neu aus.

## Lokale Prüfung
Renderer `gl_compatibility` (llvmpipe), 1280×720, Godot 4.6.2. Bilder R1 gegen
R2 in `docs/qa/grafikpass_r2_20261114/`. GM02 (grün): 0 abweichende Pixel.

Verifier `--headless`, R2 gegen R1:
- Bestanden: frontier_art_profile, frontier_main_environment,
  frontier_pass02, frontier_pass03_geology, frontier_pass07_paths,
  review8_graphics, review_completion_graphics_fixes (519),
  review_completion_station_visual (158), review_completion_building_material,
  gm01_frontier_map_edge (51), frontier_start_graphics (28),
  task_293_editor_lighting, frontier_main_ship_adoption,
  map_services_verifier_20261114 (81), playtest_20261110_resource_geometry,
  reference_polish_r3_20261106_world_dressing, gm01_frontier_editor_guard,
  hex_dynamic_ship_movement, hex_movement, hex_runtime_selection,
  playtest_20261110_free_landing, review_completion_hex_surface (246).
- Schlagen fehl, mit identischer Fehlerliste vor und nach R2:
  frontier_pass06_environment (1), homebase_visual_coherence (2),
  frontier_runtime_map_slice (5), frontier_pass04 (1),
  playtest_20261110_place_dressing (2), gm01_frontier_rebuild (3),
  gm01_frontier_hex_fow (2), gm01_frontier_hex_minimap (1),
  hex_ground_lifecycle (1), review_completion_cliff_station_revision (2).
  Die letzten fünf sind zusätzlich gegen `main` 03cdccc geprüft: identisch.
- In dieser Umgebung nicht lauffähig (Prozess wird beendet, auch auf R1):
  review_completion_grid_cache, review_completion_hex_use,
  review_completion_map_preparation, review_completion_maps,
  review_completion_station_layout.

## Risiken / offene Punkte
- Nicht im Forward+-Renderer (D3D12) und nicht im laufenden Spiel geprüft.
  Insbesondere ungeprüft: Einheit läuft auf ein Pad und wieder herunter, Schiff
  landet auf dem Deck, Auswahlring auf dem Deck. Der Hub nutzt den vorhandenen
  Stützhöhen-Weg, ein Spieltest fehlt.
- Hexlinien am Deckrand: Zellen, deren Mitte neben dem Deck liegt, bleiben am
  Boden; ihre Linien werden vom Deck teilweise verdeckt.
- Straße folgt den Zellmitten. Schräg zur Hexachse verlaufende Straßen
  schlängeln leicht.
- Auf Stationskarten liegt unter den Pads ein dunkles Asphaltfeld, weil die
  Padzellen `road` sind.
- `sun_direction_world` ist fest auf die Profilsonne (-52/-32) gesetzt.
- Shaderkosten nicht auf Zielhardware gemessen.
- Nutzerurteil steht aus; nicht in `main` integriert.

## Nächste Grafikschritte (Vorschlag, nicht umgesetzt)
- Stationsmodule neu statt Kenney-Mauern: eigene Wand-, Eck- und Türteile im
  Stil der Lagergebäude (Creme/Petrol, gefaste Kanten), in Blender gebaut,
  gleiche Footprints.
- Heimatbasis-Pads anheben, sobald `explorable_homebase.gd` frei ist.
- Geröll am Klippenfuß als Geometrie.
- Mittellinie und Abnutzung auf der Straße; gerade Straßenführung über
  Polylinien statt Zellmitten.
