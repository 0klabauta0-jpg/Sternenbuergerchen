# TASK 051 – Host/Join mit Testteams

## Ziel
Zwei Spieler koennen eine Partie hosten bzw. joinen; jeder bekommt ein vordefiniertes Testteam zugewiesen.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_050 (Server-autoritativer SimulationRoot) muss vorher implementiert sein.

## Ist-Zustand (nach TASK_050)
- `SimulationRoot` hat RPC-Methoden und Authority-Check.
- Es gibt keine Verbindungslogik, kein Lobby-System und keinen Host/Join-Flow.
- Die Missionsszene laeuft rein lokal.

## Aufgabe

### 1. Minimaler Lobby-Screen
- Neuer kleiner Screen `LobbyTestScreen` unter `res://scripts/tests/lobby_test_screen.gd`:
  - Button "Host" – erstellt einen `ENetMultiplayerPeer` als Server (Port 7777).
  - Button "Join" – verbindet als Client zu `localhost:7777`.
  - Status-Anzeige: "Waiting for players...", "Connected (2/2)", etc.
  - Button "Start Mission" – nur fuer Host sichtbar, startet die Missionsszene.

### 2. Szene
- Neue Szene `res://scenes/tests/lobby_test.tscn` mit dem `LobbyTestScreen`.

### 3. Team-Zuweisung
- Host = `team_alpha` (Friendlies).
- Client = `team_bravo` (im PvP-Modus die Gegner, fuer V1 aber nur ein zweites Friendly-Team oder Beobachter).
- Fuer V1: beide Spieler sehen dieselbe Szene, aber nur der Host kann Commands geben. Der Client beobachtet.

### 4. Mission starten
- "Start Mission" wechselt fuer beide Peers zur Missionsszene.
- `SimulationRoot.is_server_authoritative` wird auf `true` gesetzt.
- Der Host ist Authority fuer `SimulationRoot`.

### 5. Disconnect-Handling
- Bei Verbindungsabbruch: Rueckkehr zum Lobby-Screen mit Fehlermeldung.
- Kein Crash, kein haengendes Spiel.

## Nicht-Ziele
- kein Matchmaking
- kein Internet-Play (nur LAN / localhost fuer V1)
- keine Spielerauswahl von Teams
- kein Chat
- keine Persistenz

## Akzeptanzkriterien
- Host kann eine Partie erstellen
- Client kann per Join beitreten
- Beide sehen den Lobby-Status
- Host kann Mission starten, beide wechseln zur Missionsszene
- `SimulationRoot` laeuft server-autoritativ
- Disconnect fuehrt sauber zurueck zum Lobby

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add host/join lobby with test teams (TASK_051)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
