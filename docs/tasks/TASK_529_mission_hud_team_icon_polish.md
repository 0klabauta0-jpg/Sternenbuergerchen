# TASK_529 - Mission HUD Team Icon Polish

## Ziel / Problem
Die Teamchips aus TASK_526 und die Briefing-Minimap-Team-Spawns aus TASK_527 sind funktional, aber noch textlastig. Alpha/Bravo, Owner und Spawn sollen schneller lesbar werden, ohne neue Gameplay-Wahrheit im HUD oder Briefing einzufuehren.

## Sinnhaftigkeit / Ursache
Solo, Coop und PvP muessen auf einen Blick zeigen, welche Seite welchem Spieler/NPC und welchem Spawnmarker gehoert. Kompakte Icon-/Symbolfelder machen diese Information schneller scanbar und sind die Vorstufe fuer spaetere echte UI-Icons.

## Umfang
- `MissionTeamChipPresenter` um kompakte, ASCII-sichere Icon-/Symbolfelder erweitern.
- Mission-HUD-Status auf kompaktere Icon-Text-Ausgabe umstellen.
- `MissionBriefingMinimapOverlayPresenter` um dieselben Team-Icon-/Kurzlabel-Felder fuer `team_spawn`-Overlays erweitern.
- Verifier fuer Presenter-, Mission-HUD- und Briefing-Overlay-Snapshots ergaenzen.
- Status, Roadmap und laufenden HTML-Arbeitsbericht aktualisieren.

## Nicht-Ziele
- Keine neuen Textur-/Bitmap-Icons.
- Kein finaler Briefing-Panel-Renderer.
- Keine neue Multiplayer-Teamzuweisung.
- Keine Gameplay-Mutation im UI.
- Kein kompletter HUD-Layout-Umbau.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_528_rolling_html_status_report.md`
- `docs/tasks/TASK_527_briefing_minimap_team_spawn_overlay.md`
- `docs/tasks/TASK_526_mission_hud_team_chip_polish.md`
- `docs/dev/mission_briefing_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/dev/multiplayer_session_lobby.md`

## Akzeptanzkriterien
- Teamchip-Snapshots enthalten pro Team `icon_text`, `compact_text`, `icon_tooltip`, `visual_priority` und `team_color_hex`.
- Der Mission-HUD-Labeltext nutzt die kompakte Icon-Ausgabe und bleibt deutlich kuerzer als die alte Owner-/Spawn-Volltextkette.
- Briefing-Minimap-Team-Spawns enthalten dieselben kompakten Icon-/Label-Felder.
- Alle neuen Felder bleiben read-only und werden aus bestehenden Ownership-/Vertical-Slice-/Terrain-Daten abgeleitet.
- Bestehende TASK_526- und TASK_527-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/mission/mission_team_chip_presenter.gd`
- `scripts/mission/mission_briefing_minimap_overlay_presenter.gd`
- `scripts/tests/task_529_mission_hud_team_icon_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_briefing_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_529_mission_hud_team_icon_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_526_mission_hud_team_chip_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_527_briefing_minimap_team_spawn_overlay.gd`
- `git diff --check`

## Risiken / offene Punkte
- ASCII-Symbole sind nur eine Zwischenstufe. Spaeter koennen echte kleine Icons/TextureRects folgen, wenn der HUD-Renderer dafuer aufgeraeumt wird.
- Der finale Briefing-Panel-Renderer bleibt TASK_530.

## Status: IMPLEMENTIERT
