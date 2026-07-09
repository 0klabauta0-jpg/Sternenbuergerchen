# TASK_914 - Release First Exchange Fire Lane World Read Acceptance Recapture

## Ziel / Problem
TASK_913 poliert die erste Weltlesung des ersten Feuerwechsels: Fire-Lane-Core und Source-/Target-Anker sind staerker, Label/Halo/Weltlinien treten weiter zurueck. Noch fehlt der echte Window-Handle-Beweis, ob dieser Polish im Release-Fenster wirklich zuerst als Quelle-zu-Ziel-Bewegung gelesen wird.

## Sinnhaftigkeit / Ursache
Headless-Renderwerte koennen beweisen, dass TASK_913 aktiv ist. Sie beweisen aber nicht, ob der Spieler im echten Fenster die Fire-Lane zuerst liest. TASK_914 schafft deshalb einen eigenen Recapture-/Acceptance-Rahmen nach TASK_913 und trennt `review_ready` weiter von menschlicher Akzeptanz.

## Umfang
- Bestehenden TASK_911-Window-Handle-Capture-Pfad wiederverwenden.
- Eigenes TASK_914-Manifest und eigene Screenshotpfade schreiben.
- TASK_913-Schema und Style als erwartete Acceptance-Polish-Quelle festhalten.
- TASK_910-Schema und Style als World-Read-Micro-Basis festhalten.
- Pflichtchecks fuer echten Spielerblick definieren:
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
- Keine neue UI- oder Gameplay-Wahrheit.
- Keine Shortcut-Aenderung.
- Keine automatische menschliche Akzeptanz aus einem PNG.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_913_release_first_exchange_fire_lane_world_read_acceptance_polish.md`
- `docs/tasks/TASK_911_release_first_exchange_fire_lane_world_read_real_window_recapture.md`
- `docs/tasks/TASK_910_release_first_exchange_fire_lane_world_read_micro_polish.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `scripts/tools/capture_release_first_exchange_fire_lane_world_read_acceptance_recapture.ps1` erzeugt ein eigenes TASK_914-Manifest und eigene Screenshotpfade.
- `ReleaseFirstExchangeFireLaneWorldReadAcceptanceRecapture.build_snapshot()` blockt fehlende oder falsche TASK_913-/TASK_911-/TASK_910-Metadaten.
- Ein technisch gueltiges Manifest wird `review_ready`, aber nicht ohne manuelle Checks `accepted`.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement- oder Multiplayer-Mutationen.
- Der naechste Schritt wird als TASK_915 Findings-Slice benannt.

## Betroffene Dateien
- `docs/tasks/TASK_914_release_first_exchange_fire_lane_world_read_acceptance_recapture.md`
- `scripts/mission/release_first_exchange_fire_lane_world_read_acceptance_recapture.gd`
- `scripts/tools/capture_release_first_exchange_fire_lane_world_read_acceptance_recapture.ps1`
- `scripts/tests/task_914_release_first_exchange_fire_lane_world_read_acceptance_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_914_release_first_exchange_fire_lane_world_read_acceptance_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_913_release_first_exchange_fire_lane_world_read_acceptance_polish.gd`
- `git diff --check`

## Optionaler echter Capture
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_fire_lane_world_read_acceptance_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`

## Risiken / offene Punkte
TASK_914 erzeugt den Belegrahmen und optional die PNG-/JSON-Artefakte, akzeptiert den Screenshot aber nicht automatisch. TASK_915 muss den echten Fensterblick read-only schneiden und entscheiden, ob der TASK_913-Polish reicht.

## Naechster Schritt
TASK_915 - Release First Exchange Fire Lane World Read Acceptance Visual Findings.
