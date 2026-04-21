# TASK_108 – PatrolEditorTool und Pre-Contact-Patrol

## Ziel
Der Map-Editor erhaelt ein `PatrolEditorTool` fuer gegnerische Patrouillenpfade. In der Mission folgen Gegner diesen Pfaden bis zum ersten Feindkontakt und wechseln danach auf das bestehende reaktive Kampfverhalten.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_063_map_editor_speichern.md](docs/tasks/TASK_063_map_editor_speichern.md)
- Lies [docs/tasks/TASK_064_mission_terrain_aus_json.md](docs/tasks/TASK_064_mission_terrain_aus_json.md)
- Lies [docs/tasks/TASK_045_gegner_wellen.md](docs/tasks/TASK_045_gegner_wellen.md)
- Pruefe den Git-Status

## Aufgabe

### 1. Datenvertrag fuer Patrouillenpfade
- Pro Gegner-Spawn existiert eine geordnete Wegpunktliste.
- Speicherung erfolgt in der bestehenden Karten-JSON.

### 2. `PatrolEditorTool`
- Patrouillenpunkte koennen gesetzt, verschoben und entfernt werden.
- Die Reihenfolge bleibt sichtbar und editierbar.
- Das Tool ist Teil des internen Editors, nicht der Missions-UI.

### 3. Pre-Contact-Patrol in der Mission
- Gegner laufen ihre Patrouille, solange kein Feindkontakt besteht.
- Bei Kontakt uebergeben sie an die vorhandenen reaktiven Systeme.
- `MissionCombatLoopDriver` und `EnemyWaveController` bleiben strukturell unveraendert.

### 4. Sichtbarkeit
- Patrouillenpfade sind im Editor sichtbar.
- In der Mission bleiben sie fuer den Spieler unsichtbar.

## Nicht-Ziele
- keine neue Gegner-KI-Architektur
- kein vollwertiger Stealth-/Awareness-Rewrite
- keine sichtbare Patrol-HUD in der Mission

## Akzeptanzkriterien
- Patrouillenpfade koennen im Editor gesetzt und in JSON gespeichert werden.
- Gegner folgen ihnen bis zum ersten Kontakt.
- Nach Kontakt greift wieder die bestehende reaktive Kampflogik.
- Patrouillenpfade sind nur im Editor sichtbar.
