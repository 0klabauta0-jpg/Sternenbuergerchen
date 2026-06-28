# TASK_517 - Mission Scenario Vertical Slice

## Status: IMPLEMENTIERT

## Ziel / Problem
Das Spiel braucht wieder einen konkret spielbaren Zielzustand statt nur weitere Einzelsysteme. Der naechste Slice soll das vom User beschriebene Szenario vorbereiten: Luftabwehr ausschalten, Stations-/Computerbereich halten, Frachter kurz anlanden lassen und wieder abfliegen lassen.

## Sinnhaftigkeit / Ursache
Die grosse Startmap und die Loadout-/Briefing-/Air-Asset-Grundlagen sind vorhanden, aber `frontier_probe` ist bisher bewusst map-only. Fuer Playtests fehlt ein Datenanker, der Singleplayer gegen NPCs und spaeter PvP mit NPC-Besatzung in derselben Mission beschreibt.

## Umfang
- Neues Szenario `frontier_probe_vertical_slice` fuer die 192x192-Startmap.
- Homebase-Katalogeintrag fuer den Slice, ohne die bestehende map-only `frontier_probe`-Mission umzudeuten.
- Briefing mit terrain-only Minimap, AA-/Computer-/Cargo-Zielen und sinnvollen Loadout-Empfehlungen.
- Separater read-only Contract-Reader fuer `vertical_slice`-Payloads mit Play-Modes, Team-Slots und Flow-Steps.
- Verifier fuer ScenarioData, Briefing, Air-Asset-Risk, Map-Marker und Homebase-Katalog.

## Nicht-Ziele
- Kein neues Runtime-Objective-System.
- Kein Combat-Rewrite.
- Kein neues Dropship- oder Cargo-State-Mutieren in UI.
- Keine gespeicherte Spieler-LZ im Szenario.
- Keine Multiplayer-Lobby-/Netzwerklogik in diesem Task.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/mission_briefing_contract.md`
- `docs/dev/air_asset_threat_damage_contract.md`
- `docs/tasks/TASK_482_mission_briefing_data_contract.md`
- `docs/tasks/TASK_499_review_followup_architecture_cleanup.md`
- `docs/tasks/TASK_500_gameflow_spine_hardening.md`
- `docs/tasks/TASK_504_startmap_expansion_performance_pass.md`

## Akzeptanzkriterien
- `data/mission_scenarios/frontier_probe_vertical_slice.json` validiert ueber `MissionScenarioData`.
- Die bestehende `frontier_probe` bleibt im Homebase-Katalog map-only.
- Der neue Homebase-Eintrag `frontier_probe_vertical_slice` verweist auf die getrackte 192x192-Map und die neue Scenario-Datei.
- Das Briefing nennt Luftabwehr, Computer/Gebaeude-Hold und Cargo-Touchdown/Extract.
- Empfohlene Loadouts nutzen kanonische `WeaponData`-IDs, unter anderem `sniper`, `rocket_launcher`, `rail_gun` und `medictool`.
- `vertical_slice.play_modes` enthaelt Solo- und PvP-/MP-Faehigkeit.
- `vertical_slice.team_slots` bindet `team_alpha` an `spawn_alpha` und `team_bravo` an `spawn_bravo`.
- `vertical_slice.flow_steps` beschreibt AA-Shutdown, Computer-Hold und Cargo-Touchdown/Extract, ohne Runtime-State im UI zu speichern.

## Betroffene Dateien
- `data/mission_scenarios/frontier_probe_vertical_slice.json`
- `scripts/mission/mission_scenario_vertical_slice_contract.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_517_mission_scenario_vertical_slice.gd`
- `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_517_mission_scenario_vertical_slice.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_504_startmap_expansion_performance_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_482_mission_briefing_data_contract.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Slice beschreibt Objective-Gates nur als Datenvertrag. Echte Runtime-Auswertung fuer AA aus, Computer-Hold, Cargo-Touchdown/Extract bleibt Folgearbeit.
- Fuer PvP braucht der naechste Schritt Lobby-/Team-Zuweisung und klare NPC-Besitzregeln.
- Die Marker fuer Computer und Cargo nutzen vorerst bestehende Map-Marker; feineres Mission-Authoring kann spaeter eigene Marker im Editor setzen.
