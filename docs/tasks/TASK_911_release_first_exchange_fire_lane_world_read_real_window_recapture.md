# TASK_911 - Release First Exchange Fire Lane World Read Real Window Recapture

## Ziel / Problem
TASK_910 hat den belegten TASK_909-Befund eng im bestehenden Primary3D-Fire-Lane-/Label-Cluster-Pfad poliert: Label/Halo/Marker treten weiter zurueck, Fire-Lane-Core und Source-/Target-Anker tragen die Schussbewegung staerker. Noch fehlt der echte Fensterbeweis, ob diese Aenderung im Release-Fenster wirklich als erste Weltlesung funktioniert.

## Sinnhaftigkeit / Ursache
Headless-Snapshots beweisen nur die Render-Parameter. Die Spielerfrage ist enger: Sieht man im echten Window-Handle-Screenshot zuerst die Fire-Lane von Quelle zu Ziel, oder springt der Blick weiter auf Label/Halo/Marker? TASK_911 schafft dafuer den eigenen Recapture-/Acceptance-Rahmen und trennt `review_ready` weiter von menschlicher Akzeptanz.

## Umfang
- Bestehenden TASK_908-Window-Handle-Capture-Pfad wiederverwenden.
- Eigenes TASK_911-Manifest und eigene Screenshotpfade schreiben.
- TASK_910-Schema und Style als erwartete World-Read-Micro-Quelle festhalten.
- TASK_907-Schema und Style als Label-Cluster-Basis festhalten.
- Pflichtchecks fuer echten Spielerblick definieren:
  - CONTACT FIRE bleibt in #17/#18/#19 sichtbar.
  - Fire-Lane wird vor Label/Halo/Marker-Cluster gelesen.
  - Welt-Fire-Label bleibt leise und klar verschoben.
  - Target-Halo tritt hinter die Lane zurueck.
  - Source-to-target-Lane-Core ist die primaere Weltbewegung.
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
- `docs/tasks/TASK_910_release_first_exchange_fire_lane_world_read_micro_polish.md`
- `docs/tasks/TASK_908_release_first_exchange_fire_lane_label_cluster_real_window_recapture.md`
- `docs/tasks/TASK_907_release_first_exchange_fire_lane_label_cluster_polish.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `scripts/tools/capture_release_first_exchange_fire_lane_world_read_real_window_recapture.ps1` erzeugt ein eigenes TASK_911-Manifest und eigene Screenshotpfade.
- `ReleaseFirstExchangeFireLaneWorldReadRealWindowRecapture.build_snapshot()` blockt fehlende oder falsche TASK_910-/TASK_908-/TASK_907-Metadaten.
- Ein technisch gueltiges Manifest wird `review_ready`, aber nicht ohne manuelle Checks `accepted`.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement- oder Multiplayer-Mutationen.
- Der naechste Schritt wird als TASK_912 Findings-Slice benannt.

## Betroffene Dateien
- `docs/tasks/TASK_911_release_first_exchange_fire_lane_world_read_real_window_recapture.md`
- `scripts/mission/release_first_exchange_fire_lane_world_read_real_window_recapture.gd`
- `scripts/tools/capture_release_first_exchange_fire_lane_world_read_real_window_recapture.ps1`
- `scripts/tests/task_911_release_first_exchange_fire_lane_world_read_real_window_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_911_release_first_exchange_fire_lane_world_read_real_window_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_910_release_first_exchange_fire_lane_world_read_micro_polish.gd`
- `git diff --check`

Optionaler echter Capture:
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_fire_lane_world_read_real_window_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`

## Risiken / offene Punkte
TASK_911 erzeugt den Belegrahmen und optional die PNG-/JSON-Artefakte, akzeptiert den Screenshot aber nicht automatisch. TASK_912 muss den echten Fensterblick read-only schneiden und entscheiden, ob die Fire-Lane wirklich vor Label/Halo/Marker gelesen wird.

## Naechster Schritt
TASK_912 - Release First Exchange Fire Lane World Read Visual Findings.
