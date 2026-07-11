# TASK_1101 - Connected Interaction Reconnect State Recovery

## Ziel / Problem
Ein Client-Disconnect waehrend einer laufenden Mission setzt derzeit auf dem Host den Session-Missionsstatus zurueck. Ein Rejoin startet deshalb keine Client-Mission und kann den aktuellen Interaction-/Gate-State nicht wiederherstellen.

## Sinnhaftigkeit / Ursache
Die Host-Mission bleibt als Runtime-Instanz aktiv, waehrend `MultiplayerSession._on_peer_disconnected()` `_mission_started` auf false setzt. Beim spaeteren Peer-Connect wird nur ein Lobby-Snapshot gesendet; der Rejoin-Peer erhaelt keinen Mission-Handoff und die neue Peer-ID wird nicht in die aktive `SimulationRoot`-Zuweisung uebernommen.

## Umfang
- Laufende Host-Mission bei Client-Disconnect erhalten.
- Host-autorisierte Missionsidentitaet auf die neue Peer-ID uebertragen und Assignment-Saetze vollstaendig ersetzen.
- Reconnect-Slot mit zufaelligem 256-Bit-Token vor fremdem First-Connect-Hijack schuetzen.
- Token getrennt von allen publizierten Peer-/Session-/Assignment-Daten halten.
- Rejoin-Peer bei aktiver Mission gezielt ueber den bestehenden Mission-Start-RPC in eine neue Client-Mission bringen.
- Die echte Produkt-Lobby statt nur des historischen Testadapters als MissionHost verwenden.
- Ersten vollen Host-Snapshot zur Wiederherstellung von Interaction-/Gate-/HUD-State nutzen.
- Echten ENet-Disconnect/Rejoin mit neuer Peer-ID pruefen.

## Nicht-Ziele
- Kein Host-Migration-System.
- Kein Persistieren einer beendeten Serverinstanz.
- Kein Rollback/Prediction und kein zweiter Mission-State im Lobby-UI.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/dev/multiplayer_authority_command_contract.md`
- `docs/tasks/TASK_1100_connected_interaction_snapshot_loss_jitter_resilience.md`

## Akzeptanzkriterien
- Client-Disconnect beendet die Host-Mission nicht.
- Host-Interaction-State laeuft waehrend der Trennung weiter.
- Rejoin erzeugt eine neue Client-Mission und aktualisierte Peer-/Fireteam-Zuweisungen.
- Client-Setup kann waehrend der Mission die host-autorisierte Team-/Rollen-/Fireteam-Identitaet nicht umschreiben.
- Alte Peer-Rollen sind nach Rejoin weder in Host noch Client vorhanden.
- Falscher Reconnect-Token erhaelt weder Mission-Handoff noch Assignment-Slot.
- Malformed Token wird ebenso abgewiesen; der wartende Peer ist ohne globalen Transportstopp einzeln blockiert.
- Snapshot-Transport wird erst nach reliable Mission-Ready-ACK fuer die neue Peer-ID freigegeben.
- Combat-Result beendet Mission und Session auf Host und Client und stellt beide Lobby-Panels wieder her.
- Der erste aktuelle Full-State stellt Completed Interactions und Gates wieder her.
- Rejoin erzeugt keine lokalen Gameplay-Commands oder Effects.

## Betroffene Dateien
- `scripts/multiplayer/multiplayer_session.gd`
- `scripts/core/simulation_root.gd`
- `scripts/ui/multiplayer_lobby_screen.gd`
- `scripts/tests/lobby_test_screen.gd`
- `scripts/tests/task_1101_connected_interaction_reconnect_state_recovery.gd`
- Contract, Status, Roadmap und HTML-Iststandsbericht

## Lokale Pruefung
- `task_1101_connected_interaction_reconnect_state_recovery.gd`
- `task_167_multiplayer_session_verifier.gd`
- `task_1091_connected_station_route_two_player_command_playtest.gd`
- `task_1100_connected_interaction_snapshot_loss_jitter_resilience.gd`
- `git diff --check`

## Risiken / offene Punkte
Reconnect behaelt dieselbe host-autorisierte Client-Team-/Fireteam-Vorgabe und erhaelt eine neue ENet-Peer-ID. Der Token ist nur fuer die laufende lokale Session gedacht, nicht als Account-Authentifizierung. Ein Rejoin nach Host-Abbruch bleibt ausserhalb dieses Tasks.
