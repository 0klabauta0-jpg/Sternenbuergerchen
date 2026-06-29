# TASK_553 - Mission Cargo Extract Readability Pass

## Status: IMPLEMENTIERT

## Ziel / Problem
Nach AA-Shutdown und Computer-Hold muss der letzte Frontier-Probe-Schritt fuer den Spieler lesbar werden: Frachter-Anflug, Touchdown-Hold, Abflug und Missionsabschluss duerfen nicht nur als interner Cargo-State existieren.

## Sinnhaftigkeit / Ursache
TASK_519 liefert die CargoBridge, TASK_522 rendert Cargo-Visuals. Was noch fehlte, war ein gemeinsamer Mission-Control-/Snapshot-Blick, der CargoBridge, Runtime-Gate und Primary3D-Visual in einem Spielerpfad zusammen prueft.

## Umfang
- Kompakte `CARGO ...`-Zeile in Mission Control.
- Read-only Snapshot `get_mission_cargo_extract_readability_snapshot()`.
- Verifier fuer CargoBridge, Cargo-Gate, Hold-Fortschritt, Mission-Control-Zeile, Primary3D-Visual und Completion-Gate.
- Rolling-HTML-Bericht wird auf TASK_553 aktualisiert und nennt den naechsten sinnvollen Anschluss.

## Nicht-Ziele
- Kein neues Cargo-Gameplay-System.
- Kein neues Flugphysik-/VFX-System.
- Kein neues Cargo-Modell.
- Keine UI-Parallelwahrheit fuer Missionsziele.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_519_cargo_touchdown_runtime_bridge.md`
- `docs/tasks/TASK_522_cargo_touchdown_visual_polish.md`
- `docs/tasks/TASK_552_mission_objective_interaction_readability_pass.md`
- `data/mission_scenarios/frontier_probe_vertical_slice.json`

## Akzeptanzkriterien
- Mission Control zeigt Cargo-Status, Hold-/Progress-Daten oder Departure-Status kompakt.
- Der Snapshot meldet CargoBridge, Cargo-Gate, CargoState, Hold-Fortschritt, Primary3D-Cargo-Visual und Completion-Konsistenz.
- `departed` schliesst CargoBridge und Scenario-Gate konsistent ab.
- Der Snapshot bleibt read-only.
- Der Verifier `scripts/tests/task_553_mission_cargo_extract_readability_pass.gd` laeuft gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_553_mission_cargo_extract_readability_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_553_mission_cargo_extract_readability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_552_mission_objective_interaction_readability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_522_cargo_touchdown_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task prueft Headless-Snapshots und Render-Zaehler, keinen menschlichen F6-Sichttest.
- Die naechste Folgearbeit sollte den ganzen AA/Computer/Cargo-Slice als zusammenhaengenden Playthrough-Smoke pruefen.
