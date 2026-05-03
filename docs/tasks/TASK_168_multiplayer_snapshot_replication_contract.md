# TASK_168 - Multiplayer Snapshot Replication Contract

## Ziel
Der server-authoritative Snapshot-Pfad wird fuer Multiplayer definiert und minimal umgesetzt: Server sendet kompakte State-Snapshots, Clients rendern/interpolieren nur.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_053_state_synchronisation.md`
- Lies `docs/tasks/TASK_166_multiplayer_authority_command_contract.md`
- Lies `docs/tasks/TASK_167_multiplayer_session_lobby_extraction.md`
- Lies `docs/reviews/strategic_review_ui_assets_multiplayer_2026_05_03.md`
- Pruefe den Git-Status

## Kontext
- `SimulationRoot` baut bereits Tick-State und Unit-Snapshots.
- `TestUnit.apply_remote_snapshot()` existiert.
- `MultiplayerSynchronizer` kann Properties replizieren, aber der Projektkern passt besser zu expliziten Snapshots, weil UI/3D-View nicht die Wahrheit sein darf.

## Umfang
1. Snapshot-Schema festlegen:
   - tick
   - units
   - vital updates
   - objective
   - dropship presence/deploy state
   - contacts, soweit fuer Clientanzeige notwendig
   - mission result
2. Transfer-Modi trennen:
   - haeufige Positions-/Runtime-Snapshots unreliable oder unreliable ordered
   - Mission result, Vital-Sonderfaelle und Start/Load reliable
3. Client-Anwendung:
   - Interpolation nur in Darstellung/Unit-Proxy.
   - keine Client-Mutation von Gameplay-Wahrheit.
4. Snapshot-Debug:
   - letzter Tick
   - verlorene/out-of-order Snapshots
   - apply count
   - missing unit count

## Nicht-Ziele
- Kein Prediction/Rollback.
- Kein Interest-Management fuer grosse Karten.
- Kein Dedizierter Server.
- Kein Matchmaking.

## Architekturregeln
- Server ist SimulationRoot-Authority.
- Clients wenden Snapshots als Spiegelung an.
- 2.5D-View liest weiter aus Snapshots/Runtime-Proxies.

## Akzeptanzkriterien
- Snapshot-Vertrag ist dokumentiert und in Code zentral gebaut.
- Client ignoriert alte Snapshots.
- Client setzt keine authoritativen Commands aus Snapshot-Anwendung ab.
- Bestehende Singleplayer- und Playability-Verifier bleiben gruen.

## Ergebnis
- `scripts/multiplayer/multiplayer_snapshot_contract.gd` definiert und normalisiert das V1-Snapshot-Schema mit `tick`, `units`, `vital_updates`, `objective`, `dropship`, `contacts` und `mission_result`.
- `SimulationRoot` baut Multiplayer-Snapshots jetzt zentral ueber den Contract, sendet State-Snapshots als `unreliable_ordered`, behaelt Vital-Deltas als `reliable` bei und stellt Snapshot-Debug-Zaehler bereit.
- Client-Anwendung laeuft ueber `apply_multiplayer_snapshot()` / `_receive_tick_state()`, ignoriert alte oder doppelte Ticks, zaehlt fehlende Units und enqueued keine Commands oder Effects.
- `MissionCombatLoopDriver` speist Contact-/Mission-Result-Kontext ein; `MissionTacticalSandboxController` speist Dropship-Anzeigezustand ein. Gameplay-Wahrheit bleibt bei `SimulationRoot`.
- `docs/dev/multiplayer_snapshot_replication_contract.md` dokumentiert Schema, Transfer-Modi, Debug und Nicht-Ziele.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_168_multiplayer_snapshot_contract_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [ ] Manueller Zwei-Instanzen-Smoke nach `TASK_167`
- [x] `git diff --check`

## Risiken
- Zu viele Snapshot-Felder erhoehen Bandbreite und Kopplung.
- Zu wenige Felder fuehren zu Client-UI-Luecken. Erst kleine, sichtbare V1-Felder waehlen.
