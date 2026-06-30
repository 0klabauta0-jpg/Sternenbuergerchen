# TASK_691 - Mission Interaction Runtime Visual Assets

## Ziel / Problem
TASK_687 zeichnet bereits kleine Object-Reaction-Proxies fuer Computer, AA, Cargo und Door-Familien. Fuer den naechsten Spielgefuehl-Schritt fehlt aber ein stabiler Runtime-Visual-State: Eine Door soll im Snapshot klar closed/half/open zugeordnet sein, ein Computer soll idle/active/controlled lesbar werden, und die 3D-Ansicht soll diese Zustaende sichtbarer machen.

## Sinnhaftigkeit / Ursache
Der Spieler soll Interaktionsobjekte nicht nur als Textlabels wahrnehmen. Gleichzeitig duerfen wir kein neues Door-State-System oder Tile-Swap-System einschmuggeln. Deshalb erweitert TASK_691 den bestehenden read-only Object-Reaction-Pfad um Visual-Asset-State-Daten und kleine Render-Proxies, ohne Terrain, LOS, Collision oder Scenario-Gates zu mutieren.

## Umfang
- `MissionInteractionObjectReaction` exportiert Runtime-Visual-State, Asset-Familie, Asset-Type-ID, Modell-/Preview-Hinweise und State-Labels.
- Door-Reaktionen bekommen `closed`, `half` oder `open` plus Space-Station-Door-Familie.
- Computer-Reaktionen bekommen `idle`, `active` oder `controlled` plus Screen-/Panel-State.
- `TerrainMap3DView` uebernimmt diese Felder in den Render-Snapshot und zeichnet Computer-Fortschritts-/Kontrollanzeige sowie Door-Open-Hinweise.
- Neuer Verifier `task_691_mission_interaction_runtime_visual_assets.gd`.

## Nicht-Ziele
- Kein echter Tile-/Asset-Swap in `TerrainMapData`.
- Keine Collision-, Walkability- oder LOS-Aenderung.
- Kein Computer-Hack-Minispiel.
- Kein neues Objective-/Gate-System.
- Kein menschlicher FullHD-Sichtentscheid.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_687_mission_interaction_object_reaction.md`
- `docs/tasks/TASK_690_mission_interaction_manual_sight_notes.md`

## Akzeptanzkriterien
- Object-Reaction-Snapshot bleibt read-only und meldet `ui_sets_gameplay_truth = false`.
- Door complete ergibt Runtime-Visual-State `open` und Asset-Type `station_set_door_single`.
- Door active mit Teilfortschritt ergibt Runtime-Visual-State `half`.
- Door locked/blocked ergibt Runtime-Visual-State `closed`.
- Computer active ergibt Runtime-Visual-State `active`, `screen_active = true` und einen aktiven Panel-Text.
- Computer complete ergibt Runtime-Visual-State `controlled`.
- Render-Snapshot exportiert die neuen Runtime-Visual-Felder.

## Betroffene Dateien
- `scripts/mission/mission_interaction_object_reaction.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_691_mission_interaction_runtime_visual_assets.gd`
- `docs/tasks/TASK_691_mission_interaction_runtime_visual_assets.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_691_mission_interaction_runtime_visual_assets.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_687_mission_interaction_object_reaction.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das ist eine visuelle Runtime-Schicht, kein autoritativer Door-State. Echte Door-Collision/LOS und Tile-Swaps brauchen weiter einen eigenen Slice.
