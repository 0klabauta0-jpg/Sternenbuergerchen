# TASK_840 - Release Firefight World Label Real Window Recapture

## Ziel / Problem
TASK_839 reduziert die Welttext-Dichte im ersten Release-Firefight headless, aber der echte Fensterblick muss erneut als Review-Paket festgehalten werden. Ohne Recapture bleibt unklar, ob die Karte nach dem Declutter wirklich ruhiger und trotzdem taktisch lesbar ist.

## Sinnhaftigkeit / Ursache
Die letzten Release-Probleme waren im echten EXE-Fenster sichtbar, nicht nur in Contracts. Der Declutter darf nicht einfach nur Labels wegnehmen; er muss im Spielerblick Fire-VFX, Friendly-Fire-Warnungen, kritische Unit-Zustaende, HUD und Command-Matrix zusammen lesbar halten.

## Umfang
- Neuer PowerShell-Wrapper fuer einen TASK_840-Recapture nach TASK_839.
- Wiederverwendung des bestehenden TASK_837-First-GO-Firefight-Captures.
- Eigenes Manifest unter `tmp/release_firefight_world_label_real_window_recapture.json`.
- Eigene Screenshotpfade fuer Desktop und Window-Crop.
- Pflichtcheckliste fuer den menschlichen Sichtbefund nach dem Declutter.
- Headless-Verifier fuer Tool-Grenzen, Doku und optionales Manifest.

## Nicht-Ziele
- Keine automatische Pixel-/Schoenheitsbewertung.
- Kein neues Gameplay-, Combat-, Contact- oder Movement-Verhalten.
- Kein Entfernen von HUD-/Event-Log-Details.
- Kein Markieren des manuellen Sichtreviews als erledigt.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_837_release_first_go_firefight_real_window_review.md`
- `docs/tasks/TASK_839_release_firefight_world_label_declutter.md`

## Akzeptanzkriterien
- Script `scripts/tools/capture_release_firefight_world_label_real_window.ps1` existiert.
- Script nutzt den bestehenden TASK_837-Capture und den Deep-Link `--release-singleplayer-first-go-firefight`.
- Manifest schreibt Schema `sternenbuergerchen.release_firefight_world_label_real_window_recapture.v1` und `task_id = TASK_840`.
- Manifest nennt `source_task_id = TASK_839`, `expected_world_label_density_mode = release_firefight_declutter` und `expected_world_label_declutter_style_id = task_839_release_firefight_world_label_declutter_v1`.
- Manifest nennt Screenshotpfade `tmp/release_firefight_world_label_real_window_desktop.png` und `tmp/release_firefight_world_label_real_window.png`.
- Pflichtchecks nennen weniger Welttext-Dichte, erhaltene Fire-VFX/Trace/Impact, erhaltene Friendly-Fire-Warnung, erhaltene kritische Unit-Zustaende und lesbare HUD-/Event-Log-Details.
- Manifest bleibt read-only: `ui_sets_gameplay_truth=false`, `creates_command=false`, `creates_fire_event=false`, `creates_damage_event=false`, `sets_multiplayer_truth=false`.
- Prozessstart/-stop ist nur ueber explizite Switches sichtbar.
- `manual_review_required=true` und `manual_review_done=false`.

## Betroffene Dateien
- `scripts/tools/capture_release_firefight_world_label_real_window.ps1`
- `scripts/tests/task_840_release_firefight_world_label_real_window_recapture.gd`
- `docs/tasks/TASK_840_release_firefight_world_label_real_window_recapture.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_840_release_firefight_world_label_real_window_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_839_release_firefight_world_label_declutter.gd`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_firefight_world_label_real_window.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 30`
- `git diff --check`

## Risiken / offene Punkte
Der Recapture erzeugt Evidenz und eine Pflichtcheckliste, entscheidet aber nicht automatisch, ob das Bild wirklich schoen genug ist. Der menschliche PNG-Befund bleibt Folgearbeit fuer TASK_841 - Release Firefight World Label Visual Findings.
