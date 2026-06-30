# TASK_630 - Frontier Probe Mini Scenario Feel Route

## Ziel / Problem
Nach TASK_629 ist der Host/Client-Klicklauf als Packet vorbereitet. Fuer das eigentliche Spielgefuehl braucht die aktuelle Frontier-Probe-Mission aber einen klaren, kleinen Playtest-Loop: Wo starte ich, warum schalte ich AA aus, warum halte ich den Computer, wann darf Cargo landen und was pruefe ich danach?

## Sinnhaftigkeit / Ursache
Die Route existiert bereits in Daten und Einzel-Smokes, ist aber als spielerischer Mini-Szenario-Ablauf nur indirekt sichtbar. Ohne einen kompakten Route-/Feel-Snapshot driftet der naechste Test wieder in technische Einzelchecks statt in die Frage: fuehlt sich das als kleine Mission gut, lesbar und multiplayerfaehig an?

## Umfang
- `MissionTacticalSandboxController` liefert einen read-only `get_frontier_probe_mini_scenario_feel_route_snapshot()`.
- Der Snapshot buendelt Scenario-Daten, Vertical-Slice-Flow, Ownership, AA-/Computer-/Cargo-Gates und Mission-Control-Lesbarkeit.
- Ein Verifier prueft die Route gegen die echte Frontier-Probe-Fixture.
- Reports und Statusdateien nennen TASK_630 als aktuellen spielerischen Folgepunkt.

## Nicht-Ziele
- Kein neues Missionssystem.
- Kein Combat-Rewrite.
- Kein automatischer Host/Client-Klicktest.
- Kein neues HUD-Panel.
- Keine neue Gameplay-Wahrheit in UI oder Verifier.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_629_host_client_real_click_playtest_evidence_pass.md`
- `docs/tasks/TASK_554_frontier_probe_integrated_objective_playthrough_smoke.md`
- `docs/tasks/TASK_555_frontier_probe_multiplayer_objective_ownership_smoke.md`
- `data/mission_scenarios/frontier_probe_vertical_slice.json`

## Akzeptanzkriterien
- Der Snapshot nennt `TASK_630`, bleibt `read_only = true` und setzt `ui_sets_gameplay_truth = false`.
- Die Route enthaelt mindestens drei spielerische Beats: AA ausschalten, Computer halten, Cargo landen/abziehen.
- Alpha ist der Angreifer/Spielerpfad, Bravo bleibt Solo-NPC und PvP-zuweisbar.
- Die AA-Gruppe ist als relevante Raketen-/Anti-Armor-Bedrohung sichtbar und blockiert Cargo vor Abschluss.
- Computer-Hold nennt die 18 Sekunden.
- Cargo-Ziel bleibt `spawn_alpha` und verlangt den AA-Schritt.
- Der integrierte Objective/Cargo-Playthrough und Multiplayer-Ownership bleiben gruen.
- Der Snapshot empfiehlt danach entweder echten Host/Client-Klicklauf oder Mini-Szenario-Visual/Feel-Polish.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_630_frontier_probe_mini_scenario_feel_route.gd`
- `docs/tasks/TASK_630_frontier_probe_mini_scenario_feel_route.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_630_frontier_probe_mini_scenario_feel_route.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_629_host_client_real_click_playtest_evidence_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_554_frontier_probe_integrated_objective_playthrough_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_555_frontier_probe_multiplayer_objective_ownership_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_630 macht die Route pruefbar und sichtbar, aber noch keinen finalen balancierten Encounter.
- Der echte Zwei-Fenster-Klicklauf aus TASK_629 bleibt sinnvoll; falls dort UI-Reibung auftritt, hat diese Vorrang vor weiterem Scenario-Polish.
