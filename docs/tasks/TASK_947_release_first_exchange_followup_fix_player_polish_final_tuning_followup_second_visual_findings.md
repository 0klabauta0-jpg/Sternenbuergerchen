# TASK_947 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Visual Findings

## Ziel / Problem
TASK_946 stellt nach dem TASK_945-Second-Fix einen echten Window-Handle-Recapture-/Review-Rahmen bereit. Der naechste Schritt darf diesen Beleg nicht automatisch als Erfolg behandeln. TASK_947 bewertet den TASK_946-Snapshot/Manifest read-only und entscheidet, ob der First-Exchange-Playability-Smoke sinnvoll ist.

## Sinnhaftigkeit / Ursache
Die First-Exchange-Polish-Kette hat bereits mehrere enge Sichtfixes erhalten. Wenn der echte Fensterblick nach TASK_945 noch immer nicht akzeptiert ist, soll nicht automatisch ein weiterer Werte-Polish folgen. Dann ist der bessere naechste Schritt, wieder auf spielbare Szenarien und Tactical-Decision-Clarity zu gehen.

## Umfang
- TASK_946-Snapshot/Manifest als Quelle pruefen.
- TASK_945-Second-Fix, TASK_944-Findings, TASK_942-Followup-Fix und TASK_943-Recapture-Basis nachvollziehbar halten.
- Positive Evidence, offene Sichtbefunde und blockierende Source-Probleme trennen.
- Akzeptierten Sichtbefund zu `TASK_948 - Release First Exchange Playability Smoke` routen.
- Nicht akzeptierten Sichtbefund zu `TASK_948 - Tactical Decision Clarity Scenario Return` routen.
- Read-only-Grenzen beibehalten.

## Nicht-Ziele
- Kein weiterer visueller Polish.
- Kein neuer Capture.
- Kein Playability-Smoke-Run.
- Kein Combat-, Damage-, Contact-, Movement- oder Command-Rewrite.
- Keine neue UI-, HUD-, Multiplayer- oder Gameplay-Wahrheit.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_946_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.md`
- `docs/tasks/TASK_945_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix.md`
- `docs/tasks/TASK_944_release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.md`
- `docs/tasks/TASK_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.md`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupFixPlayerPolishFinalTuningFollowupSecondVisualFindings.build_snapshot()` blockt fehlende oder falsche TASK_946-/TASK_945-/TASK_944-/TASK_942-Quellen.
- Der Snapshot meldet `schema = sternenbuergerchen.release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings.v1` und `task_id = TASK_947`.
- Ohne manuellen Sichtbefund bleibt der Snapshot `needs_manual_review`.
- Sauber akzeptierte Review-Notizen empfehlen `TASK_948 - Release First Exchange Playability Smoke`.
- Restreibung nach TASK_945 empfiehlt `TASK_948 - Tactical Decision Clarity Scenario Return`, statt noch einen automatischen Mikropolish zu starten.
- Snapshot meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_947_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings.md`
- `scripts/mission/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings.gd`
- `scripts/tests/task_947_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_947_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_946_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_947 bewertet nur den Beleg. Er ersetzt weder den echten Playability-Smoke noch ein spielbares Mini-Szenario. Wenn TASK_947 nicht akzeptiert wird, sollte der naechste Schritt bewusst wieder in spielbare Entscheidungslesbarkeit, Szenarioinhalt und Flow gehen.

## Naechster Schritt
Bei akzeptiertem Sichtbefund: TASK_948 - Release First Exchange Playability Smoke.  
Bei Restreibung: TASK_948 - Tactical Decision Clarity Scenario Return.
