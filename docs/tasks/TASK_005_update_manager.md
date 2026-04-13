# TASK 005 – UpdateManager

## Ziel
Dirty-Flags und Batch-Updates als Lastbremse einführen.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Prüfe den Git-Status
- Arbeite im lokalen Projekt `C:\dev\SternenBuergerchen`

## Aufgabe
- Implementiere einen `UpdateManager`.
- Führe dirty-basierte Anmeldung für relevante Updates ein.
- Verarbeite Updates in Batches.
- Vermeide per-frame Vollupdates über alle Units.
- Halte die erste Version klein und nachvollziehbar.

## Nicht-Ziele
- kein komplettes Optimierungsframework
- kein vorgezogener Umbau aller Systeme

## Akzeptanzkriterien
- UpdateManager existiert
- Dirty-Flag-/Batch-Grundlage ist vorhanden
- keine offensichtlichen Vollupdates im bearbeiteten Bereich
- lokale Prüflogik dokumentiert

## Git-Schritte nach lokaler Prüfung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Add UpdateManager with dirty batch updates"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
