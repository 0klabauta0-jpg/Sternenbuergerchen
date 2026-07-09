# TASK_921 - Release First Exchange Followup World Read Recapture

## Ziel / Problem
TASK_920 setzt den belegten Follow-up-Fix fuer die Weltlesung um. Noch fehlt der echte Window-Handle-Beweis, ob der Spieler im Release-Fenster nun zuerst die Fire-Lane als Quelle-zu-Ziel-Bewegung liest.

## Sinnhaftigkeit / Ursache
Headless-Renderwerte beweisen, dass der TASK_920-Style aktiv ist. Sie beweisen aber nicht, ob der echte Spielerblick im Fenster die Schussrichtung intuitiv liest. TASK_921 schafft deshalb einen eigenen Recapture-Rahmen nach TASK_920 und trennt `review_ready` weiter von menschlicher Akzeptanz.

## Umfang
- Bestehenden TASK_917-Window-Handle-Capture-Pfad wiederverwenden.
- Eigenes TASK_921-Manifest und eigene Screenshotpfade schreiben.
- TASK_920-Schema und Style als erwartete Follow-up-Quelle festhalten.
- TASK_917-Schema als Recapture-Basis festhalten.
- Pflichtchecks fuer den echten Spielerblick definieren:
  - CONTACT FIRE bleibt in #17/#18/#19 sichtbar.
  - Follow-up-Fire-Lane wird als erste Weltbewegung gelesen.
  - Source-/Target-Anker tragen Richtung.
  - Welt-Fire-Label und Target-Halo bleiben hinter der Lane.
  - Raster-/Weltlinien konkurrieren nicht.
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
- `docs/tasks/TASK_920_release_first_exchange_final_world_read_followup_fix.md`
- `docs/tasks/TASK_917_release_first_exchange_final_world_read_recapture.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `scripts/tools/capture_release_first_exchange_followup_world_read_recapture.ps1` erzeugt ein eigenes TASK_921-Manifest und eigene Screenshotpfade.
- `ReleaseFirstExchangeFollowupWorldReadRecapture.build_snapshot()` blockt fehlende oder falsche TASK_920-/TASK_917-Metadaten.
- Ein technisch gueltiges Manifest wird `review_ready`, aber nicht ohne manuelle Checks `accepted`.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.
- Der naechste Schritt wird als TASK_922 Findings-Slice benannt.

## Betroffene Dateien
- `docs/tasks/TASK_921_release_first_exchange_followup_world_read_recapture.md`
- `scripts/mission/release_first_exchange_followup_world_read_recapture.gd`
- `scripts/tools/capture_release_first_exchange_followup_world_read_recapture.ps1`
- `scripts/tests/task_921_release_first_exchange_followup_world_read_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_921_release_first_exchange_followup_world_read_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_920_release_first_exchange_final_world_read_followup_fix.gd`
- `git diff --check`

## Optionaler echter Capture
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_followup_world_read_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`

## Risiken / offene Punkte
TASK_921 erzeugt den Belegrahmen und optional die PNG-/JSON-Artefakte, akzeptiert den Screenshot aber nicht automatisch. TASK_922 muss den echten Fensterblick read-only schneiden und entscheiden, ob danach ein kurzer First-Exchange-Playability-Smoke reicht.

## Naechster Schritt
TASK_922 - Release First Exchange Followup World Read Visual Findings.
