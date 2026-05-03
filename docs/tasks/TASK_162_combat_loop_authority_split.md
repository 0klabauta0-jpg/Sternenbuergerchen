# TASK_162 - Combat Loop Authority Split

## Ziel
Der Combat-/Objective-/Wave-Driver soll eine klare produktive Runtime-Grenze bekommen und seine autoritativen State-Mutationen explizit ueber Simulation/Effects fuehren. Das bereitet Multiplayer vor, ohne Combat-Balancing zu veraendern.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_118_combat_entscheidungen_aus_mission_driver_herausloesen.md`
- Lies `docs/tasks/TASK_119_seeded_combat_rng_und_roll_override_begrenzen.md`
- Lies `docs/reviews/strategic_review_ui_assets_multiplayer_2026_05_03.md`
- Pruefe den Git-Status

## Kontext
- `scripts/tests/mission_combat_loop_driver.gd` liefert produktive Combat-, Objective-, Contact-, Wave- und Playability-Snapshots.
- Er besitzt bereits RPCs fuer Remote-Events und Missionsergebnis.
- Fuer server-authoritative Multiplayer muss klar sein, welche Daten Ergebnis der Simulation sind und welche nur UI-Events darstellen.

## Umfang
1. Produktivpfad festlegen, z.B. `scripts/mission/mission_combat_loop_driver.gd` oder kleinere Komponenten.
2. Snapshot-Vertrag dokumentieren:
   - Playability-Snapshot
   - Objective-State
   - Contact-State
   - Mission-Result
   - Read-only UI-Events
3. Mutationen pruefen:
   - Damage, Heal, Bleedout, Respawn, Dropship-Deploy bleiben/werden `SimulationRoot`-Effects.
   - Objective-Progress wird nicht in UI dupliziert.
4. RPCs vorlaeufig kapseln:
   - Remote-Event-Ausgabe in eine kleine Bridge verschieben oder klar markieren.
   - Keine neuen Netzwerkfeatures in diesem Task.

## Nicht-Ziele
- Kein neues Treffer- oder Balancingmodell.
- Kein kompletter Combat-Rewrite.
- Kein Client Prediction.
- Kein Multiplayer-Smoke.

## Architekturregeln
- Combat-Entscheidungen duerfen Daten erzeugen, aber authoritativer Gameplay-State wird ueber Simulation/Effects committed.
- UI liest Snapshots.
- Tests duerfen Testpayloads wie `roll_override` nutzen; Produktivpfade nicht.

## Akzeptanzkriterien
- Combat-/Objective-Runtime liegt in einem produktiven Pfad oder ist sauber in produktive Komponenten getrennt.
- Multiplayer-relevante Snapshots sind als Dictionary-Vertrag dokumentiert oder in kleinen Buildern gekapselt.
- Bestehende Combat-/Objective-/Playability-Verifier bleiben gruen.
- Kein neues Verhalten im Kampfbalancing.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_162_combat_authority_contract_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_119_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_118_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`

## Ergebnis
- `scripts/mission/mission_combat_authority_contract.gd` dokumentiert und kapselt den Playability-, Objective-, Contact- und Mission-Result-Vertrag sowie die erlaubten autoritativen `SimulationRoot`-Effect-Typen.
- `scripts/mission/mission_combat_remote_event_bridge.gd` kapselt Combat-Remote-Events als `read_only`-UI-Payloads; die bestehenden RPCs bleiben auf dem Driver, geben aber nur Anzeige-Events weiter.
- `MissionCombatLoopDriver.get_playability_snapshot()` und `_build_mission_result()` nutzen den neuen produktiven Vertrag, ohne Kampfbalancing oder Snapshot-Key-Namen zu aendern.
- `docs/dev/combat_loop_authority_contract.md` haelt die Runtime-Grenze fuer kommende Multiplayer-Tasks fest.

## Risiken
- Der Driver ist fachlich dicht verdrahtet. Erst Grenzen sichtbar machen, dann Verhalten veraendern.
- Snapshot-Keys sind bereits von UI/Verifiern genutzt; Umbenennungen vermeiden.
