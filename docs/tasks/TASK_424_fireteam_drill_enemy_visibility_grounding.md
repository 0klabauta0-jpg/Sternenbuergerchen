# TASK_424 - Fireteam Drill Enemy Visibility Grounding

## Ziel / Problem

Auf der Fireteam-Command-Drill-Karte sind im Playtest gegnerische NPCs nicht klar sichtbar; teilweise sieht man nur `IDLE`-Labels. Ausserdem stehen Pflanzen-/Nature-Props optisch auf unpassenden Untergruenden, und die grauen Objective-Tiles wirken wie eine Erhoehung, obwohl fuer den Drill keine Hoehenmechanik gemeint ist.

## Sinn / Ursache

Die Drill-Karte soll als schnelle Sicht- und Bewegungspruefung fuer Fireteam-Kommandos dienen. Dafuer muessen Gegnerkoerper, Statuslabels, Boden/Props und Objective-Flaeche eindeutig lesbar sein, ohne dass visuelle Assets falsche Gameplay-Hoehe suggerieren.

## Umfang

- Enemy-Fireteam der Drill-Szene im Primary-3D-View sichtbar pruefen und bei Bedarf die Visual-/Setup-Pipeline absichern.
- Nature-/Pflanzen-Props der Drill-Karte auf Ground-Tiles authoren.
- Graue Objective-Floor-Panels im Drill so anpassen, dass keine falsche Hoehenwirkung entsteht.
- Headless-Verifier fuer Gegner-Proxies, Nature-Grounding und fehlende Gameplay-Erhoehung.

## Nicht-Ziele

- Kein neues Gegner-KI- oder Combat-System.
- Kein allgemeiner Terrain-Asset-Redesign.
- Keine Aenderung an Gameplay-Wahrheiten ausser der Drill-Map-Authoring-Daten.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_416_fireteam_command_drill_map.md`
- `docs/tasks/TASK_423_normal_move_parallel_spacing.md`

## Akzeptanzkriterien

- [x] Drill-Szene erzeugt vier sichtbare gegnerische 3D-Proxies mit Enemy-Archetype, nicht nur Statuslabels.
- [x] Nature-/Pflanzen-Props der Drill-Karte liegen auf Ground-Surface und nicht auf Road-/Station-Flaechen.
- [x] Die Objective-Flaeche der Drill-Karte nutzt keine grauen Floor-Panels, die optische Erhoehung suggerieren.
- [x] Alle Drill-Tiles behalten `height_level == 0`, soweit nicht explizit spaeter Hoehe authoriert wird.
- [x] Verifier prueft Szene, Map-Authoring und relevante Dokumentation.

## Betroffene Dateien

- `docs/tasks/TASK_424_fireteam_drill_enemy_visibility_grounding.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/tools/generate_fireteam_command_drill_24x24.gd`
- `maps/fireteam_command_drill_24x24.json`
- `data/mission_scenarios/fireteam_command_drill_24x24.json`
- `scripts/tests/task_424_fireteam_drill_enemy_visibility_grounding.gd`
- `scripts/terrain/terrain_map_3d_view.gd`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tools/generate_fireteam_command_drill_24x24.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_424_fireteam_drill_enemy_visibility_grounding.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_416_fireteam_command_drill_map.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- Enemy-Modelle koennen wegen Asset-/Importfehlern auf Fallback-Visuals fallen; der Test soll das sichtbar diagnostizieren.
- Die grauen Floor-Panels sind in anderen Maps weiterhin korrekt als Space-/Station-Optik nutzbar. Diese Task beschraenkt sich auf die kleine Drill-Map.
