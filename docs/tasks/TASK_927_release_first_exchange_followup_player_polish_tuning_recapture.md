# TASK_927 - Release First Exchange Followup Player Polish Tuning Recapture

## Ziel / Problem
TASK_926 hat den TASK_925-Restbefund als enges Player-Polish-Tuning umgesetzt. Noch fehlt der echte Window-Handle-Beleg, ob der Spieler im Release-Fenster jetzt zuerst die Source-to-target-Fire-Lane liest.

## Sinnhaftigkeit / Ursache
Headless-Renderwerte beweisen, dass der TASK_926-Style aktiv ist. Sie beweisen aber nicht, ob der echte Spielerblick im Fenster die Schussrichtung intuitiv vor FIRE/CONTACT-Text, Target-Halo, Grid und Weltlinien liest. TASK_927 schafft deshalb den frischen Recapture-Rahmen nach TASK_926 und trennt `review_ready` weiter von menschlicher Akzeptanz.

## Umfang
- Bestehenden TASK_924-Window-Handle-Capture-Pfad wiederverwenden.
- Eigenes TASK_927-Manifest und eigene Screenshotpfade schreiben.
- TASK_926-Schema und Style als erwartete Tuning-Quelle festhalten.
- TASK_925-Findings und TASK_923-Player-Polish als Herkunft festhalten.
- Pflichtchecks fuer den echten Spielerblick definieren:
  - CONTACT FIRE bleibt in #17/#18/#19 sichtbar.
  - Tuning-Fire-Lane wird als erste Weltbewegung gelesen.
  - Source-/Target-Anker tragen Richtung.
  - Welt-Fire-Label, Target-Halo, Grid und Weltlinien bleiben hinter der Lane.
  - Die Lane wird vor FIRE/CONTACT-Text und Zielcluster gelesen.
  - Command-Surfaces bleiben bedienbar.
- Analyzer/Verifier fuer `review_ready` vs. `accepted`.
- Doku, Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein neuer Visual-Polish.
- Keine neuen FireEvents, DamageEvents, Commands oder Movement-Entscheidungen.
- Keine neue UI-, Contact-, Mission- oder Multiplayer-Wahrheit.
- Keine Shortcut-Aenderung.
- Keine automatische menschliche Akzeptanz aus einem PNG.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_926_release_first_exchange_followup_player_polish_tuning.md`
- `docs/tasks/TASK_925_release_first_exchange_followup_player_polish_visual_findings.md`
- `docs/tasks/TASK_924_release_first_exchange_followup_player_polish_recapture.md`
- `docs/reports/spielstand_zwischenbericht_task926_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `scripts/tools/capture_release_first_exchange_followup_player_polish_tuning_recapture.ps1` erzeugt ein eigenes TASK_927-Manifest und eigene Screenshotpfade.
- `ReleaseFirstExchangeFollowupPlayerPolishTuningRecapture.build_snapshot()` blockt fehlende oder falsche TASK_926-/TASK_925-/TASK_923-/TASK_924-Metadaten.
- Ein technisch gueltiges Manifest wird `review_ready`, aber nicht ohne manuelle Checks `accepted`.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.
- Der naechste Schritt wird als TASK_928 Followup Player Polish Tuning Visual Findings benannt.

## Betroffene Dateien
- `docs/tasks/TASK_927_release_first_exchange_followup_player_polish_tuning_recapture.md`
- `scripts/mission/release_first_exchange_followup_player_polish_tuning_recapture.gd`
- `scripts/tools/capture_release_first_exchange_followup_player_polish_tuning_recapture.ps1`
- `scripts/tests/task_927_release_first_exchange_followup_player_polish_tuning_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task926_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_927_release_first_exchange_followup_player_polish_tuning_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_926_release_first_exchange_followup_player_polish_tuning.gd`
- `git diff --check`

## Optionaler echter Capture
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_followup_player_polish_tuning_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`

## Risiken / offene Punkte
TASK_927 erzeugt den Belegrahmen und optional PNG-/JSON-Artefakte, akzeptiert den Screenshot aber nicht automatisch. TASK_928 muss den echten Fensterblick read-only schneiden und entscheiden, ob danach ein kurzer First-Exchange-Playability-Smoke reicht.

## Naechster Schritt
TASK_928 - Release First Exchange Followup Player Polish Tuning Visual Findings.
