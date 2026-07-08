# TASK_874 - Release First Exchange CONTACT-FIRE Real Window Recapture

## Ziel / Problem
TASK_873 hat den Runtime-/Snapshot-Pfad repariert, aber noch nicht bewiesen, dass der echte Release-Fensterblick nach Export und EXE-Start besser lesbar ist. TASK_874 erzeugt deshalb einen frischen Window-Handle-Recapture nach TASK_873.

## Sinnhaftigkeit / Ursache
Die letzten Findings zeigten mehrfach: Headless- oder Snapshot-Gruen reicht nicht. Der entscheidende Beweis ist der echte Release-Build mit `--release-singleplayer-first-go-firefight`, echter EXE, echtem Fenster-Screenshot und einem Manifest, das Capture-Ziel, Fenstervertrauen und erwartete CONTACT-FIRE-Surfaces festhaelt.

## Umfang
- Einen TASK_874-Capture-Wrapper auf Basis des bestehenden TASK_869-Recapture-Pfads bereitstellen.
- Eigene TASK_874-Screenshot- und Manifestpfade erzeugen.
- TASK_873-Readability-Fix als Quelle und erwarteten Contract festhalten.
- Window-Handle-Capture-/Foreground-Evidence propagieren.
- Read-only Acceptance-Snapshot fuer den manuellen Sichtentscheid erzeugen.
- Status, Roadmap und Contract synchronisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue UI-, Combat-, Damage-, Command-, Movement-, Contact- oder Multiplayer-Wahrheit.
- Kein automatischer Pixel-/OCR-Entscheid als bestanden.
- Kein Shortcut-Update.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_873_release_first_exchange_contact_fire_readability_fix.md`
- `docs/tasks/TASK_869_release_first_exchange_real_window_recapture_after_los_setup.md`
- `docs/reports/spielstand_zwischenbericht_task873_contact_fire_2026_07_08.html`

## Akzeptanzkriterien
- Capture-Wrapper schreibt `tmp/release_first_exchange_contact_fire_real_window_recapture.json`.
- Manifest referenziert TASK_873, TASK_869, TASK_868, TASK_844 und Window-Handle-Capture-Evidence.
- Eigene Desktop-/Window-Screenshotpfade werden geschrieben.
- Snapshot bleibt read-only und mutiert keine Gameplay-Wahrheit.
- Pflichtchecks nennen #17/#18 CONTACT FIRE, #19 Event Log, FireTrace/Impact/Target-Focus und keinen stale `NO_LOS`/`CONTACT PRESSURE`-Only-Zustand.
- Verifier akzeptiert synthetische und reale Manifeste.

## Betroffene Dateien
- `scripts/tools/capture_release_first_exchange_contact_fire_real_window_recapture.ps1`
- `scripts/mission/release_first_exchange_contact_fire_real_window_recapture.gd`
- `scripts/tests/task_874_release_first_exchange_contact_fire_real_window_recapture.gd`
- `docs/tasks/TASK_874_release_first_exchange_contact_fire_real_window_recapture.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_contact_fire_real_window_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 38`
- `godot_console.exe --headless --path . --script scripts/tests/task_874_release_first_exchange_contact_fire_real_window_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_873_release_first_exchange_contact_fire_readability_fix.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_874 ist ein Capture-/Acceptance-Slice. Wenn der Screenshot weiter nicht als CONTACT FIRE lesbar ist, folgt ein enger Findings-Task statt ein weiterer blinder HUD-Override.
