# Absturzstelle ausgestalten (14.11.2026)

Auftrag von Björn im Grafik-Chat. Branch `task/claude-kampagnenkarten-20261114`, Basis `origin/main` `068784888`.

## Ziel / Problem

Die erste Kampagnenkarte (`maps/satellite_crash_site.json`, Ort „Satelliten-Absturzstelle“) war fast leer: als Satellit stand eine kleine Kenney-Schüssel, es gab kein sichtbares Landepad, kein sichtbares Frachterwrack und nichts an den Abbaustellen. Gewünscht sind Satellit, Schleiffurche und Trümmer (Playtest L11, Grafikteil) im Stil von Windbruch.

## Umfang

Ausgestaltung auf dem vorhandenen Gelände, kein Neubau der Region: `tools/dress_satellite_crash_site.py` geht immer vom Kartenstand `068784888` aus und ergänzt

- erhöhtes Landepad `satellite_pad_01` am Landepunkt, geteerte Straße zum Handelsposten, Trampelpfade zu Satellit, Frachterwrack und beiden Erzstellen;
- Schleiffurche (heller Bodenstreifen, drei Aufsetzstellen davor), Erdwälle beidseits, abgerissene Solarflächen und Kleinteile, Satellitenwrack am Ende vor dem Missionsmarker;
- Frachterwrack als Modelle in den Zellen, die die Bergestelle schon sperrt; Erzbrocken mit farbigen Kristallen an A- und B-Benit;
- kleines Ensemble am Handelsposten, lose Felsdeckung im Kern, detaillierte Klippen im Kern (`cliff_detail_bounds`).

Neue Modelle: `art/absturz_kit_20261114/build_kit.py` → `Assets/curated/absturz_kit_20261114/` (7 Modelle, 148–664 Dreiecke), eigene Entwürfe im Windbruch-Kit-Stil.

## Nicht-Ziele

Höhenstufen, Rampen, Marker, Ressourcenorte, Regionsdaten und Szenarien bleiben unverändert. Wann der Satellitenmarker erscheint und wie das Suchgebiet funktioniert, gehört zum Bedien-Strang.

## Was sich an Spieldaten ändert

- 303 zusätzlich gesperrte Zellen im Kern (Modelle und 254 Felsbrocken), Flächentyp `road` bzw. `sand` auf Straße, Pfaden und Furche.
- Die beiden Platzhalterobjekte (`spacekit_satellite_dish_detailed`, `station_container_wide`) sind entfernt; ihre Zellen sind wieder begehbar.
- `place_presentation`: `pads`, `props`, `cliff_detail_bounds`.

## Lokale Prüfung (Linux, headless, ohne native Erweiterung)

| Prüfung | Ergebnis |
| --- | --- |
| Generator: alle Marker und Ressourcenzellen begehbar und vom Landepunkt erreichbar, keine Route verstellt | bestanden |
| `location_resource_runtime_verifier` | 21 / 0 |
| `campaign_maps_content_verifier` | 69 / 0 |
| `playtest_20261110_location_terrain_verifier`, `playtest_20261110_resource_geometry_verifier` | 0 Fehlschläge |
| `map_save_metadata_roundtrip_verifier` | 42 / 0 |
| `map_services_verifier_20261114` | 81 / 0 |
| `playtest_20261109_satellite_recovery_verifier` (40 / 7), `satellite_mouse_use_verifier` (17 / 3), `playtest_20261109_campaign_landed_craft_verifier` | dieselben Fehlschläge wie mit der unveränderten Karte |
| `review_completion_maps_verifier` | hier wegen Speicher beendet, nicht gelaufen |

Bilder: `docs/qa/absturzstelle_20261114/` (00 vorher, 01–06 nachher).

## Risiken / offene Punkte

- Der Auftrag „Satellitendaten bergen“ ist auf der neuen Fassung nicht gespielt.
- Das Wrack sperrt Zellen direkt neben dem Missionsmarker; die Markerzelle und ihre Nachbarn bleiben frei.
- Die Erdwälle sind reine Darstellung ohne Deckung oder Sperre.
- Die Furche ist nur Bodenfarbe plus Modelle, keine Vertiefung im Gelände.

## Nachtrag 14.11., 21:00: Handelsaußenposten und neue Straße

**Handelsaußenposten** (`maps/trade_outpost.json`, `tools/dress_trade_outpost.py`, gleiche Arbeitsweise, Basis `068784888`): die 103 alten Space-Kit-Felsen sind durch den Sandstein der übrigen Karten ersetzt (gleiche Zellen, gleiche Sperrwirkung); Freihafen und fernes Außenlager haben Kit-Teile bekommen (Container, Kisten, Solar, Aggregat, Wohnmodul); A- und C-Benit sind mit Erzbrocken markiert (neues Modell `ab_ore_outcrop_c`); zwei Pfade zu den Erzstellen; 316 Felsbrocken als Deckung in beiden Kernen. Pads, Dienste, Frachtlift, Gebäude, Marker und Ressourcen unverändert. Alle zehn Marker und Ressourcenzellen bleiben erreichbar.

**Straße** (`scripts/terrain/frontier_road_deck.gd`, Wunsch von Björn nach dem Referenzbild „Rostgrenze“): gleichmäßiges Band mit weichen Bögen (Mittellinie stärker geglättet: 12 Durchgänge, bis 0,42 Zelle), Fahrbahn 1,1 Zellen breit, heller Metallrahmen, orangefarbene Linie, kleine Leuchtpunkte am Rahmen (`BuiltRoadLights`, reine Darstellung). Straßen sind in den Kartendaten jetzt eine Zelle breit (Absturzstelle, GM02 neu erzeugt). Die Platte ragt damit optisch etwa 0,2 Zellen in die Nachbarzellen; deren Hexlinien liegen dort unter der Platte. Die Farben der GM01-Wegbänder in `frontier_art_dressing.gd` sind angeglichen.

Prüfung nach dem Nachtrag (Linux, headless): `campaign_maps_content_verifier` 69 / 0, `location_resource_runtime_verifier` 21 / 0, `playtest_20261110_location_terrain_verifier` und `…resource_geometry_verifier` ohne Fehlschlag, `ground_mission02_relay_ridge_verifier` 35 / 0, `review_completion_hex_surface_verifier` 246 / 0, `map_services_verifier_20261114` 81 / 0, `windbruch_outpost_verifier` 41 / 0. Bilder: `docs/qa/handelsposten_strasse_20261114/`.
