# TASK_942 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Fix

## Ziel / Problem
TASK_941-Gate und das vorhandene TASK_940-Manifest melden Restreibung statt Smoke-Freigabe: Die Final-Tuning-Fire-Lane ist noch nicht sicher die erste Weltbewegung, FIRE/CONTACT-Text und Zielcluster ziehen teilweise vor, und Label/Halo konkurrieren noch.

## Sinnhaftigkeit / Ursache
CONTACT FIRE ist im HUD/Log bereits sauber vorhanden. Der naechste sinnvolle Schritt ist deshalb kein neuer Combat- oder HUD-Wahrheitspfad, sondern ein enger Presentation-Fix fuer die 2.5D-Welt-Hierarchie.

## Umfang
- TASK_941-Gate als Quelle pruefen.
- TASK_940-Primary-Issue `final_tuning_fire_lane_not_first_world_movement` als Ausloeser verlangen.
- Neuen Style `task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix_v1` einfuehren.
- Fire-Lane/Core gegenueber TASK_938 staerken.
- FIRE/CONTACT-Text, Target-Halo, Grid-Noise und Weltlinien weiter in den Hintergrund nehmen.
- Source-/Target-Anker knapp unter der Scheiben-Grenze halten.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Smoke-Run.
- Kein neuer Capture.
- Keine neuen FireEvents, DamageEvents, Commands oder Movement-Entscheidungen.
- Keine neue UI-, Contact-, Mission- oder Multiplayer-Wahrheit.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_941_release_first_exchange_final_tuning_playability_smoke_gate.md`
- `docs/tasks/TASK_940_release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.md`
- `docs/tasks/TASK_938_release_first_exchange_followup_fix_player_polish_final_tuning.md`
- `docs/reports/spielstand_zwischenbericht_task939_ausblick_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupFixPlayerPolishFinalTuningFollowupFix.build_snapshot()` verlangt TASK_941 `followup_fix_required` und TASK_940 `ready_for_followup_fix_player_polish_final_tuning_followup_fix`.
- Der Snapshot meldet `gate = pass`, wenn der neue Style aktiv ist und die Werte strenger als TASK_938 sind.
- `TerrainMap3DView` meldet den neuen Style, Lane/Core, Text-/Halo-Rueckzug, Grid-/World-Line-Rueckzug und Fire-VFX-Eintrag.
- Source-/Target-Anker bleiben `<= 0.225`, damit sie nicht als Scheiben wirken.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.md`
- `scripts/mission/release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.gd`
- `scripts/tests/task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task939_ausblick_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_941_release_first_exchange_final_tuning_playability_smoke_gate.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_938_release_first_exchange_followup_fix_player_polish_final_tuning.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_942 ersetzt keinen echten Fensterbeweis. Nach dem Fix braucht es wieder einen Recapture-/Review-Slice, bevor ein Playability-Smoke ehrlich freigegeben werden kann.

## Naechster Schritt
TASK_943 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Recapture.
