# TASK_905 - Release First Exchange Fire Lane Real Window Recapture

## Ziel / Problem
TASK_904 hat die Fire-Lane im Primary3D-Renderpfad gepolished. Jetzt braucht der Stand wieder einen echten Release-/Window-Handle-Beweis, damit nicht nur der Verifier, sondern der Spielerfensterblick zaehlt.

## Sinnhaftigkeit / Ursache
Die bisherigen Slices haben gezeigt, dass headless Snapshots allein nicht ausreichen. Die sichtbare Reibung entsteht im echten Fenster durch HUD-Dichte, Weltlinien, Kamera, Marker und Timing. TASK_905 erzeugt deshalb nach TASK_904 einen frischen Recapture-Rahmen.

## Umfang
- Frischen Release-Fenster-Capture ueber den bestehenden First-GO-Firefight-Pfad erzeugen.
- Bestehende TASK_902-Capture-Kette wiederverwenden statt neue Window-Handle-Logik zu bauen.
- Eigenes TASK_905-Manifest und eigene Screenshot-Pfade schreiben.
- Erwarteten TASK_904-Fire-Lane-Style und TASK_901-Quelle im Manifest festhalten.
- Pflichtchecks fuer echten Sichtbefund festhalten: CONTACT FIRE, Fire-Lane-Core, Source-/Target-Anker, ruhiger Halo, weiter bedienbare HUD-/Command-Surfaces.

## Nicht-Ziele
- Keine automatische visuelle Akzeptanz nur wegen Screenshot-Datei.
- Kein Combat-, Damage-, Movement-, Contact-, UI- oder Multiplayer-Umbau.
- Keine Shortcut-/Taskleisten-Aenderung.
- Keine neue Capture-Architektur.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_904_release_first_exchange_fire_lane_readability_polish.md`
- `docs/tasks/TASK_902_release_first_exchange_combat_marker_scale_real_window_recapture.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Akzeptanzkriterien
- `capture_release_first_exchange_fire_lane_real_window_recapture.ps1` erzeugt ein TASK_905-Manifest unter `tmp/`.
- Das Manifest nennt TASK_904 als Quelle, TASK_902 als Recapture-Basis und den erwarteten Style `task_904_release_first_exchange_fire_lane_readability_v1`.
- Der Capture nutzt Window-Handle-Print und bleibt read-only.
- `ReleaseFirstExchangeFireLaneRealWindowRecapture.build_snapshot()` trennt `review_ready` von echter Akzeptanz.
- Verifier prueft fehlende/gueltige Manifeste, Manual-Check-Gates und read-only-Grenzen.

## Betroffene Dateien
- `docs/tasks/TASK_905_release_first_exchange_fire_lane_real_window_recapture.md`
- `scripts/tools/capture_release_first_exchange_fire_lane_real_window_recapture.ps1`
- `scripts/mission/release_first_exchange_fire_lane_real_window_recapture.gd`
- `scripts/tests/task_905_release_first_exchange_fire_lane_real_window_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_fire_lane_real_window_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`
- `godot_console.exe --headless --path . --script scripts/tests/task_905_release_first_exchange_fire_lane_real_window_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_904_release_first_exchange_fire_lane_readability_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_905 beweist nur, dass der frische Spielerblick vorliegt und review-ready ist. Ob die Fire-Lane wirklich angenehm genug wirkt, muss TASK_906 als read-only Visual Findings schneiden.

## Naechster Schritt
TASK_906 - Release First Exchange Fire Lane Visual Findings.
