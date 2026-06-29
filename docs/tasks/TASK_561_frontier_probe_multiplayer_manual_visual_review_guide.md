# TASK_561 - Frontier Probe Multiplayer Manual Visual Review Guide

## Status: IMPLEMENTIERT

## Ziel / Problem
Der laufende HTML-Bericht hat bereits einen MP-F6-Screenshot-/Hover-Notizblock. Nach TASK_560 ist aber klarer, was im manuellen Sichttest konkret bewertet werden soll: Teamchip-Hover, Objective-/Cargo-Zeilen, Selected-Fireteam-Kontext, Dropship-/Panel-Dichte und Weltverdeckung.

## Sinnhaftigkeit / Ursache
Ohne gefuehrte Bewertung landet die naechste UI-Korrektur schnell wieder bei Bauchgefuehl. Der Bericht soll die menschliche Sichtpruefung so strukturieren, dass der naechste Codex-Slice aus exportierten Notizen gezielt einen echten Reibungspunkt behebt.

## Umfang
- Der MP-F6-Review-Block im HTML-Bericht bekommt zusaetzliche Pflicht-/Bewertungsfelder.
- Bewertet werden Teamchip-Hover, Objective/Cargo, Selected Fireteam, Dropship-/Panel-Dichte, Weltverdeckung und naechste Polish-Prioritaet.
- Der JSON-Export bleibt Arbeitsnotiz und keine Runtime-/Gameplay-Wahrheit.
- TASK_558-Verifier wird auf die aktuelle Follow-up-Kette korrigiert.
- Neuer statischer TASK_561-Verifier prueft Bericht, Contract, Status, Roadmap und Export-Keys.

## Nicht-Ziele
- Kein behaupteter manueller Screenshot.
- Kein UI-Redesign und kein Gameplay-State.
- Kein Multiplayer-Transport-, Objective-, Cargo-, Combat- oder Command-Change.
- Keine Auswertung echter User-Notizen, solange noch kein Export vorliegt.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.md`
- `docs/tasks/TASK_560_frontier_probe_multiplayer_teamchip_tooltip_polish.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der HTML-Bericht enthaelt einen sichtbaren TASK_561-Guide im MP-F6-Review-Block.
- Der JSON-Export erfasst Detailchecks und Ratings fuer Teamchip-Hover, Objective/Cargo, Selected Fireteam, Paneldichte, Weltverdeckung und naechste Polish-Prioritaet.
- Der Bericht markiert weiterhin keinen manuellen Screenshot als erledigt.
- Roadmap und Status nennen TASK_561 als implementiert und TASK_562 als naechsten Anwendungsslice.
- TASK_561- und aktualisierter TASK_558-Verifier laufen gruen.

## Betroffene Dateien
- `docs/reports/project_review_status_2026_06_28.html`
- `scripts/tests/task_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.gd`
- `scripts/tests/task_561_frontier_probe_multiplayer_manual_visual_review_guide.gd`
- `docs/tasks/TASK_561_frontier_probe_multiplayer_manual_visual_review_guide.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_561_frontier_probe_multiplayer_manual_visual_review_guide.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Guide macht die Sichtpruefung besser auswertbar, ersetzt aber weiterhin keinen echten Blick auf das laufende F6-Fenster.
- Der naechste sinnvolle Schritt ist TASK_562: exportierte MP-F6-Review-Notizen in konkrete UI-/Layout-Korrekturen uebersetzen.
