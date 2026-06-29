# TASK_554 - Frontier Probe Integrated Objective Playthrough Smoke

## Status: IMPLEMENTIERT

## Ziel / Problem
AA-Shutdown, Computer-Hold und Cargo-Extract sind einzeln lesbar, aber noch nicht als ein zusammenhaengender Frontier-Probe-Missionsabschluss abgesichert.

## Sinnhaftigkeit / Ursache
Der Spieler soll den Scenario-Slice als Ablauf verstehen: Luftabwehr aus, Stationscomputer halten, Frachter landet, Frachter hebt ab, Mission komplett. Die bestehenden TASK_552- und TASK_553-Snapshots pruefen Teilblicke; TASK_554 verbindet sie zu einem integrierten Playthrough-Smoke.

## Umfang
- Read-only Snapshot `get_frontier_probe_integrated_objective_playthrough_snapshot()`.
- Headless-Smoke, der die reale Mission-Testszene mit Frontier-Probe-Scenario konfiguriert.
- Pruefung von AA-, Computer- und Cargo-Gates in einem Ablauf.
- Pruefung von Mission-Control-Text, Objective-Visual, Cargo-Visual und finaler Gate-Completion.
- Rolling-HTML-Bericht wird auf TASK_554 aktualisiert und nennt den naechsten sinnvollen Anschluss.

## Nicht-Ziele
- Kein neues Objective-System.
- Kein neues Cargo-System.
- Kein Combat-Rewrite.
- Kein manuell behaupteter F6-Sichttest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_552_mission_objective_interaction_readability_pass.md`
- `docs/tasks/TASK_553_mission_cargo_extract_readability_pass.md`
- `docs/tasks/TASK_518_mission_scenario_runtime_gates.md`
- `data/mission_scenarios/frontier_probe_vertical_slice.json`

## Akzeptanzkriterien
- Der integrierte Snapshot meldet Objective- und Cargo-Readability-Snapshots gruen.
- Runtime-Gates fuer AA, Computer und Cargo sind im finalen Zustand komplett.
- Mission Control zeigt AA/COM/OBJ und CARGO im selben integrierten Statusbild.
- Primary3D spiegelt Objective-Visual und final entfernte Cargo-Visuals konsistent.
- Der Snapshot bleibt read-only.
- Der Verifier `scripts/tests/task_554_frontier_probe_integrated_objective_playthrough_smoke.gd` laeuft gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_554_frontier_probe_integrated_objective_playthrough_smoke.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_554_frontier_probe_integrated_objective_playthrough_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_553_mission_cargo_extract_readability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_552_mission_objective_interaction_readability_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Smoke setzt die Scenario-Zustaende kontrolliert im Test und ersetzt noch keinen echten manuellen Spielrun mit Zeitdruck, Gegnerdruck und Spielerinput.
- Naechster sinnvoller Anschluss ist ein kurzer F6-/Screenshot-Sichttest oder ein Host/Client-Smoke fuer denselben Objective-Slice.
