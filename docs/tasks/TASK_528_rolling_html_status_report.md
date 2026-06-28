# TASK_528 - Rolling HTML Status Report

## Ziel / Problem
Der bestehende Gesamt-Review-Report soll nicht nur ein statischer Rueckblick sein, sondern waehrend der laufenden Arbeit als aktualisierbarer HTML-Zwischenbericht dienen.

## Sinnhaftigkeit / Ursache
Die Entwicklung bewegt sich gerade schnell durch kleine Mission-, Multiplayer-, Editor- und Export-Slices. Ohne sichtbaren Zwischenstand gehen erledigte Schritte, offene Reibungen und die naechste sinnvolle Prioritaet im Chat leicht verloren.

## Umfang
- Den bestehenden Report `docs/reports/project_review_status_2026_06_28.html` als laufenden Arbeitsbericht aktualisieren.
- Klar sichtbar machen:
  - zuletzt erledigte Tasks
  - aktueller Arbeitsstand
  - offene Risiken/Reibungen
  - naechste empfohlene Tasks
  - lokale Prueflogik
- Den JSON-Export weiter nach `docs/dev/html_report_workbench_contract.md` kompatibel halten.
- `docs/IMPLEMENTATION_STATUS.md` und `docs/TASK_ROADMAP.md` auf den neuen Zwischenstand bringen.

## Nicht-Ziele
- Kein Runtime-Code.
- Keine neue Gameplay-Wahrheit.
- Kein neues Missions-, UI- oder Multiplayer-Verhalten.
- Kein vollstaendiger neuer Reviewbericht neben dem bestehenden Report.

## Relevante Contracts / Dokumente
- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/html_report_workbench_contract.md`

## Akzeptanzkriterien
- Der HTML-Report nennt TASK_528 als Berichtspflege und verschiebt die naechsten Gameplay-/UI-Schritte sichtbar weiter.
- Der Report enthaelt einen klaren Zwischenstandsbereich mit erledigten, offenen und empfohlenen naechsten Punkten.
- `JSON exportieren` bleibt vorhanden und exportiert `recommended_next_tasks`, `recently_completed_tasks`, `open_risks` und Report-Metadaten.
- Status und Roadmap stimmen mit dem Report ueberein.

## Betroffene Dateien
- `docs/tasks/TASK_528_rolling_html_status_report.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `git diff --check`
- HTML-Struktur-/Export-Sanity per lokalem Textcheck.

## Risiken / offene Punkte
- Der Report ist ein Arbeitsartefakt und ersetzt keinen echten F6-Sichttest.
- Der naechste spielbare Fortschritt bleibt danach Icon-/Briefing-/Playtest-Polish, nicht noch mehr Berichtspflege.
