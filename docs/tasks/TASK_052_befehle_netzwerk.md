# TASK 052 – Befehlsuebertragung ueber Netzwerk

## Ziel
Commander-Befehle des Spielers werden als RPC an den Server gesendet, dort validiert und ueber `SimulationRoot` autoritativ ausgefuehrt.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_050 (Server-autoritativer SimulationRoot) muss vorher implementiert sein.
- TASK_051 (Host/Join) muss vorher implementiert sein.

## Ist-Zustand (nach TASK_051)
- Host und Client koennen verbinden und die Missionsszene starten.
- `SimulationRoot` hat `request_command()` als RPC-Methode.
- Aber: `MissionTacticalSandboxController` und `MissionCommandFlowDriver` rufen `enqueue_command()` noch direkt lokal auf.

## Aufgabe

### 1. Command-Flow ueber RPC umleiten
- `MissionCommandFlowDriver`: wenn `SimulationRoot.is_server_authoritative == true`, soll `enqueue_command()` durch `request_command.rpc_id(1, command_dict)` ersetzt werden (sendet an Server/Host).
- Wenn `is_server_authoritative == false`: bisheriger lokaler Pfad bleibt.

### 2. Server-seitige Validierung
- `SimulationRoot.request_command()` prueft:
  - Ist der Absender berechtigt fuer das angegebene `team_id`? (Peer-ID -> Team-Mapping aus TASK_051)
  - Ist der Command-Typ gueltig?
  - Bei ungueltigem Command: `push_warning()` und ignorieren.

### 3. Effect-Enqueue nur serverseitig
- `enqueue_effect()` darf weiterhin nur lokal auf dem Server aufgerufen werden.
- `MissionCombatLoopDriver` laeuft nur auf dem Server (Authority-Check in `_ready()`).

### 4. Client-Input ermoeglichen
- Fuer V1: nur der Host gibt Commands (der Client beobachtet).
- Vorbereitung: die Team-ID-Pruefung erlaubt spaeter, dass der Client Commands fuer sein eigenes Team senden kann.

## Nicht-Ziele
- kein Client-Side-Prediction
- keine Input-Pufferung oder Latenz-Ausgleich
- kein PvP mit zwei aktiven Commandern (V1 ist nur Host-steuerbar)
- keine komplexe Autorisierungslogik

## Akzeptanzkriterien
- Im Multiplayer-Modus werden Commands ueber RPC an den Server gesendet
- Server validiert und fuehrt Commands autoritativ aus
- Ungueltige Commands werden abgelehnt
- Im Singleplayer-Modus funktioniert alles wie bisher
- Keine Regression in der bestehenden Befehlskette

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Route commander commands through RPC (TASK_052)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
