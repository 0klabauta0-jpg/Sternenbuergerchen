# TASK_674 - Mission Interaction Point Bindings

## Ziel / Problem
TASK_673 hat Door-/Computer-/Hold-Interactions als Marker und Contract vorbereitet. Was noch fehlte, war die Bruecke in echte Szenario-Daten: Ein Szenario muss ausdruecken koennen, welcher Marker zu welchem Gate, welcher Bedienart und welchem erwarteten Runtime-Zustand gehoert.

## Sinnhaftigkeit / Ursache
Ohne explizite Bindings muessten Computer, AA-Zone und Cargo-Hold aus Briefing-Texten, Flow-Step-Namen oder HUD-Zeilen erraten werden. Das waere schlecht fuer Editor, Multiplayer und spaetere Runtime-Interaktion. Der Binding-Snapshot macht die Verbindung maschinenlesbar, bleibt aber read-only.

## Umfang
- `MissionInteractionPointBinding` als Mission-Contract-Helper anlegen.
- `MissionScenarioData` bewahrt `vertical_slice` und liefert Interaction-Point-Bindings/Snapshot.
- `MissionScenarioVerticalSliceContract` normalisiert und validiert `interaction_points`.
- `frontier_probe_vertical_slice.json` bekommt explizite Bindings fuer AA-Shutdown, Station-Computer und Cargo-Hold.
- `MissionTacticalSandboxController` bekommt eine read-only Snapshot-Fassade fuer den aktiven Szenario-/Gate-Zustand.
- Doku, Roadmap, Status und HTML-Handbuch fortschreiben.

## Nicht-Ziele
- Keine Door-Animation.
- Kein neuer Command-Button.
- Kein Computer-Hack-Minispiel.
- Kein Objective-/Cargo-Rewrite.
- Kein HUD-Pflichtlabel im Hotpath.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_673_mission_interaction_point_contract.md`
- `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`
- `docs/tasks/TASK_637_frontier_probe_playfeel_next_interaction.md`

## Akzeptanzkriterien
- Frontier Probe enthaelt drei explizite `vertical_slice.interaction_points`.
- Der Binding-Snapshot validiert Marker, Typen, Orders, Radius und Mehrfach-IDs.
- Cargo-Hold ist blockiert, solange `disable_air_defense` nicht komplett ist.
- Wenn Runtime-Gates komplett sind, meldet der Snapshot die betroffenen Interactions als `complete`.
- `ui_sets_gameplay_truth = false` bleibt in Helper, ScenarioData und Controller-Snapshot erhalten.
- Der Verifier `scripts/tests/task_674_mission_interaction_point_bindings.gd` laeuft gruen.

## Betroffene Dateien
- `data/mission_scenarios/frontier_probe_vertical_slice.json`
- `scripts/mission/mission_interaction_point_binding.gd`
- `scripts/mission/mission_scenario_data.gd`
- `scripts/mission/mission_scenario_vertical_slice_contract.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_674_mission_interaction_point_bindings.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_674_mission_interaction_point_bindings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_674_mission_interaction_point_bindings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_673_mission_interaction_point_contract.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_517_mission_scenario_vertical_slice.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Snapshot ist noch kein Bedien- oder Animationssystem. Als naechstes braucht es Editor-Inspector-Felder fuer Bindings oder eine kleine Runtime-Use-State-Bruecke fuer Naehe/Bedienzeit.
