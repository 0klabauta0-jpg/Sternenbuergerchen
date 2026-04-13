# TASK 004 – Registries

## Ziel
Zentrale Registries statt SceneTree-Vollscans einführen.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Prüfe den Git-Status
- Arbeite im lokalen Projekt `C:\dev\SternenBuergerchen`

## Aufgabe
- Implementiere:
  - `UnitRegistry`
  - `FTLRegistry`
  - optional `TileRegistry` als Platzhalter, wenn sinnvoll
- Ersetze offensichtliche direkte SceneTree-Abfragen im bearbeiteten Bereich durch Registry-Zugriff.
- Halte Registries klein und eindeutig.

## Nicht-Ziele
- kein globales Umschreiben des ganzen Projekts
- keine komplexen Caches über die Aufgabe hinaus

## Akzeptanzkriterien
- Registries existieren
- bearbeiteter Bereich nutzt Registries
- keine neuen Vollscans im Hotpath
- lokale Prüflogik dokumentiert

## Git-Schritte nach lokaler Prüfung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add runtime registries"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
