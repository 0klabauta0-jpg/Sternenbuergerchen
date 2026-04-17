# TASK 053 – Synchronisierte Spielzustandsanzeige

## Ziel
Beide Clients (Host und Joiner) sehen denselben Spielzustand: Unit-Positionen, Vital-Status, Objective-Fortschritt und Missionsergebnis werden synchronisiert.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_050 (Server-autoritativer SimulationRoot) muss vorher implementiert sein.
- TASK_051 (Host/Join) muss vorher implementiert sein.
- TASK_052 (Befehlsuebertragung) muss vorher implementiert sein.

## Ist-Zustand (nach TASK_052)
- Commands werden ueber RPC an den Server gesendet und dort ausgefuehrt.
- `SimulationRoot` hat eine vorbereitete `_broadcast_tick_state()`-Methode.
- Der Client sieht noch keinen aktualisierten Spielzustand – Units bewegen sich nur auf dem Server.

## Aufgabe

### 1. State-Broadcast aktivieren
- `SimulationRoot._broadcast_tick_state()` wird nach jedem Tick aufgerufen (nur wenn `is_server_authoritative == true` und Multiplayer aktiv).
- Broadcast-Dictionary pro Unit:
  - `unit_id: String`
  - `position: Vector2`
  - `vital_state: String`
  - `health: int`
  - `runtime_state: String`
  - `fire_mode: String`

### 2. Client-seitige State-Anwendung
- Neue Methode `_apply_remote_state(state_dict: Dictionary) -> void` auf dem Client.
- Fuer jede Unit im State-Dictionary:
  - Position setzen (direkt oder mit einfacher Interpolation).
  - Vital-Status synchronisieren.
  - Health synchronisieren.
  - Runtime-Status synchronisieren.
- Interpolation: einfaches Lerp zwischen alter und neuer Position (keine komplexe Prediction).

### 3. Objective-Status synchronisieren
- `ObjectiveStatus` (aus TASK_040) wird als Teil des Tick-Broadcasts mitgesendet:
  - `owning_team_id`, `capture_progress`, `capturing_team_id`.
- Client aktualisiert die lokale Objective-Anzeige basierend auf Server-Daten.

### 4. Missionsergebnis synchronisieren
- Wenn der Server ein Missionsergebnis feststellt (Sieg/Niederlage aus TASK_041), wird dieses per `@rpc("authority", "reliable")` an alle Clients gesendet.
- Beide Clients zeigen den Debrief-Screen.

### 5. Sichtbare Feedback-Synchronisation
- Event-Labels (HIT, DOWN, BLEEDOUT, RESPAWN) werden per RPC als einfache Strings an Clients gesendet.
- Client-Units zeigen diese Events wie im Singleplayer.

## Nicht-Ziele
- keine Client-Side-Prediction
- keine Snapshot-Interpolation mit Pufferung
- keine Lag-Kompensation
- keine Authority-Uebertragung an Clients
- kein Fog-of-War pro Spieler (beide sehen alles)

## Akzeptanzkriterien
- Der Client sieht Unit-Bewegungen in Echtzeit (mit minimalem Delay)
- Vital-Status (fit/down/bleedout/respawning) ist auf beiden Seiten synchron
- Objective-Fortschritt ist synchronisiert
- Missionsergebnis erscheint auf beiden Clients
- Singleplayer-Modus funktioniert weiterhin ohne Regression

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Synchronize game state to multiplayer clients (TASK_053)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
