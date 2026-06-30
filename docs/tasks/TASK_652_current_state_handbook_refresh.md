# TASK_652 - Current State Handbook Refresh

## Ziel / Problem
Der HTML-Iststand-/Handbuchbericht stand noch auf TASK_648/TASK_650. Nach TASK_651 ist das irrefuehrend, weil Host/Client-Follow-up-Evidence inzwischen erledigt ist und der naechste sinnvolle Schritt wieder Richtung spielbarem Mini-Szenario gehen soll.

## Sinnhaftigkeit / Ursache
Der Bericht ist die schnelle Orientierung im Browser. Wenn er hinter dem Git-Stand herlaeuft, fuehrt er beim naechsten Playtest in die falsche Richtung.

## Umfang
- `project_current_state_handbook_2026_06_30.html` auf TASK_651 als letzten Stand aktualisieren.
- Empfohlenen naechsten Slice auf `TASK_653 - Frontier Probe One-Screen Playability Pass` setzen.
- JSON-Export-Metadaten um `updated_for_task = TASK_652` erweitern.
- Kleinen Verifier fuer Report-Inhalt, Export-Schluessel und Doku-Klammer ergaenzen.

## Nicht-Ziele
- Kein neuer Gameplay-Code.
- Kein echter Host/Client-Fensterlauf.
- Kein neuer zweiter Bericht neben dem bestehenden Handbuch.

## Relevante Contracts / Dokumente
- `docs/dev/html_report_workbench_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `docs/tasks/TASK_651_host_client_click_followup_evidence.md`

## Akzeptanzkriterien
- Bericht nennt TASK_651 als letzten Stand.
- Bericht empfiehlt TASK_653 als naechsten Gameplay-Slice.
- JSON-Export enthaelt `latest_completed_task`, `recommended_next_task`, `created_for_task` und `updated_for_task`.
- Report bleibt `sternenbuergerchen.html_workbench.v1` mit `JSON exportieren`.
- TASK_652 ist in Roadmap und Implementation Status sichtbar.

## Betroffene Dateien
- `docs/tasks/TASK_652_current_state_handbook_refresh.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `scripts/tests/task_652_current_state_handbook_refresh.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_652_current_state_handbook_refresh.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_649_current_state_handbook_report.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Bericht ist Orientierung und Arbeitsnotiz, keine Runtime-Wahrheit.
- TASK_653 ist eine Empfehlung, noch keine implementierte Gameplay-Aenderung.
