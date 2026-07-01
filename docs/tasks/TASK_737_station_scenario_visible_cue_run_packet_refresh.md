# TASK_737 - Station Scenario Visible Cue Run Packet Refresh

## Ziel / Problem
Nach TASK_736 ist die Command-Cue-Sprache headless poliert, aber der sichtbare TASK_727-Lauf darf nicht mehr mit den alten TASK_729-Checks starten. Das Run-Packet muss explizit sagen, welche neue Cue im FullHD-/Host-Client-Blick zu pruefen ist.

## Sinnhaftigkeit / Ursache
Die technische Vorbereitung meldet `ready_to_run_visible_playtest`, und es gibt aktuell keinen belegten Harness-Fehler. Der naechste sinnvolle Schritt ist daher nicht Harness-Modernisierung, sondern ein aktualisiertes Playtest-Packet, das die TASK_736-Erwartungen fuer den menschlichen Sichttest mitfuehrt.

## Umfang
- `prepare_station_scenario_visible_playtest_run.ps1` schreibt `refresh_task_id = TASK_737` und `latest_feedback_task_id = TASK_736`.
- Das Packet nennt erwartete sichtbare Cue-Fragmente, verbotene Altfragmente und zusaetzliche Required-Checks.
- Der aktuelle Iststand-/Handbuchbericht nennt TASK_737 als Evidence-Refresh und routet weiter zur TASK_727-Workbench.
- Ein Verifier prueft Script, Packet, Status, Roadmap, Contract und Bericht.

## Nicht-Ziele
- Kein automatisch bestandener TASK_727-Sichttest.
- Keine UI-, HUD-, Runtime- oder SimulationRoot-Aenderung.
- Keine Scenario-Harness-Modernisierung ohne belegten Harness-Fehler.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_727_station_scenario_f6_host_client_playtest_notes.md`
- `docs/tasks/TASK_729_station_scenario_visible_playtest_run_packet.md`
- `docs/tasks/TASK_736_station_scenario_command_feedback_polish.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Das frisch erzeugte Packet bleibt read-only und setzt keine Gameplay-Wahrheit.
- Das Packet enthaelt `visible_feedback_expectations.cue_line_example = CUE AA: BLUE naeher ran | 3.9km`.
- Das Packet nennt `BLUE 3859m`, `3859m` und `CARGO blockiert` als verbotene sichtbare Altfragmente fuer die knappe ACT-/Cue-Pruefung.
- Required-Checks enthalten polierte Cue, versteckte Rohdistanz und ausgeblendeten Future-Cargo-Blocker.
- Der empfohlene naechste Schritt bleibt TASK_727 sichtbar ausfuellen.

## Betroffene Dateien
- `scripts/tools/prepare_station_scenario_visible_playtest_run.ps1`
- `scripts/tests/task_737_station_scenario_visible_cue_run_packet_refresh.gd`
- `docs/tasks/TASK_737_station_scenario_visible_cue_run_packet_refresh.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `powershell -ExecutionPolicy Bypass -File scripts/tools/prepare_station_scenario_visible_playtest_run.ps1`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_737_station_scenario_visible_cue_run_packet_refresh.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_736_station_scenario_command_feedback_polish.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_729_station_scenario_visible_playtest_run_packet.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
TASK_737 aktualisiert nur die sichtbare Abnahmevorbereitung. Der eigentliche menschliche TASK_727-Fensterlauf und der JSON-Export bleiben offen.
