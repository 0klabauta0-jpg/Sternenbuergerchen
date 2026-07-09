# TASK_938 - Release First Exchange Followup Fix Player Polish Final Tuning

## Ziel / Problem
TASK_937 bewertet den TASK_936-Spielerblick nach TASK_935 read-only. Ohne akzeptierten Sichtbefund bleibt der First-Exchange-Playability-Smoke zu frueh. TASK_938 setzt deshalb nur den belegten Restbefund als engen Presentation-Slice um: Die Source-to-target-Fire-Lane soll im ersten CONTACT-FIRE-Moment noch klarer vor Text, Halo, Raster und Weltlinien gelesen werden.

## Sinnhaftigkeit / Ursache
Der erste Feuerwechsel ist inzwischen in #17/#18/#19 und Primary3D vorhanden, aber der Spielerblick darf nicht erneut in Text-/Halo-/Grid-Konkurrenz kippen. Mehr Combat-Logik oder mehr HUD-Text waere hier der falsche Hebel. Der richtige Hebel ist ein kleiner, pruefbarer Render-/Snapshot-Folgepolish.

## Umfang
- TASK_937-Findings als Quelle pruefen.
- TASK_935-Player-Polish als Baseline wiederverwenden.
- Neuen Style `task_938_release_first_exchange_followup_fix_player_polish_final_tuning_v1` einfuehren.
- Fire-Lane/Core minimal staerker vor Text/Halo lesbar machen.
- Label, Halo, Grid und World-Lines weiter zuruecknehmen.
- Source-/Target-Anker leicht tragender machen, aber unter der Scheiben-Grenze halten.
- Controller-Payload und `TerrainMap3DView`-Render-Snapshot erweitern.
- Contract, Status, Roadmap und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein neuer Capture.
- Kein Playability-Smoke.
- Kein Combat-, Damage-, Contact-, Movement- oder HUD-Truth-Umbau.
- Keine neuen Commands oder FireEvents.
- Keine Multiplayer-Wahrheit und keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_937_release_first_exchange_followup_fix_player_polish_visual_findings.md`
- `docs/tasks/TASK_935_release_first_exchange_followup_fix_player_polish.md`
- `docs/tasks/TASK_932_release_first_exchange_final_readability_followup_fix.md`
- `docs/reports/spielstand_zwischenbericht_task937_938_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupFixPlayerPolishFinalTuning.build_snapshot()` verlangt TASK_937-Findings mit `ready_for_followup_fix_player_polish_final_tuning`.
- Der Snapshot verlangt einen passierenden TASK_935-Player-Polish als Baseline.
- Der neue Renderstil ist aktiv, wenn TASK_935 aktiv ist und der TASK_938-Payload gesetzt wird.
- Lane/Core sind staerker als TASK_935, waehrend Lane-Alpha, Label-Alpha, Halo, Grid und World-Line-Faktoren weiter zuruecktreten.
- Source-/Target-Anker werden tragender, bleiben aber unter der Scheiben-Grenze.
- Fire-VFX-Eintraege melden den TASK_938-Style und verwenden dessen Core/Label-Werte effektiv.
- Snapshot und Renderpfad bleiben read-only und erzeugen keine Gameplay-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_938_release_first_exchange_followup_fix_player_polish_final_tuning.md`
- `scripts/mission/release_first_exchange_followup_fix_player_polish_final_tuning.gd`
- `scripts/tests/task_938_release_first_exchange_followup_fix_player_polish_final_tuning.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task937_938_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_938_release_first_exchange_followup_fix_player_polish_final_tuning.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_937_release_first_exchange_followup_fix_player_polish_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_935_release_first_exchange_followup_fix_player_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_938 ersetzt weiterhin keinen echten Fensterbeweis. Nach diesem Final-Tuning muss wieder ein Recapture-/Findings-Slice folgen oder bei akzeptiertem Blick endlich der Playability-Smoke starten.

## Naechster Schritt
TASK_939 - Release First Exchange Followup Fix Player Polish Final Tuning Recapture.
