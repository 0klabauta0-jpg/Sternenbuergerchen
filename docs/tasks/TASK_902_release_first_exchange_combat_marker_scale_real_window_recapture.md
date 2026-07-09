# TASK_902 - Release First Exchange Combat Marker Scale Real Window Recapture

## Ziel / Problem
TASK_901 ist headless/runtime-gruen, aber noch nicht im echten Release-Fenster belegt. Wir brauchen einen neuen Window-Handle-Recapture, der prueft, ob kleinerer Target-Halo, ruhigeres Raster und leisere World-Lines im Spielerblick wirklich angenehmer wirken.

## Sinnhaftigkeit / Ursache
TASK_901 reduziert Marker- und World-Noise auf Zahlen- und Render-Snapshot-Ebene. Das beweist den Pfad, aber nicht den eigentlichen Spielerblick. Der naechste Fortschritt ist deshalb wieder ein echter Fensterbeleg, nicht ein weiterer Combat- oder HUD-Polish.

## Umfang
- Eigenen TASK_902-Capture-Wrapper anlegen.
- Den bestehenden TASK_899/TASK_896 Window-Handle-Pfad wiederverwenden.
- Eigenes Manifest und eigene Screenshotpfade unter `tmp/` schreiben.
- Erwartete TASK_901-Schema-/Style-ID festhalten.
- Pflichtchecks fuer kleineren Halo, ruhigeres Grid/World-Noise, lesbare Source-to-target-Lane, CONTACT FIRE und keine neue Gameplay-Wahrheit definieren.
- Analyzer/Verifier fuer `review_ready` vs. `accepted` bereitstellen.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein weiterer Visual-Polish.
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage-, Contact-, Movement-, Command-, UI- oder Multiplayer-Wahrheit.
- Kein automatisches visuelles Akzeptieren ohne Sichtbefund.
- Keine Shortcut-/Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_901_release_first_exchange_combat_marker_scale_world_noise_polish.md`
- `docs/tasks/TASK_900_release_first_exchange_combat_focal_elegance_visual_findings.md`
- `docs/tasks/TASK_899_release_first_exchange_combat_focal_elegance_real_window_recapture.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Akzeptanzkriterien
- `capture_release_first_exchange_combat_marker_scale_real_window_recapture.ps1` erzeugt ein TASK_902-Manifest und eigene Desktop-/Window-Screenshotpfade.
- `ReleaseFirstExchangeCombatMarkerScaleRealWindowRecapture.build_snapshot()` trennt `review_ready` von `accepted`.
- Das Manifest nennt TASK_901 als Quelle und erwartet Style-ID `task_901_release_first_exchange_combat_marker_scale_world_noise_v1`.
- Der Snapshot verlangt trusted `window_handle_print`, Post-Final-Capture nach `deeplink_final`, finalen CONTACT-FIRE-Source-Snapshot und vorhandenen Window-Screenshot.
- Ohne manuelle Checks bleibt der Snapshot `review_ready`, nicht `accepted`.
- Read-only-Grenzen bleiben explizit: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_902_release_first_exchange_combat_marker_scale_real_window_recapture.md`
- `scripts/tools/capture_release_first_exchange_combat_marker_scale_real_window_recapture.ps1`
- `scripts/mission/release_first_exchange_combat_marker_scale_real_window_recapture.gd`
- `scripts/tests/task_902_release_first_exchange_combat_marker_scale_real_window_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_902_release_first_exchange_combat_marker_scale_real_window_recapture.gd`
- Optionaler echter Capture: `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_combat_marker_scale_real_window_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`
- `godot_console.exe --headless --path . --script scripts/tests/task_901_release_first_exchange_combat_marker_scale_world_noise_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_902 erzeugt den Belegrahmen und kann ein neues PNG schreiben. Der menschliche Spielerbefund bleibt bewusst offen, bis das Bild als TASK_903 read-only bewertet wird.

## Naechster Schritt
TASK_903 - Release First Exchange Combat Marker Scale Visual Findings.
