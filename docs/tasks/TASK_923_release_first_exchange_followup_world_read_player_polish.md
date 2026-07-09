# TASK_923 - Release First Exchange Followup World Read Player Polish

## Ziel / Problem
TASK_922 trennt den Follow-up-Spielerblick sauber in Akzeptanz oder Restreibung. Ohne akzeptierten Sichtbefund bleibt der First-Exchange-Smoke gesperrt. Der naechste sinnvolle Schritt ist deshalb ein enger Player-Polish auf dem bestehenden TASK_920-World-Read-Pfad.

## Sinnhaftigkeit / Ursache
Die aktuelle Reibung ist eng: CONTACT FIRE ist in den HUD-Flaechen vorhanden, aber die Weltbewegung Quelle -> Ziel muss fuer den ersten Blick weiter fuehren. Wir duerfen dafuer nicht Combat, Damage, LOS, Movement oder HUD-Wahrheit oeffnen; nur die Presentation-Gewichtung im bestehenden Primary3D-Fire-Lane-Pfad wird nachgezogen.

## Umfang
- Einen TASK_923-Style-Schalter an den bestehenden TASK_920-Follow-up-Pfad haengen.
- Fire-Lane-Core etwas staerker und lesbarer machen.
- Source-/Target-Anker etwas staerker als Richtungspunkte, aber nicht scheibenhaft.
- Welt-Fire-Label, Target-Halo, Grid und Weltlinien weiter zuruecknehmen.
- Snapshot-, Render- und VFX-Metadaten fuer die neuen Werte ausgeben.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-, Movement-, LOS-, Pathfinding- oder HUD-Truth-Rewrite.
- Kein echter Playability-Smoke-Run in diesem Task.
- Keine neuen Commands, FireEvents, DamageEvents oder Movement-Entscheidungen.
- Keine neue Multiplayer-Wahrheit.
- Keine Shortcut-/Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_922_release_first_exchange_followup_world_read_visual_findings.md`
- `docs/tasks/TASK_920_release_first_exchange_final_world_read_followup_fix.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupWorldReadPlayerPolish.build_snapshot()` akzeptiert TASK_922-Restreibung und TASK_920-Follow-up-Fix als Quelle.
- Fehlende oder falsche Quellen blocken den Snapshot.
- `TerrainMap3DView.get_render_snapshot()` meldet den TASK_923-Style und effektive Lane-/Core-/Halo-/Anchor-/Label-/Noise-Werte.
- Fire-Lane-Core ist staerker als TASK_920, aber Label/Halo/Grid/Weltlinien sind ruhiger als TASK_920.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.
- Der naechste Schritt wird als TASK_924 Follow-up Player Polish Recapture benannt.

## Betroffene Dateien
- `docs/tasks/TASK_923_release_first_exchange_followup_world_read_player_polish.md`
- `scripts/mission/release_first_exchange_followup_world_read_player_polish.gd`
- `scripts/tests/task_923_release_first_exchange_followup_world_read_player_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_923_release_first_exchange_followup_world_read_player_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_922_release_first_exchange_followup_world_read_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_920_release_first_exchange_final_world_read_followup_fix.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_923 ist erneut nur Presentation-Polish. Danach muss frisch recaptured werden; kein Test darf den neuen Stil automatisch als Spielerakzeptanz ausgeben.

## Naechster Schritt
TASK_924 - Release First Exchange Followup Player Polish Recapture.
