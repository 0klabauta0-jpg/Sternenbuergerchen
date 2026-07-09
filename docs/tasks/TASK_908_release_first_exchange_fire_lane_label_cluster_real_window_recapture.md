# TASK_908 - Release First Exchange Fire Lane Label Cluster Real Window Recapture

## Ziel / Problem
TASK_907 hat den belegten TASK_906-Befund im bestehenden Primary3D-Pfad poliert: FIRE/CONTACT-Weltlabel leiser, Target-Halo ruhiger, Fire-Lane-Core und Source-/Target-Anker tragfaehiger. Noch fehlt der echte Fensterbeweis, ob diese Aenderung im Release-Fenster wirklich als erste Schussbewegung gelesen wird.

## Sinnhaftigkeit / Ursache
Die bisherigen Headless-Snapshots beweisen den Render-Contract, aber nicht den Spielerblick. Dieser Task legt deshalb einen eigenen Recapture-/Acceptance-Rahmen an TASK_907, kopiert eigene PNG-/Manifest-Artefakte und trennt `review_ready` weiter von echter visueller Akzeptanz.

## Umfang
- Bestehenden TASK_905-Window-Handle-Capture-Pfad wiederverwenden.
- Eigenes TASK_908-Manifest und eigene Screenshotpfade schreiben.
- TASK_907-Schema und Style als erwartete Label-Cluster-Quelle festhalten.
- Pflichtchecks fuer echten Spielerblick definieren:
  - CONTACT FIRE bleibt in #17/#18/#19 sichtbar.
  - Fire-Lane wird vor FIRE/CONTACT-/Halo-Cluster gelesen.
  - Label bleibt leise und versetzt.
  - Halo wirkt nicht wie Marker-Scheibe.
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
- `docs/tasks/TASK_907_release_first_exchange_fire_lane_label_cluster_polish.md`
- `docs/tasks/TASK_905_release_first_exchange_fire_lane_real_window_recapture.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Akzeptanzkriterien
- `scripts/tools/capture_release_first_exchange_fire_lane_label_cluster_real_window_recapture.ps1` erzeugt ein eigenes TASK_908-Manifest und eigene Screenshotpfade.
- `ReleaseFirstExchangeFireLaneLabelClusterRealWindowRecapture.build_snapshot()` blockt fehlende oder falsche TASK_907-/TASK_905-Metadaten.
- Ein technisch gueltiges Manifest wird `review_ready`, aber nicht ohne manuelle Checks `accepted`.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement- oder Multiplayer-Mutationen.
- Der naechste Schritt wird als TASK_909 Findings-Slice benannt.

## Betroffene Dateien
- `docs/tasks/TASK_908_release_first_exchange_fire_lane_label_cluster_real_window_recapture.md`
- `scripts/mission/release_first_exchange_fire_lane_label_cluster_real_window_recapture.gd`
- `scripts/tools/capture_release_first_exchange_fire_lane_label_cluster_real_window_recapture.ps1`
- `scripts/tests/task_908_release_first_exchange_fire_lane_label_cluster_real_window_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_908_release_first_exchange_fire_lane_label_cluster_real_window_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_907_release_first_exchange_fire_lane_label_cluster_polish.gd`
- `git diff --check`

Optionaler echter Capture:
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_fire_lane_label_cluster_real_window_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`

## Risiken / offene Punkte
TASK_908 erzeugt den Belegrahmen und optional die PNG-/JSON-Artefakte, akzeptiert den Screenshot aber nicht automatisch. TASK_909 muss den echten Fensterblick read-only schneiden und entscheiden, ob der Label-/Halo-Cluster wirklich hinter die Fire-Lane zuruecktritt.

## Naechster Schritt
TASK_909 - Release First Exchange Fire Lane Label Cluster Visual Findings.
