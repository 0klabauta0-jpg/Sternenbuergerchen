# ARCHITECTURE

## Grundsatz
Simulation, Darstellung und UI strikt trennen.

## Zentrale Regeln
- Gameplay-Wahrheit liegt nicht im UI
- State-Mutationen laufen zentral über `SimulationRoot`
- Kommunikation bevorzugt über Signale / EventRouter
- Keine SceneTree-Vollscans im Hotpath
- Registries statt `get_tree().get_nodes_in_group()` im Laufzeitkern
- Dirty-Flags statt per-frame Komplett-Refresh
- Out-of-View-Simulation vereinfacht, aber konsistent
- Navigation ueber A*-Pfadsuche auf dem Iso-Grid (walkable, Hoehenunterschied, Surface-Kosten); Geradlinien-Fallback ohne TerrainRegistry
- Datenbasiertes Combat statt Physik-Ballistik

## Kernbausteine
### SimulationRoot
- einzige autoritative Stelle für Gameplay-State-Änderungen
- verarbeitet Command Queue
- läuft in `_physics_process()`

### RuntimeLeader / FTL
- eigene Node-Komponente
- interpretiert Commander-Befehle
- kommuniziert über Signale / Router
- keine direkten UI-Abhängigkeiten

### EventRouter
- entkoppelt Systeme
- sammelt wichtige Gameplay-Signale

### Registries
- `UnitRegistry`
- `FTLRegistry`
- optional `TileRegistry`

### UpdateManager
- dirty-basierte Batch-Verarbeitung
- keine Vollupdates aller Units pro Frame

## UI-Regeln
- UI liest State, setzt höchstens Commands
- kein Gameplay-Commit in UI-Callbacks
- Panels nur gezielt aktualisieren

## Multiplayer-Vorbereitung
- server-authoritative vorbereitet
- Testteams für V1
- Host/Join statt Matchmaking
