# TASK_747 - Station Scenario Homebase Visible Readiness Review

## Ziel / Problem
Nach TASK_746 fuehrt die Homebase nach dem Station-Debrief in die naechste Sortie-Vorbereitung. Jetzt muss dieser Zustand als sichtbarer Homebase-Review belegbar werden: Summary und Next-Sortie-Zeile muessen im MissionPanel sichtbar, geordnet, kompakt und ohne Overflow/Overlap sein.

## Sinnhaftigkeit / Ursache
Die Review-Probleme drehen sich nicht nur um technische Gates, sondern um Lesbarkeit und Spielgefuehl. Der Frontier-Pfad hat dafuer seit TASK_642 einen sichtbaren Review-Snapshot mit Rects, Bounds, Reihenfolge und Evidence-PNG. Die Station-Route braucht denselben Review-Anker, bevor ein echter Host/Client-Fensterlauf oder weiterer Polish sinnvoll bewertet werden kann.

## Umfang
- Station-spezifischen Snapshot `get_station_scenario_homebase_visible_readiness_review_snapshot()` ergaenzen.
- Bestehende Homebase-Followup-Controls lesen: Post-Debrief-Summary, Next-Sortie-Readiness, FollowupPanel, MissionPanel.
- Sichtbarkeit, Reihenfolge, Bounds, Overlap, Overflow und Kompaktheit pruefen.
- Headless-Verifier mit FullHD-Evidence-PNG und JSON-Manifest ergaenzen.
- TASK_746, TASK_745 und Frontier-TASK_642 als Regression stabil halten.
- Contract, Status, Roadmap und HTML-Handbuch fortschreiben.

## Nicht-Ziele
- Kein neuer Homebase-Startpfad.
- Keine Navigation, kein Command, kein Startbutton-Commit.
- Keine Progression-/XP-Berechnung.
- Keine MissionResult- oder Staging-Mutation in der UI.
- Kein echter Host/Client-Fensterlauf.
- Kein groesserer Homebase-Layoutumbau.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_746_station_scenario_homebase_next_sortie_readiness.md`
- `docs/tasks/TASK_745_station_scenario_post_debrief_homebase_readability.md`
- `docs/tasks/TASK_642_frontier_probe_homebase_visible_readiness_review.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Der Snapshot liefert `schema = sternenbuergerchen.station_scenario_homebase_visible_readiness_review.v1`.
- `readiness_gate = pass`, `route_id = station_route_aa_door_computer_cargo`, `scenario_id = station_route_one_screen_multiplayer_drill`.
- `post_summary_visible = true`, `next_sortie_visible = true`, `followup_panel_visible = true`.
- Post-Summary und Next-Sortie-Zeile liegen im MissionPanel und im FollowupPanel.
- Next-Sortie steht unter der Post-Summary und beide Zeilen ueberlappen nicht.
- Das MissionPanel laeuft nicht ueber.
- Die Next-Sortie-Zeile bleibt einzeilig und kompakt.
- `manual_review_required = true`, `manual_review_done = false`.
- `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_navigation = false`, `creates_command = false`.
- Verifier schreibt `tmp/station_scenario_homebase_visible_readiness_review.png` und `.json`.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_747_station_scenario_homebase_visible_readiness_review.gd`
- `docs/tasks/TASK_747_station_scenario_homebase_visible_readiness_review.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_747_station_scenario_homebase_visible_readiness_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_746_station_scenario_homebase_next_sortie_readiness.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_642_frontier_probe_homebase_visible_readiness_review.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
TASK_747 ist ein Headless-/Evidence-Review. Er sagt, dass die Homebase-Controls geometrisch und textlich plausibel sind, ersetzt aber keinen echten Host/Client-Fensterblick. Der naechste sinnvolle Schritt ist danach entweder ein Station-Homebase-Visual-Polish-Findings-Slice oder der echte Host/Client-Recapture.
