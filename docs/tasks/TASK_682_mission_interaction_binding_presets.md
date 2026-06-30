# TASK_682 - Mission Interaction Binding Presets

## Ziel / Problem
Der TASK_681-Editor kann Interaction-Bindings schreiben, verlangt aber noch zu viele rohe Felder. Fuer angenehmen Mapbau sollen typische Bindings wie Door, Computer, Hold-Zone, AA-Shutdown und Cargo-Hold als Presets schnell gesetzt werden koennen.

## Ursache / Sinnhaftigkeit
Ohne Presets tippt der Autor immer wieder Interaction-Typ, Order, Radius, Dauer, Step und Required-State. Das ist fehleranfaellig und bremst den Szenario-Workflow, obwohl die Runtime-Vertraege bereits klare Muster haben.

## Umfang
- Preset-Auswahl im bestehenden Marker-Binding-Editor.
- Presets fuellen ID, Typ, Order, Dauer, Radius, Team, Step, Required-State und optionale Abhaengigkeit.
- Snapshot exportiert Presetliste und aktive Preset-Vorschau.
- Apply schreibt weiter nur `MissionScenarioData.vertical_slice.interaction_points`.

## Nicht-Ziele
- Kein neues Runtime-Gate-System.
- Keine automatische Asset-Erkennung mit Pflichtwirkung.
- Kein FullHD-Layout-Redesign.
- Kein Missions-Objective-Rewrite.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_681_mission_interaction_binding_editor.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Binding-Editor bietet Presets fuer Door, Computer, Hold-Zone, AA-Shutdown und Cargo-Hold.
- Ein Preset kann die Editor-Felder sichtbar fuellen.
- Apply nach Preset speichert die erwarteten Scenario-Felder.
- Cargo-Hold-Preset speichert die Abhaengigkeit auf `disable_air_defense`.
- Snapshot und Tests belegen weiter `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `scripts/tests/task_682_mission_interaction_binding_presets.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_682_mission_interaction_binding_presets.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_681_mission_interaction_binding_editor.gd`
- `git diff --check`

## Risiken / offene Punkte
- Presets sind bewusst klein und allgemein. Spaeter koennen sie aus Asset-Familien oder Scenario-Templates kommen.
- Ein echter FullHD-Sichtlauf bleibt noetig, um zu pruefen, ob der rechte Panelbereich noch bequem bedienbar ist.
