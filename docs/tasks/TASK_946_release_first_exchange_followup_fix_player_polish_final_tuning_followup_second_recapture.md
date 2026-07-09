# TASK_946 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Recapture

## Ziel / Problem
TASK_945 hat den TASK_944-Restbefund als zweiten engen Presentation-Fix umgesetzt. Es fehlt danach wieder der echte Fensterbeweis, ob die TASK_945-Fire-Lane/Core-Hierarchie im Spielerblick wirklich vor FIRE/CONTACT-Text, Target-Halo, Grid und Weltlinien gelesen wird.

## Sinnhaftigkeit / Ursache
Der First-Exchange-Playability-Smoke bleibt zu frueh, solange TASK_945 nur ueber Headless-/Render-Snapshots belegt ist. TASK_946 legt deshalb einen read-only Recapture- und Review-Rahmen an den bestehenden TASK_943-Pfad, ohne Combat-, Movement-, HUD- oder Multiplayer-Wahrheit zu veraendern.

## Umfang
- TASK_943-Recapture-Pfad wiederverwenden.
- Eigenes TASK_946-Manifest und eigene Screenshotpfade schreiben.
- Erwartete TASK_945-Schema-/Style-ID im Manifest fixieren.
- TASK_944-Findings, TASK_942-Followup-Fix und TASK_943-Recapture-Basis als Quellen festhalten.
- Pflichtchecks fuer TASK_945-Weltlesung, CONTACT-FIRE-HUD und bedienbare Command-Surfaces definieren.
- `review_ready` von echter manueller Akzeptanz trennen.
- Snapshot read-only halten.

## Nicht-Ziele
- Kein neuer Playability-Smoke.
- Kein weiterer visueller Polish.
- Kein Combat-, Damage-, Contact-, Movement- oder Command-Rewrite.
- Keine neue HUD-, UI-, Multiplayer- oder Gameplay-Wahrheit.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_945_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix.md`
- `docs/tasks/TASK_944_release_first_exchange_followup_fix_player_polish_final_tuning_followup_visual_findings.md`
- `docs/tasks/TASK_943_release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.md`
- `docs/tasks/TASK_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.md`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupFixPlayerPolishFinalTuningFollowupSecondRecapture.build_snapshot()` akzeptiert nur ein TASK_946-Manifest mit TASK_945, TASK_944, TASK_942 und TASK_943 als erwarteten Quellen.
- Capture-Script schreibt `tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.json`, `tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.png` und Desktop-Screenshotpfad.
- Falsche Schemas, falsche Task-IDs, falscher Launch-Arg, fehlender Prozess, untrusted Capture oder fehlender Window-Screenshot blocken.
- Gutes Manifest wird `review_ready`, aber ohne manuelle Checks nicht `accepted`.
- Abgeschlossene Pflichtchecks setzen den Snapshot auf `accepted`.
- Snapshot meldet `read_only`, erzeugt keine Commands, FireEvents, DamageEvents, Movement-Events, Multiplayer-Wahrheit oder Shortcut-Aenderungen.
- Naechster Schritt ist `TASK_947 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Visual Findings`.

## Betroffene Dateien
- `docs/tasks/TASK_946_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.md`
- `scripts/mission/release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.gd`
- `scripts/tools/capture_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.ps1`
- `scripts/tests/task_946_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_946_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_945_release_first_exchange_followup_fix_player_polish_final_tuning_followup_second_fix.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_946 erzeugt den Belegrahmen, akzeptiert aber keinen Screenshot automatisch. Der echte PNG-Befund muss danach als TASK_947 read-only bewertet werden. Erst wenn der Spielerblick akzeptiert ist, ist ein First-Exchange-Playability-Smoke sinnvoll.

## Naechster Schritt
TASK_947 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Second Visual Findings.
