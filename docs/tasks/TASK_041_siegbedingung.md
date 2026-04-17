# TASK 041 – Siegbedingung

## Ziel
Die Mission soll eine klare Siegbedingung haben, die das Missionsende ausloest und ein Ergebnis an den bestehenden Debrief-Flow zurueckgibt.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Ist-Zustand
- `MissionCombatLoopDriver` markiert den Fight als beendet, sobald alle Gegner nicht mehr `fit` sind (reine Eliminierung).
- Der Debrief-Screen zeigt ein einfaches Ergebnis (`mission_result` aus dem CombatLoopDriver).
- Es gibt keine Objective-basierte Siegbedingung, keinen Timer und keinen expliziten Verlust-Zustand.
- Mit TASK_040 existiert eine `ObjectiveStatus` mit Capture-Fortschritt.

## Abhaengigkeit
- TASK_040 (Take-Befehl und Objective) muss vorher implementiert sein.

## Aufgabe

### 1. Siegbedingungstypen definieren
- Enum oder Konstanten fuer Siegbedingungen:
  - `ELIMINATION` – alle Gegner eliminiert (bestehendes Verhalten)
  - `OBJECTIVE_CAPTURE` – Friendly-Team hat Objective gecaptured
  - `OBJECTIVE_DEFENSE` – Friendly-Team haelt Objective fuer X Sekunden nach Capture

### 2. MissionCombatLoopDriver erweitern
- Neues Export-Property `win_condition: String` (default: `"elimination"`).
- Pro Tick pruefen:
  - `elimination`: alle Enemy-Units sind nicht `fit` → Sieg
  - `objective_capture`: `ObjectiveStatus.owning_team_id == friendly_team_id` → Sieg
  - `objective_defense`: Objective gecaptured + Y Sekunden gehalten → Sieg
- Verlust-Bedingung: alle Friendly-Units gleichzeitig nicht `fit` (alle down/bleedout/respawning) → Niederlage.

### 3. Missionsergebnis-Daten
- Das bestehende `mission_result`-Dictionary erhaelt zusaetzliche Felder:
  - `win_condition_type: String`
  - `result: String` (`"victory"` oder `"defeat"`)
  - `objective_captured: bool`
  - `duration_seconds: float` (Missionsdauer)

### 4. Debrief-Anzeige
- Der bestehende `DebriefScreen` zeigt jetzt zusaetzlich:
  - Sieg oder Niederlage
  - Art der Siegbedingung
  - Missionsdauer

### 5. Testszene konfigurieren
- Die Missions-Testszene nutzt standardmaessig `objective_capture` als Siegbedingung.
- Der Fight endet, wenn das Friendly-Team das Objective gecaptured hat ODER alle Friendlies gleichzeitig down sind.

## Nicht-Ziele
- keine mehrstufigen Missionsziele
- keine Zeitlimit-Niederlage
- keine Score- oder Punktewertung
- keine Kampagnenfolgen aus dem Missionsergebnis
- keine Gegner-Siegbedingung (Gegner haben keine eigene Capture-Logik)

## Akzeptanzkriterien
- Mission endet bei Objective-Capture durch Friendlies → Sieg
- Mission endet wenn alle Friendlies gleichzeitig down → Niederlage
- Debrief zeigt Sieg/Niederlage und Bedingungstyp
- Elimination als Fallback-Siegbedingung funktioniert weiterhin
- Bestehender Meta-Layer-Rueckfluss (Debrief → FOB / Homebase) bleibt intakt

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add win/loss conditions with objective support (TASK_041)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
