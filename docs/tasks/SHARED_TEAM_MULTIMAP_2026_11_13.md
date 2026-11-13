# Gemeinsame Teams und unabhängige Kartenansichten

## Ziel und Ursache
Userbestätigung vom 13.11.2026: PvP, Koop gegen KI und Koop-PvP. Mehrere Menschen
steuern die Einheiten ihres Teams gemeinsam und sprechen ihre Aufgaben selbst ab.
Mitglieder desselben Teams müssen gleichzeitig auf unterschiedlichen Karten spielen
können. Kamera, Auswahl und Kartenansicht gehören zum jeweiligen Client.

Die bisherige Session hat zwei Plätze, verteilt im Koop einzelne Fireteams und
degradiert weitere Peers zu Zuschauern. Der Lobbyadapter startet zudem genau eine
Mission. Ein höheres Spielerlimit allein erfüllt die Anforderung daher nicht.

## Umfang / Nicht-Ziele
- Bestehende Session-, Command-, Karten- und SimulationRoot-Owner erweitern.
- Keine feste Fünf-Personen-Grenze je Team. Technische Sessionkapazität konfigurierbar;
  Startbereitschaft nicht an das vollständige Belegen aller Plätze koppeln.
- Spieler entscheiden lokal, welchen vorhandenen Ort sie ansehen. Ein Kartenwechsel
  verschiebt weder Truppen noch die Ansichten anderer Spieler.
- Befehle bleiben an den richtigen Kartenruntime, das eigene Team und die vorhandene
  Hostprüfung gebunden. Gegnerische Sicht und unbekannte Karten bleiben geschützt.
- Kein neuer zweiter Gameplay-State in UI, keine Desktopübernahme, kein neuer Transport
  durch bloßen Kartenwechsel, kein Versprechen unbegrenzter Netzwerkleistung.

## Relevante Verträge
- `docs/ARCHITECTURE.md`
- `docs/dev/multiplayer_session_lobby.md`
- `docs/dev/multiplayer_authority_command_contract.md`
- `docs/dev/hex_tactical_runtime_contract.md`
- `docs/dev/starmap_smart_mobile_contract.md`

## Akzeptanz
1. Fünf aktive Koop-Spieler behalten Zugriff auf dieselben eigenen Fireteams.
2. Koop-PvP erlaubt mehrere aktive Spieler auf beiden Seiten; fremde Teams bleiben
   für normale Spielerbefehle gesperrt. Vorhandenes PvP bleibt möglich.
3. Alle verbundenen Spieler müssen bereit sein; freie Plätze verhindern den Start nicht.
4. Zwei Spieler desselben Teams können gleichzeitig verschiedene echte Kartenruntimes
   bedienen. Befehle und Snapshots erreichen ausschließlich den passenden Runtime.
5. Auswahl/Kamera/Kartenwechsel wirken lokal; Hintergrundsimulation läuft autoritativ
   weiter. Fehlende Sicht wird nicht durch einen Ansichtswechsel aufgedeckt.
6. Disconnect/Rejoin erhält die Teamzuordnung, erzeugt keine zusätzlichen Einheiten
   und setzt keine fremden lokalen Ansichten zurück.
7. Identische eigene Rechte erhalten pro Ort Fireteam-Auswahl und Kameraposition;
   reduzierte Rechte filtern nur die bestehende Auswahl, erweiterte Rechte wählen
   nichts automatisch aus. Der echte Mehrkarten-Verifier prüft auch fremden Rejoin.
8. Wiederholtes Öffnen und Beenden eines echten Ortes lässt nach dem RPC-Drain keine
   toten Registry-/Präsentationsdatensätze zurück und verändert den zweiten Ort nicht.

## Dateien / Prüfung
Session und Lobby, vorhandene Location-/Runtime-Registrierung und Netzwerk-Routing;
konkrete neue Adapter werden nach dem Ownership-Audit ergänzt.
Produktiver Ortsadapter: `scripts/multiplayer/multiplayer_world_runtime.gd`;
sichtbare lokale Ortsauswahl/Host-Öffnen im Missionslebenszyklus von
`scripts/ui/multiplayer_lobby_screen.gd`. APIs und Grenzen stehen in
`docs/dev/multiplayer_world_runtime_contract.md`. Der bestehende
`LocationRuntimeRegistry` bleibt Lookup. Sessionauthentifizierung erfolgt über
`is_mission_peer_authenticated`; zusätzliche READY-RPCs bleiben ortsbezogen.
Konkrete Regression: `scripts/tests/shared_team_multimap_enet_verifier.gd`
mit drei echten localhost-Sessions, zwei produktiven Missionstrees,
gemeinsamem Team, fremder Seite, Root-RPCs und tatsächlichem Rejoin.
Regressionen prüfen produktive Owner sowie echte localhost-ENet-Verbindungen mit
mehreren Peers, zwei Karten und negativen Team-/Token-/Sichtfällen. Engineausführung
serialisiert über den bestehenden QA-Runner; Report trennt bestandene Teilprüfungen
von noch offener Gesamtabnahme.

## Risiken / aktueller Stand
Implementierung läuft. Mehrkarten-Lobby und Replikation sind noch nicht als spielbar
nachgewiesen. Bestehende Einzelmissions-Kontexte dürfen nicht still aufgeweicht werden.

### Restbefund Terrain-FoW
Der reale Mehrkartenlauf 3583 (84/1) belegt fehlende Terrainpublikation auf Clients. Schließen über vorhandenen Host-Fogowner und gebundene Schema-2-Snapshots; keine lokale Ersatzaufklärung. Regression: schwarz vor Erstpublikation, reale Hostaufklärung für Alpha und Bravo getrennt, identisches Wissen für gleiche Teams, erhaltenes Wissen bei Kartenwechsel und abgelehnte fremde/veraltete Publikation. Editor-/UI-Nachbarn unverändert.
