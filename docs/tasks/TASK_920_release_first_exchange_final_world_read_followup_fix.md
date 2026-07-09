# TASK_920 - Release First Exchange Final World Read Followup Fix

## Ziel / Problem
Der echte TASK_917-Window-Capture bestaetigt CONTACT FIRE in den HUD-Flaechen, aber die Weltlesung ist noch nicht sauber genug: FIRE/CONTACT-Welttext und Zielcluster konkurrieren weiter mit der Source-to-target-Fire-Lane.

## Sinnhaftigkeit / Ursache
TASK_919 sperrt den Playability-Smoke, solange TASK_918 keine echte Akzeptanz meldet. Der belegte Restpunkt ist eng: nicht Combat, Movement oder HUD-Wahrheit, sondern die visuelle Hierarchie im bestehenden Primary3D-Fire-Lane-Pfad.

## Umfang
- TASK_918-Follow-up-Befund read-only als Quelle verwenden.
- Einen eigenen TASK_920-Style-Schalter am bestehenden TASK_916-Final-Pfad anhaengen.
- Fire-Lane-Core und Source-/Target-Anker minimal staerken.
- Welt-Fire-Label, Target-Halo, Raster und Weltlinien weiter beruhigen.
- Snapshot-, Render- und VFX-Metadaten fuer die neuen Werte ausgeben.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-, Movement-, LOS-, Pathfinding- oder HUD-Truth-Rewrite.
- Kein echter Playability-Smoke-Run.
- Keine neuen Commands, FireEvents, DamageEvents oder Movement-Entscheidungen.
- Keine neue Multiplayer-Wahrheit.
- Keine Shortcut-/Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_919_release_first_exchange_playability_smoke_gate.md`
- `docs/tasks/TASK_918_release_first_exchange_final_world_read_visual_findings.md`
- `docs/tasks/TASK_916_release_first_exchange_fire_lane_world_read_final_polish.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFinalWorldReadFollowupFix.build_snapshot()` akzeptiert TASK_918-Follow-up-Findings und TASK_916-Final-Polish als Quelle.
- Fehlende oder falsche Quellen blocken den Snapshot.
- `TerrainMap3DView.get_render_snapshot()` meldet den TASK_920-Style und effektive Lane-/Core-/Halo-/Anchor-/Label-/Noise-Werte.
- Fire-Lane-Core ist staerker als TASK_916, aber Label/Halo/Grid/Weltlinien sind ruhiger als TASK_916.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_920_release_first_exchange_final_world_read_followup_fix.md`
- `scripts/mission/release_first_exchange_final_world_read_followup_fix.gd`
- `scripts/tests/task_920_release_first_exchange_final_world_read_followup_fix.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_920_release_first_exchange_final_world_read_followup_fix.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_919_release_first_exchange_playability_smoke_gate.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_916_release_first_exchange_fire_lane_world_read_final_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_920 ersetzt keinen echten Smoke. Nach dem Fix muss wieder ein echter Window-Capture/Findings-Schnitt pruefen, ob die Fire-Lane im Spielerblick jetzt wirklich die erste Weltbewegung ist.

## Naechster Schritt
TASK_921 - Release First Exchange Followup World Read Recapture.
