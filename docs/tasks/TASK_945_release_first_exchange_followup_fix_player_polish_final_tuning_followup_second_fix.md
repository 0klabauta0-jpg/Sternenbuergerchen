# TASK_945 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Fix

## Ziel / Problem
TASK_944 hat den TASK_943-Fensterbefund read-only ausgewertet und nicht fuer den First-Exchange-Playability-Smoke akzeptiert. CONTACT FIRE ist sichtbar und die HUD-Surfaces sind vorhanden, aber die Source-to-target-Fire-Lane ist im echten Fenster noch nicht sicher die erste Weltbewegung. FIRE/CONTACT-Text, Zielcluster oder Halo konkurrieren weiterhin mit der Lane.

## Sinnhaftigkeit / Ursache
Der naechste Schritt darf kein weiterer Combat-, HUD- oder Gameplay-Truth-Umbau sein. Der belegte Restbefund ist eng: die Weltbild-Hierarchie im ersten Feuerwechsel muss noch einmal nachgeschoben werden. TASK_945 setzt daher nur einen zweiten Presentation-Fix auf die TASK_942-Baseline, damit Lane/Core klarer vor Text/Halo gelesen werden und Label/Grid/Weltlinien weiter zuruecktreten.

## Umfang
- TASK_944-Findings als Quelle pruefen.
- TASK_942-Followup-Fix als Presentation-Baseline beibehalten.
- Einen neuen read-only Style fuer Primary3D/Fire-VFX einfuehren:
  - Fire-Lane/Core noch klarer als erste Weltbewegung.
  - Breite Lane etwas ruhiger, Core etwas tragender.
  - FIRE/CONTACT-Weltlabel, Target-Halo, Grid und Weltlinien weiter in den Hintergrund.
  - Source-/Target-Anker bleiben unter der Scheiben-Grenze.
- Mission-Controller-Snapshot und Order-Visual-Payload an die bestehende Kette haengen.
- Status, Roadmap und Contract aktualisieren.

## Nicht-Ziele
- Kein neuer Capture.
- Kein Playability-Smoke.
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands, Navigation oder Movement-Entscheidungen.
- Keine neue UI-, Contact-, Mission- oder Multiplayer-Wahrheit.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_944_release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.md`
- `docs/tasks/TASK_943_release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.md`
- `docs/tasks/TASK_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.md`
- `docs/tasks/TASK_941_release_first_exchange_final_tuning_playability_smoke_gate.md`
- `docs/tasks/TASK_940_release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.md`
- `docs/tasks/TASK_938_release_first_exchange_followup_fix_player_polish_final_tuning.md`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupFixPlayerPolishFinalTuningFollowupSecondFix.build_snapshot()` blockt fehlende oder falsche TASK_944-/TASK_942-Quellen.
- Der Snapshot meldet `schema = sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix.v1`, `task_id = TASK_945` und einen stabilen Style `task_945_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix_v1`.
- Der neue Style ist nur aktiv, wenn der TASK_945-Payload aktiv ist.
- Lane/Core werden gegenueber TASK_942 klarer, Label/Halo/Grid/Weltlinien leiser.
- Source-/Target-Anker bleiben unter oder gleich `0.225`.
- Fire-VFX-Eintraege tragen die TASK_945-Flags und nutzen die TASK_945-Core-Breite als effektive Trace-Breite.
- Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.
- Naechster Schritt ist `TASK_946 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Recapture`.

## Betroffene Dateien
- `docs/tasks/TASK_945_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix.md`
- `scripts/mission/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix.gd`
- `scripts/tests/task_945_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_945_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_944_release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_945 darf nicht zur endlosen Mikropolish-Schleife werden. Nach diesem Fix braucht es wieder einen frischen Recapture und dann entweder den echten Playability-Smoke oder eine bewusste Entscheidung, den First-Exchange-Polish zu stoppen und zur Tactical-Decision-Clarity bzw. zum kleinen Szenario zurueckzugehen.

## Naechster Schritt
TASK_946 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Recapture.
