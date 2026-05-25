# TASK_500 - Gameflow Spine Hardening

## Ziel / Problem
Der aktuelle Spielerpfad Homebase -> FOB -> Dropship -> Mission -> LZ -> Kampf -> Debrief ist grundsaetzlich spielbar, hat aber noch rote oder schwer nutzbare Gameflow-Gates:

- Die 2.5D-Missionsansicht verliert nach dem Absetzen den sichtbaren LZ-Terrainmarker.
- Ein alter Multi-Dropship-Regressionstest prueft noch die fruehere LZ-Label-Form statt den aktuellen nummerierten LZ-Contract.
- Der Dropship-Performance-Gate ist zu breit und instanziiert die Missionsszene mehrfach, wodurch er lokal als schneller Gate haengen bleibt.
- `frontier_probe` verweist im Homebase-Katalog auf eine lokale, ungetrackte Editor-Map.

## Sinnhaftigkeit / Ursache
TASK_495 bis TASK_499 haben die grossen Architektur- und Review-Kanten sortiert. Vor neuem Szenario-Content braucht der Gameflow wieder ein kleines, verlaessliches Prueffenster, damit Dropship-, LZ- und Missionsstart-Rueckwege nicht bei jedem Folge-Task neu unsicher werden.

## Umfang
- LZ-Visual-Contract fuer outbound Dropships so reparieren, dass die zuletzt genutzte LZ als Terrainfeld sichtbar bleibt.
- Multi-Dropship-Labeltest auf den aktuellen nummerierten `LZ1/LZ2 + DisplayName`-Vertrag bringen.
- TASK_399 so eingrenzen, dass er die bestehenden Dropship-Hotpath-Zaehler in einer Missionsinstanz prueft.
- `frontier_probe` auf eine getrackte Map umbiegen.
- Einen kleinen TASK_500-Verifier fuer diese Gameflow-Grenzen ergaenzen.

## Nicht-Ziele
- Keine grosse Extraktion aus `mission_tactical_sandbox_controller.gd` oder `mission_combat_loop_driver.gd`.
- Keine neue Mission, kein Balancing und keine neuen Assets.
- Keine Aenderung an SimulationRoot-Autoritaet, Damage, Objective-Logik oder Loadout-Werten.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/dev/terrain_truth_visual_audit_contract.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/flight_altitude_layer_contract.md`

## Akzeptanzkriterien
- `task_160_tactical_playability_verifier.gd` ist am LZ-Terrainmarker wieder gruen.
- `bugfix_mission_multi_dropship_cards.gd` akzeptiert den aktuellen nummerierten LZ-Labelvertrag und bleibt als Besitz-/Payload-Regression sinnvoll.
- Der Dropship-Hotpath-Gate laeuft als schneller lokaler Check statt mehrfacher Vollszenen-Instanzierung.
- `frontier_probe` nutzt keine ungetrackte Map-Datei mehr.
- `git diff --check` bleibt gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/bugfix_mission_multi_dropship_cards.gd`
- `scripts/tests/task_399_dropship_flow_contract_performance_pass.gd`
- `scripts/tests/task_500_gameflow_spine_hardening.gd`
- `scripts/meta/meta_layer_flow.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_500_gameflow_spine_hardening.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_multi_dropship_cards.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_399_dropship_flow_contract_performance_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die grossen Missionscontroller bleiben bewusst Legacy-Bridge unter `scripts/tests/`; die eigentliche Extraktion ist ein eigener Folge-Task.
- Der TASK_399-Gate prueft gezielt die Dropship-Hotpath-Zaehler und ersetzt keinen manuellen Sichttest der kompletten Mission.
