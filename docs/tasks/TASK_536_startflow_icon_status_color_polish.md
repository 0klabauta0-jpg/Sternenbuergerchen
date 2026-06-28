# TASK_536 - Startflow Icon And Status Color Polish

## Status: IMPLEMENTIERT

## Ziel / Problem
TASK_535 hat den Pre-Mission-Startflow im FullHD-Deck platziert, aber die Readiness-Zeile war noch stark textuell. Die Marker `OK`, `!` und `X` waren zwar testbar, aber visuell noch zu schwach fuer einen angenehmen Commander-Workflow.

## Sinnhaftigkeit / Ursache
Der Spieler soll vor dem Missionsstart sehr schnell sehen, welche Punkte bereit, riskant oder blockiert sind. Statusfarben und kleine Indikatoren verbessern Lesbarkeit, ohne neue Startlogik einzufuehren.

## Umfang
- Readiness-Items werden als kompakte farbige Chips mit Status-Indikator und Label gerendert.
- Ready, Warn und Blocked bekommen eigene Farben, Tooltip bleibt detailreich.
- Startbutton expose't die Readiness-Farbe und den Status weiterhin aus dem bestehenden Readiness-Snapshot.
- Homebase-Snapshot expose't Icon-/Farb-/State-Daten fuer Regressionen.
- Rolling-HTML-Bericht nennt TASK_536 und schlaegt den naechsten sinnvollen Anschluss vor.

## Nicht-Ziele
- Kein neuer Start-Guard.
- Keine Aenderung an `can_request_mission_start()`.
- Keine neue Mission-, Loadout-, Dropship-, Cargo- oder Boarding-Wahrheit.
- Kein vollstaendiger Homebase-Art-Style-Rewrite.

## Relevante Contracts / Dokumente
- `docs/dev/mission_briefing_contract.md`
- `docs/tasks/TASK_535_pre_mission_fullhd_startflow_visual_pass.md`
- `docs/tasks/TASK_534_pre_mission_readiness_checklist.md`
- `docs/tasks/TASK_528_rolling_html_status_report.md`

## Akzeptanzkriterien
- Readiness-Chips haben pruefbare State-, Icon- und Color-Metadaten.
- Ready, Warn und Blocked unterscheiden sich sichtbar ueber Farbe und Tooltip.
- Startbutton-Metadaten spiegeln Readiness-State und Readiness-Farbe, ohne Startlogik zu veraendern.
- Bestehende TASK_535- und TASK_534-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_536_startflow_icon_status_color_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_536_startflow_icon_status_color_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_535_pre_mission_fullhd_startflow_visual_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_534_pre_mission_readiness_checklist.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Chips nutzen Godot-Controls und Farben, aber noch keine finalen Texture-Icons.
- Ein echter F6-/Screenshot-Sichttest bleibt fuer finale optische Balance offen.
