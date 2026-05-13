# TASK_400 - Agent Rules Doc Refresh

## Ziel
Die projektweiten Arbeitsanweisungen aktualisieren, damit neue Codex-Tasks die inzwischen gewachsene Architektur, die Dokumentenlandschaft und die "eine Wahrheit"-Regel konsequent beachten.

## Sinnhaftigkeit
Viele aktuelle Probleme entstehen nicht aus fehlendem Code, sondern aus Drift: UI-Pfade speichern versehentlich eigene Wahrheit, neue Tasks lesen nicht alle relevanten Contracts, Review-Befunde werden ohne Abgleich uebernommen oder Hotfixes bauen per-frame Rebuilds ein. Die Regeln existieren teilweise bereits, sollen aber zentraler und eindeutiger erreichbar sein.

## Umfang
- `AGENTS.md` als Arbeitsanweisung schaerfen, ohne Feature-Spezialregeln hineinzuschreiben.
- `docs/CODEX_RULES.md` um Wahrheitsquellen, Registry-Grenzen, relevante Docs und Doku-Hygiene erweitern.
- `docs/ARCHITECTURE.md` um einen kompakten Abschnitt zu Wahrheitsquellen und Grenzen ergaenzen.
- `docs/CODEX_TASK_PROMPT_TEMPLATE.md` auf die aktuellen Pflichtdokumente und Contract-Referenzen bringen.
- `docs/TASK_ROADMAP.md` und `docs/IMPLEMENTATION_STATUS.md` fuer Task-/Status-Hygiene aktualisieren.

## Nicht-Ziele
- Keine Gameplay- oder UI-Codeaenderung.
- Keine Feature-Contracts in `AGENTS.md` ausbreiten.
- Keine Neuordnung aller bestehenden Taskdateien.

## Relevante Contracts / Dokumente
- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/qa/regression_gate_coverage_crosswalk.md`

## Akzeptanz
- `AGENTS.md` beschreibt klar, dass Gameplay-Wahrheit nicht im UI liegt und Registries Lookup-/Index-Wahrheit sind.
- Pflicht-Leselisten nennen relevante Contracts, Reviews, QA- und Performance-Dokumente.
- Task-/Prompt-Vorlage fordert eine sichtbare Liste relevanter Contracts/Dokumente.
- Roadmap und Implementation Status sind aktualisiert.
- Keine Code-Dateien werden geaendert.

## Betroffene Dateien
- `AGENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/CODEX_TASK_PROMPT_TEMPLATE.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_400_agent_rules_doc_refresh.md`

## Pruefung
- [x] `git diff --check`

## Risiken / offene Punkte
- Regeln koennen nur wirken, wenn kuenftige Tasks sie wirklich lesen. Eine spaetere Docs-Audit-Aufgabe koennte pruefen, ob alte Task-Dateien nachtraeglich relevante Contract-Referenzen brauchen.
