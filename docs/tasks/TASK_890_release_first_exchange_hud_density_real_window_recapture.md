# TASK_890 - Release First Exchange HUD Density Real Window Recapture

## Ziel / Problem
TASK_889 verbessert die Headless-/Runtime-Lesbarkeit des bestaetigten CONTACT-FIRE-Moments. Es fehlt noch der echte nicht-headless Fensterbeweis, ob #17, #18, #19, FireTrace, Impact und Target-Fokus im Spielerblick wirklich ruhiger und schneller lesbar sind.

## Sinnhaftigkeit / Ursache
Der vorherige Widerspruch zwischen finaler CONTACT-FIRE-Quelle und Screenshot-Frame wurde in TASK_887 geloest. TASK_888 hat danach die visuelle Dichte als neue Reibung benannt, TASK_889 hat sie klein poliert. TASK_890 darf deshalb nicht erneut Gameplay oder HUD-Wahrheit aendern, sondern muss den neuen Stand reproduzierbar capturen und als Review-Paket sichern.

## Umfang
- Frischen Release-/Window-Handle-Capture nach TASK_889 vorbereiten.
- TASK_887-Post-Final-Capture-Pfad wiederverwenden, damit erst nach `deeplink_final` gecaptured wird.
- Eigenes TASK_890-Manifest mit Screenshotpfaden, Quellen, erwarteter TASK_889-Schema-/Style-ID und Pflichtchecks schreiben.
- Analyzer/Verifier pruefen, dass der Capture read-only bleibt und keine Gameplay-Wahrheit erzeugt.
- Contract, Status, Roadmap und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage-, Movement-, Contact-, Command-, UI- oder Multiplayer-Wahrheit.
- Kein Shortcut-/Taskleisten-Update.
- Kein automatisches Bestehen eines visuellen Urteils ohne echten Sichtbefund.
- Kein Editor-/Mapbuilder-Polish.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_889_release_first_exchange_hud_density_and_fire_visual_polish.md`
- `docs/tasks/TASK_887_release_first_exchange_real_window_hud_render_frame_sync_fix.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- `capture_release_first_exchange_hud_density_real_window_recapture.ps1` erzeugt ein eigenes TASK_890-Manifest und eigene Screenshotpfade unter `tmp/`.
- Das Manifest referenziert TASK_889, TASK_887, TASK_879, TASK_883, TASK_880 und TASK_876.
- Der Capture erfolgt nach `deeplink_final` ueber denselben laufenden Release-Prozess per trusted `window_handle_print`.
- Pflichtchecks benennen CONTACT FIRE in #17/#18/#19, #19-Dichte, FireTrace, Impact, Target-Fokus, Bottom-HUD-Ruhe und keine neue HUD-Wahrheit.
- Der Analyzer meldet `review_ready`, wenn Capture und Quellen belastbar sind, aber der manuelle Sichtentscheid noch offen ist.
- Der Analyzer meldet `accepted`, wenn alle Pflichtchecks durch einen Sichtbefund als erledigt markiert sind.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_890_release_first_exchange_hud_density_real_window_recapture.md`
- `scripts/mission/release_first_exchange_hud_density_real_window_recapture.gd`
- `scripts/tests/task_890_release_first_exchange_hud_density_real_window_recapture.gd`
- `scripts/tools/capture_release_first_exchange_hud_density_real_window_recapture.ps1`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_890_release_first_exchange_hud_density_real_window_recapture.gd`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_hud_density_real_window_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`
- `godot_console.exe --headless --path . --script scripts/tests/task_889_release_first_exchange_hud_density_and_fire_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_890 beweist den neuen Fensterstand und paketiert die Pflichtchecks. Wenn der Screenshot weiter zu dicht oder unklar wirkt, folgt ein read-only Findings-Schnitt statt sofort weiterer Runtime-Polish.

## Naechster Schritt
TASK_891 - Release First Exchange HUD Density Visual Findings.
