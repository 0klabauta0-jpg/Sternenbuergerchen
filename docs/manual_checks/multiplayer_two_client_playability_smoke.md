# Multiplayer Two-Client Playability Smoke

## Zweck
Diese Checkliste prueft den sichtbaren lokalen V1-Mehrspielerpfad mit zwei Godot-Instanzen. Der automatisierte State-Smoke `scripts/tests/task_169_multiplayer_two_client_playability_smoke.gd` prueft zusaetzlich serverseitige Command-Validation, Snapshot-Anwendung und Mission-Result-Spiegelung ohne fragile Zwei-Prozess-Steuerung.

## Vorbereitung
- Nutze zwei lokale Godot-Instanzen mit demselben Projekt.
- Oeffne in beiden Instanzen `res://scenes/tests/lobby_test.tscn`.
- Verwende standardmaessig Port `7777`. Falls der Port belegt ist, stelle in der Session-Komponente denselben freien Port in beiden Instanzen ein.
- Fuer den TASK-169-Smoke nutzt der Join-Peer standardmaessig Rolle `commander`, Team `team_bravo` und Fireteam `red`. Observer-Runden koennen `client_role_id` explizit auf `spectator` setzen.

## Ablauf
1. Instanz A: `Host` ausfuehren.
2. Instanz A: `Ready` aktivieren.
3. Instanz B: `Join` auf `127.0.0.1` und den gewaehlten Port ausfuehren.
4. Instanz B: `Ready` aktivieren.
5. Instanz A: pruefen, dass beide Peers sichtbar sind und `Start Mission` verfuegbar ist.
6. Instanz A: `Start Mission` ausfuehren.
7. In beiden Instanzen pruefen, dass die Mission sichtbar startet und die Session nicht in der Lobby haengen bleibt.
8. Instanz B: einen erlaubten Befehl fuer das eigene Team/Fireteam ausloesen, sobald die Missionseingabe dafuer verfuegbar ist.
9. Instanz A: pruefen, dass der Befehl serverseitig angenommen wird und kein Client-State direkt als Wahrheit uebernommen wird.
10. Instanz B: pruefen, dass Bewegung, Objective-/Contact-Fortschritt und Missionsergebnis ueber Snapshots sichtbar gespiegelt werden.

## Erwartete Debugwerte
- Session-Snapshot enthaelt Peer-IDs `1` und `2`.
- Peer `2` hat im TASK-169-Smoke Team `team_bravo`, Rolle `commander` und Fireteam `red`.
- `SimulationRoot.get_network_command_contract_snapshot()` zeigt mindestens einen akzeptierten Client-Command.
- Ein Payload mit verbotenem State-Key, zum Beispiel `damage`, wird mit sichtbarem Reject-Grund abgelehnt.
- `SimulationRoot.get_multiplayer_snapshot_debug_snapshot()` auf dem Client zeigt den letzten angewendeten Server-Tick und `missing_unit_count == 0`.
- Das Mission-Result wird im letzten Server-State des Clients gespiegelt.

## Hinweise
- Wenn die UI fuer Client-Kommandos in der aktuellen Szene noch nicht vollstaendig erreichbar ist, gilt der sichtbare Host/Join/Missionstart als manueller Teil und der Headless-Smoke als autoritativer Nachweis fuer Client-Command, Reject und Snapshot.
- Fehler bitte mit Port, Peer-Rolle, Session-Snapshot, Command-Debug und Snapshot-Debug notieren.
- Gameplay-Wahrheit bleibt bei `SimulationRoot`; UI und 2.5D-View duerfen nur anzeigen oder Commands senden.
