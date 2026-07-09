# TASK_939 - Release First Exchange Followup Fix Player Polish Final Tuning Recapture

## Ziel / Problem
TASK_938 hat den belegten TASK_937-Restbefund als engen Final-Tuning-Slice umgesetzt. Es fehlt noch der echte Fensterbeweis, ob Fire-Lane/Core, leiser Text/Halo/Grid und tragendere Source-/Target-Anker im Spielerblick wirklich als erste Weltbewegung gelesen werden.

## Sinnhaftigkeit / Ursache
Ein First-Exchange-Playability-Smoke ist erst sinnvoll, wenn TASK_938 nicht nur im Headless-/Render-Snapshot, sondern auch im echten Window-Handle-Blick traegt. TASK_939 legt deshalb einen read-only Recapture- und Review-Rahmen an den vorhandenen TASK_936-Pfad, ohne Combat-, Movement- oder HUD-Wahrheit zu veraendern.

## Umfang
- TASK_936-Recapture-Pfad wiederverwenden.
- Eigenes TASK_939-Manifest und eigene Screenshotpfade schreiben.
- Erwartete TASK_938-Schema-/Style-ID im Manifest fixieren.
- TASK_937-Findings und TASK_935-Player-Polish als Quellen festhalten.
- Pflichtchecks fuer Final-Tuning-Weltlesung, CONTACT-FIRE-HUD und bedienbare Command-Surfaces definieren.
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
- `docs/tasks/TASK_938_release_first_exchange_followup_fix_player_polish_final_tuning.md`
- `docs/tasks/TASK_937_release_first_exchange_followup_fix_player_polish_visual_findings.md`
- `docs/tasks/TASK_936_release_first_exchange_followup_fix_player_polish_recapture.md`
- `docs/tasks/TASK_935_release_first_exchange_followup_fix_player_polish.md`
- `docs/reports/spielstand_zwischenbericht_task938_939_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupFixPlayerPolishFinalTuningRecapture.build_snapshot()` akzeptiert nur ein TASK_939-Manifest mit TASK_938, TASK_937, TASK_936 und TASK_935 als erwarteten Quellen.
- Capture-Script schreibt `tmp/release_first_exchange_followup_fix_player_polish_final_tuning_recapture.json`, `tmp/release_first_exchange_followup_fix_player_polish_final_tuning_recapture.png` und Desktop-Screenshotpfad.
- Falsche Schemas, falsche Task-IDs, falscher Launch-Arg, fehlender Prozess, untrusted Capture oder fehlender Window-Screenshot blocken.
- Gutes Manifest wird `review_ready`, aber ohne manuelle Checks nicht `accepted`.
- Abgeschlossene Pflichtchecks setzen den Snapshot auf `accepted`.
- Snapshot meldet `read_only`, erzeugt keine Commands, FireEvents, DamageEvents, Movement-Events, Multiplayer-Wahrheit oder Shortcut-Aenderungen.
- Naechster Schritt ist `TASK_940 - Release First Exchange Followup Fix Player Polish Final Tuning Visual Findings`.

## Betroffene Dateien
- `docs/tasks/TASK_939_release_first_exchange_followup_fix_player_polish_final_tuning_recapture.md`
- `scripts/mission/release_first_exchange_followup_fix_player_polish_final_tuning_recapture.gd`
- `scripts/tools/capture_release_first_exchange_followup_fix_player_polish_final_tuning_recapture.ps1`
- `scripts/tests/task_939_release_first_exchange_followup_fix_player_polish_final_tuning_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task938_939_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_939_release_first_exchange_followup_fix_player_polish_final_tuning_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_938_release_first_exchange_followup_fix_player_polish_final_tuning.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_937_release_first_exchange_followup_fix_player_polish_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_939 erzeugt den Belegrahmen, akzeptiert aber keinen Screenshot automatisch. Der echte PNG-Befund muss danach als TASK_940 read-only bewertet werden. Erst wenn der Spielerblick akzeptiert ist, ist der Playability-Smoke sinnvoll.

## Naechster Schritt
TASK_940 - Release First Exchange Followup Fix Player Polish Final Tuning Visual Findings.
