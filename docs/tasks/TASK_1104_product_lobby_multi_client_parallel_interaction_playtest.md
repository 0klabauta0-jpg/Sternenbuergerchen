# TASK_1104 - Product Lobby Multi-Client Parallel Interaction Playtest

## Ziel / Problem
Die Produkt-Lobby soll einen Host und zwei Clients mit getrennten Fireteams in dieselbe Mission bringen. Parallele Interaction-Ownership und das TASK_1103-HUD-Feedback muessen im echten Drei-Peer-Pfad konsistent bleiben.

## Ursache / Sinnhaftigkeit
`MultiplayerSession` erlaubt konfigurierbar mehr als zwei Spieler, weist aber jedem Client dieselbe exportierte `client_fireteam_ids`-Liste zu. Bei drei Peers erhalten beide Clients daher `red`, waehrend `gold` beim Host verbleibt. Das widerspricht der Command-Authority und verhindert echte getrennte Client-Ownership.

## Umfang
- Deterministische Fireteam-Verteilung vor Missionsstart.
- Coop-Fireteams aus den tatsaechlich vorhandenen Mission-Fireteams `blue,gold` verteilen.
- Bei drei Peers: Host `blue`, erster Client `gold`, zweiter Client als expliziter Spectator ohne Command-Fireteam.
- Echte Produkt-Lobby mit drei separaten MultiplayerAPIs und ENet-Peers testen.
- Gemeinsamer Mission-Handoff, paralleler Interaction-Fortschritt, Konflikt-Reject und HUD-Zeile pruefen.

## Nicht-Ziele
- Keine dynamische Mid-Mission-Neuverteilung.
- Keine Host-Migration.
- Kein Matchmaking oder Internet-Lobby-Service.
- Keine vierte spielbare Fireteam-Rolle ohne zusaetzliche Missions-Fireteams.

## Akzeptanzkriterien
- Drei Produkt-Lobbys verbinden sich und werden eindeutig in `peer_fireteams` abgebildet.
- Kein aktives Fireteam ist gleichzeitig zwei Peers zugewiesen; ueberzaehlige Peers sind Spectator.
- Coop-Umschaltung normalisiert alle Peer-Team-IDs auf das Host-Team.
- Ein nachtraegliches Client-Setup-RPC kann die autoritative Coop-Team-ID nicht zurueck auf Versus umschreiben.
- Alle drei Clients/Host starten eine echte Missioninstanz.
- Host- und Client-Fireteam koennen zwei Interactions parallel halten.
- Der aktive Client kann die Host-Interaction nicht uebernehmen und sieht `ANDERES FIRETEAM AKTIV`; der dritte Peer repliziert als Spectator.
- Beide Clients replizieren dieselben zwei Owner/Progress-States und zeigen die kompakte Parallelzeile.
- Client-Snapshots erzeugen keine lokalen Commands oder Effects.
- Spectator kann auch mit bekannter Unit-ID kein Fireteam-Kommando autorisieren.
- Spectator-Reject wird als `ZUSCHAUER KANN NICHT BEFEHLEN` statt als technischer Reason-Code angezeigt.
- Der Zwei-Spieler-Vertrag bleibt unveraendert.
- `Coop -> Versus` stellt Teams, Rollen und Fireteams wieder her; ein zusaetzlicher Versus-Peer bleibt Spectator statt `red` zu duplizieren.
- Faellt ein aktiver Coop-Peer vor Missionsstart aus, uebernimmt der naechste Spectator deterministisch das freie Fireteam.

## Betroffene Dateien
- `scripts/multiplayer/multiplayer_session.gd`
- `scripts/tests/task_1104_product_lobby_multi_client_parallel_interaction_playtest.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- TASK_1104 Drei-Peer-Produktverifier.
- TASK_1103 HUD-Regression.
- TASK_1102 Ownership-Regression.
- TASK_1101 Reconnect-Regression.
- TASK_167 Session-Regression.
- TASK_227 Produkt-Lobby-Regression.
- `git diff --check`.

## Risiken / offene Punkte
- Die aktuelle Mission besitzt zwei etablierte Friendly-Fireteams; weitere aktive Spieler brauchen spaeter zusaetzliche Fireteams. Bis dahin greift die explizite Spectator-Policy.
- Ein echter manueller Drei-Fenster-Sichtlauf bleibt nach dem technischen Beleg sinnvoll.
