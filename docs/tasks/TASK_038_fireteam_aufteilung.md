# TASK 038 – Fireteam-Aufteilung

## Ziel
Die Fireteam-Auswahl (ALL / BLUE / GOLD) soll echte Gameplay-Wirkung haben: Orders gehen nur an die Units des gewaehlten Fireteams, und Units wissen, zu welchem Fireteam sie gehoeren.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Ist-Zustand
- `MissionTacticalSandboxController` hat bereits Q/E-Hotkeys fuer ALL / BLUE / GOLD.
- `_get_active_flow_drivers()` filtert schon nach Fireteam: BLUE = Alpha + Bravo, GOLD = Charlie, ALL = alle drei.
- Aber: jede `MissionCommandFlowDriver`-Instanz ist fest an genau eine `TestUnit` gebunden (unit_id). Es gibt keine datenbasierte Fireteam-Zugehoerigkeit auf Unit-Ebene.
- `RuntimeLeader` kennt keine Fireteam-Unterscheidung.

## Aufgabe

### 1. Fireteam-ID auf Unit-Ebene
- `TestUnit` erhaelt ein neues Property `fireteam_id: String` (z.B. `"blue"`, `"gold"`).
- `MissionTestSetup` setzt beim Registrieren die Fireteam-ID: Alpha + Bravo = `"blue"`, Charlie = `"gold"`.

### 2. Fireteam-ID im UnitRuntimeStatus
- `UnitRuntimeStatus` erhaelt ein optionales Feld `fireteam_id: String` fuer spaetere Abfragen.

### 3. Sichtbare Fireteam-Zugehoerigkeit
- `TestUnit` zeigt die Fireteam-ID als kleinen farbigen Text (BLUE = blau, GOLD = gelb) neben dem bestehenden Status-Label.

### 4. Bestehendes Verhalten beibehalten
- Die bestehende `_get_active_flow_drivers()`-Logik im `MissionTacticalSandboxController` bleibt erhalten – sie filtert bereits korrekt nach Fireteam.
- Kein Umbau der Driver-Architektur.

## Nicht-Ziele
- keine dynamische Fireteam-Zuweisung zur Laufzeit
- keine Fireteam-UI ueber den bestehenden Hotkey-Pfad hinaus
- kein Fireteam-spezifisches Verhalten im Combat-Loop
- keine Formation oder Gruppenlogik

## Akzeptanzkriterien
- Jede `TestUnit` hat eine `fireteam_id`
- In der Testszene ist sichtbar, welche Unit zu welchem Fireteam gehoert
- Orders ueber ALL / BLUE / GOLD gehen weiterhin korrekt an die zugehoerigen Units
- Keine Regression im bestehenden Command-Flow

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add fireteam assignment to units (TASK_038)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
