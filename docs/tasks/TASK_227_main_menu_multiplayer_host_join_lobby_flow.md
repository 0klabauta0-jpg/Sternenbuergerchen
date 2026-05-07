# TASK_227 - Main Menu Multiplayer Host Join Lobby Flow

## Ziel
Der `Multiplayer`-Button im Hauptmenue soll nicht nur auf einen Testpfad zeigen, sondern einen klaren Host/Join-Lobby-Flow oeffnen: Host erstellen, Join mit Adresse/Port, Ready, Disconnect und Start.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_167 - Multiplayer Session and Lobby Extraction
- TASK_169 - Multiplayer Two-Client Playability Smoke
- TASK_199 - Main Menu Shell and Background Image
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay

## Kontext
`MultiplayerSession` kapselt Host/Join, Ready, Start und Zuordnungen bereits als produktive Komponente. Der Hauptmenue-Einstieg muss diese Schicht sichtbar und bedienbar machen, ohne direkt Gameplay-Simulation in UI-Buttons zu stecken.

## Umfang
1. Multiplayer-Menue:
   - Aus dem Hauptmenue erreichbar.
   - Host-Button mit Port.
   - Join-Button mit Adresse und Port.
   - Zurueck/Disconnect.
2. Lobby-State:
   - Connected Peers.
   - Ready-State.
   - Host-only Start.
   - Status-/Fehlerzeile.
   - Team-/Fireteam-Zuordnung mindestens als Snapshot sichtbar.
3. Zielpfade:
   - Weiterhin `MultiplayerSession` als Wahrheit.
   - Test-/Adapter-Screen darf genutzt werden, wenn er klar dokumentiert ist.
   - UI ruft keine SimulationRoot-Gameplay-Commands direkt.
4. Settings-Bezug:
   - Port/Adresse optional aus Settings oder letzten Eingaben.
   - FoW-Modus fuer Lobby/Missionsstart nur als Setting mitgeben, nicht dort erfinden.
5. Verifier:
   - Multiplayer-Button oeffnet Lobby.
   - Host/Join-Controls existieren.
   - Host-only Start respektiert Ready-State.
   - Disconnect kehrt sicher zurueck.

## Nicht-Ziele
- Kein Matchmaking.
- Kein NAT-Traversal/Relay.
- Kein Online-Service.
- Kein Map-Download, das folgt in TASK_228.
- Kein Gameplay-Snapshot-Rework.

## Akzeptanzkriterien
- [x] Hauptmenue-Button `Multiplayer` oeffnet einen bedienbaren Host/Join-Screen.
- [x] Host und Join nutzen `MultiplayerSession`.
- [x] Ready/Start/Disconnect sind sichtbar und strukturell getestet.
- [x] Start bleibt server-authoritative.
- [x] Fehler wie belegter Port oder Join-Fehler landen sichtbar im UI-State.
- [x] Ein TASK_227-Verifier prueft Menue-Routing, Session-Anbindung und Start-Grenzen.

## Erwartete Dateien
- `scripts/ui/main_menu_screen.gd`
- `scripts/ui/multiplayer_lobby_screen.gd`
- optional `scenes/ui/multiplayer_lobby.tscn`
- `scripts/multiplayer/multiplayer_session.gd`
- `scripts/tests/task_227_main_menu_multiplayer_host_join_lobby_flow.gd`
- `docs/tasks/TASK_227_main_menu_multiplayer_host_join_lobby_flow.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_227_main_menu_multiplayer_host_join_lobby_flow.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_167_multiplayer_session_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_169_multiplayer_two_client_playability_smoke.gd`
- [ ] Manueller Zwei-Instanzen-Host/Join-Test.
- [x] `git diff --check`

## Risiken
- Echter Netzwerk-Test bleibt lokal fragiler als State-Verifier.
- UI darf nicht mit Testscreen-State und produktiver Session-Wahrheit auseinanderlaufen.

## Umsetzung
- Das Hauptmenue routet `Multiplayer` jetzt auf `res://scenes/ui/multiplayer_lobby.tscn` und markiert den Pfad als produktiven Lobby-Flow.
- `scripts/ui/multiplayer_lobby_screen.gd` stellt Host-Port, Join-Adresse/-Port, Ready, host-only Start, Disconnect, Zurueck, Peer-Liste, Assignments und FoW-Settings-Zusammenfassung dar.
- Die Lobby besitzt eine echte `MultiplayerSession`-Node und spiegelt nur deren Snapshot. Start bleibt `request_start_mission()` auf der Session; Clients koennen nicht starten.
- `MultiplayerSession._has_active_peer()` behandelt den Godot-Offline-Peer als inaktiv, damit idle Lobby-Snapshots nicht faelschlich als verbunden gelten.
- `task_227_main_menu_multiplayer_host_join_lobby_flow.gd` prueft Main-Menu-Routing, Controls, Session-Anbindung, Ready-Grenzen, Host-only Start, Assignments und Disconnect-Status.

## Naechster Schritt
Nach TASK_227 kann TASK_228 den Host-Map-Download fuer unbekannte Editor-Maps vorbereiten.
