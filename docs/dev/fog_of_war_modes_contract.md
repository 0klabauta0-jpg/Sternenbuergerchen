# Fog of War Modes Contract

Stand: 2026-05-06

## Ziel
Der Fog-of-War-Vertrag trennt Terrainwissen, aktuelle Sicht und letzte bekannte Kontakte. UI und 2.5D-Visualisierung duerfen diesen Zustand lesen, aber nicht als Gameplay-Wahrheit setzen.

## Mode-IDs
Stabile IDs aus `scripts/core/fog_of_war_mode_contract.gd`:

- `off`
- `known_terrain`
- `unexplored_blackout`

Default ist `known_terrain`, weil taktische Lesbarkeit wichtiger ist als sofortiger Blackout.

## Mode-Verhalten
`off`:
Terrain, Units, Marker und Gegner folgen normalen Debug-/Gameplay-Regeln. Es gibt keine unbekannten Tiles.

`known_terrain`:
Das Terrain ist voll bekannt und lesbar. Dynamische Targets, Gegner, VFX und Events folgen aktueller Sicht oder bewusst gespeicherten letzten bekannten Kontakten.

`unexplored_blackout`:
Aktuell sichtbare Tiles sind hell sichtbar. Bereits erkundete Tiles bleiben als Erinnerung sichtbar. Nie gesehene Tiles sind `unknown` und sollen spaeter schwarz dargestellt werden.

## Getrennter Zustand
`FogOfWarSystem.build_team_state_snapshot(team_id)` liefert:

- `terrain_knowledge.visible_tile_ids`
- `terrain_knowledge.explored_tile_ids`
- `current_visibility.visible_target_ids`
- `current_visibility.visible_event_ids`
- `last_known_contacts`

Diese Felder duerfen nicht zusammengelegt werden. Terrain-Walkability, LOS, Cover und Combat bleiben in Terrain-/LOS-/Simulation-Systemen.

## Settings
`scripts/ui/game_settings_contract.gd` bereitet den Gameplay-Settings-Wert `fog_of_war_mode` vor. Er wird in derselben Config-Datei wie bestehende Settings gespeichert, aber unter der Section `gameplay`.

Beispiel:

```ini
[gameplay]
fog_of_war_mode="known_terrain"
```

## Multiplayer
FoW ist Team-/Peer-scoped:

- `FogOfWarSystem.set_peer_team(peer_id, team_id)` mappt Peer auf Team.
- `build_peer_state_snapshot(peer_id)` liefert nur den FoW-Zustand dieses Teams.
- Host/Server bleibt autoritativ fuer sichtbare Enemy-/Event-Snapshots.
- Clients duerfen versteckte Gegner nicht aus Snapshots rekonstruieren.

## Beispiele
32x32 `known_terrain`:
Alle 1024 Tiles sind als Terrain lesbar. Gegner ausserhalb aktueller Sicht werden nicht als aktuelle Targets geliefert; nur letzte bekannte Kontakte duerfen angezeigt werden.

64x64 `unexplored_blackout`:
Nur aktuell sichtbare Tiles sind `visible`. Bereits betretene oder beobachtete Tiles sind `explored`. Alle anderen Tiles bleiben `unknown`.

## Grenzen
Dieser Task baut noch keine 2.5D-Overlay-Visualisierung und keine neue Stealth-Balance. TASK_224 setzt Tile-Sicht, Hoehenlinien, Deckung und LOS konkret um; TASK_225 visualisiert die Modi.

## LOS-Reichweitenpruefung R7, 08.11.2026
Punktabfragen mit TerrainRegistry delegieren an den vorhandenen vollstaendig
geschuetzten Terrain-LOS-Einstieg. Dieser prueft die unveraenderte Distanz und
Reichweitengrenze einmal vor jeder Traversierung. Ohne Registry prueft der
Punkt-Einstieg weiter selbst. Direkte Terrainabfragen bleiben vollstaendig
geschuetzt; negative Reichweite bleibt unbegrenzt. Es entsteht kein Cache.
Hex-/Square-Metrik, Occlusion, Runtime-Tuerblocker, Sichtweite, Fogbudget,
Kandidatenfolge und atomare Full-/Dirty-Veröffentlichung bleiben erhalten.
Der separate Fog-Reichweitenguard vor dem LOS-Aufruf bleibt bestehen.
