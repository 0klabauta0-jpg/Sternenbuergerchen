# TASK 043 – Einfache Gegner-Positionierung

## Ziel
Enemy-Units sollen sich nicht mehr nur stationaer am Spawn aufhalten, sondern sich langsam Richtung Objective bewegen, damit der Einsatz dynamischer wird.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Ist-Zustand
- Enemy-Units stehen nach dem Spawn an ihrer festen Position und bewegen sich nicht.
- `MissionCombatLoopDriver` prueft LOS-Kontakt und enqueued Damage-Effects, aber Enemies haben keine eigene Bewegungslogik.
- `SimulationRoot` kann `move_to_position`-Commands verarbeiten – dieser Pfad wird bisher nur fuer Friendlies genutzt.
- Es gibt keine Gegner-Befehlskette und keinen Gegner-Commander.

## Aufgabe

### 1. Enemy-Bewegungslogik im CombatLoopDriver
- `MissionCombatLoopDriver` erhaelt ein neues Export-Property `enemy_advance_enabled: bool` (default: true).
- Wenn aktiviert: pro Tick bewegen sich `fit`-Enemy-Units langsam Richtung `objective_point` (oder einer konfigurierbaren Zielposition).
- Bewegung erfolgt ueber `SimulationRoot.enqueue_command()` mit `move_to_position` fuer Enemy-Units.
- Geschwindigkeit: deutlich langsamer als Friendly-ASSAULT (z.B. `move_speed_factor = 0.3`).

### 2. Stopp bei Kontakt
- Wenn eine Enemy-Unit LOS-Kontakt zu einer Friendly-Unit hat UND innerhalb einer bestimmten Kampfdistanz ist (z.B. `< 200px`), bleibt sie stehen und feuert, statt weiterzulaufen.
- Einfache Logik: `if has_contact and distance < engage_distance: stop advancing`.

### 3. Respawn-Verhalten
- Nach einem Respawn beginnt die Enemy-Unit erneut, Richtung Objective vorzuruecken.

## Nicht-Ziele
- keine echte Gegner-KI oder Entscheidungslogik
- keine Pfadplanung oder Navigation
- keine Gruppenkoordination zwischen Enemies
- keine Deckungssuche
- keine eigene Gegner-Befehlskette

## Akzeptanzkriterien
- Enemy-Units bewegen sich nach Spawn langsam Richtung Objective
- Enemies stoppen bei Feindkontakt in Kampfreichweite
- Nach Respawn bewegen sich Enemies erneut vor
- Friendly-Bewegung und -Befehle funktionieren weiterhin ohne Regression
- Enemy-Bewegung laeuft ueber den bestehenden SimulationRoot-Command-Pfad

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add simple enemy advance toward objective (TASK_043)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
