# TASK_729 - Station Scenario Visible Playtest Run Packet

## Ziel / Problem
TASK_728 meldet korrekt `needs_visible_playtest`, aber der sichtbare Stationslauf muss ohne Ratespiel startbar sein: richtiges Szenario, richtige Workbench, richtige Manifestpfade und klare Befehle fuer Host/Client-Fenster.

## Sinnhaftigkeit / Ursache
Der vorhandene Zwei-Fenster-Launcher konnte Rolle, Peer und Team setzen, aber keinen konkreten Szenario-Pfad weiterreichen. Dadurch war der neue One-Screen-Station-Drill technisch vorhanden, aber nicht als reproduzierbarer sichtbarer Testlauf gebuendelt.

## Umfang
- `MissionTestSetup` akzeptiert `--scenario-file=` / `--mission-scenario=` als sichtbaren Run-Override.
- `launch_host_client_two_window_review.ps1` kann `-ScenarioPath` in Host-/Client-Argumente schreiben.
- Neuer Helper `prepare_station_scenario_visible_playtest_run.ps1` schreibt ein read-only Run-Packet mit Szenario, Workbench, Manifeststatus und Startbefehlen.
- Verifier sichert Script, Parser, Packet und Doku ab.

## Nicht-Ziele
- Kein automatisch bestandener Sichttest.
- Kein HUD-/Performance-/Sync-Polish ohne echte Notizen.
- Kein neues Netcode- oder Missionssystem.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_727_station_scenario_f6_host_client_playtest_notes.md`
- `docs/tasks/TASK_728_station_scenario_playtest_findings.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Launch-Plan kann `--scenario-file=res://data/mission_scenarios/station_route_one_screen_multiplayer_drill.json` enthalten.
- `MissionTestSetup.apply_cmdline_scenario_override()` uebernimmt den Szenario-Pfad ohne UI-Gameplay-Wahrheit.
- Run-Packet meldet `ready_to_run_visible_playtest`, wenn TASK_726 bereit ist und TASK_727/TASK_728 offen auf sichtbaren Playtest warten.
- Run-Packet nennt Workbench-URI, Manifestpfade, Launch-/Capture-Kommandos und Required-Checks.

## Betroffene Dateien
- `scripts/tests/mission_test_setup.gd`
- `scripts/tools/launch_host_client_two_window_review.ps1`
- `scripts/tools/prepare_station_scenario_visible_playtest_run.ps1`
- `scripts/tests/task_729_station_scenario_visible_playtest_run_packet.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `powershell -ExecutionPolicy Bypass -File scripts/tools/prepare_station_scenario_visible_playtest_run.ps1`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_729_station_scenario_visible_playtest_run_packet.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_728_station_scenario_playtest_findings.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
TASK_729 macht den sichtbaren Lauf reproduzierbarer, ersetzt ihn aber nicht. Der naechste Schritt bleibt: Workbench sichtbar ausfuellen, JSON exportieren und danach nur konkrete TASK_729/TASK_730-Polish-Findings umsetzen.
