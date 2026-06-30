# TASK_632 - Frontier Probe Mini Scenario F6 Visual Review

## Ziel / Problem
TASK_631 macht die Frontier-Probe-Route als LZ/AA/COM/CARGO-Callouts sichtbar, aber der naechste Spielgefuehl-Schritt braucht ein reproduzierbares F6-Review-Artefakt. Ohne PNG/Manifest bleibt unklar, ob die Route im eigentlichen Missionsbild gut genug lesbar ist.

## Sinnhaftigkeit / Ursache
Die Mini-Mission soll nicht nur als Datenpfad funktionieren, sondern sich schnell als spielbare Idee lesen: landen, AA entfernen, Computer halten, Cargo rein und wieder raus. Dafuer muss der naechste Review sehen, ob Callouts, Mission-Control-Zusammenfassung und Primary3D-Snapshot zusammenpassen.

## Umfang
- Lokales F6-Visual-Review-Paket fuer die TASK_631-Callouts.
- PNG-Artefakt unter `tmp/` mit Viewport-Readback, wenn vorhanden, sonst bewusst markiertes Evidence-Board.
- Manifest mit Route-Callouts, Tone-Counts, Primary3D-Renderdaten, Review-Gates und offenen manuellen Checks.
- Rolling HTML-Report und Ist-Stand-/Handbuch-Bericht aktualisieren.
- Regression gegen TASK_631 und TASK_630.

## Nicht-Ziele
- Kein neues Missions- oder Objective-System.
- Kein Balancing der AA-, Computer- oder Cargo-Zeiten.
- Kein automatischer menschlicher Sichtentscheid.
- Kein Host/Client-Langlauf; dieser Task bewertet die lokale F6-Lesbarkeit der Mini-Szenario-Route.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_631_frontier_probe_mini_scenario_visual_feel_polish.md`
- `docs/dev/html_report_workbench_contract.md`

## Akzeptanzkriterien
- `scripts/tests/task_632_frontier_probe_mini_scenario_f6_visual_review.gd` erzeugt PNG und JSON-Manifest.
- Das Manifest bestaetigt TASK_631-Gate, vier Callouts, Tone-Counts, Primary3D-Callout-Count und Route-Summary.
- Headless-Fallback ist klar als Evidence-Board gekennzeichnet und nicht mit einem echten Sichttest verwechselt.
- Report und Handbuch exportieren die TASK_632-Felder und lassen den manuellen Sichtentscheid offen.
- TASK_631 und TASK_630 bleiben gruen.

## Betroffene Dateien
- `scripts/tests/task_632_frontier_probe_mini_scenario_f6_visual_review.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`
- aktuelle Report-Assertionen der vorherigen Tasks

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_632_frontier_probe_mini_scenario_f6_visual_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_631_frontier_probe_mini_scenario_visual_feel_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_630_frontier_probe_mini_scenario_feel_route.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das Headless-Board ersetzt keinen finalen menschlichen Fensterblick. Wenn TASK_632 zeigt, dass das Review-Paket bereit ist, sollte danach entweder ein echter Fenster-/Host-Client-Sichttest oder ein belegter Callout-Layout-Polish folgen.
