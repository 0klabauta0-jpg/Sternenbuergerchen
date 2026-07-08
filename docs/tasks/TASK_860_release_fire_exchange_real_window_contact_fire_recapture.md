# TASK_860 - Release Fire Exchange Real Window Contact-Fire Recapture

## Ziel / Problem
TASK_859 bindet den echten #17/#18-Window-HUD-Pfad an die vorhandene `CONTACT FIRE | ...`-Primaerquelle. TASK_860 beweist diesen Fix nicht nur im Snapshot, sondern bereitet einen frischen echten Release-Fenster-Recapture mit eigenem Manifest, eigenen Screenshotpfaden und read-only Acceptance-Snapshot vor.

## Sinnhaftigkeit / Ursache
Die letzten Slices haben mehrfach gezeigt, dass headless und Snapshot gruen sein koennen, waehrend der Spieler im echten Fenster weiter `NO FIRE NO_LOS` / LOS-Korrektur liest. Darum braucht der Source-Binding-Fix einen echten Fensterbeweis, bevor wir den First-Exchange als erledigt behandeln.

## Umfang
- Ein neues Capture-Script haengt sich an den bestehenden TASK_857-Contact-Fire-Primary-HUD-Recapture.
- Das TASK_860-Manifest erwartet TASK_859-Source-Binding-Schema und Style-ID.
- Ein read-only Analyzer paketiert Manifest, Screenshotpfade, Pflichtchecks und optionale Source-Binding-Snapshots.
- Ein Verifier prueft Doku, Capture-Script, Manifestregeln, Mutationsgrenzen und optionale echte Capture-Dateien.
- Status-, Roadmap-, Contract- und Berichtssync.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein neuer FireEvent-, DamageEvent-, Command-, Movement-, Contact-, UI- oder Multiplayer-State.
- Kein OCR-/Pixel-Autourteil; der echte Fensterblick bleibt manuell zu bewerten.
- Keine Shortcut- oder Export-Preset-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_859_release_fire_exchange_real_window_primary_hud_source_binding_polish.md`
- `docs/tasks/TASK_857_release_fire_exchange_contact_fire_primary_hud_recapture.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- `capture_release_fire_exchange_real_window_contact_fire_recapture.ps1` erzeugt `tmp/release_fire_exchange_real_window_contact_fire_recapture.json`.
- Das Manifest enthaelt `schema = sternenbuergerchen.release_fire_exchange_real_window_contact_fire_recapture.v1`, `task_id = TASK_860`, `source_task_id = TASK_859`, `source_recapture_task_id = TASK_857`, TASK_856-/TASK_853-/TASK_850-/TASK_847-/TASK_844-/TASK_837-Verweise, eigene Screenshotpfade und Pflichtchecks fuer CONTACT FIRE in #17/#18.
- Das Manifest erwartet `task_859_release_fire_exchange_real_window_primary_hud_source_binding_v1`.
- `ReleaseFireExchangeRealWindowContactFireRecapture` meldet einen read-only Acceptance-Snapshot ohne Gameplay-Mutationen.
- Pflichtchecks nennen sichtbares CONTACT FIRE in #17/#18, kein primaeres Debug-`NO FIRE` vor CONTACT FIRE, Event-Log, FireTrace/Impact/Target-Focus und weiter bedienbare Command-Flaechen.

## Betroffene Dateien
- `scripts/tools/capture_release_fire_exchange_real_window_contact_fire_recapture.ps1`
- `scripts/mission/release_fire_exchange_real_window_contact_fire_recapture.gd`
- `scripts/tests/task_860_release_fire_exchange_real_window_contact_fire_recapture.gd`
- `docs/tasks/TASK_860_release_fire_exchange_real_window_contact_fire_recapture.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_860_release_fire_exchange_real_window_contact_fire_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_859_release_fire_exchange_real_window_primary_hud_source_binding_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_857_release_fire_exchange_contact_fire_primary_hud_recapture.gd`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_fire_exchange_real_window_contact_fire_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 38`
- `git diff --check`

## Risiken / offene Punkte
TASK_860 ist weiterhin ein Capture-/Acceptance-Slice. Der lokale echte Capture lief mit `gate = review_ready` und schrieb Window-/Desktop-Screenshots, aber der sichtbare Zustand liest weiter eher als `NEXT LOS/RANGE KORRIGIEREN`, `Kampf NO FIRE NO_LOS` und `CONTACT PRESSURE` statt als klare CONTACT-FIRE-Erstlesung. Folgearbeit sollte deshalb TASK_861 als enger Findings-/Polish-Schnitt sein, kein grosser Combat- oder HUD-Umbau.
