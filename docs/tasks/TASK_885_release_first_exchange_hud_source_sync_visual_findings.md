# TASK_885 - Release First Exchange HUD Source Sync Visual Findings

## Ziel / Problem
TASK_884 hat nach TASK_883 einen frischen echten Window-Handle-Capture erzeugt. Der Capture ist technisch `review_ready`, trusted und schreibt eigene Screenshot-/Manifestpfade. Der sichtbare Spielerblick ist aber weiter nicht akzeptiert: #17 und #18 lesen zuerst `NEXT LOS/RANGE KORRIGIEREN` / `Kampf NO FIRE NO_LOS`, #19 zeigt weiter `CONTACT PRESSURE`.

## Sinnhaftigkeit / Ursache
TASK_879 belegt im finalen Export-Trace CONTACT FIRE. TASK_883 bindet die HUD-/Event-Log-Source im Runtime-Snapshot an diesen finalen Stand. TASK_884 zeigt nun die Reibung zwischen sauberem Trace/Manifest und realem Screenshot. Das muss als Findings-Schnitt festgehalten werden, bevor der naechste Fix gezielt am echten Render-/Capture-Frame-Pfad ansetzt.

## Umfang
- TASK_884-Manifest als Quelle auswerten.
- Positive Evidence festhalten: trusted Window-Handle-Capture, korrektes Missionsfenster, TASK_883-HUD-Source-Sync-Quelle, Runtime-Trace-Aktivierung, keine finale Trace-NO_LOS-/CONTACT-PRESSURE-Ueberschreibung.
- Sichtbefund festhalten: #17/#18 weiter NO_LOS-first, #19 weiter CONTACT PRESSURE, CONTACT FIRE nicht als Fenster-Erstlesung.
- Primaere Reibung benennen: `task_883_hud_source_sync_not_real_window_first_reading`.
- Naechste Richtung benennen: echten Render-/Capture-Frame-Pfad tracebar machen, damit Screenshot-Zeitpunkt und finaler HUD-Source-Snapshot zusammenfallen.
- Doku, Roadmap, Status, Contract und HTML-Zwischenbericht synchronisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein weiterer FireTrace-/Impact-Tuningwert in diesem Task.
- Kein neuer HUD-Text-Override.
- Keine neue Movement-, FireEvent-, Damage-, Contact-, UI- oder Multiplayer-Wahrheit.
- Kein neuer Export in diesem Task.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_884_release_first_exchange_hud_source_sync_recapture.md`
- `docs/tasks/TASK_883_release_first_exchange_real_window_hud_source_sync_fix.md`
- `docs/tasks/TASK_879_release_first_exchange_exported_status_source_trace.md`

## Akzeptanzkriterien
- Findings-Snapshot akzeptiert TASK_884 als Quelle.
- Snapshot unterscheidet positive technische Evidence von verbleibender CONTACT-FIRE-Lesbarkeitsreibung.
- Snapshot benennt `task_883_hud_source_sync_not_real_window_first_reading` als primaere Reibung.
- Snapshot benennt #17/#18/#19-spezifische Restprobleme.
- Snapshot empfiehlt TASK_886 fuer Real-Window-HUD-Render-/Capture-Frame-Trace.
- Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_exchange_hud_source_sync_visual_findings.gd`
- `scripts/tests/task_885_release_first_exchange_hud_source_sync_visual_findings.gd`
- `docs/tasks/TASK_885_release_first_exchange_hud_source_sync_visual_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_885_release_first_exchange_hud_source_sync_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_884_release_first_exchange_hud_source_sync_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_885 aendert keine Runtime. Der naechste sinnvolle Fix ist TASK_886 - Release First Exchange Real Window HUD Render Frame Trace: Im echten Fenster muessen Screenshot-Zeitpunkt, gerenderte #17/#18/#19-Texte und finaler CONTACT-FIRE-Source-Snapshot zusammen belegt werden, statt weiter nur den finalen Trace oder nur ein einzelnes PNG getrennt zu betrachten.
