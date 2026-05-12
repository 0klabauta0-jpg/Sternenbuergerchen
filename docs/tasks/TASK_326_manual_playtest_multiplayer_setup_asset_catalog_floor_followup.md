# TASK_326 - Manual Playtest Multiplayer Setup Asset Catalog Floor Followup

## Ziel
Multiplayer-Lobby und Map-Editor sollen die naechsten Playtest-Funde abdecken: Spielername, Roster-/Team-/Map-Auswahl, ehrlicher Direct-IP-Hinweis und bessere Einsortierung/Flush-Hoehe der importierten Space-/Station-/Nature-Bodenassets.

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Kontext
Im Playtest fehlte ein sichtbarer Spielername und eine klare Auswahl fuer eigenen Roster, Seite/Teammodus und Map. Ausserdem war unklar, ob Direct-IP ueber Router/Internet funktioniert. Im Editor lagen Space-Kit-Assets noch in Sammelgruppen; `station_set_floor_*` und Nature-Boden wirkten weiterhin erhoeht oder als blaue Platzhalter.

## Umfang
1. Multiplayer-Lobby:
   - Neue Setup-Zeile fuer Spielername, lokalen Roster, Spielerseite, Teammodus, Map und Verbindungsmodus.
   - Session-Snapshot und Start-Assignments fuehren diese Lobbydaten mit.
   - Direct-IP-Internet wird als ENet-Direktverbindung mit UDP-Portfreigabe/Firewall/VPN-Hinweis dargestellt.
2. Map-Editor-Katalog:
   - Importierte `space_kit_full`, `space_station_full`, `modular_space` und `factory`-Assets werden in vorhandene Palette-Gruppen einsortiert.
   - Crater/Meteor/Rock landen in Crater/Felsen, Walls/Doors/Gates in Waende, Pipes/Rails/Fahrzeuge/Technik/Deko entsprechend in ihren Gruppen.
3. Bodenhoehen:
   - Nature-Boden ist jetzt primaeres Ground-Surface-Visual statt aufgesetzter Detail-Layer.
   - Station-Set-Floor-Panel-Varianten sowie `station_set_floor_corner` und `station_set_floor_detail` sind Terrain/Surface-Varianten und werden top-anchored gerendert.
   - `modular_floor_raised` ist Terrain/Surface-Variante statt Object-Layer-Prop und sitzt auf Bodenniveau.
   - Terrain-Surface-Modelle respektieren ihre Mapping-Scale, damit Modular-Floors in der erwarteten Groesse erscheinen.
   - Modular-Space-Walls/Gates nutzen die gleiche grobe Scale wie Station-Waende.

## Nicht-Ziele
- Kein Relay-/Matchmaking-/UPnP-System.
- Keine echte Internet-NAT-Durchquerung ohne erreichbaren Host-Port.
- Keine finale Asset-Balance fuer jedes importierte Kit-Objekt.

## Akzeptanzkriterien
- [x] Lobby zeigt Spielername, Roster, Seite, Teammodus, Map und Verbindung.
- [x] Direct-IP-Hinweis nennt UDP-Portfreigabe/Router-Firewall/VPN.
- [x] Session-Snapshot enthaelt `lobby_setup`.
- [x] Importierte Kit-Assets erscheinen in vorhandenen Editor-Gruppen.
- [x] Nature-, Station-Set- und Modular-Raised-Floors rendern ohne erhoehten Detail-Layer.

## Erwartete Dateien
- `scripts/ui/multiplayer_lobby_screen.gd`
- `scripts/multiplayer/multiplayer_session.gd`
- `scenes/ui/multiplayer_lobby.tscn`
- `scripts/terrain/terrain_tile_catalog.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `data/terrain_tile_catalog.json`
- `data/terrain_3d_asset_mapping.json`
- `data/terrain_surface_visual_theme_catalog.json`
- `data/contextual_help_catalog.json`
- `scripts/tests/bugfix_multiplayer_lobby_setup_and_asset_catalog_followup.gd`

## Lokale Pruefung
- [x] `bugfix_multiplayer_lobby_setup_and_asset_catalog_followup.gd`
- [x] `task_231_app_shell_game_setup_integration_and_open_items_review.gd`
- [x] `task_253_nature_ground_surface_editor_palette_pass.gd`
- [x] `task_255_nature_kit_hill_playability_visual_performance_smoke.gd`
- [x] `hill_mechanics_16x16_testmap_verifier.gd`
- [x] `bugfix_map_editor_station_floor_structure_undo.gd`
- [x] `task_266_command_mission_editor_settings_help_content_pass.gd`

## Risiken
- Internet-Multiplayer ist weiterhin Direct-IP. Fuer Spieler ohne Portfreigabe braucht es spaeter Relay, Matchmaking, STUN/TURN oder UPnP.
- Die dynamische Asset-Einsortierung ist heuristisch nach Assetnamen; einzelne Kit-Objekte koennen noch manuell umsortiert werden.
- Exakte optische Balance der Station-/Modular-Bauteile sollte weiter im Editor-Sichttest geprueft werden; Bodenhoehe und Mapping-Scale sind headless abgesichert.
