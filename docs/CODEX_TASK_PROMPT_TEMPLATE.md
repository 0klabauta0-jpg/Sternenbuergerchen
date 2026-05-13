# CODEX_TASK_PROMPT_TEMPLATE

Nutze diese Vorlage fuer jede Codex-Aufgabe in VS / VS Code.

## Startprompt
Arbeite im lokalen Projekt:
`C:\dev\SternenBuergerchen`

Lies zuerst:
- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- die konkrete Task-Datei unter `docs/tasks/`

Lies ausserdem, falls relevant:
- passende Contracts unter `docs/dev/`
- passende Reviews unter `docs/reviews/`
- passende QA-/Performance-Dokumente unter `docs/qa/` oder `docs/performance/`
- `docs/GDD_STATUS.md`, falls das alte GDD/DOCX als Quelle benutzt wird

Relevante Contracts / Dokumente fuer diese Aufgabe:
- <hier eintragen>

Wichtige Vorgaben:
- aendere nur die fuer die Aufgabe noetigen Dateien
- keine grossen Refactors ohne klaren Zwang
- Gameplay-Wahrheit bleibt in Simulation/Runtime/Contracts/Registries, nicht in UI
- Registries fuer Lookup nutzen, keine SceneTree-Vollscans im Hotpath
- keine per-frame Komplett-Rebuilds von HUD oder grossen UI-Trees
- pruefe lokal im Godot-Projekt, soweit fuer die Aufgabe sinnvoll
- aktualisiere `docs/IMPLEMENTATION_STATUS.md`
- aktualisiere `docs/TASK_ROADMAP.md` nur bei Task-Status/Reihenfolge
- committe nach erfolgreicher lokaler Pruefung
- pushe nach GitHub, wenn der Remote vorhanden und erreichbar ist
- wenn Push scheitert: klar benennen

Lieferformat:
1. Problem
2. Ursache
3. Aenderung
4. betroffene Dateien
5. Risiken / offene Punkte
6. lokale Prueflogik
7. Git-Status / Commit / Push-Status
