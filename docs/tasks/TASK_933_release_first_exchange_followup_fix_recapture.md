# TASK_933 - Release First Exchange Followup Fix Recapture

## Ziel / Problem
TASK_932 hat den nicht akzeptierten TASK_931-Spielerblick als engen Presentation-Folgefix umgesetzt. Noch fehlt der echte Window-Handle-Beleg, ob der Follow-up-Fix im Release-Fenster jetzt zuerst als Source-to-target-Fire-Lane gelesen wird und danach ein Playability-Smoke sinnvoll ist.

## Sinnhaftigkeit / Ursache
TASK_932 beweist ueber Headless-/Snapshot-Werte, dass der neue Primary3D-Style aktiv ist. Das beweist aber nicht, ob der echte Spielerblick im Fenster die Fire-Lane vor FIRE/CONTACT-Text, Target-Halo, Raster und Weltlinien liest. TASK_933 erzeugt deshalb den frischen Recapture-Rahmen nach TASK_932 und trennt `review_ready` weiter von menschlicher Akzeptanz.

## Umfang
- Bestehenden TASK_930-Window-Handle-Capture-Pfad wiederverwenden.
- Eigenes TASK_933-Manifest und eigene Screenshotpfade schreiben.
- TASK_932-Schema und Style als erwartete Follow-up-Fix-Quelle festhalten.
- TASK_931-Findings, TASK_930-Recapture und TASK_929-Final-Readability als Herkunft festhalten.
- Pflichtchecks fuer den echten Spielerblick definieren:
  - CONTACT FIRE bleibt in #17/#18/#19 sichtbar.
  - Follow-up-Fix-Fire-Lane wird als erste Weltbewegung gelesen.
  - Source-/Target-Anker tragen Richtung ohne Scheibenwirkung.
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
- `docs/tasks/TASK_932_release_first_exchange_final_readability_followup_fix.md`
- `docs/tasks/TASK_931_release_first_exchange_final_readability_visual_findings.md`
- `docs/tasks/TASK_930_release_first_exchange_final_readability_recapture.md`
- `docs/tasks/TASK_929_release_first_exchange_followup_player_polish_tuning_final_readability_polish.md`
- `docs/reports/spielstand_zwischenbericht_task932_ausblick_2026_07_09.html`

## Akzeptanzkriterien
- `scripts/tools/capture_release_first_exchange_followup_fix_recapture.ps1` erzeugt ein eigenes TASK_933-Manifest und eigene Screenshotpfade.
- `ReleaseFirstExchangeFollowupFixRecapture.build_snapshot()` blockt fehlende oder falsche TASK_932-/TASK_931-/TASK_930-/TASK_929-Metadaten.
- Ein technisch gueltiges Manifest wird `review_ready`, aber nicht ohne manuelle Checks `accepted`.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.
- Der naechste Schritt wird als TASK_934 Followup Fix Visual Findings benannt.

## Betroffene Dateien
- `docs/tasks/TASK_933_release_first_exchange_followup_fix_recapture.md`
- `scripts/mission/release_first_exchange_followup_fix_recapture.gd`
- `scripts/tools/capture_release_first_exchange_followup_fix_recapture.ps1`
- `scripts/tests/task_933_release_first_exchange_followup_fix_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task932_ausblick_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_933_release_first_exchange_followup_fix_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_932_release_first_exchange_final_readability_followup_fix.gd`
- `git diff --check`

## Optionaler echter Capture
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_followup_fix_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`

## Risiken / offene Punkte
TASK_933 erzeugt den Belegrahmen und optional PNG-/JSON-Artefakte, akzeptiert den Screenshot aber nicht automatisch. TASK_934 muss den echten Fensterblick read-only schneiden und entscheiden, ob danach ein kurzer First-Exchange-Playability-Smoke reicht.

## Naechster Schritt
TASK_934 - Release First Exchange Followup Fix Visual Findings.
