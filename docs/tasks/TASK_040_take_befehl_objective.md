# TASK 040 – Take-Befehl und Objective

## Ziel
Der Commander-Befehl `take` soll als Objective-Capture funktionieren: Units bewegen sich zum Zielpunkt, sichern ihn und der Objective-Status wird im Spielzustand nachvollziehbar.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Ist-Zustand
- `take` existiert als Commander-Befehlstyp und wird ueber `CommandToFTLTaskTranslator` in einen `FTLTask` uebersetzt (aktuell auf `engage_in_area`).
- Im `RuntimeLeader` fuehrt `take` zu `engage_area` / `fire_at_will` – identisch zu `flank`, nur ohne Offset.
- Es gibt keinen echten Objective-Zustand: kein Capture-Fortschritt, keine Capture-Zone und keinen Besitzwechsel.
- Der bestehende `objective_point`-Marker in der Map ist nur ein visueller Zielmarker ohne Gameplay-Logik.

## Aufgabe

### 1. Objective-Datenmodell
- Neues kleines Datenmodell `ObjectiveStatus` (RefCounted) unter `res://scripts/core/objective_status.gd`:
  - `objective_id: String`
  - `position: Vector2`
  - `capture_radius: float` (z.B. 80.0)
  - `owning_team_id: String` (leer = neutral)
  - `capture_progress: float` (0.0 bis 1.0)
  - `capturing_team_id: String`
  - Methoden: `is_captured() -> bool`, `is_contested() -> bool`, `to_dict() -> Dictionary`

### 2. Capture-Logik im SimulationRoot
- `SimulationRoot` erhaelt eine Referenz auf eine optionale `ObjectiveStatus`-Instanz.
- Pro Tick prueft `SimulationRoot`, welche `fit`-Units innerhalb des `capture_radius` stehen.
- Wenn nur Units eines Teams im Radius stehen: `capture_progress` steigt langsam (z.B. +0.01 pro Tick).
- Wenn Units beider Teams im Radius stehen: contested, kein Fortschritt.
- Bei `capture_progress >= 1.0`: `owning_team_id` wird auf das capturende Team gesetzt.

### 3. Take-Befehl verdrahten
- Wenn `take` als Commander-Befehl ausgegeben wird, sollen die betroffenen Units zum Objective-Punkt bewegt werden und dort `engage_area` + `fire_at_will` erhalten.
- Der bestehende Flow reicht dafuer aus – es braucht nur sichergestellt zu werden, dass der Zielmarker auf dem Objective-Punkt liegt, wenn `take` genutzt wird.

### 4. Sichtbares Feedback
- Am `objective_point`-Marker in der Szene: kleines Label mit aktuellem `owning_team_id` und `capture_progress` als Prozentwert.
- Optional: Farbwechsel des Markers bei Besitzwechsel.

### 5. MissionTestSetup anpassen
- `MissionTestSetup` erstellt eine `ObjectiveStatus`-Instanz basierend auf dem bestehenden `objective_point`-Marker und reicht sie an `SimulationRoot` weiter.

## Nicht-Ziele
- keine mehreren Objectives gleichzeitig
- keine komplexe Capture-Zone-Geometrie
- kein automatischer `take`-Befehl durch Gegner
- keine Capture-Unterbrechung durch Bleedout im Radius
- keine Verteidigungsbonus-Logik fuer den Besitzer

## Akzeptanzkriterien
- `take`-Befehl bewegt Units zum Objective und sie beginnen zu capturen
- Capture-Fortschritt ist am Marker sichtbar
- Bei vollem Fortschritt wechselt der Besitzer
- Contested-Zustand blockiert Fortschritt
- Bestehende move/defend/flank-Befehle funktionieren weiter ohne Regression

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add take command with objective capture (TASK_040)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
