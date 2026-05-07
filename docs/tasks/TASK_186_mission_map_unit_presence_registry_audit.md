# TASK_186 - Mission Map Unit Presence and Registry Audit

## Ziel
Die Mission Map bekommt einen expliziten Audit, der prueft, ob alle erwarteten NPCs wirklich existieren, sichtbar sind, registriert werden und in den relevanten Snapshots auftauchen.

Der Task betrifft friendly Spieler-NPCs und Enemy-NPCs. Das ist auch Multiplayer-Vorarbeit: Was lokal nicht eindeutig in Registry und Snapshot steht, kann spaeter nicht sauber repliziert werden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_158 - Editor-to-Live Mission Validation
- TASK_159 - 2.5D Editor and Mission Primary View
- TASK_160 - Tactical Mission Playability Smoke
- TASK_166 - Multiplayer Authority Command Contract
- TASK_168 - Multiplayer Snapshot Replication Contract
- TASK_171 bis TASK_176 - NPC-Visuals und Loadout-Attachments

## Kontext
Die Live-Mission spiegelt Units in der 2.5D-View, haelt Gameplay aber weiter in `SimulationRoot`, `UnitRegistry`, `FTLRegistry`, `MissionCombatLoopDriver` und TacticalController. Dieser Audit soll verhindern, dass friendly oder enemy Units nur visuell existieren oder nur im Testsetup stehen, aber nicht in den autoritativen Datenpfaden.

## Umfang
1. Erwartete Units definieren:
   - Friendly-Fireteams aus aktuellem Mission-/FOB-Setup.
   - Enemy-Units aus Scenario/Waves/Patrol-Bindings.
   - Unit-ID, Team-ID, Role/Loadout, Vital-State, Node2D-Anker, 2.5D-Proxy.
2. Registry-Audit:
   - Jede erwartete Unit steht in `UnitRegistry`.
   - Friendly-Fireteams stehen in `FTLRegistry` oder im aktuellen Fireteam-Snapshot.
   - Enemy-Units haben Team-ID, Vital-State und Combat-Registrierung.
3. Mission-Map-Audit:
   - Jede registrierte Unit hat genau einen sichtbaren 2.5D-Proxy oder einen expliziten Missing-Visual-Diagnoseeintrag.
   - Hidden/Inactive Enemy-Waves werden nicht als aktive Units gezaehlt, bevor ihre Welle startet.
   - Spawn, Dropship-Deploy und Enemy-Wave-Start werden getrennt geprueft.
4. Snapshot-Audit:
   - Tactical snapshot, 2.5D snapshot und Multiplayer snapshot enthalten dieselben aktiven Unit-IDs.
   - Keine UI-only Unit-ID.
   - Keine Visual-only Unit-ID.
5. Verifier:
   - Startet die Mission in einem kleinen Setup.
   - Prueft initiale Friendlys, initiale Enemies, nach Dropship-Deploy und nach Enemy-Wave-Start.
   - Prueft, dass Unit-Proxies nicht doppelt angelegt werden.

## Nicht-Ziele
- Keine neue KI.
- Keine neue Spawn-Logik.
- Keine neuen NPC-Modelle.
- Keine Aenderung an Combat-Balance.
- Keine Multiplayer-Netzwerkimplementierung.

## Akzeptanzkriterien
- [x] Alle aktiven Friendly- und Enemy-NPCs existieren als autoritative Runtime-Units.
- [x] Alle aktiven Units sind in `UnitRegistry` und den relevanten Snapshots auffindbar.
- [x] Jede aktive Unit hat einen sichtbaren 2.5D-Proxy oder eine klare Missing-Visual-Diagnose.
- [x] Hidden/Inactive Enemy-Waves werden nicht als aktive Units fehlgezaehlt.
- [x] Multiplayer-Snapshot und lokale Mission-Snapshots widersprechen sich nicht bei Unit-IDs, Team-IDs und Vital-State.
- [x] Ein TASK_186-Verifier deckt Spawn, Deploy, Enemy-Wave und Proxy-Duplizierung ab.

## Erwartete Dateien
- `scripts/tests/mission_test_setup.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/mission/mission_primary_view_bridge.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/multiplayer/multiplayer_snapshot_contract.gd`
- `scripts/tests/task_186_mission_map_unit_presence_registry_audit.gd`
- `docs/tasks/TASK_186_mission_map_unit_presence_registry_audit.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_186_mission_map_unit_presence_registry_audit.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd`
- [x] `git diff --check`

## Ergebnis
- `SimulationRoot` schreibt `team_id` und `fireteam_id` in Unit-Snapshots; `MultiplayerSnapshotContract` transportiert `team_id` weiter.
- `TerrainMap3DView` liefert Proxy-ID-Diagnostik (`unit_proxy_ids`, `visible_unit_proxy_ids`, `missing_unit_model_ids`, `unit_proxy_state_by_id`) fuer den Audit.
- `MissionTacticalSandboxController`, `MissionCombatLoopDriver` und `MissionTestSetup` liefern explizite Presence-Audit-Snapshots, ohne Gameplay-State in UI-Logik zu verschieben.
- `scripts/tests/task_186_mission_map_unit_presence_registry_audit.gd` prueft initialen Spawn, Dropship-Deploy, zweiten Enemy-Wave-Start, Registry/Snapshot-Konsistenz und Proxy-Duplizierung.

## Risiken
- Ein Unit-Presence-Audit darf nicht anfangen, fehlende Units in der UI zu erfinden. Fehlende Units muessen im autoritativen Setup gefixt oder bewusst als inactive markiert werden.
- Enemy-Waves brauchen klare Aktivierungsregeln, sonst zaehlt der Audit absichtlich versteckte Gegner falsch.

## Naechster Schritt
Nach TASK_186 ist klar, welche NPCs wirklich aktiv sind. Darauf kann TASK_187 den Mindestabstand fuer friendly und enemy Units absichern.
