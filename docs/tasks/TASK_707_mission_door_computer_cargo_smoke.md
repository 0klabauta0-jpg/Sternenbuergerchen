# TASK_707 - Mission Door/Computer/Cargo Smoke

## Ziel / Problem
Nach Door-Layout-Polish soll der kurze Stationsfluss nicht nur isoliert gut aussehen. Der naechste sinnvolle Spiel-Flow-Smoke prueft Door -> Computer -> Cargo in einem Missionslauf, ohne neue Gameplay-Wahrheit oder ein neues Missionssystem zu bauen.

## Sinnhaftigkeit / Ursache
Door, Computer und Cargo sind die Bausteine fuer das geplante kleine Single-/Multiplayer-Szenario: Luftabwehr aus, Station/Computer sichern, Frachter landen lassen, Cargo wieder raus. Die Systeme existieren einzeln; jetzt braucht es einen integrierten Kontrollpunkt, der zeigt, dass Door-Visualstate, Computer-Gate und Cargo-Abschluss zusammenpassen.

## Umfang
- Temporäre Test-Scenario-Variante auf Basis von `frontier_probe_vertical_slice.json`.
- Door-Interaction am Stationsmarker ergaenzen und vor dem Computer-Schritt oeffnen.
- Danach Computer kontrollieren, Cargo-Hold abschliessen und Objective-Gates pruefen.
- Render-Snapshot muss Door-Open und TASK_706-Layout-Readout sehen.
- Manifest unter `tmp/` fuer den Smoke schreiben.

## Nicht-Ziele
- Kein neues Door-Gate in der echten Frontier-Probe-Scenario-Datei.
- Kein neues Missionssystem.
- Kein echter Host/Client-Fensterklick.
- Kein Aendern von Walkability/LOS ausserhalb bestehender Runtime-Producer.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_706_mission_door_layout_visual_polish.md`
- `docs/tasks/TASK_685_mission_interaction_objective_gate.md`
- `docs/tasks/TASK_696_door_runtime_visual_animation_asset_swap.md`

## Akzeptanzkriterien
- Verifier startet die echte Mission-Testszene bei 1920x1080.
- Door-Open erscheint im Render-Snapshot inklusive `door_layout_tone = success`.
- Door-Open setzt keine Objective-Gate-Wahrheit und blockiert den Computer-Schritt nicht.
- Computer-Control fuehrt zum Cargo-Next-Step.
- Cargo-Departed schliesst alle Objective-Gates ab.
- Smoke-Manifest bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `docs/tasks/TASK_707_mission_door_computer_cargo_smoke.md`
- `scripts/tests/task_707_mission_door_computer_cargo_smoke.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_707_mission_door_computer_cargo_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_706_mission_door_layout_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das ist ein integrierter technischer Smoke, kein menschlicher Sicht-/Bedienentscheid.
- Die echte Scenario-Datei bekommt noch kein dauerhaftes Door-Objective; der Test erzeugt die Door nur fuer den Kontrolllauf.
