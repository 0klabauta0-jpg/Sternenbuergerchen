# TASK_544 - Mission Fire And Cover Visual Polish Pass

## Ziel / Problem
Die erste Combat-Entscheidung ist seit TASK_543 als Datenpfad nachvollziehbar, aber im sichtbaren Missionsbild muss der Spieler schneller erkennen, wer feuert, wohin geschossen wird, ob ein Treffer/Miss vorliegt und welcher Status an den Units gerade relevant ist.

## Sinnhaftigkeit / Ursache
Der aktuelle FireEvent-Pfad hatte bereits Muzzle, Trace und Impact. Fuer spielbare Lesbarkeit fehlt aber ein kompakter Ziel-Fokus und pruefbare Badge-Metadaten, ohne aus UI-Visuals eine zweite Gameplay-Wahrheit zu machen.

## Umfang
- Bestehenden `TerrainMap3DView`-FireEvent-VFX-Pfad erweitern.
- Ziel-Fokusmarker und kompaktes Fire-Statuslabel am Impact anzeigen.
- Unit-Statusbadges mit Farbe/Style im Render-Snapshot ausgeben.
- `MissionTacticalSandboxController` um einen read-only TASK_544-Snapshot ergaenzen.
- Rolling-HTML-Bericht auf TASK_544 aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue Damage-/LOS-/Cover-Wahrheit im HUD.
- Kein manueller F6-/Pixel-Sichttest in diesem Task.
- Keine Aenderung an Fireteam-, Dropship- oder Mission-Command-Semantik.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_543_mission_first_engagement_feedback_pass.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- FireTrace bleibt sichtbar und duenn genug fuer wiederholte FireEvents.
- Impact bekommt einen Ziel-Fokusmarker und ein kurzes Statuslabel (`FIRE`, `HIT`, `MISS`, `FF`).
- Unit-Badges bleiben sichtbar und liefern Text, Farb-Hexwert und Style im Snapshot.
- `get_mission_fire_cover_visual_polish_snapshot()` ist read-only und behauptet keine Gameplay-Mutation.
- Der Rolling-HTML-Bericht nennt erledigte Arbeit und naechsten Anschluss.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_544_mission_fire_cover_visual_polish_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_544_mission_fire_cover_visual_polish_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_543_mission_first_engagement_feedback_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Task prueft Render-Snapshots headless und keinen menschlichen Screenshot. Der naechste sinnvolle Anschluss ist ein kurzer F6-Sichttest im echten Godot-Fenster oder direkt ein spielbarer First-Engagement-Polish mit Screenshot-Notizen.
