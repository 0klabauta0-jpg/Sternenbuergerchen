# Fireteam Runtime Execution Path Contract

Status: TASK_415

## Zweck

Dieser Contract macht den aktuellen Mission-Tactical-Pfad zum offiziellen sichtbaren Fireteam-Ausfuehrungspfad.

Der aktive Laufzeitpfad ist:

`MissionTacticalSandboxController -> FireteamMovementController / FireteamSecurityController / tactical resolver -> UnitCommand dictionary -> SimulationRoot.enqueue_command()`

Der alte `RuntimeLeader -> FTLTask -> UnitCommand`-Pfad bleibt vorhanden, aber nur als Legacy-, Compatibility- und Adapter-Pfad. Neue sichtbare Mission-Fireteam-Features sollen nicht als separater FTLTask-only-Pfad entstehen.

## Aktiver Pfad

Der Mission-Tactical-Pfad besitzt folgende Verantwortungen:

- `MissionTacticalSandboxController` verwaltet Auswahl, Waypoints, AreaOrders, aktive Phasen, Command-HUD-Snapshots und GO-Ausloesung.
- `FireteamBehaviorResolver`, `MultiFireteamPlanResolver`, `TacticalStanceController` und verwandte Resolver erzeugen Plan- und Profilentscheidungen.
- `FireteamMovementController` erzeugt pro Fireteam-Mitglied konkrete `UnitCommand`-Dictionaries fuer Rush, Bounding, Caterpillar, Postures und Zielbewegung.
- `FireteamSecurityController` erzeugt Security-/Overwatch-Snapshots und deckt die sichtbaren Sicherheitsmodi ab.
- `SimulationRoot` bleibt die autoritative Runtime-Mutationsstelle.

## Autoritaetsgrenzen

| Schicht | Darf schreiben | Darf lesen | Darf nicht |
| --- | --- | --- | --- |
| Mission UI / HUD | Auswahl, CommanderIntent, Waypoints, AreaOrders, Anzeige-Snapshots | Mission- und Runtime-Snapshots | Unit-State als Wahrheit setzen |
| Mission-Tactical Controller | Planungszustand, aktive Waypoint-/AreaOrder-Ausfuehrung | Fireteam-Units, Resolver, Runtime-Snapshots | SimulationRoot umgehen |
| Tactical Resolver | FireteamExecutionPlan, Movement-/Security-Profile, UnitAction-Konventionen | CommanderIntent, FTL-Snapshot, Terrain/Kontakt | Gameplay-State direkt mutieren |
| Fireteam Movement/Security | UnitCommand-Dictionaries und Security-Snapshots | Fireteam-Mitglieder, Profile, Simulationsroot-Queue | Unit-State vor dem SimulationRoot-Tick mutieren oder dauerhafte UI-Wahrheit erzeugen |
| SimulationRoot | Autoritativen Unit-/Combat-/Objective-State | validierte Commands und Effects | UI- oder Snapshot-Logik besitzen |

## Legacy-Policy

`RuntimeLeader`, `FTLTask`, `CommandToFTLTaskTranslator` und `FTLRegistry` bleiben erlaubt fuer:

- bestehende Basistests der urspruenglichen Command-Architektur,
- Compatibility-Adapter,
- Migration/Referenz beim spaeteren Aufraeumen,
- Lookup-/Index-Rollen ohne versteckte Gameplay-Mutation.

Sie sollen nicht mehr erweitert werden als:

- alleiniger neuer Pfad fuer sichtbares Mission-Fireteam-Gameplay,
- zweiter paralleler Bewegungs-/Security-Orchestrator,
- UI-nahe Quelle fuer Unit- oder Mission-Wahrheit.

## Snapshot

`scripts/tactical/fireteam_runtime_execution_path_contract.gd` definiert den maschinenlesbaren Contract.

`MissionTacticalSandboxController.get_fireteam_runtime_execution_path_snapshot()` liefert den Headless-Pruefpunkt fuer:

- `active_path_id = mission_tactical`,
- `legacy_policy = compatibility_adapter_only`,
- `runtime_authority = SimulationRoot`,
- `simulation_enqueue_method = SimulationRoot.enqueue_command`,
- `ui_sets_unit_truth = false`,
- `snapshots_are_truth = false`.

## Migrationsregeln

- Neue sichtbare Fireteam-Features docken an den Mission-Tactical-Pfad an.
- Neue Runtime-Mutationen laufen ueber `SimulationRoot`.
- Producer reihen Commands nur ein. Command-Token und Supersession leitet der
  `SimulationRoot` aus Queue- und Commit-Status ab; ein Producer setzt keinen
  UnitCommand als Vorabmutation.
- Snapshots bleiben read-only und duerfen UI/Tests versorgen, aber keine Gameplay-Wahrheit bilden.
- Wenn RuntimeLeader wieder eine Rolle im sichtbaren Pfad bekommt, dann nur als Adapter um den Mission-Tactical-Pfad, nicht als zweiter Besitzer.
- Vor groesserem Ausbau soll der historisch benannte `MissionTacticalSandboxController` aus `scripts/tests` in einen Produktionspfad extrahiert werden.

## Nicht-Ziele

- Kein Entfernen alter Architektur-Bausteine.
- Kein neuer Pathfinding-, Combat- oder Security-Algorithmus.
- Kein Multiplayer-Rewrite.
- Keine UI-Neugestaltung.
