# TASK_884 - Release First Exchange HUD Source Sync Recapture

## Ziel / Problem
TASK_883 synchronisiert #17 Selected Fireteam, #18 Mission Control und #19 Event Log mit der belegten CONTACT-FIRE-Quelle. Es fehlt noch der echte Fensterbeweis: Der Spieler muss im Window-Handle-Screenshot sehen, ob CONTACT FIRE, FireTrace, Impact und Target-Fokus nun wirklich zuerst lesbar sind.

## Sinnhaftigkeit / Ursache
TASK_883 ist ein Runtime-/Snapshot-Fix. Ohne frischen Release-Export und echten Window-Handle-Recapture bleibt offen, ob der sichtbare Spielerblick wirklich besser geworden ist oder ob der Screenshot weiter eine andere Lesung zeigt.

## Umfang
- Eigener TASK_884-Capture-Wrapper.
- Wiederverwendung des bestehenden TASK_881/TASK_879-Capture-Pfads.
- Eigene Manifest- und Screenshot-Pfade fuer TASK_884.
- Read-only Analyzer fuer Acceptance-/Manual-Review-Status.
- Verifier fuer Dokumentation, Manifest-Schema, Pflichtchecks und read-only-Grenzen.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein HUD-/VFX-Polish in diesem Task.
- Keine neuen Commands, FireEvents, DamageEvents, Movement-Events oder Multiplayer-Wahrheit.
- Kein automatischer Pixelentscheid; der menschliche Sichtentscheid bleibt als manueller Review markiert.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_883_release_first_exchange_real_window_hud_source_sync_fix.md`
- `docs/tasks/TASK_881_release_first_exchange_fire_visual_recapture.md`
- `docs/tasks/TASK_879_release_first_exchange_exported_status_source_trace.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- Das TASK_884-Manifest nennt TASK_883 als HUD-Source-Sync-Quelle und TASK_881/TASK_879 als Capture-/Trace-Quellen.
- Der Capture laeuft ueber `--release-singleplayer-first-go-firefight`.
- Screenshotpfade sind eigene TASK_884-Pfade.
- Pflichtchecks nennen CONTACT FIRE in #17/#18/#19, FireTrace, Impact, Target-Fokus, kurzes Fire-Statuslabel und weiter bedienbare Command-Flaechen.
- Der Analyzer blockiert fehlende/manipulierte Manifestdaten, bleibt aber read-only.
- Der Analyzer erzeugt keine Commands, FireEvents, DamageEvents, Movement oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_884_release_first_exchange_hud_source_sync_recapture.md`
- `scripts/tools/capture_release_first_exchange_hud_source_sync_recapture.ps1`
- `scripts/mission/release_first_exchange_hud_source_sync_recapture.gd`
- `scripts/tests/task_884_release_first_exchange_hud_source_sync_recapture.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_hud_source_sync_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`
- `godot_console.exe --headless --path . --script scripts/tests/task_884_release_first_exchange_hud_source_sync_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_883_release_first_exchange_real_window_hud_source_sync_fix.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_884 erzeugt nur Beweis und Acceptance-Schale. Wenn der Screenshot weiter nicht ueberzeugt, folgt ein read-only Findings-Schnitt als TASK_885. Wenn er ueberzeugt, kann der Release-First-Exchange-Strang auf die naechste Spielbarkeitsreibung wechseln.

## Lokaler Sichtbefund
- `tmp/release_first_exchange_hud_source_sync_recapture.json`: `gate = review_ready`, `window_capture_method = window_handle_print`, `window_capture_trusted = true`, keine Hard-Failures.
- `tmp/release_first_exchange_hud_source_sync_recapture.png`: echter Fensterblick zeigt weiter `NEXT LOS/RANGE KORRIGIEREN`, `Kampf NO FIRE NO_LOS` und im Event Log `CONTACT PRESSURE`.
- Ergebnis: TASK_884 ist als Beweisrahmen erfolgreich, aber der Spielblick ist noch nicht akzeptiert. Folge: TASK_885 - Release First Exchange HUD Source Sync Visual Findings.
