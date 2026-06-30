# TASK_639 - Frontier Probe Meta Debrief Route Smoke

## Ziel / Problem
TASK_638 macht im Missions-HUD sichtbar, dass die Frontier-Probe-Route in den Debrief und danach zur Homebase fuehrt. Der echte Meta-Weg muss als kleiner Smoke belegbar sein: Frontier-Probe-Ergebnis im Debrief anzeigen, Return-to-Homebase ausloesen und das Ergebnis auf dem Rueckweg erhalten.

## Sinnhaftigkeit / Ursache
Die Debrief-Homebase-Bruecke existiert seit TASK_586. Nach dem neuen Frontier-Probe-Handoff fehlte aber noch der spezifische Nachweis, dass ein Frontier-Probe-Resultat denselben Weg korrekt nutzt. Ohne diesen Smoke waere der Abschluss zwar im Missions-HUD lesbar, aber die Loop-Kette Mission -> Debrief -> Homebase nicht frontier-spezifisch abgesichert.

## Umfang
- `MetaLayerFlow` um einen read-only Frontier-Probe-Meta-Debrief-Route-Smoke-Snapshot erweitern.
- Den bestehenden TASK_586-Debrief-Return-Handoff wiederverwenden.
- Vor und nach dem Return pruefen: Debrief sichtbar, Return verfuegbar, Homebase sichtbar nach Return, MissionResult erhalten.
- Lokales Manifest fuer den Smoke schreiben.
- Reports, Roadmap, Contract und Verifier auf TASK_639 fortschreiben.

## Nicht-Ziele
- Kein neuer Debrief-Button im Missions-HUD.
- Kein neuer Meta-Navigationspfad.
- Keine neue MissionResult-, XP-, Skill-, Ammo-, Combat-, Movement- oder UI-Wahrheit.
- Kein visueller Debrief-Polish und keine Homebase-Progression-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_638_frontier_probe_debrief_handoff_feel.md`
- `docs/tasks/TASK_586_debrief_return_homebase_handoff.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- `get_frontier_probe_meta_debrief_route_smoke_snapshot()` liefert `schema = sternenbuergerchen.frontier_probe_meta_debrief_route_smoke.v1`.
- Der Snapshot erkennt `route_id = frontier_probe_aa_computer_cargo` oder `scenario_id = frontier_probe_vertical_slice`.
- Vor Return gilt: Debrief sichtbar, Homebase verborgen, Return-to-Homebase verfuegbar.
- Nach Return gilt: Homebase sichtbar, Debrief verborgen, Navigation sichtbar.
- `mission_result_preserved = true`, `active_mission_released = true`, `read_only = true` und `ui_sets_gameplay_truth = false`.
- Der Testhelper nutzt weiterhin nur den bestehenden TASK_586-Return-Handler.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_639_frontier_probe_meta_debrief_route_smoke.gd`
- `docs/tasks/TASK_639_frontier_probe_meta_debrief_route_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_639_frontier_probe_meta_debrief_route_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_638_frontier_probe_debrief_handoff_feel.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_586_debrief_return_homebase_handoff.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_639 ist ein Headless-Meta-Smoke, kein finaler sichtbarer Debrief-/Homebase-Polish.
- Der Debrief selbst kann noch dichter, schoener und spielerischer erklaert werden.
- Naechster sinnvoller Schritt: `TASK_640 - Frontier Probe Post Debrief Homebase Readability`, wenn der Homebase-Rueckkehrzustand nach Frontier-Probe spielerisch lesbarer werden soll.
