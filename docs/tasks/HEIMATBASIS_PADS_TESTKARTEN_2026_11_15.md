# Heimatbasis-Pads erhoeht und alte Stationskarten aus der Spielerauswahl (15.11.2026)

## Ziel
1. Landeplaetze der Heimatbasis sind niedrige erhoehte Decks (Oberkante 0.12 ueber dem Boden), wie auf den Missionskarten, nicht buendig im Boden.
2. `station_outpost_64x64` und `station_outpost_192x192` sind alte Testkarten und werden dem Spieler nicht mehr zur Auswahl angeboten. Die Dateien bleiben unveraendert auf der Platte.

## Ursache
- Teil A: `explorable_homebase.gd` versenkte das Deck um `PAD_SCRIPT.DECK_HEIGHT`, damit die Oberkante buendig mit dem Boden lag. Die Missionskarten nutzen seit Grafikpass R2 `PAD_DECK_TOP` (place_reference_dressing.gd).
- Teil B: `productive_ground_maps.gd` fuehrt beide Karten in `PLAYABLE`; Lobby-Auswahl (`_populate_map_options`, Ort oeffnen) liest `playable_paths()`.

## Umfang
- Heimatbasis: Pad-Deck mit `PAD_DECK_TOP` (Skalierung `PAD_DECK_TOP / DECK_HEIGHT`, `use_raised_deck_shadows`), nur Anzeige. Schiffe auf dem Pad und Personen/Avatar innerhalb des Pad-Rechtecks werden um denselben Betrag angehoben (einfache Stufe, keine Rampe). Beschriftung/Markierungen sind Kinder des Pad-Knotens und wandern mit. Unbebaute Bauplaetze bleiben wie bisher.
- Karten: neue Konstante `TEST_ONLY` und `selectable_paths()` in `productive_ground_maps.gd`; die zwei Lobby-Listen nutzen `selectable_paths()`.

## Nicht-Ziele
- Keine Aenderung an Pad-Positionen, -Groessen, Einstiegspunkten, Navigation, Klickflaechen (Klick-Ebene `_standing_y` bleibt unveraendert).
- `playable_paths()` und `all_paths()` bleiben unveraendert (Multiplayer-Runtime-Validierung, Karten-Verifier).
- Keine Aenderung an Szenarien/Missionskatalog, keine Umbenennung/Verschiebung/Inhaltsaenderung der Kartendateien.

## Akzeptanzkriterien
- Deck-Oberkante der gebauten Heimatbasis-Pads = surface_y + `PAD_DECK_TOP`.
- Geparktes Schiff steht auf der Deck-Oberkante; Personen im Pad-Rechteck werden angehoben, ausserhalb nicht.
- Beide Stationskarten nicht in `selectable_paths()`, laden aber weiter direkt.
- Bestehende Verifier unveraendert gruen (Vergleich vorher/nachher).

## Betroffene Dateien
- scripts/meta/explorable_homebase.gd (geteilte Datei, minimaler Diff)
- scripts/mission/productive_ground_maps.gd
- scripts/ui/multiplayer_lobby_screen.gd
- scripts/tests/homebase_pads_testmaps_verifier.gd (neu)
- docs/IMPLEMENTATION_STATUS.md

## Lokale Pruefung
`homebase_pads_testmaps_verifier`, `map_services_verifier_20261114`, `base_management_access_verifier`, Pad-/Homebase-Verifier, Vorher/Nachher-Screenshots 1920x1080.

## Risiken / offene Punkte
- Spielerstartbare Szenarien nutzen die 192er-Karte weiterhin: `HOMEBASE_MISSION_CATALOG` in `meta_layer_flow.gd` (frontier_probe, frontier_probe_vertical_slice, station_route_one_screen_multiplayer_drill). Bewusst nicht geaendert, Entscheidung beim User.
- Der Karteneditor nutzt `station_outpost_64x64` als Default-Karte (Editor, nicht Spielerauswahl), unveraendert.
- Personen werden an der Pad-Kante ohne Rampe schlagartig 0.12 angehoben.
