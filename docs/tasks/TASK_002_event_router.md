# TASK 002 – EventRouter

## Ziel
Zentrale Event-/Signal-Entkopplung einführen.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Prüfe den Git-Status
- Arbeite im lokalen Projekt `C:\dev\SternenBuergerchen`

## Aufgabe
- Erstelle einen EventRouter als zentrale Stelle für Gameplay-Ereignisse.
- Definiere erste Signale für:
  - squad_command
  - unit_down
  - threat_detected
- Binde RuntimeLeader so an, dass Commands nicht hart direkt in andere Systeme geschrieben werden.
- Halte die Signale schmal und dokumentierbar.

## Nicht-Ziele
- keine komplette Gameplay-Pipeline
- keine UI-Effekte
- kein globales Rework aller vorhandenen Signale

## Akzeptanzkriterien
- EventRouter existiert
- mindestens die Basissignale sind implementiert
- RuntimeLeader nutzt Router/Signale statt harter Kopplung
- lokale Prüflogik dokumentiert

## Git-Schritte nach lokaler Prüfung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add central EventRouter"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
