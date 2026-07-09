# TASK_917 - Release First Exchange Final World Read Recapture

## Ziel / Problem
TASK_916 setzt den finalen engen World-Read-Polish fuer den ersten Feuerwechsel um. Noch fehlt der echte Window-Handle-Beweis, ob der Spieler im Release-Fenster nun zuerst die Fire-Lane als Quelle-zu-Ziel-Bewegung liest.

## Sinnhaftigkeit / Ursache
Headless-Renderwerte beweisen, dass der TASK_916-Style aktiv ist. Sie beweisen aber nicht, ob der echte Spielerblick im Fenster die Schussrichtung intuitiv liest. TASK_917 schafft deshalb einen eigenen Recapture-Rahmen nach TASK_916 und trennt `review_ready` weiter von menschlicher Akzeptanz.

## Umfang
- Bestehenden TASK_914-Window-Handle-Capture-Pfad wiederverwenden.
- Eigenes TASK_917-Manifest und eigene Screenshotpfade schreiben.
- TASK_916-Schema und Style als erwartete Final-Polish-Quelle festhalten.
- TASK_914-Schema als Recapture-Basis festhalten.
- Pflichtchecks fuer den echten Spielerblick definieren:
  - CONTACT FIRE bleibt in #17/#18/#19 sichtbar.
  - Fire-Lane wird als erste Weltbewegung gelesen.
  - Source-/Target-Anker tragen Richtung.
  - Welt-Fire-Label und Target-Halo bleiben hinter der Lane.
  - Raster-/Weltlinien konkurrieren nicht.
  - Command-Surfaces bleiben bedienbar.
- Analyzer/Verifier fuer `review_ready` vs. `accepted`.
- Doku, Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands oder Movement-Entscheidungen.
- Keine neue UI-, Contact-, Mission- oder Multiplayer-Wahrheit.
- Keine Shortcut-Aenderung.
- Keine automatische menschliche Akzeptanz aus einem PNG.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_916_release_first_exchange_fire_lane_world_read_final_polish.md`
- `docs/tasks/TASK_914_release_first_exchange_fire_lane_world_read_acceptance_recapture.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `scripts/tools/capture_release_first_exchange_final_world_read_recapture.ps1` erzeugt ein eigenes TASK_917-Manifest und eigene Screenshotpfade.
- `ReleaseFirstExchangeFinalWorldReadRecapture.build_snapshot()` blockt fehlende oder falsche TASK_916-/TASK_914-Metadaten.
- Ein technisch gueltiges Manifest wird `review_ready`, aber nicht ohne manuelle Checks `accepted`.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.
- Der naechste Schritt wird als TASK_918 Findings-Slice benannt.

## Betroffene Dateien
- `docs/tasks/TASK_917_release_first_exchange_final_world_read_recapture.md`
- `scripts/mission/release_first_exchange_final_world_read_recapture.gd`
- `scripts/tools/capture_release_first_exchange_final_world_read_recapture.ps1`
- `scripts/tests/task_917_release_first_exchange_final_world_read_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_917_release_first_exchange_final_world_read_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_916_release_first_exchange_fire_lane_world_read_final_polish.gd`
- `git diff --check`

## Optionaler echter Capture
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_final_world_read_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`

## Risiken / offene Punkte
TASK_917 erzeugt den Belegrahmen und optional die PNG-/JSON-Artefakte, akzeptiert den Screenshot aber nicht automatisch. TASK_918 muss den echten Fensterblick read-only schneiden und entscheiden, ob danach ein kurzer First-Exchange-Playability-Smoke reicht.

## Naechster Schritt
TASK_918 - Release First Exchange Final World Read Visual Findings.
