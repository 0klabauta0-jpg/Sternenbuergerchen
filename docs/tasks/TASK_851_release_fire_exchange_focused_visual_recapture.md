# TASK_851 - Release Fire Exchange Focused Visual Recapture

## Ziel / Problem
TASK_850 hat den ersten Release-Fire-Exchange visuell fokussiert: FireTrace, Impact und Target-Focus sind staerker, Friendly-Aim-/LOS-Weltlinien leiser. Der echte Spielerblick ist damit aber noch nicht bewiesen.

Ziel dieses Tasks ist ein frischer Release-Export plus echter Fenster-Recapture nach TASK_850, damit der naechste Polish-Schritt aus belegter Evidence kommt.

## Sinnhaftigkeit / Ursache
Headless-Snapshots beweisen Parameter und Architekturgrenzen, nicht automatisch Lesbarkeit. Fuer den Spieler zaehlt, ob der erste Feuerwechsel im echten Fenster ohne Erklaertext erkennbar ist. TASK_851 sammelt deshalb nur Evidence und Review-Gates.

## Umfang
- Eigenes TASK_851-Capture-Script fuer den fokussierten Release-Fire-Exchange.
- Read-only Analyzer fuer das neue Recapture-Manifest.
- Manifest `tmp/release_fire_exchange_focused_visual_recapture.json` mit Screenshotpfaden, erwarteter TASK_850-Style-ID und manuellen Pflichtchecks.
- Verifier fuer Contract, Report, Script, Analyzer und Manifest-Roundtrip.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen Commands, FireEvents, DamageEvents, Navigation oder Multiplayer-Wahrheit.
- Kein automatischer Pixel-/OCR-Schoenheitsentscheid.
- Kein Shortcut-, Export-Preset- oder Spieleordner-Umbau ausser dem expliziten Export-/Capture-Lauf.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_850_release_fire_exchange_focused_visual_polish.md`
- `docs/tasks/TASK_849_release_fire_exchange_visual_polish_findings.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- `ReleaseFireExchangeFocusedVisualRecapture.build_snapshot()` meldet Schema `sternenbuergerchen.release_fire_exchange_focused_visual_recapture.v1` und `task_id = TASK_851`.
- Snapshot verlinkt TASK_850, TASK_847, TASK_845, TASK_844 und TASK_837.
- Manifest erwartet Schema `sternenbuergerchen.release_fire_exchange_focused_visual_polish.v1` und Style-ID `task_850_release_fire_exchange_focused_visual_polish_v1`.
- Pflichtchecks nennen sichtbares `CONTACT FIRE`/Fire-Exchange-Feedback, FireTrace/Impact/Target-Focus, gedimmte Weltlinien, #17/#18/#19-Konsistenz und weiter bedienbare Command-Flächen.
- Snapshot bleibt read-only: keine Gameplay-Wahrheit, keine Commands, keine FireEvents, keine DamageEvents, keine Multiplayer-Wahrheit, keine Shortcut-Updates.

## Betroffene Dateien
- `scripts/tools/capture_release_fire_exchange_focused_visual_recapture.ps1`
- `scripts/mission/release_fire_exchange_focused_visual_recapture.gd`
- `scripts/tests/task_851_release_fire_exchange_focused_visual_recapture.gd`
- `docs/tasks/TASK_851_release_fire_exchange_focused_visual_recapture.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_fire_exchange_focused_visual_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 32`
- `godot_console.exe --headless --path . --script scripts/tests/task_851_release_fire_exchange_focused_visual_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_850_release_fire_exchange_focused_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_851 ersetzt keinen menschlichen Sichtentscheid. Wenn der frische Screenshot den Feuerwechsel weiterhin nicht klar zeigt, folgt ein enger Findings-/Polish-Slice statt weiterer Architekturarbeit.
