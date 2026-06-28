# TASK_527 - Briefing Minimap Team Spawn Overlay

## Ziel / Problem
TASK_526 macht Alpha/Bravo-Besitz im laufenden Missions-HUD sichtbar. Vor dem Start fehlt dieselbe Team-/Spawn-Lesbarkeit im Briefing-Minimap-Pfad.

## Sinnhaftigkeit / Ursache
Solo, Coop und PvP sollen bereits im Briefing klar machen, wo Alpha und Bravo starten. Der Spieler soll nicht erst nach Missionsstart erkennen, welche Seite welchem Spawnmarker gehoert.

## Umfang
- Read-only Presenter fuer Briefing-Minimap-Overlay bauen.
- Bestehende `briefing.annotations` mit automatisch abgeleiteten `team_spawn`-Eintraegen aus `vertical_slice.team_slots` verbinden.
- Markerpositionen ueber `TerrainMapData` auf Minimap-UV normalisieren.
- `frontier_probe_vertical_slice` gegen Alpha-/Bravo-Spawn-Overlay pruefen.
- Laufenden HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein kompletter Briefing-Screen.
- Keine neue Gameplay-Wahrheit im Briefing.
- Keine Terrain-, Marker- oder Patrol-Duplizierung im Briefing-JSON.
- Kein finaler Icon-/Art-Direction-Pass.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_526_mission_hud_team_chip_polish.md`
- `docs/tasks/TASK_525_team_badge_spawn_readability_polish.md`
- `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`
- `docs/dev/mission_briefing_contract.md`
- `docs/dev/html_report_workbench_contract.md`

## Akzeptanzkriterien
- Snapshot hat `ui_sets_gameplay_truth == false`.
- Alpha- und Bravo-Spawn-Overlays entstehen aus `vertical_slice.team_slots`.
- `spawn_alpha` und `spawn_bravo` werden ueber `TerrainMapData` auf Weltposition und Minimap-UV aufgeloest.
- Bestehende Briefing-Annotations bleiben erhalten.
- Briefing-JSON dupliziert weiterhin keine `tiles`, `markers` oder `patrol_paths`.

## Betroffene Dateien
- `scripts/mission/mission_briefing_minimap_overlay_presenter.gd`
- `scripts/tests/task_527_briefing_minimap_team_spawn_overlay.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_briefing_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_527_briefing_minimap_team_spawn_overlay.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_526_mission_hud_team_chip_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_517_mission_scenario_vertical_slice.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Presenter liefert Daten fuer ein spaeteres Briefing-Panel; die eigentliche UI-Render-Komponente bleibt Folgearbeit.

## Status: IMPLEMENTIERT
