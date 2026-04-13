# TASK 006 – VS/Codex/GitHub-Workflow absichern

## Ziel
Den lokalen VS/Codex-Workflow gegen das Godot-Projekt sauber absichern.

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Prüfe den Git-Status
- Arbeite im lokalen Projekt `C:\dev\SternenBuergerchen`

## Aufgabe
- Prüfe und dokumentiere, welche Projektpfade, Szenen- oder Script-Orte für Codex relevant sind.
- Ergänze nur wenn nötig Hilfsdokumentation oder kleine Workflow-Dateien im Repo.
- Stelle sicher, dass Tasks klar auf das lokale Projekt `C:\dev\SternenBuergerchen` verweisen.
- Falls bereits GitHub-Remote vorhanden ist, nutze den bestehenden Remote statt etwas Neues zu erfinden.

## Nicht-Ziele
- kein Umbau der Spielarchitektur
- keine CI-Pipeline
- keine Repo-Neustrukturierung

## Akzeptanzkriterien
- Workflow im Repo ist klar dokumentiert
- lokale Prüfschritte für Godot und GitHub sind genannt
- keine unnötigen Strukturänderungen
- lokale Prüflogik dokumentiert

## Git-Schritte nach lokaler Prüfung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Document VS Codex GitHub workflow"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` aktualisieren
