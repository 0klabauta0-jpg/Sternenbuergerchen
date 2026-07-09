# TASK_943 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Recapture

## Ziel / Problem
TASK_942 hat den TASK_941-Restpfad als engen Followup-Fix umgesetzt. Es fehlt noch der echte Fensterbeweis, ob die Fire-Lane/Core-Hierarchie nach TASK_942 im Spielerblick wirklich vor FIRE/CONTACT-Text, Target-Halo, Grid und Weltlinien gelesen wird.

## Sinnhaftigkeit / Ursache
Der First-Exchange-Playability-Smoke bleibt zu frueh, solange der TASK_942-Presentation-Fix nur im Headless-/Render-Snapshot belegt ist. TASK_943 legt deshalb einen read-only Recapture- und Review-Rahmen an den vorhandenen TASK_939-Pfad, ohne Combat-, Movement- oder HUD-Wahrheit zu veraendern.

## Umfang
- TASK_939-Recapture-Pfad wiederverwenden.
- Eigenes TASK_943-Manifest und eigene Screenshotpfade schreiben.
- Erwartete TASK_942-Schema-/Style-ID im Manifest fixieren.
- TASK_941-Gate, TASK_940-Findings und TASK_938-Final-Tuning-Basis als Quellen festhalten.
- Pflichtchecks fuer TASK_942-Weltlesung, CONTACT-FIRE-HUD und bedienbare Command-Surfaces definieren.
- `review_ready` von echter manueller Akzeptanz trennen.
- Snapshot read-only halten.

## Nicht-Ziele
- Kein neuer Smoke-Run.
- Kein weiterer visueller Polish.
- Kein Combat-, Damage-, Contact-, Movement- oder Command-Rewrite.
- Keine neue HUD-, UI-, Multiplayer- oder Gameplay-Wahrheit.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.md`
- `docs/tasks/TASK_941_release_first_exchange_final_tuning_playability_smoke_gate.md`
- `docs/tasks/TASK_940_release_first_exchange_followup_fix_player_polish_final_tuning_visual_findings.md`
- `docs/tasks/TASK_939_release_first_exchange_followup_fix_player_polish_final_tuning_recapture.md`
- `docs/tasks/TASK_938_release_first_exchange_followup_fix_player_polish_final_tuning.md`
- `docs/reports/spielstand_zwischenbericht_task942_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupFixPlayerPolishFinalTuningFollowupRecapture.build_snapshot()` akzeptiert nur ein TASK_943-Manifest mit TASK_942, TASK_941, TASK_940, TASK_939 und TASK_938 als erwarteten Quellen.
- Capture-Script schreibt `tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.json`, `tmp/release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.png` und Desktop-Screenshotpfad.
- Falsche Schemas, falsche Task-IDs, falscher Launch-Arg, fehlender Prozess, untrusted Capture oder fehlender Window-Screenshot blocken.
- Gutes Manifest wird `review_ready`, aber ohne manuelle Checks nicht `accepted`.
- Abgeschlossene Pflichtchecks setzen den Snapshot auf `accepted`.
- Snapshot meldet `read_only`, erzeugt keine Commands, FireEvents, DamageEvents, Movement-Events, Multiplayer-Wahrheit oder Shortcut-Aenderungen.
- Naechster Schritt ist `TASK_944 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Visual Findings`.

## Betroffene Dateien
- `docs/tasks/TASK_943_release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.md`
- `scripts/mission/release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.gd`
- `scripts/tools/capture_release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.ps1`
- `scripts/tests/task_943_release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task942_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_943_release_first_exchange_followup_fix_player_polish_final_tuning_followup_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_942_release_first_exchange_followup_fix_player_polish_final_tuning_followup_fix.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_943 erzeugt den Belegrahmen, akzeptiert aber keinen Screenshot automatisch. Der echte PNG-Befund muss danach als TASK_944 read-only bewertet werden. Erst wenn der Spielerblick akzeptiert ist, ist der First-Exchange-Playability-Smoke sinnvoll.

## Naechster Schritt
TASK_944 - Release First Exchange Followup Fix Player Polish Final Tuning Followup Visual Findings.
