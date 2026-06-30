# TASK_640 - Frontier Probe Post Debrief Homebase Readability

## Ziel / Problem
Nach TASK_639 ist der technische Meta-Weg Frontier Probe -> Debrief -> Homebase gruen. Auf der Homebase soll der Spieler nach dem Return aber auch sofort lesen koennen, dass der Debrief abgeschlossen ist, welches Frontier-Probe-Ergebnis zurueckgetragen wurde und welcher naechste Homebase-Schritt sinnvoll ist.

## Sinnhaftigkeit / Ursache
Der Core Loop lebt vom Ruecksprung in die Homebase. Wenn dort nur wieder der normale Missions-/Staging-Zustand steht, wirkt der Abschluss trotz korrektem Debrief technisch leer. Eine kompakte read-only Ergebniszeile macht den Loop fuer Spieler besser begreifbar, ohne Progression, MissionResult oder Navigation neu zu erfinden.

## Umfang
- Homebase bekommt eine kompakte Post-Debrief-Summary-Zeile im MissionPanel.
- `MetaLayerFlow` reicht das vorhandene `_last_mission_result` an die Homebase weiter.
- `HomebaseTestScreen.get_frontier_probe_post_debrief_homebase_readability_snapshot()` prueft Route, Ergebnis, Debrief/Homebase-Hinweis, Next-Step und read-only-Grenzen.
- Verifier, Contract, Status, Roadmap und HTML-Berichte auf TASK_640 fortschreiben.

## Nicht-Ziele
- Keine neue Homebase-Navigation.
- Keine neue XP-/Skill-/Roster-Berechnung.
- Keine neue MissionResult-Wahrheit in der UI.
- Kein groesserer Homebase-Layoutumbau.
- Kein neuer Debrief-Screen-Polish.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_639_frontier_probe_meta_debrief_route_smoke.md`
- `docs/tasks/TASK_594_post_mission_skill_delta_homebase_bridge.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- Die Homebase zeigt nach dem Debrief-Return eine kompakte Zeile wie `Debrief complete -> Homebase | Frontier Probe / VICTORY / ... | Next: ...`.
- Der Snapshot liefert `schema = sternenbuergerchen.frontier_probe_post_debrief_homebase_readability.v1`.
- `route_id = frontier_probe_aa_computer_cargo` und `scenario_id = frontier_probe_vertical_slice` bleiben lesbar.
- `summary_label_visible = true`, `frontier_probe_result_present = true`, `mission_result_preserved = true`.
- `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_navigation = false`, `creates_command = false`.
- Die Summary bleibt kompakt und einzeilig.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_640_frontier_probe_post_debrief_homebase_readability.gd`
- `docs/tasks/TASK_640_frontier_probe_post_debrief_homebase_readability.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_640_frontier_probe_post_debrief_homebase_readability.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_639_frontier_probe_meta_debrief_route_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_586_debrief_return_homebase_handoff.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_640 verbessert die Rueckkehrlesbarkeit, ersetzt aber keinen echten sichtbaren Homebase-Spielgefuehltest.
- Der naechste sinnvolle Schritt ist `TASK_641 - Frontier Probe Homebase Next Sortie Readiness`, wenn aus der Rueckkehrzeile ein klarerer Vorbereitungsfluss fuer die naechste Mission entstehen soll.
