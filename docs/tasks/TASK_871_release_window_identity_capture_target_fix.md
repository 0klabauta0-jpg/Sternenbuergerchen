# TASK_871 - Release Window Identity Capture Target Fix

## Ziel / Problem
TASK_870 hat gezeigt: Der TASK_869-Capture kann technisch `review_ready` und `window_crop_trusted=true` melden, waehrend der sichtbare PNG-Inhalt trotzdem eine fremde World-at-War/TripleA-Karte zeigt. Damit ist der Release-Fensterblick kein belastbarer Sternenbuergerchen-Beweis.

## Sinnhaftigkeit / Ursache
Der bisherige Fenster-Screenshot entsteht primaer als Desktop-Crop anhand der Fensterkoordinaten. Das ist bei mehreren Fenstern, Fokusproblemen, Overlays oder Z-Order-Reibung zu fragil. Der Capture muss zuerst versuchen, direkt vom Ziel-Window-Handle zu lesen, und erst danach auf den Desktop-Crop zurueckfallen.

## Umfang
- Generischen Visible-Window-Capture um einen direkten HWND-Capture erweitern.
- Capture-Methode, HWND-Erfolg und Desktop-Fallback im Manifest festhalten.
- `window_capture_method` und `window_capture_trusted` als belastbarere Evidence einfuehren.
- TASK_871-Verifier fuer Script, Manifest und read-only Grenzen.
- TASK_869/870 bleiben inhaltlich unveraendert, lesen aber die bessere Evidence aus dem gemeinsamen Capture-Pfad.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein HUD-Text-Override.
- Keine neue Command-, FireEvent-, Damage-, Contact-, Movement- oder Multiplayer-Wahrheit.
- Kein Zwang, fremde User-Programme zu beenden.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_870_release_first_exchange_post_los_visual_findings.md`
- `docs/tasks/TASK_869_release_first_exchange_real_window_recapture_after_los_setup.md`

## Akzeptanzkriterien
- `capture_release_singleplayer_visible_window.ps1` versucht zuerst einen direkten Window-Handle-Capture.
- Manifest nennt `window_capture_method`, `window_capture_trusted`, `window_handle_capture`, `desktop_crop_status`.
- Wenn der Handle-Capture gelingt und nicht blank ist, gilt er als trusted und wird als Window-Screenshot verwendet.
- Desktop-Crop bleibt als Fallback erhalten und bleibt nur trusted, wenn Foreground/Prozess passt.
- Verifier bleibt read-only und prueft, dass keine Gameplay-Wahrheit erzeugt wird.

## Betroffene Dateien
- `scripts/tools/capture_release_singleplayer_visible_window.ps1`
- `scripts/tests/task_871_release_window_identity_capture_target_fix.gd`
- `docs/tasks/TASK_871_release_window_identity_capture_target_fix.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_871_release_window_identity_capture_target_fix.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_870_release_first_exchange_post_los_visual_findings.gd`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_los_setup_real_window_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 38`
- `git diff --check`

## Risiken / offene Punkte
Windows-/GPU-Fenster koennen `PrintWindow` oder Handle-Capture je nach Rendering-Pfad blank liefern. Deshalb bleibt der Desktop-Crop als Fallback erhalten, aber die Methode wird explizit im Manifest sichtbar.

Der lokale Recapture nach TASK_871 lief mit `window_capture_method=window_handle_print`, `window_capture_trusted=true` und zeigt wieder das Sternenbuergerchen-Missionsfenster. Der verbleibende Befund ist damit kein Capture-Identitaetsproblem mehr: Im richtigen Fenster liest der First Exchange weiterhin `NEXT LOS/RANGE KORRIGIEREN`, `Kampf NO FIRE NO_LOS` und Event-Log `CONTACT PRESSURE`. TASK_872 sollte diesen korrekten Fensterinhalt als Acceptance sichern und den verbleibenden CONTACT-FIRE-/LOS-Befund read-only schneiden.
