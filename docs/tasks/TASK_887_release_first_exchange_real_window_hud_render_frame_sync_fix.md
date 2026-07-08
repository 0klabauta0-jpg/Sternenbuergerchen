# TASK_887 - Release First Exchange Real Window HUD Render Frame Sync Fix

## Ziel / Problem
TASK_886 hat den Widerspruch zwischen dem echten Screenshot-Frame und dem finalen Runtime-Source-Snapshot belegt: Der kopierte Fensterframe las noch `NO_FIRE`/`NO_LOS`/`CONTACT_PRESSURE`, waehrend der finale Trace bereits `CONTACT FIRE` in #17/#18/#19 meldete.

## Sinnhaftigkeit / Ursache
Der alte Capture-Pfad konservierte einen frueheren Recapture-Frame und wartete erst danach auf den finalen Runtime-Trace. Dadurch wurde ein veralteter Render-Frame neben einen spaeteren Source-Snapshot gelegt. Der Fix muss den sichtbaren Fensterframe an den finalen Trace-Zeitpunkt binden, statt weitere CONTACT-FIRE-Texte in die Runtime zu schichten.

## Umfang
- Release-First-Exchange mit aktivem Runtime-Trace starten.
- Auf `deeplink_final` im Trace warten.
- Danach denselben laufenden Release-Prozess per Window-Handle neu capturen.
- Manifest mit finalem Source-Snapshot, Post-Final-Screenshotpfaden und manueller Readback-Struktur schreiben.
- Analyzer/Verifier pruefen, dass Post-Final-Frame und finaler Source-Snapshot auf CONTACT FIRE ausgerichtet sind.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein neuer HUD-Text-Override.
- Keine neue UI-, Command-, Combat-, Damage-, Contact-, Movement- oder Multiplayer-Wahrheit.
- Kein Screenshot-OCR.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_886_release_first_exchange_real_window_hud_render_frame_trace.md`
- `docs/tasks/TASK_879_release_first_exchange_exported_status_source_trace.md`
- `docs/tasks/TASK_883_release_first_exchange_real_window_hud_source_sync_fix.md`

## Akzeptanzkriterien
- TASK_887-Manifest nennt TASK_886 als Frame-Trace-Quelle und TASK_879 als Runtime-Trace-Quelle.
- Manifest enthaelt `post_final_capture_after_deeplink_final = true`, denselben Release-Prozess, trusted `window_handle_print` und eigene Screenshotpfade.
- Finaler Source-Snapshot meldet CONTACT FIRE in #17/#18/#19 und kein CONTACT PRESSURE.
- Post-Final-Readback meldet CONTACT FIRE fuer #17/#18/#19 und keine NO_FIRE-/CONTACT-PRESSURE-Erstlesung.
- Analyzer meldet `status = pass` und `render_frame_synced_to_final_trace = true`.
- Analyzer und Capture bleiben read-only gegen Gameplay-State.

## Betroffene Dateien
- `docs/tasks/TASK_887_release_first_exchange_real_window_hud_render_frame_sync_fix.md`
- `scripts/tools/capture_release_first_exchange_hud_render_frame_sync_fix.ps1`
- `scripts/mission/release_first_exchange_hud_render_frame_sync_fix.gd`
- `scripts/tests/task_887_release_first_exchange_hud_render_frame_sync_fix.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_hud_render_frame_sync_fix.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`
- `godot_console.exe --headless --path . --script scripts/tests/task_887_release_first_exchange_hud_render_frame_sync_fix.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_886_release_first_exchange_hud_render_frame_trace.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_887 haertet den Capture-/Acceptance-Zeitpunkt und beweist, dass der finale reale Fensterframe CONTACT FIRE lesen kann. Es ersetzt keinen menschlichen Gameplay-Playtest fuer Lesbarkeit, Dichte und Schoenheit des Kampf-HUDs.
