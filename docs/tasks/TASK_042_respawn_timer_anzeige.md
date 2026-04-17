# TASK 042 – Respawn-Timer-Anzeige

## Ziel
Der Spieler soll sehen, welche Units gerade respawnen und wie lange es noch dauert.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Ist-Zustand
- `RespawnManager` verwaltet timerbasierte Respawns in `_pending_respawns` (Dictionary mit unit_id -> verbleibende Zeit).
- `RespawnManager` hat Signale `unit_respawn_started` und `unit_respawn_completed`.
- Respawn-Timer laufen intern, aber es gibt keine sichtbare Anzeige fuer den Spieler.
- `TestUnit` zeigt bei `respawning`-Zustand einen gruenen "RESPAWN"-Text, aber keinen Countdown.

## Aufgabe

### 1. RespawnManager: Timer-Abfrage-API
- Neue Methode `get_pending_respawns() -> Dictionary` die ein Dictionary `{ unit_id: remaining_seconds }` zurueckgibt.
- Neue Methode `get_remaining_time(unit_id: String) -> float` fuer Einzelabfragen.

### 2. Respawn-UI-Overlay
- Neues kleines UI-Element in der Missions-Testszene: ein `VBoxContainer` mit `Label`-Eintraegen fuer jede aktuell respawnende Unit.
- Format pro Eintrag: `"[UNIT_ID] RESPAWN in Xs"` (ganzzahlig gerundet).
- Position: obere rechte Ecke, unter dem bestehenden Command-Feedback-Label.
- Aktualisierung: einmal pro Frame in `_process()`.

### 3. TestUnit-Countdown
- Wenn eine `TestUnit` im Zustand `respawning` ist, zeigt ihr Status-Label zusaetzlich die verbleibende Zeit: z.B. `RESPAWN 12s`.
- Dafuer liest `TestUnit` die verbleibende Zeit ueber den `RespawnManager` (Referenz per NodePath oder Signal).

### 4. MissionTestSetup verdrahten
- Die neue Respawn-UI-Komponente wird in `MissionTestSetup` oder direkt in der Testszene eingebunden.
- `RespawnManager`-Referenz wird an die UI-Komponente weitergereicht.

## Nicht-Ziele
- keine aufwendige HUD-Architektur
- keine Respawn-Queue-Anzeige
- keine Spawn-Punkt-Auswahl-UI
- keine Animationen oder Fortschrittsbalken

## Akzeptanzkriterien
- Waehrend ein Respawn laeuft, ist im UI sichtbar welche Unit respawnt und wie viele Sekunden verbleiben
- Der Countdown zaehlt korrekt herunter
- Bei Respawn-Abschluss verschwindet der Eintrag
- Bestehende Respawn-Logik funktioniert ohne Regression

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add respawn timer UI overlay (TASK_042)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
