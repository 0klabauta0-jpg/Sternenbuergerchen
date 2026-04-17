# TASK 039 – Phasen-Wirkung

## Ziel
Die Phasen-Auswahl (APPROACH / ASSAULT / HOLD) soll echte Gameplay-Wirkung auf das Unit-Verhalten haben: Bewegungstempo, Feuerverhalten und taktische Vorsicht sollen sich je nach Phase unterscheiden.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Ist-Zustand
- `MissionTacticalSandboxController` hat R/F-Hotkeys fuer APPROACH / ASSAULT / HOLD.
- `_current_phase_index` wird bei `issue_command()` als `phase_override` an `MissionCommandFlowDriver.issue_command()` weitergegeben.
- `CommanderCommand` hat ein `phase`-Feld (int).
- `RuntimeLeader` leitet taktische Unterschiede fuer `defend`, `move`, `flank` ab, aber die Phase hat keinen Einfluss auf `UnitCommand`-Werte wie Tempo, `fire_mode` oder `cover_score`.
- `SimulationRoot` bewegt Units mit festem `move_speed_factor` ohne Phaseneinfluss.

## Aufgabe

### 1. Phasen-Konstanten definieren
- In `CommanderCommand` oder als eigene kleine Konstanten-Klasse die drei Phasen formalisieren:
  - `PHASE_APPROACH = 0` – vorsichtig, langsam, hold_fire
  - `PHASE_ASSAULT = 1` – schnell, fire_at_will, niedriger cover_score
  - `PHASE_HOLD = 2` – stationaer, fire_at_will, hoher cover_score

### 2. RuntimeLeader: Phase in UnitCommand abbilden
- Wenn `RuntimeLeader` einen FTLTask in UnitCommands uebersetzt, soll die Phase folgende Werte beeinflussen:
  - `move_speed_factor`: APPROACH = 0.5, ASSAULT = 1.5, HOLD = 0.0
  - `fire_mode`: APPROACH = `hold_fire`, ASSAULT = `fire_at_will`, HOLD = `fire_at_will`
  - `cover_score`-Bonus: APPROACH = +20, ASSAULT = +0, HOLD = +30

### 3. SimulationRoot: move_speed_factor beruecksichtigen
- Der bestehende Move-Pfad in `SimulationRoot` soll `move_speed_factor` aus dem UnitCommand / UnitRuntimeStatus lesen und die Bewegungsgeschwindigkeit entsprechend skalieren.
- HOLD (0.0) bedeutet: keine Bewegung, Unit bleibt stehen.

### 4. Sichtbares Feedback
- `TestUnit` zeigt die aktive Phase als kleinen Text (z.B. `APR`, `ASS`, `HLD`) neben dem bestehenden Status-Label.

## Nicht-Ziele
- keine komplexe Verhaltens-KI pro Phase
- keine phasenabhaengige Zielwahl oder Formationslogik
- keine automatischen Phasenwechsel
- kein Phasen-Einfluss auf Gegner (Gegner haben keine eigene Befehlskette)

## Akzeptanzkriterien
- APPROACH-Units bewegen sich langsamer und feuern nicht
- ASSAULT-Units bewegen sich schneller und feuern bei Kontakt
- HOLD-Units bleiben stehen und feuern bei Kontakt
- Phase ist an der Unit sichtbar
- Bestehende taktische Unterschiede (defend/flank cover_score, attack_bonus) werden mit Phasenwerten kombiniert, nicht ersetzt

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add phase gameplay effects (TASK_039)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
