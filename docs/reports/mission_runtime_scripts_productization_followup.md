# TASK_330 - Mission Runtime Scripts Productization Followup

## Ergebnis
Die produktiv in `scenes/tests/mission_reactivity_test.tscn` verdrahteten Mission-Runtime-Skripte liegen jetzt unter `res://scripts/mission/`. Der Task ist ein reiner Pfad-/Produktisierungsschnitt: Signale, `class_name`-Vertraege, Node-Struktur, Snapshot-Felder und Gameplay-Verhalten wurden nicht fachlich geaendert.

## Verschobene produktive Skripte
- `scripts/tests/mission_tactical_sandbox_controller.gd` -> `scripts/mission/mission_tactical_sandbox_controller.gd`
- `scripts/tests/mission_combat_loop_driver.gd` -> `scripts/mission/mission_combat_loop_driver.gd`
- `scripts/tests/mission_test_setup.gd` -> `scripts/mission/mission_test_setup.gd`
- `scripts/tests/mission_command_flow_driver.gd` -> `scripts/mission/mission_command_flow_driver.gd`
- `scripts/tests/mission_map_camera_controller.gd` -> `scripts/mission/mission_map_camera_controller.gd`
- `scripts/tests/mission_objective_status_view.gd` -> `scripts/mission/mission_objective_status_view.gd`
- `scripts/tests/mission_respawn_overlay.gd` -> `scripts/mission/mission_respawn_overlay.gd`
- `scripts/tests/enemy_wave_controller.gd` -> `scripts/mission/enemy_wave_controller.gd`
- `scripts/tests/phase_controller.gd` -> `scripts/mission/phase_controller.gd`

Die jeweiligen `.gd.uid`-Begleitdateien wurden mit verschoben.

## Aktualisierte Referenzen
- `scenes/tests/mission_reactivity_test.tscn` referenziert die produktiven Mission-Skripte jetzt aus `res://scripts/mission/...`.
- Verifier und Harnesses unter `scripts/tests` bleiben an ihrem Ort, laden die verschobenen Produktivskripte aber ueber die neuen Pfade.
- Ein `rg`-Check findet keine alten `res://scripts/tests/...`-Scriptreferenzen fuer die verschobenen Mission-Runtime-Dateien mehr in `scripts`, `scenes` oder `tests`.

## Bewusst verbleibende Testpfade
- `scripts/tests/mission_preset_loader.gd` bleibt ein Test-/Authoring-Harness fuer Preset-Injektion.
- `scripts/tests/mission_map_3d_calibration.gd`, `scripts/tests/mission_map_3d_render_spike.gd` und `scripts/tests/mission_map_camera_verifier.gd` bleiben Kalibrierungs- bzw. Verifier-Hilfen.
- Historische Task-, Review- und Statusabschnitte koennen weiterhin die alten Pfade zitieren, weil sie den damaligen Arbeitsstand beschreiben. Die aktuelle Pfadwahrheit fuer Folgearbeiten ist dieser Report plus `scripts/mission`.

## Legacy-Hinweis
`scripts/npc/test_unit.gd` liegt nicht unter `scripts/tests` und wurde in diesem Task nicht umbenannt. Eine fachliche Umbenennung von `TestUnit` waere wegen der breiten Test- und Runtime-Nutzung ein eigener, separater Rename-Task.

## Lokale Pruefung
- [x] `rg "res://scripts/tests/(mission_tactical_sandbox_controller|mission_combat_loop_driver|mission_test_setup|mission_command_flow_driver|mission_map_camera_controller|mission_objective_status_view|mission_respawn_overlay|enemy_wave_controller|phase_controller)\\.gd" scripts scenes tests`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_282_tactical_overhaul_playability_performance_help_gate.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd`
- [x] `git diff --check`

## Risiken
- Der Task reduziert Pfaddrift, loest aber nicht die Groesse des Mission-Tactical-Controllers oder Combat-Loop-Drivers. Das bleibt fuer TASK_331 und TASK_336.
- Historische Markdown-Dateien wurden nicht massenhaft umgeschrieben, damit alte Review- und Taskbefunde nachvollziehbar bleiben.
