# TASK_531 - Briefing Minimap Visual Renderer

## Status: IMPLEMENTIERT

## Ziel / Problem
TASK_530 macht das Briefing als Textpanel sichtbar, aber die Karte bleibt noch abstrakt. Spieler sollen vor Missionsstart grob sehen, wo Terrain, Alpha/Bravo-Spawns, Objectives, Danger-Zonen und Routen liegen, ohne in die Mission zu starten.

## Sinnhaftigkeit / Ursache
Die Daten sind bereits vorhanden: `TerrainMapData` liefert Grid-/Marker-/Surface-Daten, `MissionBriefingMinimapOverlayPresenter` liefert read-only Annotationen und Team-Spawns. Es fehlt eine kleine UI-Komponente, die daraus eine robuste, performante Pre-Mission-Minimap zeichnet.

## Umfang
- `MissionBriefingMinimapVisualPresenter` baut einen read-only Visual-Snapshot aus Terrain-Samples und Overlay-Entries.
- `MissionBriefingMinimapVisual` zeichnet diesen Snapshot als kompaktes Homebase-Preview-Control.
- `MissionBriefingPanelPresenter` reicht den Visual-Snapshot an das Briefing-Panel weiter.
- `HomebaseTestScreen` rendert die Minimap im bestehenden `MissionBriefingPanel`.

## Nicht-Ziele
- Keine vollstaendige TileMap-/Texture-Renderer-Pipeline.
- Keine interaktive Annotation-Bearbeitung.
- Keine Gameplay-, Objective-, Marker- oder Terrain-Mutation im UI.
- Kein manueller FullHD-Sichttest in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_briefing_contract.md`
- `docs/tasks/TASK_530_briefing_panel_renderer_mvp.md`
- `docs/tasks/TASK_527_briefing_minimap_team_spawn_overlay.md`
- `docs/tasks/TASK_528_rolling_html_status_report.md`

## Akzeptanzkriterien
- Visual-Snapshot setzt `ui_sets_gameplay_truth = false`.
- Visual-Snapshot enthaelt grobe Terrain-Samples, Team-Spawn-Entries und Briefing-Annotationen.
- Homebase rendert ein `BriefingMinimapVisual`-Control fuer `frontier_probe_vertical_slice`.
- Snapshot dupliziert keine vollstaendige `tiles`-/`markers`-/`patrol_paths`-Wahrheit.
- Bestehende TASK_530/TASK_529/TASK_527-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/mission/mission_briefing_minimap_visual_presenter.gd`
- `scripts/ui/mission_briefing_minimap_visual.gd`
- `scripts/mission/mission_briefing_panel_presenter.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_531_briefing_minimap_visual_renderer.gd`
- `docs/dev/mission_briefing_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_531_briefing_minimap_visual_renderer.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_530_briefing_panel_renderer_mvp.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_529_mission_hud_team_icon_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_527_briefing_minimap_team_spawn_overlay.gd`
- `git diff --check`

## Risiken / offene Punkte
Die Karte ist ein schnelles, grob gesampeltes Preview-Bild. Sie ersetzt keinen spaeteren hochwertigen Minimap-Renderer mit Tileset-Texturen, Zoom, Hover oder Annotation-Painting.
