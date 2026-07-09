# TASK_916 - Release First Exchange Fire Lane World Read Final Polish

## Ziel / Problem
TASK_915 benennt als Restreibung, dass die Fire-Lane nach TASK_913 zwar staerker ist, aber noch nicht sicher als erste Weltbewegung gelesen wird. TASK_916 setzt deshalb einen letzten engen Weltlese-Polish um, ohne Combat-, HUD- oder Gameplay-Wahrheit zu oeffnen.

## Sinnhaftigkeit / Ursache
Der Spieler soll im ersten Feuerwechsel zuerst die Bewegung Quelle -> Ziel lesen. Der TASK_913-Polish hat die richtige Richtung, aber TASK_915 haelt Fire-Lane, Richtunganker und Label/Halo-Konkurrenz als offene Sichtreibung fest. Der naechste Schritt muss deshalb Presentation-only bleiben: Core/Anker minimal staerker, Halo/Label/Weltlinien minimal leiser.

## Umfang
- TASK_916 als naechsten Visual-Polish auf der bestehenden TASK_913-Kette aktivieren.
- Fire-Lane-Core und Source-/Target-Anker final etwas staerken.
- Guide-Lane weich halten, damit kein Debug-Balken entsteht.
- Target-Halo, Welt-Fire-Label, Grid und Weltlinien weiter zuruecknehmen.
- Controller-Snapshot und `TerrainMap3DView.get_render_snapshot()` read-only erweitern.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands oder Movement-Entscheidungen.
- Keine neue UI-, Contact-, Mission- oder Multiplayer-Wahrheit.
- Kein neuer Capture in diesem Task.
- Kein Bottom-HUD-Refactor.
- Keine Shortcut-/Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_915_release_first_exchange_fire_lane_world_read_acceptance_visual_findings.md`
- `docs/tasks/TASK_913_release_first_exchange_fire_lane_world_read_acceptance_polish.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFireLaneWorldReadFinalPolish.build_snapshot()` akzeptiert TASK_915-Findings als Quelle.
- `TerrainMap3DView.get_render_snapshot()` meldet `task_916_release_first_exchange_fire_lane_world_read_final_v1`.
- TASK_916 ist nur aktiv, wenn TASK_913 aktiv ist.
- Fire-Lane-Core und Source-/Target-Anker sind staerker als TASK_913, bleiben aber klein genug fuer ein nicht-debughaftes Weltbild.
- Target-Halo, Welt-Fire-Label, Grid und Weltlinien treten weiter hinter die Lane zurueck.
- Controller liefert `get_release_first_exchange_fire_lane_world_read_final_polish_snapshot()` read-only.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_916_release_first_exchange_fire_lane_world_read_final_polish.md`
- `scripts/mission/release_first_exchange_fire_lane_world_read_final_polish.gd`
- `scripts/tests/task_916_release_first_exchange_fire_lane_world_read_final_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_916_release_first_exchange_fire_lane_world_read_final_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_915_release_first_exchange_fire_lane_world_read_acceptance_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_913_release_first_exchange_fire_lane_world_read_acceptance_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_916 ist weiterhin kein echter Fensterbeweis. Der naechste Slice muss wieder recapturen und den Spielerblick bewerten. Wenn TASK_916 danach reicht, sollte kein weiterer Fire-Lane-Polish folgen, sondern ein kurzer First-Exchange-Playability-Smoke.

## Naechster Schritt
TASK_917 - Release First Exchange Final World Read Recapture.
