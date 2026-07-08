# TASK_877 - Release First Exchange Visible Status Recapture

## Ziel / Problem
TASK_876 hat die validierte CONTACT-FIRE-Evidence als read-only sichtbare Statusquelle stabilisiert. TASK_877 erzeugt danach einen frischen echten Release-Fenster-Recapture, damit der menschliche Blick pruefen kann, ob #17 Selected Fireteam, #18 Mission Control und #19 Event Log nun wirklich CONTACT FIRE zuerst lesen.

## Sinnhaftigkeit / Ursache
Headless- und Snapshot-Pruefungen koennen beweisen, dass die Statusquelle existiert und vom HUD-Pfad konsumiert wird. Sie beweisen aber nicht, ob das echte exportierte Fenster fuer den Spieler gut lesbar ist. Der bisherige Problemstrang war genau diese Luecke zwischen interner Evidence und sichtbarer Erstlesung.

## Umfang
- Neuer Capture-Wrapper fuer den TASK_876-Stand.
- Eigenes TASK_877-Manifest mit Screenshotpfaden, Window-Handle-Trust und erwarteter TASK_876-Statusquelle.
- Read-only Acceptance-Snapshot fuer den Capture.
- Verifier fuer Task-Datei, Tool, Analyzer, Roadmap, Contract und optionales echtes Manifest.
- Status, Roadmap und Mission-Command-Feedback-Contract synchronisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents oder Commands.
- Keine zweite Gameplay-Wahrheit im HUD.
- Kein automatischer Pixel-/OCR-Sichtentscheid.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_876_release_first_exchange_visible_status_source_reconciliation.md`
- `docs/tasks/TASK_874_release_first_exchange_contact_fire_real_window_recapture.md`

## Akzeptanzkriterien
- Capture-Manifest nennt TASK_877, TASK_876, TASK_874, TASK_873 und den First-GO-Firefight-Launch.
- Manifest verlangt CONTACT FIRE in #17/#18/#19, FireTrace/Impact und keine stale NO_LOS-/CONTACT_PRESSURE-only-Erstlesung.
- Window-Handle-Capture bleibt trusted oder wird als `manual_open` markiert.
- Analyzer bleibt read-only und erzeugt keine Gameplay-Wahrheit.
- Verifier ist gruen.

## Betroffene Dateien
- `scripts/tools/capture_release_first_exchange_visible_status_recapture.ps1`
- `scripts/mission/release_first_exchange_visible_status_recapture.gd`
- `scripts/tests/task_877_release_first_exchange_visible_status_recapture.gd`
- `docs/tasks/TASK_877_release_first_exchange_visible_status_recapture.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_visible_status_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 38`
- `godot_console.exe --headless --path . --script scripts/tests/task_877_release_first_exchange_visible_status_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_876_release_first_exchange_visible_status_source_reconciliation.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_877 liefert den frischen echten Fensterbeweis, aber keine automatische menschliche Sichtentscheidung. Wenn der PNG-Blick weiter nicht eindeutig CONTACT FIRE zeigt, folgt TASK_878 als Visual-Findings-Schnitt.
