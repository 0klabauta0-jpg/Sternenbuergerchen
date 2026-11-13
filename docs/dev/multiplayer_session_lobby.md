# Multiplayer Session and Lobby

## Zweck
`scripts/multiplayer/multiplayer_session.gd` zieht den Host/Join-Testpfad aus dem Lobby-Testscreen heraus. Die Komponente kennt Verbindung, Peers, Ready-State, serverseitigen Missionsstart und einfache Zuordnungen. Sie kennt keinen laufenden Gameplay-State und repliziert keine Snapshots.

## Verbindung
- V1 nutzt `ENetMultiplayerPeer` auf Port `7777`.
- `start_host(port)` erstellt den Host mit maximal `max_players - 1` Clients.
- `join_session(address, port)` verbindet standardmaessig zu `127.0.0.1:7777`.
- `disconnect_session()` setzt den MultiplayerPeer zurueck und leert den Session-State.
- Vor der lokalen Peerfreigabe stoppt der Sessionowner die oeffentliche
  `NetworkTime.stop()`-API, wenn Netfox und Session dieselbe MultiplayerAPI
  besitzen. So kann der Client-Sync-Timer auslaufen, bevor er erneut ohne Peer
  sendet. Unabhaengige MultiplayerAPI-Teilbaeume stoppen keine fremde Root-Uhr.

## Ready und Start
- Peers haben einen Ready-State.
- Der Host kann starten, wenn mindestens zwei Peers verbunden und alle verbundenen
  Peers bereit sind. `max_players` ist ausschließlich die Verbindungskapazität.
- Standardkapazität: 16, vor dem Hosten einstellbar von 2 bis 64. Dies ist eine
  technische Gesamtschranke, keine feste Spielergrenze je Team und kein Nachweis
  der Performance bei 64 Teilnehmern.
- `request_start_mission()` ist server-authoritative. Clients koennen den Missionsstart nicht autoritativ ausloesen.
- Der eigentliche Szenenwechsel bleibt im Lobby-Adapter; die Session emittiert nur `mission_start_requested(assignments)`.

## Zuordnungen
Die Session liefert Zuordnungen fuer den TASK_166-Command-Contract:
- Host Peer `1`: `team_alpha`, Rolle `host`, Fireteams `blue` und `gold`.
- Joined Peer V1-Smoke: `team_bravo`, Rolle `commander`, Fireteam `red`.
- Fuer reine Observer-Runden kann `MultiplayerSession.client_role_id` auf `spectator` gesetzt werden.

### Gemeinsame Teamsteuerung (13.11.2026)
- `coop`: alle aktiven Spieler steuern die Seite des Hosts gegen die Szenario-KI.
- `versus` (PvP) und `coop_versus` (Koop-PvP): Spieler wählen Alpha oder Bravo;
  zum Start müssen beide Seiten aktive Spieler haben. Weitere Spieler derselben
  Seite erhalten ebenfalls Zugriff auf die bestehenden Fireteams dieser Seite.
- Fireteams werden nicht exklusiv unter Peers aufgeteilt. Zusätzliche Peers
  erzeugen keine neuen Units, Dropships oder Teams und werden nicht automatisch
  zu Zuschauern. Die bestehenden Commander-/Fireteam-Commands bleiben vom Host
  geprüft. Gegenläufige Befehle werden in der bestehenden Hostqueue verarbeitet.
- Teamwahl wird vor dem Start auf der Authority normalisiert. Eine geänderte
  Zuordnung entzieht die alte Bereitschaft; ein Moduswechsel setzt alle zurück.
  Während einer laufenden Mission bleiben Team, Modus und Kapazität gesperrt.
- Rejoin stellt die validierte frühere Identität wieder her. Der Weggang eines
  einzelnen Mitclients beendet die Verbindungen der verbleibenden Spieler nicht.
- `is_mission_peer_authenticated(peer_id)` ist eine reine Authority-Abfrage für
  ortsspezifische READY-Nachrichten; sie erzeugt weder Zuordnungen noch State.
- Kartenansicht und Auswahl bleiben lokal. Mehrere Karten benötigen jeweils
  eigene manifestgeprüfte Runtimekontexte; der Einzelkartenkontext wird dafür
  nicht gelockert. Umsetzung/Abnahme: `docs/tasks/SHARED_TEAM_MULTIMAP_2026_11_13.md`.

Der Lobby-Adapter uebergibt diese Daten beim Missionsstart an `SimulationRoot`:
- `set_peer_team_assignments(...)`
- `set_peer_role(...)`
- `set_peer_fireteam_assignments(...)`

## UI-Adapter
`scripts/tests/lobby_test_screen.gd` bleibt als Test-/Adapter-Screen bestehen. Er erzeugt eine `MultiplayerSession`, verbindet UI-Buttons mit Session-Methoden und instanziiert die bestehende Missions-Testszene erst nach dem serverseitigen Startsignal.

## Testbarkeit
`scripts/tests/task_167_multiplayer_session_verifier.gd` prueft den Session-State ohne echte UDP-Verbindung:
- Host-/Peer-Erfassung
- Ready-State und Startberechtigung
- Client darf nicht starten
- Zuordnungen passen zu `SimulationRoot`
- Disconnect leert den Session-State
- Lobby-Screen erzeugt den Session-Adapter

`shared_team_session_verifier.gd` ergänzt echte localhost-ENet-Session-RPCs mit
sechs Peers, gemeinsamer Teamsteuerung, 3-gegen-3, freien Plätzen, Teamrechten,
Disconnect und laufendem Rejoin. Das ersetzt keinen WAN-/Latenz-/Lasttest.
