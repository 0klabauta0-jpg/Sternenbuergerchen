# TASK 046 – Unit-Skill-Werte

## Ziel
Jede Unit soll individuelle Faehigkeitswerte haben (Schiessen, Bewegung, Fuehrung), die spaeter das Gameplay beeinflussen.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Ist-Zustand
- `TestUnit` hat `max_health_points` und einen festen Vital-/Runtime-Status, aber keine individuellen Skill-Werte.
- `DamageModel` berechnet Treffer mit fester `hit_chance` aus dem Effect-Dictionary, ohne Unit-spezifische Modifikation.
- Bewegungsgeschwindigkeit ist einheitlich fuer alle Units.

## Aufgabe

### 1. Skill-Datenmodell
- Neues kleines RefCounted-Modell `UnitSkills` unter `res://scripts/npc/unit_skills.gd`:
  - `accuracy: float` (0.0–1.0, default 0.5) – Treffsicherheit
  - `speed: float` (0.0–1.0, default 0.5) – Bewegungstempo
  - `leadership: float` (0.0–1.0, default 0.3) – Fuehrungsqualitaet (spaeter relevant fuer FTL-Wirkung)
  - `toughness: float` (0.0–1.0, default 0.5) – Widerstandsfaehigkeit / Schadensreduktion
  - Methoden: `to_dict() -> Dictionary`, statische `from_dict(data: Dictionary) -> UnitSkills`

### 2. TestUnit: Skills integrieren
- `TestUnit` erhaelt ein Property `skills: UnitSkills` (erstellt in `_ready()` mit Default-Werten).
- Export-Properties fuer die vier Skillwerte, damit sie pro Unit in der Szene konfigurierbar sind.

### 3. MissionTestSetup: Unterschiedliche Skills
- Die drei Friendly-Units erhalten leicht unterschiedliche Skillwerte, damit der Unterschied spaeter spuerbar wird:
  - Alpha: accuracy=0.6, speed=0.4, leadership=0.2, toughness=0.5
  - Bravo: accuracy=0.4, speed=0.6, leadership=0.3, toughness=0.4
  - Charlie: accuracy=0.5, speed=0.5, leadership=0.6, toughness=0.6
- Enemy-Units: einheitlich accuracy=0.4, speed=0.3, toughness=0.5.

### 4. Sichtbarkeit
- `TestUnit` zeigt im Debug-Label einen kompakten Skill-Hinweis (z.B. `A:0.6 S:0.4`).

## Nicht-Ziele
- keine Skill-Wirkung im Gameplay (das folgt in TASK_047)
- keine Skill-Entwicklung oder -Veraenderung zur Laufzeit
- keine UI-Anzeige in der Homebase (das folgt in TASK_049)
- kein Balancing

## Akzeptanzkriterien
- Jede `TestUnit` hat individuelle Skill-Werte
- Skills sind in der Szene pro Unit konfigurierbar
- Skill-Werte sind im Debug-Label sichtbar
- Bestehende Kampf- und Bewegungslogik bleibt unveraendert (Skills haben noch keine Wirkung)

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add unit skill data model (TASK_046)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
