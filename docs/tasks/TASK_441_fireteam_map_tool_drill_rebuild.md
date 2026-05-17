# TASK_441 - Fireteam Map Tool Drill Rebuild

## Ziel / Problem
Die aktuelle Fireteam-Drillmap soll einmal durch den MapEditor-Authoring-Pfad kontrolliert werden, damit sichtbar ist, ob die im Playtest genutzte Karte auch im Tool sauber mit allen Markern, Patrol-Routen, Gegnern und Objektlayern bearbeitbar ist.

## Sinnhaftigkeit / Ursache
Im manuellen Playtest waren mehrere Dinge schwer auseinanderzuhalten: nur ein sichtbarer Gegnerkoerper, mehrere IDLE-Marker, Buesche scheinbar unter oder neben Tiles und unklare Patrol-/Kontaktwirkung. Ein reiner Runtime-Fix reicht dafuer nicht, wenn der MapEditor nur alte Zwei-Gegner-Referenzen anbietet oder gebundene Patrol-Routen nicht als editierbare Ziele aufloest.

## Umfang
- MapEditor-Patrol-Auswahl liest Enemy-IDs, Binding-IDs und Patrol-Route-IDs aus dem geladenen Szenario und der Karte.
- Patrol-Edits auf einen Gegner wie `enemy_foxtrot` werden auf die gebundene Route wie `enemy_drill_foxtrot_route` aufgeloest.
- Headless-Verifier laedt die Drillmap im MapEditor, prueft Authoring-Validation, alle vier Gegnerreferenzen und die konkrete Preview-Route.
- HTML-Bericht fasst zusammen, was die Map-Tool-Pruefung bestaetigt und wo Engage/Take/Defend noch staerker kontrolliert werden muessen.

## Nicht-Ziele
- Kein neues Enemy-AI-System.
- Kein Full-Limbo-Umstieg.
- Kein neues Terrain- oder Assetformat.
- Keine echte Hoehen-/Terrain3D-Umbauarbeit an der Drillmap.
- Kein Balancing fuer Skills, Mut oder Flanking.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/enemy_team_tactics_contract.md`
- `docs/tasks/TASK_416_fireteam_command_drill_map.md`
- `docs/tasks/TASK_439_fireteam_runtime_map_flow_limbo_review.md`
- `docs/tasks/TASK_440_enemy_limbo_contact_diagnostics.md`

## Akzeptanzkriterien
- [x] Drillmap laedt weiter als 24x24-`TerrainMapData` mit vier Missionsslots.
- [x] Buesche bleiben Objektlayer-Cover auf normalen Ground-Tiles.
- [x] MapEditor-Authoring-Validation ist fuer Map, Scenario und Patrols gruen.
- [x] Patrol-Selector enthaelt `enemy_delta`, `enemy_echo`, `enemy_foxtrot`, `enemy_golf` sowie die konkreten Drill-Routen.
- [x] `enemy_foxtrot` wird im Tool auf `enemy_drill_foxtrot_route` aufgeloest und zeigt mindestens drei Waypoints.
- [x] Bericht benennt klar: Engage, Take und Defend sind vorhanden, aber noch nicht final streng genug kontrolliert.

## Betroffene Dateien
- `scripts/editor/map_editor.gd`
- `scripts/tests/task_441_fireteam_map_tool_drill_rebuild.gd`
- `docs/reports/fireteam_map_tool_drill_rebuild_status.html`
- `docs/tasks/TASK_441_fireteam_map_tool_drill_rebuild.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tools/generate_fireteam_command_drill_24x24.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_441_fireteam_map_tool_drill_rebuild.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Der MapEditor beweist Bearbeitbarkeit und Authoring-Konsistenz, nicht finales Kampfverhalten.
- Engage/Take/Defend brauchen als naechsten Schritt eine strengere Runtime-Testmatrix fuer Tile vs. Area, Kontakt vs. kein Kontakt und C/N/A.
- Die Drillmap bleibt absichtlich flach; echte Hoehenlogik gehoert in einen separaten Terrain-Task.
