# TASK_936 - Release First Exchange Followup Fix Player Polish Recapture

## Ziel / Problem
TASK_935 hat den belegten TASK_934-Restbefund als engen Player-Polish umgesetzt. Es fehlt aber noch der echte Fensterbeweis, ob Fire-Lane/Core, Source-/Target-Anker und gedimmter Text-/Halo-/Grid-Layer im Spielerblick wirklich als erste Weltbewegung gelesen werden.

## Sinnhaftigkeit / Ursache
Ein Playability-Smoke waere weiterhin verfrueht, solange der TASK_935-Polish nur ueber Headless-/Render-Snapshots und nicht ueber einen frischen Window-Handle-Screenshot belegt ist. TASK_936 baut deshalb keinen neuen Spielzustand, sondern legt einen read-only Recapture- und Review-Rahmen an den vorhandenen TASK_933-Capture-Pfad.

## Umfang
- TASK_933-Recapture-Pfad wiederverwenden.
- Eigenes TASK_936-Manifest und eigene Screenshotpfade schreiben.
- Erwartete TASK_935-Schema-/Style-ID im Manifest fixieren.
- TASK_934-Findings und TASK_932-Follow-up-Fix als Quellen festhalten.
- Pflichtchecks fuer Player-Polish-Weltlesung, CONTACT-FIRE-HUD und bedienbare Command-Surfaces definieren.
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
- `docs/tasks/TASK_935_release_first_exchange_followup_fix_player_polish.md`
- `docs/tasks/TASK_934_release_first_exchange_followup_fix_visual_findings.md`
- `docs/tasks/TASK_933_release_first_exchange_followup_fix_recapture.md`
- `docs/tasks/TASK_932_release_first_exchange_final_readability_followup_fix.md`
- `docs/reports/spielstand_zwischenbericht_task935_936_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupFixPlayerPolishRecapture.build_snapshot()` akzeptiert nur ein TASK_936-Manifest mit TASK_935, TASK_934, TASK_933 und TASK_932 als erwarteten Quellen.
- Capture-Script schreibt `tmp/release_first_exchange_followup_fix_player_polish_recapture.json`, `tmp/release_first_exchange_followup_fix_player_polish_recapture.png` und Desktop-Screenshotpfad.
- Falsche Schemas, falsche Task-IDs, falscher Launch-Arg, fehlender Prozess, untrusted Capture oder fehlender Window-Screenshot blocken.
- Gutes Manifest wird `review_ready`, aber ohne manuelle Checks nicht `accepted`.
- Abgeschlossene Pflichtchecks setzen den Snapshot auf `accepted`.
- Snapshot meldet `read_only`, erzeugt keine Commands, FireEvents, DamageEvents, Movement-Events, Multiplayer-Wahrheit oder Shortcut-Aenderungen.
- Naechster Schritt ist `TASK_937 - Release First Exchange Followup Fix Player Polish Visual Findings`.

## Betroffene Dateien
- `docs/tasks/TASK_936_release_first_exchange_followup_fix_player_polish_recapture.md`
- `scripts/mission/release_first_exchange_followup_fix_player_polish_recapture.gd`
- `scripts/tools/capture_release_first_exchange_followup_fix_player_polish_recapture.ps1`
- `scripts/tests/task_936_release_first_exchange_followup_fix_player_polish_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task935_936_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_936_release_first_exchange_followup_fix_player_polish_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_935_release_first_exchange_followup_fix_player_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_934_release_first_exchange_followup_fix_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_936 erzeugt den Belegrahmen, akzeptiert aber keinen Screenshot automatisch. Der echte PNG-Befund muss danach als TASK_937 read-only bewertet werden. Erst wenn der Spielerblick akzeptiert ist, ist der Playability-Smoke sinnvoll.

## Naechster Schritt
TASK_937 - Release First Exchange Followup Fix Player Polish Visual Findings.
