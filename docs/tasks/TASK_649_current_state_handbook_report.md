# TASK_649 - Current State Handbook Report

## Ziel / Problem
Der aktuelle Projektstand ist in vielen kleinen Review-, Smoke- und Playtest-Slices abgesichert, aber die Orientierung fuer den naechsten menschlichen Blick wird unuebersichtlich. Der User braucht einen neuen HTML-Bericht, der Iststand und Handbuch verbindet.

## Sinnhaftigkeit / Ursache
Die letzten Tasks haben Homebase-Re-Entry, MissionPanel-Dichte und Next-Sortie-Cue verbessert. Danach soll der Blick wieder groesser werden: Was ist spielbar, wo reibt es, wie prueft man es, und welcher naechste Slice bringt das Spiel in Richtung angenehm, spielbar, schoen und multiplayerfaehig?

## Umfang
- Neuer interaktiver HTML-Report unter `docs/reports/`.
- Report mischt Iststand, Handbuch, Reibungen, Playtest-Notizen und naechste Schritte.
- JSON-Export bleibt lokal per `file://` nutzbar.
- Kleine Verifier-Pruefung auf Pflichtbereiche, Export-Vertrag und aktuelle Task-Verweise.

## Nicht-Ziele
- Keine Runtime-, UI- oder Gameplay-Logik aendern.
- Kein neuer Combat-, Multiplayer- oder Editor-Umbau.
- Kein Ersatz fuer echte F6-/Fenster-Playtests.

## Relevante Contracts / Dokumente
- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/reports/_html_workbench_template.html`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`
- `docs/reports/project_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Neuer Report existiert als eigenstaendige HTML-Workbench.
- Er enthaelt Iststand, Handbuch, Reibungen, Playtest-Checkliste und Roadmap/Next-Block.
- Sichtbarer Button `JSON exportieren` ist vorhanden.
- Export-Schema `sternenbuergerchen.html_workbench.v1` ist im Dokument verankert.
- Der Bericht benennt TASK_648 als abgeschlossenen Stand und TASK_650 als naechsten Gameplay-Slice-Kandidaten.
- Verifier laeuft lokal gruen.

## Betroffene Dateien
- `docs/tasks/TASK_649_current_state_handbook_report.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `scripts/tests/task_649_current_state_handbook_report.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_649_current_state_handbook_report.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Report ist Orientierung und Arbeitsnotiz, keine Gameplay-Wahrheit.
- Echte Fenster-/Playtest-Erkenntnisse muessen weiterhin in konkreten Folge-Tasks landen.
