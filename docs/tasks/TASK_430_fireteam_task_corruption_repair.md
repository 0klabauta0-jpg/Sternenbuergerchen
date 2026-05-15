# TASK_430 - Fireteam Task Corruption Repair

## Ziel / Problem

Nach TASK_429 wurden mehrere Textdateien als NUL-Bytes gespeichert. Dadurch konnten Godot und der Browser den Security-Controller, das Drill-Scenario, Verifier und HTML-Reports nicht mehr korrekt laden.

## Sinn / Ursache

Der aktuelle Arbeitsstand muss wieder lesbar, parsebar und testbar sein. Gleichzeitig soll der Scenario-/Map-Speicherpfad nach dem Schreiben flushen und der Drill-Generator seine Ausgaben sofort validieren, damit eine kaputte Datei nicht erst im Playtest auffaellt.

## Umfang

- NUL-korrupte Dateien aus TASK_429 wiederherstellen.
- `MissionScenarioData.load_from_file()` und `TerrainMapData.load_from_file()` melden NUL-/Leerdateien kontrolliert.
- `save_to_file()` flushes nach dem Schreiben.
- Der Drill-Generator validiert Map und Scenario direkt nach dem Speichern.
- Verifier pruefen C/N/A-Werte, Defense-Sektoren und NUL-freie Fireteam-Dateien.

## Nicht-Ziele

- Keine neuen Gameplay-Regeln ausserhalb der Reparatur.
- Kein vollstaendiger Legacy-Cleanup.
- Kein Redesign der Drillkarte ueber die bereits geplanten TASK_429-Anpassungen hinaus.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_429_fireteam_behavior_modes_runtime.md`
- `docs/dev/fireteam_behavior_modes_contract.md`

## Akzeptanzkriterien

- [x] Alle betroffenen `.gd`, `.json`, `.html` und `.md`-Dateien sind NUL-frei.
- [x] `FireteamSecurityController.get_fireteam_state()` ist wieder vorhanden und wird defensiv abgefragt.
- [x] Drill-Scenario laedt ohne JSON-Parse-Fehler.
- [x] Generator, TASK_424, TASK_427, TASK_429 und TASK_416 laufen wieder gruensoweit lokal pruefbar.

## Betroffene Dateien

- `docs/tasks/TASK_430_fireteam_task_corruption_repair.md`
- `scripts/mission/mission_scenario_data.gd`
- `scripts/terrain/terrain_map_data.gd`
- `scripts/tactical/fireteam_security_controller.gd`
- `scripts/tools/generate_fireteam_command_drill_24x24.gd`
- TASK_429-Doku, Reports und Verifier

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tools/generate_fireteam_command_drill_24x24.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_429_fireteam_behavior_modes_runtime.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_424_fireteam_drill_enemy_visibility_grounding.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_427_fireteam_decision_feedback_aim_pose.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_416_fireteam_command_drill_map.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- Falls der Rechner waehrend eines Schreibvorgangs hart beendet wurde, kann der Flush nur den normalen Prozesspfad absichern. Gegen echte Strom-/Dateisystemabbrueche helfen spaeter temp-file + atomic rename.
