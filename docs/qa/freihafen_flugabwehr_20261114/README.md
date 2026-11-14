# Pruefstand Freihafen und Flugabwehr (14.11.2026)

Auftrag: `docs/tasks/FREIHAFEN_FLUGABWEHR_2026_11_14.md`. Bilder in diesem Ordner sind Standbilder der
Kartenansicht (Linux, OpenGL-Kompatibilitaetsrenderer), keine Aufnahmen aus dem laufenden Spiel.

## Linux, headless (Godot 4.6.2), endgueltiger Kartenstand

| Pruefer | Ergebnis |
| --- | --- |
| `campaign_maps_content_verifier` | 69 / 0 |
| `location_resource_runtime_verifier` | 21 / 0 |
| `playtest_20261110_resource_geometry_verifier` | 0 Fehlschlaege |
| `playtest_20261109_trade_refuel_verifier` | 41 / 0 |
| `map_services_verifier_20261114` | 81 / 0 |
| `ground_mission02_relay_ridge_verifier` | 35 / 0 |
| `windbruch_outpost_verifier` | 41 / 0 |
| `review_completion_building_material_verifier` | 30 / 0 |
| `review_completion_hex_surface_verifier` | 246 / 0 |
| `campaign_pilot_ground_handoff_test` | 0 Fehlschlaege |
| `playtest_20261110_place_dressing_verifier` | 2 Fehlschlaege, dieselben zwei wie vor der Aenderung (erwartet genau 3 Baukoerper; die Karte hat seit dem 10.11. mehr) |
| `campaign_pilot_ground_loop_test` | 31 / 1, bekannter Zeitablauf "satellite_recovery actual mission instance exists" |
| `campaign_intro_loop_smoke` | 30 / 1, derselbe bekannte Zeitablauf |
| `campaign_two_moon_roundtrips_real_verifier` | nach 420 s abgebrochen, bis dahin nur PASS; Ergebnis vom Windows-Rechner siehe unten |
| `grafikpass_r123_surface_verifier` | nicht gelaufen: verlangt Codex' getrennte Projektkopie |

Die Handelsposten-Pruefer aus dieser Tabelle liefen nach der letzten Kartenaenderung (Strasse bis zum
Aussenlager) noch einmal; die Zahlen sind von diesem Lauf.

## Was nicht geprueft ist
- Kein Auftrag wurde auf den geaenderten Karten gespielt.
- Landung eines grossen Schiffs auf den beiden Freihafen-Pads im Spiel. Der Pruefer bestaetigt nur, dass die
  Landeflaeche am Marker frei ist.

## Windows-Rechner (D3D12, native Navigation)
Wird nach dem Lauf dort ergaenzt.
