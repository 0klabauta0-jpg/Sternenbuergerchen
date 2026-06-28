# TASK_535 - Pre-Mission FullHD Startflow Visual Pass

## Status: IMPLEMENTIERT

## Ziel / Problem
Nach TASK_534 ist die Startbereitschaft logisch sichtbar, aber der feste Homebase-Missionsbereich war noch auf den alten, sehr flachen Header zugeschnitten. Briefing, Minimap, Loadout-Empfehlung und Readiness konnten dadurch im FullHD-Startflow zu dicht wirken oder in die Arbeitsbereiche hineinlaufen.

## Sinnhaftigkeit / Ursache
Die Homebase ist der wichtigste Commander-Startpunkt. Der Spieler muss vor dem Start sehen koennen: Mission, Karte, empfohlene Ausruestung, Startbereitschaft und Startbutton. Wenn dieser Bereich optisch gequetscht ist, wirkt der Ablauf trotz richtiger Daten unfertig.

## Umfang
- Homebase-FullHD-Layout bekommt einen hoeheren Mission-Deck-Bereich und verschiebt Roster, Fireteams und Flightdeck sauber darunter.
- Briefing- und Readiness-Panels werden kompakter, mit festen Preview-Hoehen und weniger Textstau.
- Readiness bekommt kompakte Status-Chips in einer Flow-Zeile statt langer vertikaler Listen.
- Homebase expose't einen read-only Startflow-Visual-Snapshot mit Panel-Rechtecken, Kindhoehen, Ueberlappungs- und Startbutton-Metriken.
- Der laufende HTML-Bericht nennt TASK_535 als erledigten Zwischenstand und schlaegt den naechsten sinnvollen Anschluss vor.

## Nicht-Ziele
- Kein neuer Start-Guard.
- Keine neue Mission-, Loadout-, Dropship-, Cargo- oder Boarding-Wahrheit.
- Kein finaler Art-Style-Rewrite der Homebase.
- Kein manueller F6-Sichttest in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_briefing_contract.md`
- `docs/tasks/TASK_534_pre_mission_readiness_checklist.md`
- `docs/tasks/TASK_179_homebase_drop_light_fixed_fullhd_layout.md`
- `docs/tasks/TASK_528_rolling_html_status_report.md`

## Akzeptanzkriterien
- Mission-Deck, Roster, Fireteams und Flightdeck ueberlappen im FullHD-Contract nicht.
- Briefing plus Readiness passen in den Mission-Deck-Bereich ohne vertikalen Ueberlauf.
- Readiness bleibt read-only und folgt weiter `can_request_mission_start()`.
- Startbutton-Text und Tooltip spiegeln die Readiness-Summary, ohne selbst Gameplay-State zu setzen.
- Bestehende TASK_534- und Homebase-Fixed-Layout-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/meta/drop_light_layout_contract.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_535_pre_mission_fullhd_startflow_visual_pass.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_535_pre_mission_fullhd_startflow_visual_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_534_pre_mission_readiness_checklist.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Sichttest ist per Snapshot-Metrik abgesichert, aber nicht als echter F6-Screenshot bewertet.
- Der naechste UI-Schritt sollte die Startflow-Panels visuell mit echten Icons/Statusfarben und nicht nur ASCII-Markern polieren.
