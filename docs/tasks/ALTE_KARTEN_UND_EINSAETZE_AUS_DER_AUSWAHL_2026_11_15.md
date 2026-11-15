# Alte Karten und Einsaetze aus der Spielerauswahl nehmen (15.11.2026)

## Status: IMPLEMENTIERT (lokal geprueft, siehe unten)

## Ziel
Das Spiel hat einen neuen Grafikstil. Alte Uebungs- und Testkarten sowie drei alte Einsaetze
sollen in nichts mehr auftauchen, was der Spieler auswaehlen kann. Dateien bleiben liegen
(viele Tests laden sie); nichts wird geloescht, umbenannt oder verschoben.

## Ursache
- `ProductiveGroundMaps.selectable_paths()` war "playable_paths() minus TEST_ONLY" und nahm
  jede weitere gueltige Karten-JSON aus `res://maps` automatisch auf; Fixtures konnten so
  in die Spielerauswahl geraten.
- `HOMEBASE_MISSION_CATALOG` (`meta_layer_flow.gd`) bietet drei Einsaetze auf der alten
  Station-Karte an (`frontier_probe`, `frontier_probe_vertical_slice`,
  `station_route_one_screen_multiplayer_drill`).

## Umfang
- Teil A: `selectable_paths()` ist eine explizite Allow-List (Reihenfolge fest, fehlende Dateien
  uebersprungen): Ground_Mission01_32x32, Ground_Mission02_128x128, satellite_crash_site,
  trade_outpost, windbruch_outpost, polisa_station. `TEST_ONLY` dokumentiert alle bewusst nicht
  angebotenen Karten. `PLAYABLE`, `playable_paths()`, `all_paths()`, `BASES`,
  `HISTORICAL_FIXTURES` unveraendert.
- Teil B: die drei Katalogeintraege tragen `"player_visible": false`. Die spielersichtbaren
  Listen in `homebase_screen.gd` (Missions-Auswahl `_populate_mission_selector` und
  `get_operations_snapshot().missions`) ueberspringen solche Eintraege. Suche nach ID
  (`_get_mission_definition_by_id`, `_is_known_mission_id`, Szenario-Aufloesung) bleibt unveraendert.

## Nicht-Ziele
- Kampagne (Orte, Auftragsliste, Szenario-Dateien) bleibt unberuehrt.
- Keine Dateien loeschen/umbenennen/verschieben; kein neuer Inhalt.
- `fireteam_command_drill` und `wall_breach` bleiben als Einsaetze im Heimatbasis-Katalog sichtbar
  (nicht beauftragt; siehe offene Punkte).

## Akzeptanzkriterien
1. `selectable_paths()` entspricht exakt der Allow-List in der genannten Reihenfolge.
2. Jede TEST_ONLY-Karte existiert weiter und besteht die Pruefung von `playable_paths()`
   (bzw. liegt in `PLAYABLE`).
3. Die drei Einsaetze fehlen in Missionsauswahl und Operations-Snapshot, sind aber im Katalog
   per ID auffindbar.
4. Die Kampagnen-Auftragsliste (IDs) ist vor und nach der Aenderung identisch.

## Betroffene Dateien
- scripts/mission/productive_ground_maps.gd
- scripts/meta/meta_layer_flow.gd (nur Katalog-Flag)
- scripts/meta/homebase_screen.gd (zwei Filter)
- scripts/tests/homebase_pads_testmaps_verifier.gd
- docs/IMPLEMENTATION_STATUS.md

## Aufrufer (Karten)
- `multiplayer_lobby_screen.gd` (2x) nutzte bereits `selectable_paths()`: unveraendert.
- `multiplayer_world_runtime.gd` `playable_paths()`: validiert/laedt gegebene Pfade: unveraendert.

## Lokale Pruefung
`homebase_pads_testmaps_verifier`, `map_services_verifier_20261114`, `campaign_maps_content_verifier`
und ausgewaehlte Tests vor/nach der Aenderung (FAIL-Zeilen verglichen).

## Risiken/offene Punkte
- Die Lobby-Karte `fortified_outpost` ist nicht mehr waehlbar, bleibt aber Teil der Regionalkampagne.
- Test `selectable_paths` Reihenfolge: Lobby zeigt jetzt feste Reihenfolge statt Verzeichnisreihenfolge.
- Missions `fireteam_command_drill` und `wall_breach` nutzen alte Karten, sind aber nicht Teil des Auftrags.
