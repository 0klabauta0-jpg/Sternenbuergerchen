# TASK_167 - Multiplayer Session and Lobby Extraction

## Ziel
Der bestehende Host/Join-Testpfad wird in eine kleine produktive Session-/Lobby-Schicht ueberfuehrt. Es geht nur um Verbindung, Peer-Liste, Ready/Start und Teamzuweisung, nicht um Gameplay-Synchronisation.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/tasks/TASK_051_host_join.md`
- Lies `docs/tasks/TASK_166_multiplayer_authority_command_contract.md`
- Lies `docs/reviews/strategic_review_ui_assets_multiplayer_2026_05_03.md`
- Pruefe den Git-Status

## Kontext
- `scripts/tests/lobby_test_screen.gd` nutzt `ENetMultiplayerPeer` fuer Host/Join.
- V1-Entscheidung: ENet auf Port 7777, kein Matchmaking.
- Multiplayer muss eine kleine, robuste Session-Schicht bekommen, bevor Gameplay repliziert wird.

## Umfang
1. Produktive Session-Komponente anlegen, z.B. `scripts/multiplayer/multiplayer_session.gd`.
2. Lobby-UI als Adapter behalten oder schlank neu verdrahten.
3. Funktionen:
   - Host starten
   - Join
   - Disconnect
   - Peer connected/disconnected
   - Ready-State
   - Start Mission via Server
   - einfache Team-/Fireteam-Zuordnung
4. Bestehenden Testscreen auf die neue Komponente umstellen.

## Nicht-Ziele
- Kein Matchmaking.
- Kein NAT-Traversal/Relay.
- Kein Savegame-Multiplayer.
- Keine Gameplay-Snapshot-Replikation.

## Architekturregeln
- Session kennt Peers und Zuweisungen, aber keinen laufenden Gameplay-State.
- Missionsstart laeuft serverseitig.
- Clients duerfen Mission nicht autoritativ starten.

## Akzeptanzkriterien
- Host/Join funktioniert weiter ueber ENet.
- Session-Daten sind aus `scripts/tests` herausgeloest.
- Ready/Start ist server-authoritative.
- Bestehende Lobby-Verifier oder ein neuer Session-Verifier decken Host/Join-Basics ab.

## Ergebnis
- `scripts/multiplayer/multiplayer_session.gd` kapselt ENet-Host/Join, Disconnect, Peer-Liste, Ready-State, serverseitigen Missionsstart und einfache Team-/Rollen-/Fireteam-Zuweisungen.
- `scripts/tests/lobby_test_screen.gd` bleibt als Adapter-Screen bestehen und delegiert Session-State an die neue produktive Komponente.
- `scenes/tests/lobby_test.tscn` hat Ready- und Disconnect-Controls bekommen; Start Mission bleibt host-only und wird erst nach komplettem Ready-State freigegeben.
- Beim Missionsstart uebergibt der Lobby-Adapter die Session-Zuweisungen an `SimulationRoot` (`set_peer_team_assignments`, `set_peer_role`, `set_peer_fireteam_assignments`), ohne Gameplay-Snapshot-Replikation einzufuehren.
- `docs/dev/multiplayer_session_lobby.md` dokumentiert Verbindung, Ready/Start, Zuordnungen und die Abgrenzung zu TASK_168.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_167_multiplayer_session_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_166_multiplayer_authority_command_contract_verifier.gd`
- [ ] Manueller Host/Join-LAN-Test mit zwei Godot-Instanzen.
- [x] `git diff --check`

## Risiken
- Echte Netzwerkverbindungen sind im Headless-Test schwerer stabil zu pruefen. Trenne State-Unit-Tests und manuellen Host/Join-Smoke.
- UDP-Port 7777 kann lokal belegt sein; Test soll Port konfigurierbar halten.
