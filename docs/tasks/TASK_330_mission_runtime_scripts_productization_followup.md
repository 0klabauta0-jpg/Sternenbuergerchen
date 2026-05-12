# TASK_330 - Mission Runtime Scripts Productization Followup

## Ziel
Produktiv genutzte Mission-Runtime-Skripte sollen nicht laenger als Testcode erscheinen. Dieser Follow-up zu TASK_116 prueft die verbliebenen `scripts/tests`-Abhaengigkeiten der Mission und verschiebt nur echte Runtime-Bestandteile in klare Produktivpfade, ohne Verhalten zu aendern.

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Voraussetzung
- TASK_116 - Runtime-Systeme aus scripts/tests herausloesen
- TASK_284 - Gameplay Truth Architecture Boundary Audit
- TASK_289 - Final Sneaky Code Review Patch Queue

## Kontext
TASK_116 hat viele taktische Systeme aus `scripts/tests` herausgeloest. Die aktuelle Mission-Szene referenziert aber weiterhin zentrale Skripte wie `mission_tactical_sandbox_controller.gd`, `mission_combat_loop_driver.gd`, `mission_test_setup.gd` und `test_unit.gd` aus Testpfaden. Das erzeugt Architektur-Unklarheit: spaetere Tasks koennen schwer erkennen, was Test-Harness und was Produktiv-Runtime ist.

## Umfang
1. Referenz-Audit:
   - Alle Szenen-, `preload`-, `load`- und Testreferenzen auf die genannten Skripte erfassen.
   - Pro Skript entscheiden: produktive Runtime, Test-Fixture, Verifier oder bewusstes Kompatibilitaetsstueck.
2. Zielpfade:
   - Produktive Mission-Bestandteile nach `scripts/mission/` oder einen klar benannten Unterordner verschieben.
   - Reine Verifier und Headless-Harnesses bleiben unter `scripts/tests`.
3. Pfadupdate:
   - Szenen- und Scriptreferenzen auf die neuen Produktivpfade anpassen.
   - `class_name`-, Signal- und Datenvertraege unveraendert lassen.
4. Dokumentation:
   - Kurzen Report anlegen, welche Skripte produktiv sind und welche absichtlich Testcode bleiben.

## Nicht-Ziele
- Kein Refactor von `MissionTacticalSandboxController`.
- Keine Gameplay-, UI- oder Timing-Aenderungen.
- Kein Umbenennen von Methoden, Signalen oder Snapshot-Feldern.
- Kein neues Autoload.

## Akzeptanzkriterien
- [x] Produktiv genutzte Mission-Runtime-Skripte liegen nicht mehr unter `scripts/tests`.
- [x] Szenen- und Preload-Referenzen zeigen auf die neuen Produktivpfade.
- [x] Reine Tests bleiben unter `scripts/tests`.
- [x] Das Diff besteht im Wesentlichen aus Moves, Pfadupdates und Dokumentation.
- [x] Ein Report dokumentiert verbleibende Ausnahmen und ihre Begruendung.

## Erwartete Dateien
- `scripts/mission/**`
- `scenes/tests/mission_reactivity_test.tscn`
- betroffene `scripts/tests/*.gd`
- `docs/reports/mission_runtime_scripts_productization_followup.md`
- `docs/tasks/TASK_330_mission_runtime_scripts_productization_followup.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `rg "res://scripts/tests/(mission_tactical_sandbox_controller|mission_combat_loop_driver|mission_test_setup|mission_command_flow_driver|mission_map_camera_controller|mission_objective_status_view|mission_respawn_overlay|enemy_wave_controller|phase_controller)\\.gd" scripts scenes tests`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_282_tactical_overhaul_playability_performance_help_gate.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd`
- [x] `git diff --check`

## Risiken
- Godot-Scene-Resource-Pfade koennen bei Moves leicht stale bleiben. Deshalb ist dieser Task bewusst ein Pfad-/Produktisierungs-Slice ohne Fachlogik.

## Ergebnis
- Produktiv in der Mission-Szene verwendete Runtime-/View-Support-Skripte wurden nach `scripts/mission/` verschoben.
- `scenes/tests/mission_reactivity_test.tscn` und betroffene Verifier/Harnesses laden die verschobenen Skripte ueber `res://scripts/mission/...`.
- `docs/reports/mission_runtime_scripts_productization_followup.md` dokumentiert die verschobenen Dateien, verbleibende Test-/Authoring-Harnesses und den bewusst nicht umbenannten `scripts/npc/test_unit.gd`.

## Naechster Schritt
Nach diesem Task koennen Controller-Extraktionen auf Produktivpfade zeigen, ohne weiter Testpfade als Runtime-Wahrheit zu verfestigen.
