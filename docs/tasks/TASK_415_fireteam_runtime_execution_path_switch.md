# TASK_415 - Fireteam Runtime Execution Path Switch

## Ziel / Problem

Der Fireteam-Stand hat zwei historisch relevante Command-Pfade: den aelteren `RuntimeLeader -> FTLTask -> UnitCommand`-Pfad und den sichtbaren Mission-Tactical-Pfad ueber `MissionTacticalSandboxController`, `FireteamMovementController` und `SimulationRoot`. Fuer die weitere Fireteam-Arbeit soll der sichtbare Mission-Tactical-Pfad offiziell als Primaerpfad gelten.

## Sinn / Ursache

Die Playtest-Funktionen fuer Rush, Bounding, Caterpillar, Postures, Fireteam-Mini-Cards, AreaOrders, Waypoints und Map-Overlays laufen bereits ueber den Mission-Tactical-Pfad. Ohne explizite Entscheidung droht neue Fireteam-Logik versehentlich wieder als zweiter FTLTask-only-Pfad zu entstehen.

## Umfang

- Mission-Tactical als offiziellen sichtbaren Fireteam-Ausfuehrungspfad dokumentieren.
- `RuntimeLeader`/`FTLTask` als Legacy-/Compatibility-/Adapter-Pfad begrenzen.
- Einen kleinen Contract-Helper fuer den Runtime-Pfad ergaenzen.
- `MissionTacticalSandboxController` stellt einen Headless-Snapshot zum aktiven Fireteam-Runtime-Pfad bereit.
- HTML-Uebersicht und Architekturstatus auf die Entscheidung aktualisieren.
- Verifier prueft Contract, Snapshot und Doku-Marker.

## Nicht-Ziele

- Kein Rewrite der GO-, Waypoint- oder AreaOrder-Logik.
- Kein Entfernen von `RuntimeLeader`, `FTLTask`, `FTLRegistry` oder alten Verifiern.
- Keine neue Movement-, Security- oder KI-Semantik.
- Keine neue UI-Wahrheit und keine direkte Unit-State-Mutation in UI-Skripten.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/dev/commander_fireteam_delegation_contract.md`
- `docs/dev/multi_fireteam_plan_contract.md`
- `docs/dev/fireteam_leader_tactical_progression.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_404_fireteam_movement_posture_bridge.md`
- `docs/tasks/TASK_414_fireteam_overview_html.md`

## Akzeptanzkriterien

- [x] Ein Contract beschreibt Mission-Tactical als aktiven sichtbaren Fireteam-Ausfuehrungspfad.
- [x] Legacy-FTLTask-Arbeit ist auf Compatibility, Adapter und bestehende Basistests begrenzt.
- [x] `MissionTacticalSandboxController` liefert einen pruefbaren Runtime-Pfad-Snapshot.
- [x] HTML-Uebersicht nennt TASK_415 und markiert Pfad B als offiziell.
- [x] Headless-Verifier prueft Contract, Controller-Snapshot und Doku.

## Betroffene Dateien

- `docs/tasks/TASK_415_fireteam_runtime_execution_path_switch.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/reports/fireteam_overview.html`
- `docs/ARCHITECTURE.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/tactical/fireteam_runtime_execution_path_contract.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_415_fireteam_runtime_path_switch.gd`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_415_fireteam_runtime_path_switch.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_404_fireteam_movement_posture_bridge.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- `MissionTacticalSandboxController` liegt historisch noch unter `scripts/tests`. Das wird mit dieser Entscheidung nicht verschlimmert, bleibt aber ein klarer Extraktions-Follow-up vor groesserem Runtime-Ausbau.
- Alte Command-Flow-Verifier duerfen weiter existieren, sollen aber keine neue sichtbare Fireteam-Gameplay-Wahrheit aufbauen.
