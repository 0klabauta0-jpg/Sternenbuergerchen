# TASK_103 – Suppression, Interruption und Return-to-Plan

## Ziel
Fireteams reagieren auf Treffer und Nahmiss-Situationen mit einem echten Suppression-Zustand, koennen aktive Wegpunkte unterbrechen und spaeter automatisch oder manuell in den Phasenplan zurueckkehren.

## Status: OFFEN

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_101_fireteambehaviorresolver_und_standardverhalten.md](docs/tasks/TASK_101_fireteambehaviorresolver_und_standardverhalten.md)
- Lies [docs/tasks/TASK_102_suppression_und_return_to_plan.md](docs/tasks/TASK_102_suppression_und_return_to_plan.md)
- Pruefe den Git-Status

## Aufgabe

### 1. Fireteam-Suppression-Zustand
- Zaehler pro Fireteam.
- Erhoeht sich bei Treffern und Nahmissen.
- Sinkt pro Tick ueber konfigurierbaren Decay.
- `leadership` beschleunigt den Decay.
- `calm` verdoppelt den Decay.
- `reckless` erhoeht die Toleranz deutlich.

### 2. Wirkung bei Suppression
- `speed` aller Members sinkt auf 0.3 oder auf 0.0 bei starker Suppression.
- `hit_chance` erhaelt einen Malus von `-0.3`.
- Cover-Tiles werden gegenueber Wegpunkt-Fortschritt priorisiert.
- `fire_discipline` wird intern auf `semi_disciplined` gesetzt.
- `hold_till_last_man` ignoriert Suppression vollstaendig.

### 3. Interruption und Rueckkehr
- Aktive Wegpunkte koennen auf `interrupted` wechseln.
- Nach Stabilisierung versucht das Fireteam selbststaendig zum naechsten `pending`-Wegpunkt zurueckzukehren.
- Ein manueller `Return to Plan`-Button ist pro Fireteam verfuegbar.

### 4. `FireteamStatusPanel`
- Zeigt Suppression-Zustand.
- Zeigt aktiven Ad-hoc-Hinweis.
- Bietet den `Return to Plan`-Button.
- Zeigt den aktuellen Lead-Stern lesbar an.

## Nicht-Ziele
- keine Morale-/Panik-Kampagne
- keine neue Ballistik
- kein Munitionssystem

## Akzeptanzkriterien
- Fireteams koennen supprimiert werden.
- Suppression wirkt auf Bewegung, Trefferchance und Cover-Prioritaet.
- Wegpunkte koennen unterbrochen und spaeter fortgesetzt werden.
- Ein manueller und ein automatischer Rueckkehrpfad existieren.
