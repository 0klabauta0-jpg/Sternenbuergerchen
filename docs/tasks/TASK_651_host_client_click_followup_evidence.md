# TASK_651 - Host Client Click Followup Evidence

## Ziel / Problem
TASK_650 zeigt nach einem falschen Host/Client-Klick einen naechsten Handlungshinweis wie `USE BRAVO`. Die Real-Click-Review-Pakete pruefen bisher aber nur `BLOCK P2 wrong team`. Der naechste sichtbare Host/Client-Lauf wuerde also nicht gezielt kontrollieren, ob der neue Follow-up-Cue wirklich lesbar ist.

## Sinnhaftigkeit / Ursache
Die Multiplayer-Bedienung soll nicht nur technisch korrekt blockieren, sondern dem Spieler sofort sagen, was er als Naechstes tun soll. Dafuer muessen Capture-Manifest und Playtest-Packet denselben Cue als Pflichtbeobachtung fuehren.

## Umfang
- `capture_host_client_two_window_real_run.ps1` erweitert das read-only Manifest um erwartete Follow-up-Felder.
- `task_626_host_client_real_click_review_evidence.gd` prueft die neuen Manifestfelder weiter als Regression.
- `task_629_host_client_real_click_playtest_evidence_pass.gd` schreibt und prueft den neuen `USE BRAVO`-Cue im Playtest-Packet.
- Neuer TASK_651-Verifier prueft Task, Contract, Manifest, Packet und read-only-Grenzen.

## Nicht-Ziele
- Kein automatisches Klicken in den Godot-Fenstern.
- Kein neues Toast-/Notification-System.
- Kein neuer Multiplayer-Authority-Pfad.
- Kein UI- oder Gameplay-State.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_650_host_client_click_feedback_followup.md`
- `docs/tasks/TASK_626_host_client_real_click_review_evidence.md`
- `docs/tasks/TASK_629_host_client_real_click_playtest_evidence_pass.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Real-Run-Manifest enthaelt `visible_reject_expected_action_text = USE BRAVO`.
- Real-Run-Manifest enthaelt `visible_reject_expected_next_action_text = Use BRAVO fireteam.`.
- Manuelle Checks enthalten `action_cue_visible`.
- Playtest-Packet enthaelt denselben Action-Cue in `expected_visible_feedback`.
- Playtest-Packet fuehrt `action_cue_visible` als manuelle Beobachtung.
- Alle neuen Felder bleiben read-only und setzen keine Gameplay-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_651_host_client_click_followup_evidence.md`
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/tests/task_626_host_client_real_click_review_evidence.gd`
- `scripts/tests/task_629_host_client_real_click_playtest_evidence_pass.gd`
- `scripts/tests/task_651_host_client_click_followup_evidence.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_651_host_client_click_followup_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_626_host_client_real_click_review_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_629_host_client_real_click_playtest_evidence_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das ist weiter Evidence-Vorbereitung, nicht der erledigte menschliche Zwei-Fenster-Klicktest.
- Wenn `USE BRAVO` im echten Bild nicht auffaellig genug ist, braucht es danach einen belegten Visual-Polish-Slice.
