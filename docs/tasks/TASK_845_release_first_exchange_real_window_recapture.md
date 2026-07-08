# TASK_845 - Release First Exchange Real Window Recapture

## Ziel / Problem
TASK_844 macht den ersten Release-Fire-Exchange headless reproduzierbar, aber der echte Fensterblick muss erneut als Review-Paket festgehalten werden. Ohne Recapture bleibt unklar, ob der Spieler im exportierten Build den ersten Austausch wirklich als `CONTACT FIRE` und nicht nur als technische Kontaktlage versteht.

## Sinnhaftigkeit / Ursache
Die letzten Release-Reibungen waren oft erst im sichtbaren EXE-Fenster eindeutig: alte Homebase-Texte, Weltlabel-Dichte, Insertionsreste und zu ruhige Kontaktmomente. TASK_845 prueft deshalb den realen Fensterzustand nach dem TASK_844-Tension-Tuning, ohne neue Gameplay-Wahrheit zu erzeugen.

## Umfang
- Neuer PowerShell-Wrapper fuer einen TASK_845-Recapture nach TASK_844.
- Wiederverwendung des bestehenden TASK_837-First-GO-Firefight-Captures.
- Eigenes Manifest unter `tmp/release_first_exchange_real_window_recapture.json`.
- Eigene Screenshotpfade fuer Desktop und Window-Crop.
- Pflichtcheckliste fuer den menschlichen Sichtbefund des ersten Fire-Exchange.
- Headless-Verifier fuer Tool-Grenzen, Doku und optionales Manifest.

## Nicht-Ziele
- Keine automatische Pixel-/Schoenheitsbewertung.
- Kein neues Combat-, Damage-, Contact- oder Movement-Verhalten.
- Kein Markieren des manuellen Sichtreviews als erledigt.
- Keine Shortcut- oder Export-Preset-Aenderung.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_837_release_first_go_firefight_real_window_review.md`
- `docs/tasks/TASK_844_release_first_exchange_tension_tuning.md`

## Akzeptanzkriterien
- Script `scripts/tools/capture_release_first_exchange_real_window.ps1` existiert.
- Script nutzt den bestehenden TASK_837-Capture und den Deep-Link `--release-singleplayer-first-go-firefight`.
- Manifest schreibt Schema `sternenbuergerchen.release_first_exchange_real_window_recapture.v1` und `task_id = TASK_845`.
- Manifest nennt `source_task_id = TASK_844`, `source_capture_task_id = TASK_837`, `expected_exchange_schema = sternenbuergerchen.release_first_exchange_tension_tuning.v1` und `expected_exchange_style_id = task_844_release_first_exchange_tension_tuning_v1`.
- Manifest nennt Screenshotpfade `tmp/release_first_exchange_real_window_desktop.png` und `tmp/release_first_exchange_real_window.png`.
- Pflichtchecks nennen sichtbares `CONTACT FIRE`/Fire-Exchange-Feedback, FireEvent-/Trace-/Impact-Lesbarkeit, Gegner-/Fireteam-Kontext und weiter bedienbare HUD-/Command-Flächen.
- Manifest bleibt read-only: `ui_sets_gameplay_truth=false`, `creates_command=false`, `creates_fire_event=false`, `creates_damage_event=false`, `sets_multiplayer_truth=false`.
- Prozessstart/-stop ist nur ueber explizite Switches sichtbar.
- `manual_review_required=true` und `manual_review_done=false`.

## Betroffene Dateien
- `scripts/tools/capture_release_first_exchange_real_window.ps1`
- `scripts/tests/task_845_release_first_exchange_real_window_recapture.gd`
- `docs/tasks/TASK_845_release_first_exchange_real_window_recapture.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_845_release_first_exchange_real_window_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_844_release_first_exchange_tension_tuning.gd`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_real_window.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 32`
- `git diff --check`

## Risiken / offene Punkte
Der Recapture erzeugt Evidenz und eine Pflichtcheckliste, entscheidet aber nicht automatisch, ob das Bild wirklich gut genug ist. Der menschliche PNG-Befund bleibt Folgearbeit fuer TASK_846 - Release First Exchange Visual Findings.
