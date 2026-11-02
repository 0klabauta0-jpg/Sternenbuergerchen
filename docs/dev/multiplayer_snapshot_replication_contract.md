# Multiplayer Snapshot Replication Contract

## Zweck
Der Multiplayer-Snapshot-Pfad ist eine reine Server-zu-Client-Spiegelung. Clients rendern/interpolieren empfangene Daten, setzen aber keine Gameplay-Wahrheit und enqueuen keine Commands oder Effects aus Snapshot-Anwendung.

## Zentrale Komponente
`scripts/multiplayer/multiplayer_snapshot_contract.gd` normalisiert das V1-Schema. `SimulationRoot` baut Snapshots ueber diesen Contract und wendet Remote-Snapshots mit Tick-Guard und Debug-Zaehlern an.

## Snapshot-Schema V1
Pflichtfelder:
- `schema_version`: aktuell `1`
- `snapshot_type`: `state`
- `transfer_mode`: `unreliable` (Chunk-Reihenfolge wird ueber `tick` und `chunk_index` selbst aufgeloest)
- `tick`
- `units`
- `vital_updates`
- `objective`
- `dropship`
- `contacts`
- `mission_result`

Unit-Felder:
- `unit_id`
- `position`
- `visible`
- `runtime_state`
- `fire_mode`
- `vital_state`
- `health`
- `bleedout_ticks`
- `vital_tick`: autoritativer Tick dieser Vitaldaten; gemeinsame Ordnung mit Reliable-Vital-Deltas.
- `tactical_stance`
- `tactical_stance_revision`
- `fireteam_id`

Anzeige-/Mission-Felder:
- `objective`: Owner, Capture-Fortschritt, Capturing-Team, Contest-State, optional Position/Radius.
- `dropship`: Sichtbarkeit, State, LZ, Position, Zielposition, Fortschritt.
- `contacts`: Fireteam, Contact-Unit, Team, Detection-State, letzte bekannte Position, letzter Tick.
- `mission_result`: Ergebnis, Gewinnerteam, Win-Condition, Dauer und optionale Teamstates.

## Transfer-Vertrag
- State-Snapshots: `unreliable` als komprimierte, maximal 1000 Byte grosse Nutzlast-Chunks ueber `SimulationRoot._receive_tick_state_chunk`. Chunks duerfen in beliebiger Reihenfolge eintreffen; der Client setzt nur vollstaendige Ticks zusammen und gibt danach denselben Dictionary-State an `apply_multiplayer_snapshot()` weiter.
- Vital-Deltas: `reliable` ueber `SimulationRoot._receive_vital_state_updates`.
- Mission-Result: `reliable`, bleibt fuer bestehende Combat-Result-RPCs und wird zusaetzlich im Snapshot-Schema gespiegelt.
- Start/Load: `reliable`, bleibt bei der Session-/Lobby-Schicht aus TASK_167.

### Transportuebergreifende Vital-Reihenfolge (Review 2026-11-02)
- Jeder neue Unit-Vitalsnapshot und jedes Reliable-Vital-Delta traegt `vital_tick`.
  Die drei Vitalwerte werden gemeinsam angewendet, nur wenn dieser Tick neuer
  als der zuletzt angewendete Vital-Tick derselben Unit ist. Ein gleicher Tick
  ist ein Duplikat. Die Markierung ist Receive-Metadatum, keine Gameplay-Wahrheit.
- Alte Snapshot-Daten ohne `vital_tick` nutzen den umgebenden Snapshot-Tick.
  Reliable-Daten ohne Version duerfen bereits geordnete Vitaldaten nicht ersetzen.
- Ein Snapshot mit aelteren Vitaldaten darf weiterhin neuere Positions-/Runtime-
  Daten tragen. Seine Vitalwerte bleiben auf dem bereits angewendeten Unitstand;
  andere Units haben jeweils ihre eigene Versionsgrenze.
- Positions-only-Snapshots verbrauchen keinen Vital-Tick. Neuere Heilungen und
  Respawns bleiben gueltig. Delta-Dedupe vergleicht Vitalinhalte ohne Tick, damit
  unveraenderte Units nicht jeden Simulationstick ein Reliable-Paket erzeugen.

## Anwendung auf Clients
`SimulationRoot.apply_multiplayer_snapshot()`:
- normalisiert den Snapshot ueber den Contract
- ignoriert Snapshots mit `tick <= last_applied_tick`
- wendet Unit-Snapshots nur auf bekannte Units an
- zaehlt fehlende Units, ohne SceneTree-Vollscan
- wendet Objective-State als Spiegelung an
- enqueued keine Commands oder Effects

Debug:
- `last_applied_tick`
- `apply_count`
- `out_of_order_count`
- `missing_unit_count`
- `last_reject_reason`
- `transfer_contract`
- `get_snapshot_transport_debug_snapshot()`: Chunkzahl, maximale Chunk-Nutzlast, Raw-/Wire-Bytes, Reassembly- und Fehlerzaehler.

## Einbindung bestehender Mission
- `MissionCombatLoopDriver` publiziert Contacts und Mission-Result in den Snapshot-Kontext.
- `MissionTacticalSandboxController` publiziert Dropship-Anzeigezustand in den Snapshot-Kontext.
- `SimulationRoot` bleibt die zentrale Stelle, die den finalen Multiplayer-Snapshot baut.

## Nicht enthalten
- Prediction/Rollback
- Interest Management
- dedizierter Server
- Matchmaking
- Client-Autoritaet fuer Position, Combat, Objective oder Dropship
