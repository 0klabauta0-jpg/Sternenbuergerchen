# TASK 044 – Gegner-Reaktion auf Kontakt

## Ziel
Enemy-Units sollen bei Beschuss nicht einfach stehenbleiben, sondern sich minimal repositionieren, um den Kampf weniger statisch wirken zu lassen.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Pruefe den Git-Status

## Abhaengigkeit
- TASK_043 (Gegner-Positionierung) muss vorher implementiert sein.

## Ist-Zustand (nach TASK_043)
- Enemy-Units ruecken Richtung Objective vor und stoppen bei Kontakt.
- Es gibt keine Reaktion auf eingehenden Schaden.
- Enemies feuern bei LOS-Kontakt, aendern aber ihre Position nicht mehr.

## Aufgabe

### 1. Reaktions-Offset bei Schaden
- Wenn eine Enemy-Unit Schaden erhaelt (`damage`-Effect wird angewendet), soll sie sich um einen kleinen zufaelligen Offset von ihrer aktuellen Position wegbewegen (z.B. 30–60px in eine zufaellige Richtung).
- Bewegung erfolgt ueber `SimulationRoot.enqueue_command()` mit `move_to_position`.
- Nur wenn die Unit noch `fit` ist.

### 2. Cooldown fuer Repositionierung
- Maximal eine Repositionierung alle 3–5 Sekunden (konfigurierbar), damit Enemies nicht permanent herumspringen.
- Einfacher Timer-/Tick-Counter pro Enemy-Unit.

### 3. Richtung weg vom Angreifer
- Wenn der `attacker_id` aus dem Hit-Kontext bekannt ist, soll der Offset bevorzugt weg vom Angreifer zeigen (statt rein zufaellig).
- Fallback: zufaelliger Offset wenn kein Angreifer bekannt.

## Nicht-Ziele
- keine echte Deckungssuche (kein Terrain-Cover-System)
- keine taktische KI-Entscheidung
- keine Gruppenreaktion
- keine Flucht- oder Retreat-Logik

## Akzeptanzkriterien
- Enemy-Units bewegen sich bei Schaden leicht weg
- Repositionierung hat einen Cooldown
- Richtung zeigt bevorzugt weg vom Angreifer
- Kein Einfluss auf Friendly-Unit-Verhalten
- Bestehende Kampf- und Respawn-Logik bleibt intakt

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add enemy repositioning on damage (TASK_044)"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
