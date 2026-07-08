# TASK_857 - Release Fire Exchange Contact-Fire Primary HUD Recapture

## Ziel / Problem
TASK_856 haertet die Primaerlesung in #17 Selected Fireteam und #18 Mission Control auf `CONTACT FIRE | ...`, wenn aktive Release-Fire-Exchange-Evidence vorhanden ist. Jetzt braucht es einen frischen echten Fensterbeweis, damit dieser HUD-Polish nicht nur aus Headless-/Snapshot-Gates abgeleitet wird.

## Sinnhaftigkeit / Ursache
Die vorherigen Recaptures haben mehrfach gezeigt, dass technische FireEvent-Evidence und menschliche Fensterlesbarkeit auseinanderfallen koennen. TASK_857 paketiert deshalb einen neuen Release-Capture nach TASK_856 als read-only Review-Artefakt.

## Umfang
- Eigenes Capture-Manifest `tmp/release_fire_exchange_contact_fire_primary_hud_recapture.json`.
- Eigene Screenshotpfade fuer Desktop und Fenster.
- Read-only Analyzer `ReleaseFireExchangeContactFirePrimaryHudRecapture`.
- Pflichtchecks fuer CONTACT FIRE in #17/#18, keine primaere Debug-`NO FIRE`-Lesung, Event-Log-/FireTrace-/Command-Surface-Lesbarkeit und manuellen Sichtreview.
- Status-, Roadmap-, Contract- und Berichtssync.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands, Navigation oder Multiplayer-Wahrheit.
- Kein Pixel-/OCR-Autourteil.
- Kein Shortcut- oder Export-Preset-Umbau.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_856_release_fire_exchange_contact_fire_primary_hud_polish.md`
- `docs/tasks/TASK_854_release_fire_exchange_focused_recapture_after_readability_polish.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- Das Capture-Tool nutzt weiter `--release-singleplayer-first-go-firefight` und erzeugt ein TASK_857-Manifest mit `read_only_capture = true`.
- Der Analyzer meldet Schema `sternenbuergerchen.release_fire_exchange_contact_fire_primary_hud_recapture.v1` und `task_id = TASK_857`.
- Das Manifest referenziert TASK_856 als HUD-Polish-Quelle und TASK_854/TASK_853/TASK_850/TASK_847/TASK_844/TASK_837 als bestehende Evidence-Kette.
- Pflichtchecks nennen CONTACT FIRE in #17/#18, kein primaeres Debug-`NO FIRE`, Event-Log/FireTrace/Impact/Command-Surfaces und manuellen Sichtreview.
- Snapshot und Tool erzeugen keine UI-, Command-, Combat-, Damage-, Movement-, Multiplayer- oder Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/tools/capture_release_fire_exchange_contact_fire_primary_hud_recapture.ps1`
- `scripts/mission/release_fire_exchange_contact_fire_primary_hud_recapture.gd`
- `scripts/tests/task_857_release_fire_exchange_contact_fire_primary_hud_recapture.gd`
- `docs/tasks/TASK_857_release_fire_exchange_contact_fire_primary_hud_recapture.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_fire_exchange_contact_fire_primary_hud_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 38`
- `godot_console.exe --headless --path . --script scripts/tests/task_857_release_fire_exchange_contact_fire_primary_hud_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_856_release_fire_exchange_contact_fire_primary_hud_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Task beweist das technische Capture-Paket und legt den echten Screenshot ab. Der menschliche Bildentscheid bleibt bewusst offen. Wenn der neue Fensterblick trotz TASK_856 noch nicht klar als CONTACT FIRE liest, folgt ein Findings-/Polish-Slice statt Architekturumbau.
