# TASK_1099 - Connected Interaction Snapshot Payload Budget

## Ziel / Problem
Der seit TASK_1091 replizierte `mission_interactions`-State kann mit mehreren Fireteams und gleichzeitig aktiven Stationspunkten wachsen. Vor weiteren Netzwerkfeatures braucht dieser Teil des bestehenden State-Snapshots ein messbares Raw-/Wire-/Chunk-Budget.

## Sinnhaftigkeit / Ursache
TASK_1098 begrenzt den lokalen HUD-Refresh, misst aber nicht die Kosten auf der Host-Client-Grenze. Der bestehende Snapshot-Transport komprimiert und chunkt bereits den gesamten autoritativen State. Eine eigene Delta-Replikation nur fuer Interaktionen waere ohne Messbefund zusaetzliche Architektur.

## Umfang
- `MultiplayerSnapshotContract.build_serialization_metrics()` um reale `var_to_bytes`-/ZSTD-/Chunk-Metriken erweitern.
- Interaction-Anzahl in den Feldzaehlern sichtbar machen.
- Leere sowie 1, 8, 32 und 64 parallele Interaction-States deterministisch messen.
- Fuer 64 States maximal 8 KiB zusaetzliche Wire-Daten gegenueber der leeren Baseline und maximal 8 zusaetzliche 1000-Byte-Chunks erlauben.
- Serialisierung und Kompression fuer den groessten Probe-Snapshot unter einem breiten lokalen 50-ms-Guard halten.

## Nicht-Ziele
- Kein neues RPC oder zweites Interaction-Protokoll.
- Keine Delta-/Interest-Management-Implementierung ohne Budgetverletzung.
- Keine Aenderung an Gameplay-, Gate-, Arrival-/Hold- oder HUD-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/dev/multiplayer_authority_command_contract.md`
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK_1098_connected_interaction_progress_performance_budget.md`

## Akzeptanzkriterien
- Metriken melden Raw-Bytes, Wire-Bytes, Kompression, Chunkzahl und Interaction-Anzahl.
- 1/8/32/64 States bleiben deterministisch normalisiert und innerhalb der Budgets.
- Conditional ZSTD/Raw-Fallback und umgekehrte Eingabereihenfolge ergeben dieselben Runtime-equivalenten Payloadkosten.
- Die Metrik ist read-only und erzeugt keine Commands, Effects oder RPCs.
- Bestehende Snapshot- und Interaction-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/multiplayer/multiplayer_snapshot_contract.gd`
- `scripts/tests/task_1099_connected_interaction_snapshot_payload_budget.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- aktueller HTML-Iststandsbericht

## Lokale Pruefung
- `task_1099_connected_interaction_snapshot_payload_budget.gd`
- `task_1091_connected_station_route_two_player_command_playtest.gd`
- `task_1098_connected_interaction_progress_performance_budget.gd`
- `git diff --check`

## Risiken / offene Punkte
Die lokale ZSTD-Zeit ist maschinenabhaengig; der 50-ms-Guard ist deshalb bewusst breit. Erst eine belegte Budgetverletzung rechtfertigt einen Folge-Task fuer Delta- oder Interest-Management.
