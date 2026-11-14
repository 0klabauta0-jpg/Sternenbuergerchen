# Grafikpass R3: neue Außenposten-Karte „Windbruch“ (Bastion Silex)

## Ziel / Problem
Nutzerauftrag 14.11.2026: die Stationskarte aus Kenney-Mauern „komplett neu,
nach eigenem Gusto“, organisch und spannend, eigene Assets per Blender wo
nötig, Vergleichsfigur im Bild, Iso-Winkel beibehalten. Nach erster Ansicht:
- vorhandene Modelle (Personen, Schiffe, Gebäude) verwenden, statt neu zu bauen;
- Wachtürme, Mauer/Tor an der Straße, Laternen und Säule gefallen nicht;
- einiges zu filigran, manches wirkt schwebend (Solarfelder);
- Straße wirkt aufgeklebt, soll ein Objekt wie die Landepads sein;
- Klippen: mehr Polygone;
- Karte danach an einer passenden Stelle in die Kampagne einsetzen.

## Umfang
**Karte** `maps/windbruch_outpost.json`, 88 × 72 Hexfelder (6.336), erzeugt von
`tools/build_windbruch_outpost.py` (deterministisch, Layout von Hand gesetzt):
Landefeld im Trockenbett (Ebene 0), Siedlung auf einer Terrasse (Ebene 2),
Relais auf dem Grat (Ebene 4/6), geschlossener Felsrand. Fünf Rampen
(Hauptrampe mit Straße, Ostpfad, Hintertür, Gratsteig, Nordwest-Kuppe),
gebaute Straße vom Landefeld durch den Hof, Trampelpfade zu den Nebenzugängen,
frei stehende Tafelberge und 320 Felsblöcke als Deckung.

**Modelle**
- Eigener Bausatz `art/windbruch_kit_20261114/build_kit.py` (Blender 5.3 als
  Python-Modul) → 13 GLB unter `Assets/curated/windbruch_kit_20261114/`:
  Wohnmodul aus Rumpfsegment, Containerhalle mit Flügeldach, Relaisschüssel,
  Bunkereingang, Container (2 Farben, Stapel), Kisten, Fässer, Aggregat,
  Solarfeld, Wrackflügel, Wracktriebwerk. Palette Creme/Petrol/Orange wie die
  vorhandenen Depotgebäude.
- Vorhandene Projektmodelle: Depothalle, Depothabitat, Tank-/Technikeinheit
  (`utility_fuel_01`), Schiff „Freibeuter“ auf dem Frachtpad, Felsen
  `glut_sandstone_04`. Personen in den Bildern sind die vorhandenen
  Einheitenmodelle (`_create_unit_proxy`).
- Nach Nutzerkritik entfernt: Cockpit-Hütte, Klötzchen-Vergleichsfigur,
  Wachturm, Schrottmauer, Tor, Laterne, Triebwerksturm.

**Darstellung (wirkt auf alle ariden Karten)**
- `frontier_road_deck.gd`: Straße ist eine erhöhte Platte (0,09) mit
  Seitenflächen; Fahrbahn wird zwischen den Zellmitten geglättet; folgt über
  die Bodenhöhe auch Rampen (dort nur Asphalt, ohne Randstein).
- `terrain_map_3d_view.gd`: Straßenzellen heben Hexlinien, Auswahl und
  Einheiten um die Plattenhöhe (gleicher Weg wie Pads); `_road_ground_y`;
  Klippen-Detail für Karten bis 20.000 Zellen.
- `regional_cliff_fracture.gd`: `detail` – Absatz in Wandmitte, zurückgesetzter
  oberer und vorgewölbter unterer Block, mehr Geröll (10 statt 4 Dreiecke je
  Fläche). Große Kampagnenregionen behalten die alte Fläche (Cache-Grenze).
- `frontier_ground.gdshader`: Straßenfarbe auf Rampen.

**Kampagne**
Ort `fortified_outpost` („Bastion Silex“), Auftrag `outpost_chip_recovery`
(Wachen im Hof ausschalten, Chip am Relais sichern, zurück zum Schiff) nutzt
jetzt diese Karte:
- `data/singleplayer/locations.json`, `data/mission_scenarios/outpost_chip_recovery.json`:
  `map_file_path`.
- `scripts/meta/meta_layer_flow.gd` (`REGIONAL_CAMPAIGN_MAPS`),
  `scripts/mission/productive_ground_maps.gd` (`PLAYABLE`): Eintrag ergänzt.
- Marker der Karte: `spawn_alpha`, `ship_return`, `spawn_enemy_defense`,
  `outpost_chip`, `objective_point`; Pad-ID `fortified_pad_01`.
- `maps/fortified_outpost.json` bleibt als Datei erhalten (Tests und Werkzeuge
  nutzen sie als Geländevorlage), wird von der Kampagne aber nicht mehr geladen.

## Nicht-Ziele
- `station_outpost_64x64.json` und `…192x192.json` sind unverändert.
- Keine Änderung an Regeln, Wegfindung, Sicht oder Kampagnenlogik; nur Daten
  (Kartenpfad) und Darstellung.

## Geänderte Testerwartung
`campaign_five_actual_sorties_verifier.gd`: erwarteter Kartenpfad des dritten
Auftrags.

## Lokale Prüfung
- `scripts/tests/windbruch_outpost_verifier.gd` (neu, headless): 36/0. Lädt die
  Karte, prüft mit `TerrainTileData.allows_step`, dass alle Marker und
  Patrouillenpunkte vom Landefeld erreichbar sind, dass alle Modelle existieren
  und dass `outpost_chip_recovery` gegen die Karte validiert.
- `campaign_maps_content_verifier` 69/0, `campaign_five_missions_chain_test`,
  `orbit_surface_locations_verifier`: bestanden.
- Darstellung/Bewegung nach den Straßen- und Klippenänderungen bestanden:
  review_completion_hex_surface (246), frontier_pass07_paths,
  map_services_verifier_20261114, review_completion_station_visual,
  gm01_frontier_map_edge, playtest_20261110_free_landing, hex_movement,
  hex_dynamic_ship_movement, hex_runtime_selection,
  review_completion_graphics_fixes, frontier_pass03_geology,
  frontier_art_profile.
- Unverändert fehlschlagend wie vor R3: homebase_visual_coherence (2),
  frontier_runtime_map_slice (5), review_completion_cliff_station_revision (2),
  playtest_20261110_place_dressing (2), space_travel_state (15).
- `campaign_five_actual_sorties_verifier` läuft in dieser Umgebung nicht
  durch: auf dem Branch Timeout im zweiten Auftrag (Handelsposten, 92
  Prüfungen bestanden), auf unverändertem `main` Abbruch nach 2 Prüfungen.
  Der Auftrag auf der neuen Karte ist damit **nicht durchgespielt**.
- Bilder: `docs/qa/grafikpass_r3_windbruch_20261114/` (gl_compatibility,
  llvmpipe, 1280×720).

## Risiken / offene Punkte
- Nicht im Spiel (D3D12) gespielt: Landung auf Pad 01, Gegnerverhalten im Hof,
  Chip-Interaktion am Relais, Rückflug.
- Straßenplatte hebt Einheiten auf Straßenzellen um 0,09 (wie Pads 0,12);
  im Lauf ungeprüft.
- Auf der Rampe verdeckt die Asphaltplatte die Hexlinien von sechs Zellen.
- Das Schiff auf Pad 02 ist Kulisse mit blockierten Zellen, kein Spielobjekt.
- Relaisschüssel steht auf Ebene 6 und ist nicht begehbar; Ziel und Chip
  liegen daneben auf Ebene 4.
- Kartengröße 88 × 72; größere Fassung braucht ein erweitertes Layout.
- Basis ist `03cdccc`; `origin/main` (`a982a0b5d`, native Navigation) enthält
  keine kartenbezogenen Navigationsdaten für diesen Ort (geprüft per grep),
  ein Lauf mit der neuen Navigation steht aus.
