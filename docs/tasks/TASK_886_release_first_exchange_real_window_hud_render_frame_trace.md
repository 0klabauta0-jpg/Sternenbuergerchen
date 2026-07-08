# TASK_886 - Release First Exchange Real Window HUD Render Frame Trace

## Ziel / Problem
TASK_885 hat den Widerspruch sauber benannt: Der finale Runtime-Trace liest CONTACT FIRE in #17/#18/#19, der echte TASK_884-Fensterblick liest aber weiter `NEXT LOS/RANGE KORRIGIEREN`, `Kampf NO FIRE NO_LOS` und `CONTACT PRESSURE`.

## Sinnhaftigkeit / Ursache
Weitere CONTACT-FIRE-Textschichten waeren blind. Erst muss belegt werden, ob der Screenshot einen frueheren Render-Frame, eine spaete HUD-Quelle oder eine andere Surface-Bindung zeigt als der finale CONTACT-FIRE-Source-Snapshot.

## Umfang
- TASK_884-Recapture wiederverwenden.
- Finalen TASK_879-Runtime-Trace mit dem echten Screenshot-Befund zusammen in ein TASK_886-Manifest schreiben.
- Gerenderte #17/#18/#19-Erstlesung und finalen Source-Snapshot nebeneinander auswerten.
- Primaere Reibung `render_frame_differs_from_final_trace` benennen.
- Folgefix TASK_887 gezielt auf Render-/Refresh-Frame-Sync vorbereiten.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein neuer HUD-Text-Override.
- Kein weiterer FireTrace-/Impact-Tuningwert in diesem Task.
- Kein automatischer OCR-/Pixelentscheid.
- Keine neue UI-, Command-, Combat-, Damage-, Contact-, Movement- oder Multiplayer-Wahrheit.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_885_release_first_exchange_hud_source_sync_visual_findings.md`
- `docs/tasks/TASK_884_release_first_exchange_hud_source_sync_recapture.md`
- `docs/tasks/TASK_879_release_first_exchange_exported_status_source_trace.md`

## Akzeptanzkriterien
- TASK_886-Manifest nennt TASK_885 als Findings-Quelle, TASK_884 als Recapture-Quelle, TASK_883 als HUD-Sync-Quelle und TASK_879 als Runtime-Trace-Quelle.
- Manifest enthaelt Window-Handle-Capture-Evidence, Screenshotpfade, Capture-/Trace-Zeitdaten und die gerenderte #17/#18/#19-Erstlesung.
- Analyzer unterscheidet finalen Source-Snapshot von gerendertem Screenshot-Frame.
- Analyzer benennt `render_frame_differs_from_final_trace` als primaere Reibung, wenn Screenshot weiter NO_FIRE/CONTACT_PRESSURE liest, der finale Source-Snapshot aber CONTACT FIRE liest.
- Analyzer empfiehlt TASK_887 fuer Real-Window-HUD-Render-Frame-Sync-Fix.
- Analyzer und Capture bleiben read-only.

## Betroffene Dateien
- `docs/tasks/TASK_886_release_first_exchange_real_window_hud_render_frame_trace.md`
- `scripts/tools/capture_release_first_exchange_hud_render_frame_trace.ps1`
- `scripts/mission/release_first_exchange_hud_render_frame_trace.gd`
- `scripts/tests/task_886_release_first_exchange_hud_render_frame_trace.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_hud_render_frame_trace.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`
- `godot_console.exe --headless --path . --script scripts/tests/task_886_release_first_exchange_hud_render_frame_trace.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_885_release_first_exchange_hud_source_sync_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_886 beweist nur die Frame-/Source-Differenz. Der naechste Fix ist TASK_887 - Release First Exchange Real Window HUD Render Frame Sync Fix: Render-/Refresh-Zeitpunkt oder sichtbare Source-Bindung so haerten, dass der echte Fensterframe dieselbe CONTACT-FIRE-Quelle liest wie der finale Runtime-Snapshot.
