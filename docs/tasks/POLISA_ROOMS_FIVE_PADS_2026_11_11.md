# Polisa R04: Kartenrand, zentraler Globusraum und Stationsmenue

## Ziel / Ursache
Letzte Nutzerkorrektur ersetzt den R03-Sechspadentwurf: Station am oberen Kartenrand als Begrenzung; nur fuenf vordere Pads. Groessere quadratischere Shops und zentraler Sammelraum mit mannshohem blauem Globus, bequem umlaufbar. Alle Shopinhalte muessen aus der Standardkamera ohne Drehen sichtbar sein; Frachtbereich neu oeffnen. Raumwahrheit und Sichtdarstellung bleiben getrennt.

## Umfang / Akzeptanz
- Fuenf Frontpads, ein deutlich groesseres Hauptpad. Keine hinteren Pads.
- Ringdurchmesser mindestens grosse Padlaenge; grosse Solarzellen/Ausleger.
- Zentrale Lobby als direkter Verteiler aller Shops, blaue Globuskonsole mit umlaufender begehbarer Flaeche.
- Durchgehende echte Hexdeck-/Raum-/Tuermetadaten, Cutaway an der Kameraseite. Gesamte Raumware und Ruestungsausstellungen aus Standardkamera sichtbar.
- Station oben als Kartenrand, ausreichend leeres Vorfeld. Nahe Ansicht mit Hexen sowie ganze Map zeigen.
- Eigene Stationsshops ueber Menue nach tatsaechlicher Landung erreichbar. Fuer Polisa entfaellt der zusaetzliche Zwang, vorher den Schalter persoenlich zu benutzen. Registrierung, Transitsperre und reale Parkpruefung bleiben; UI entscheidet keine Landung. Physisches Erkunden/Schalter bleibt moeglich.
- Echtes Kaufpanel nativ zeigen: bestehende Ownerdaten und Commands, keine vorgetaeuschte Schiffskomponentenfunktion.

## Dateien / Quellen
Neues privates Artpaket art/polisa_r04_20261111, gemeinsame Layout-/Map-/Visualquelle; nach Sichtung Produktion in maps/polisa_station.json, scripts/terrain/polisa_station_visual.gd, tools/build_polisa_station.py, data/singleplayer/locations.json. Menue scripts/ui/polisa_station_screen.gd und enger Polisa-Servicezugang in singleplayer_runtime_adapter.gd. Bestehende base_management_skin/menu_equipment_icons verwenden. Grafikreferenz-, Orts-/Reise-/Supplyvertraege und bestehende Polisa-Tasks gelten, soweit durch diese Nutzerkorrektur nicht ersetzt.

## Pruefung / Risiken / Nicht-Ziele
Nur begrenzte Autorendatenpruefung, Compile und wenige native Art-/UIbilder; grosse Tests spaeter. Landung/Handel/Heimreise/Save und echte Frachterlandung bleiben spaeter abzunehmen. Kein neuer Fahrzeugimport, keine Schiffsloadoutwahrheit, keine Tabletop-Core-/Bewegungsaenderung. R03-Quellen/Bilder erhalten, aber kein fertiger R04-Nachweis daraus. Freier Raum ist keine luftdichte Innenraumsimulation.

Standardkamera: enger Polisa-Preset in place_presentation.station_initial_camera wird in bestehender _frame_reference_mission_camera uebernommen (MissionTestSetup nur diese Funktion). Sonst wuerde die allgemeine Spawn/Ziel-Mitte eine Shopseite abschneiden. Kein erneuter Geometriebau; yaw/pitch/size und vorhandene focus_world_position API, keine Actor-/Vorbereitungsaenderung.

Ganze Map erreichbar: Polisa darf ueber den bisherigen120erZoomdeckel bis280 herauszoomen; andere Karten behalten ihre bisherigen Limits. Kamerafokus bekommt einen eigenen visuellen Marker station_camera_focus aus dem gemeinsamen Layout, da trade_service siebenzehn Ebeneneinheiten weiter vorn liegt als die gepruefte Uebersicht.

Ergebnis: R04-Layout und Visual integriert, fuenf angebotene Frontpads, D52-Ringe, quadratische Shops und Globuslobby. Vier native Bilder von Root geoeffnet: Shopraeume, ganze Map, ganze Station, echtes Kaufpanel mit privatem Supply-Stand. Kleine Andock-/Kameraprobe9/0. End-to-end-Reise/Shop/Save/Framerate sowie persoenliche Stilabnahme bleiben offen. QA docs/qa/polisa_r04_20261111.
