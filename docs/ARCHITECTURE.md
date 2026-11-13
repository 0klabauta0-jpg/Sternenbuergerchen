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
- Neue Hex-Inhalte verwenden den versionierten Vertrag `hex_axial_v1` aus `docs/dev/hex_grid_v1_contract.md`: MapData besitzt die Topologie, Registry/A*/HPA lesen dieselben sechs Nachbarn und SimulationRoot verwendet das physische Bewegungsmass. Bestehende Karten ohne Topologiefeld bleiben ausdruecklich `square8`. Neben dem ersten nativen Basis-Ausschnitt verwendet die regulaere GM01 inzwischen 96×98 echte Hexfelder bis zur sichtbaren Bodenaußenkante (`gm01_frontier_map_contract.md`); das ist keine abgeschlossene Migration aller Altinhalte.
- Datenbasiertes Combat statt Physik-Ballistik

## Wahrheitsquellen und Grenzen
- `SimulationRoot` ist die autoritative Mutationsstelle fuer Gameplay-State.
- Runtime-Komponenten wie `RuntimeLeader`, CombatLoop, Navigation und Taktikcontroller besitzen nur ihren klaren Laufzeitbereich.
- Registries wie `UnitRegistry`, `FTLRegistry` und `TerrainRegistry` sind Lookup- und Index-Schichten. Sie ersetzen breite SceneTree-Suchen, sollen aber keine versteckte zweite Gameplay-Autoritaet werden.
- Contract-/Data-Helper normalisieren Werte fuer mehrere Schichten. Wenn UI und Simulation denselben Wert brauchen, zuerst einen gemeinsamen Contract/Snapshot suchen oder schaffen.
- Die Einzelspieler-Orbitreise besitzt einen eigenen SimulationRoot-gebundenen `SingleplayerSpaceTravelState` fuer Reisephase/Position. Payload, Fuel, Mission und Auftraege verbleiben bei ihren bisherigen Ownern; `orbit_quantum_travel_contract.md` trennt Abheben von Missionsanflug.
- `BasePersonnelRuntime` besitzt die Basispositionen/-wege und Betten der echten Kampagnenpersonen am selben `SimulationRoot`. Ansichten und Padvorschauen leihen dessen Projektion; sie stoppen oder leeren diesen Owner nicht. Basisaktionen und Checkpoints verlangen eine tatsaechlich geerdete Reisephase.
- UI, HUD, Editor und 2.5D/3D-Visuals sind Leseschichten. Sie duerfen Commands ausloesen und Feedback zeigen, aber keinen dauerhaften Parallel-State fuer Mission, Units, Fireteams, Loadouts, Transport oder Combat fuehren.
- Performance-Hotpaths nutzen Dirty-Flags, Batch-Updates, Caches oder `UpdateManager`; sichtbare Progressanzeigen duerfen getaktet werden, ohne Simulation-State zu verlangsamen.

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

- Seit TASK_415 ist der sichtbare Mission-Fireteam-Ausfuehrungspfad der Mission-Tactical-Pfad ueber `MissionTacticalSandboxController`, taktische Resolver, `FireteamMovementController` und `SimulationRoot.enqueue_command()`.
- `RuntimeLeader`/`FTLTask` bleibt fuer Compatibility, Adapter und Basistests erhalten, darf aber keine zweite sichtbare Fireteam-Gameplay-Wahrheit neben dem Mission-Tactical-Pfad werden.

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

## Script-Layout
Der aktuelle Runtime-Kernpfad ist `scripts/core/`, nicht `scripts/simulation/`.

- `scripts/core/`: autoritative Runtime-Kernskripte wie `SimulationRoot`, `DamageModel`, `ObjectiveStatus`, `RespawnManager`, `EventRouter`, `UpdateManager`, LOS/Fog-of-War und gemeinsame Runtime-Lesedaten.
- `scripts/mission/`: Mission-scope Contracts, Adapter und Bridges. Sie normalisieren Mission-Payloads, bauen Commands/Effects oder kapseln Input-/Visualgrenzen, ohne zweite Gameplay-Wahrheit zu speichern.
- `scripts/tactical/`: Fireteam-, Enemy-, Movement-, Cover-, Contact-, Communication- und Order-Resolver. Sie lesen State und erzeugen Plan-/Command-Daten; autoritative Mutationen laufen weiter ueber `SimulationRoot`.
- `scripts/tests/`: Verifier, Harnesses und historisch gewachsene Szenen-Driver. Produktive Logik soll dort nur als Legacy-Bridge bleiben, bis ein eigener Extraction-Task sie verschiebt.
- `scripts/simulation/`: inaktiver/reservierter Pfad. Keine neuen produktiven Skripte dort ablegen, solange kein eigener Migration-Task die Godot-`res://`-Kompatibilitaet absichert.

Details stehen in `docs/dev/runtime_script_layout_contract.md`.

## UI-Regeln
- UI liest State, setzt höchstens Commands
- kein Gameplay-Commit in UI-Callbacks
- Panels nur gezielt aktualisieren

## Multiplayer-Vorbereitung
- server-authoritative vorbereitet
- Testteams für V1
- Host/Join statt Matchmaking

Der aktuelle Review-Kandidat erweitert diese vorhandene Session um gemeinsame
Teamsteuerung für Koop, PvP und Koop-PvP. `MultiplayerWorldRuntime` verwaltet nur
den Lebenszyklus und Index unabhängiger Ortsinstanzen; jeder `SimulationRoot`
behält seine eigene Autorität. Lokaler Kartenwechsel wechselt Präsentation und
Eingabe, ohne andere Spieler umzuschalten oder Einheiten zu transportieren.
Sessionauthentifizierung, geprüftes Manifest und ortsbezogenes READY begrenzen
die Freigabe von Commands und Snapshots. Details und noch laufende Abnahme:
`docs/dev/multiplayer_world_runtime_contract.md` und
`docs/tasks/SHARED_TEAM_MULTIMAP_2026_11_13.md`.

Die produktiven Karten- und Zufallswege des Review-Kandidaten sind in
`docs/dev/productive_hex_rollout_contract.md` inventarisiert: 14 Spielkarten
und drei Basisdateien, gespeicherte Zufallsdomänen und ausdrückliche historische
Square-Kompatibilität. Runtime-Import, Aufnahme und Bewegung laufen über die
vorhandenen Owner. Vollständige Kartenvorbereitung und Gameplay-Abnahme bleiben
eigene Prüfschritte; eine Hexkennzeichnung allein gilt dafür nicht als Beleg.
