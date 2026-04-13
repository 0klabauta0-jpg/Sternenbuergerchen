# TASK 003 – SimulationRoot

## Ziel
Eine zentrale autoritative Stelle für State-Mutationen schaffen.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Prüfe den Git-Status
- Arbeite im lokalen Projekt `C:\dev\SternenBuergerchen`

## Aufgabe
- Implementiere `SimulationRoot`.
- Nutze `_physics_process()` als Commit-Stelle.
- Führe eine Command Queue ein.
- Stelle sicher, dass Gameplay-State nicht direkt aus UI oder FTL-Callbacks mutiert wird.
- Dokumentiere die Commit-Reihenfolge knapp im Code oder in der Datei.

## Nicht-Ziele
- keine vollständige Missionslogik
- keine komplette Netzwerksynchronisation
- kein Final-Balancing

## Akzeptanzkriterien
- SimulationRoot existiert
- Command Queue existiert
- State-Mutationen laufen zentral
- lokale Prüflogik dokumentiert

## Git-Schritte nach lokaler Prüfung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add SimulationRoot and command queue"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
