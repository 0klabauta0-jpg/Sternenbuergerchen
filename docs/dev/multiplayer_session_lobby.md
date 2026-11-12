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
- Der Host kann erst starten, wenn `max_players` Peers verbunden und alle ready sind.
- `request_start_mission()` ist server-authoritative. Clients koennen den Missionsstart nicht autoritativ ausloesen.
- Der eigentliche Szenenwechsel bleibt im Lobby-Adapter; die Session emittiert nur `mission_start_requested(assignments)`.

## Zuordnungen
Die Session liefert Zuordnungen fuer den TASK_166-Command-Contract:
- Host Peer `1`: `team_alpha`, Rolle `host`, Fireteams `blue` und `gold`.
- Joined Peer V1-Smoke: `team_bravo`, Rolle `commander`, Fireteam `red`.
- Fuer reine Observer-Runden kann `MultiplayerSession.client_role_id` auf `spectator` gesetzt werden.

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

Der echte Host/Join-LAN-Test bleibt manuell, weil zwei Godot-Instanzen und ein freier UDP-Port benoetigt werden.

## Vorbereiteter Laufzeitkontext (AP7, 12.11.2026)

Die Session reicht bei vorhandenem akzeptiertem Mapmanifest im zuverlaessigen
Startassignment `multiplayer_runtime_context` weiter. Schema ist
`multiplayer.runtime_context.v1`, mit `runtime_token`, `map_id`, `map_hash` und
optionalem `scenario_hash`. Lokale Cachepfade sind keine Runtimeidentitaet.
Ein erfolgreicher neuer Hoststart erzeugt den Token; Rejoin behaelt ihn, Ende
und Reset loeschen ihn. Session und Lobby liefern nur kopierende Getter.

Ein explizit vorhandener ungueltiger Kontext wird vor Aktivierung oder
Manifestmutation abgewiesen. Abgewiesene Snapshots erzeugen auch bei bereits
aktiver Mission keine Assignment-/Snapshotsignale. Fehlender Kontext bleibt
Legacy; ohne gueltiges Manifest wird keine Identity erfunden. Die bestehende
Datei-/Downloadpruefung bleibt zustaendig fuer den Inhaltsnachweis.

Dieser Baustein ruft noch keinen Rootbinder auf. Ein gepruefter Snapshot kann
einen neuen Assignmenttoken tragen; der Sessiongetter bleibt bis zum reliable
Start leer. Der folgende Rootanschluss muss Startbindung und laufende
Assignmentaenderung unterscheiden. Sender-/Receiverbindung und echte Peers
sind noch offen; siehe Task MULTIPLAYER_RUNTIME_CONTEXT_2026_11_12.md.
