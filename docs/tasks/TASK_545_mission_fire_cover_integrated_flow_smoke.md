# TASK_545 - Mission Fire Cover Integrated Flow Smoke

## Ziel / Problem
TASK_544 beweist die Fire-/Cover-Politur in einer kleinen Render-Fixture. Der naechste sinnvolle Schritt ist zu pruefen, ob dieselbe Lesbarkeit auch im echten Spielerpfad ankommt: Homebase, Dropship, Mission, Deboarding, erste Bewegung, Kontakt und erstes Engagement.

## Sinnhaftigkeit / Ursache
Ein isolierter Render-Snapshot schuetzt den Visual-Code, aber nicht den Handoff vom echten Combat-/Mission-Flow in `TerrainMap3DView`. Gerade FireEvents, Badge-State und Cover-Kontext koennen unterwegs durch Refresh-, Payload- oder Timing-Pfade verloren gehen.

## Umfang
- Einen integrierten Godot-Smoke fuer den vollen ersten Engagement-Pfad anlegen.
- Nach reproduzierbarem Kontakt/Engagement `get_mission_fire_cover_visual_polish_snapshot()` pruefen.
- Sicherstellen, dass FireTrace, Ziel-Fokus, Fire-Label, Unit-Badge-Metadaten und Cover-/LOS-/Range-Kontext im echten Flow sichtbar bleiben.
- Rolling-HTML-Bericht, Status und Roadmap aktualisieren.

## Nicht-Ziele
- Kein manueller F6-/Screenshot-Sichttest.
- Kein Combat-Rewrite.
- Keine neue Visual-Wahrheit im HUD.
- Keine Aenderung an Dropship-, Movement-, Contact- oder Damage-Semantik.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_544_mission_fire_cover_visual_polish_pass.md`
- `docs/tasks/TASK_543_mission_first_engagement_feedback_pass.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der Smoke startet aus Homebase, boarded ein Fireteam, startet die Mission, setzt LZ und deployed.
- Der Smoke plant/fuehrt eine erste Move-Order aus, erzeugt Kontakt und stoesst die bestehende Combat-Entscheidung an.
- `get_mission_fire_cover_visual_polish_snapshot()` liefert `gate = pass`.
- Die Checks fuer FireTrace, Ziel-Fokus, Unit-Badges, Cover-Kontext und read-only Verhalten sind gruen.

## Betroffene Dateien
- `scripts/tests/task_545_mission_fire_cover_integrated_flow_smoke.gd`
- `docs/tasks/TASK_545_mission_fire_cover_integrated_flow_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_545_mission_fire_cover_integrated_flow_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_544_mission_fire_cover_visual_polish_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Smoke ist absichtlich laenger und kann mehrere Minuten laufen. Er ersetzt keinen menschlichen Pixel-Sichttest, beweist aber, dass die neue Fire-/Cover-Lesbarkeit durch den echten Missionsflow bis in den Render-Snapshot gelangt.
