# TASK_854 - Release Fire Exchange Focused Recapture After Readability Polish

## Ziel / Problem
TASK_853 haelt die Fire-Exchange-Evidence im Release-HUD laenger sichtbar und synchronisiert #17 Selected Fireteam, #18 Mission Control und #19 Event Log auf `FIRE` / `CONTACT FIRE`. Der echte Fensterblick nach dieser Aenderung ist aber noch nicht frisch belegt.

Ziel dieses Tasks ist ein neuer Release-Export plus echter Fenster-Recapture nach TASK_853, damit wir pruefen koennen, ob der erste Kampfkontakt fuer Spieler ohne Erklaertext als Feuerwechsel lesbar ist.

## Sinnhaftigkeit / Ursache
Headless-Snapshots beweisen nur Contract und Datenfluss. Der vorherige echte Capture war der Grund fuer TASK_853: Der sichtbare Moment las sich noch zu stark als `CONTACT PRESSURE` / `NO FIRE`. Nach dem 45s-Readability-Polish braucht es wieder ein echtes Fensterpaket, bevor weiterer UI- oder Visual-Polish entschieden wird.

## Umfang
- Eigenes TASK_854-Capture-Script fuer den Fire-Exchange nach TASK_853.
- Read-only Analyzer fuer das neue Recapture-Manifest.
- Manifest `tmp/release_fire_exchange_after_readability_recapture.json` mit Screenshotpfaden, TASK_853-Readability-Erwartung, 45s-Persistenz und manuellen Pflichtchecks.
- Verifier fuer Contract, Report, Script, Analyzer und Manifest-Roundtrip.
- Status-/Roadmap-/Contract-/Report-Update.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen Commands, FireEvents, DamageEvents, Navigation oder Multiplayer-Wahrheit.
- Kein automatischer Pixel-/OCR-Schoenheitsentscheid.
- Kein Shortcut- oder Export-Preset-Umbau ausser dem expliziten Export-/Capture-Lauf.
- Kein neuer HUD-Polish in diesem Task; sichtbare Befunde werden danach separat entschieden.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_853_release_fire_exchange_engagement_readability_polish.md`
- `docs/tasks/TASK_851_release_fire_exchange_focused_visual_recapture.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- `ReleaseFireExchangeAfterReadabilityRecapture.build_snapshot()` meldet Schema `sternenbuergerchen.release_fire_exchange_after_readability_recapture.v1` und `task_id = TASK_854`.
- Snapshot verlinkt TASK_853, TASK_851, TASK_850, TASK_847, TASK_844 und TASK_837.
- Manifest erwartet Schema `sternenbuergerchen.release_fire_exchange_engagement_readability_polish.v1`, Style-ID `task_853_release_fire_exchange_engagement_readability_v1` und mindestens 42000ms sichtbare Fire-Exchange-Persistenz.
- Pflichtchecks nennen sichtbares `CONTACT FIRE` in #17/#18/#19, kein primaeres Debug-`NO FIRE`, FireTrace/Impact/Target-Focus, weiter bedienbare Command-Flaechen und manuellen Sichtreview.
- Snapshot bleibt read-only: keine Gameplay-Wahrheit, keine Commands, keine FireEvents, keine DamageEvents, keine Multiplayer-Wahrheit, keine Shortcut-Updates.

## Betroffene Dateien
- `scripts/tools/capture_release_fire_exchange_after_readability_recapture.ps1`
- `scripts/mission/release_fire_exchange_after_readability_recapture.gd`
- `scripts/tests/task_854_release_fire_exchange_focused_recapture_after_readability_polish.gd`
- `docs/tasks/TASK_854_release_fire_exchange_focused_recapture_after_readability_polish.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_fire_exchange_after_readability_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 38`
- `godot_console.exe --headless --path . --script scripts/tests/task_854_release_fire_exchange_focused_recapture_after_readability_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_853_release_fire_exchange_engagement_readability_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_854 ersetzt keinen menschlichen Sichtentscheid. Wenn der neue Screenshot noch nicht klar genug ist, folgt ein enger Findings-/Polish-Slice statt weiterer Architekturarbeit.
