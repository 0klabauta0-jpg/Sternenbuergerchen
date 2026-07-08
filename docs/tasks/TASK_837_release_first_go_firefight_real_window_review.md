# TASK_837 - Release First GO Firefight Real Window Review

## Ziel / Problem
Nach TASK_836 ist der First-GO-Firefight-Pfad headless und strukturell gruen, aber der echte Release-Fensterblick muss als eigenes Review-Paket festgehalten werden. Sonst bleibt unklar, ob HUD, Command Matrix, GO, Fire-Rule und Firefight-Lage im laufenden EXE-Build wirklich lesbar sind.

## Sinnhaftigkeit / Ursache
Die letzten Release-Probleme waren sichtbar im exportierten Build, obwohl viele Headless-Pfade bereits gruen waren. TASK_837 macht den echten First-GO-Firefight-Zustand reproduzierbar capturebar, ohne Gameplay- oder UI-Wahrheit zu erfinden.

## Umfang
- Neuer PowerShell-Wrapper fuer den Release-Capture mit `--release-singleplayer-first-go-firefight`.
- Optionaler Start ueber den vorhandenen checked Release-Launcher.
- Wiederverwendung von `capture_release_singleplayer_visible_window.ps1`.
- Eigenes Manifest unter `tmp/release_first_go_firefight_real_window_review.json`.
- Eigene Screenshotpfade fuer Desktop und Window-Crop.
- Pflichtcheckliste fuer manuelle Bewertung des Firefight-Fensters.
- Headless-Verifier fuer Tool-Grenzen, Doku und optionales Manifest.

## Nicht-Ziele
- Keine automatische Pixelbewertung.
- Kein manueller Review als erledigt markieren.
- Kein Gameplay-State im HUD.
- Kein neues Deep-Link-System.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/export_runtime_package_contract.md`
- `docs/tasks/TASK_832_release_first_go_firefight_deeplink_evidence.md`
- `docs/tasks/TASK_836_release_firefight_command_matrix_visual_polish.md`
- `docs/tasks/TASK_822_release_singleplayer_visible_window_findings.md`

## Akzeptanzkriterien
- Script `scripts/tools/capture_release_first_go_firefight_real_window.ps1` existiert.
- Script nutzt `--release-singleplayer-first-go-firefight`.
- Script nutzt den bestehenden checked Launcher und den bestehenden TASK_822-Capture-Helfer.
- Manifest schreibt Schema `sternenbuergerchen.release_first_go_firefight_real_window_review.v1` und `task_id = TASK_837`.
- Manifest nennt Screenshotpfade `tmp/release_first_go_firefight_real_window_desktop.png` und `tmp/release_first_go_firefight_real_window.png`.
- Manifest bleibt fuer Gameplay read-only: `ui_sets_gameplay_truth=false`, `creates_command=false`, `creates_fire_event=false`, `creates_damage_event=false`, `sets_multiplayer_truth=false`.
- Prozessstart/-stop ist nur ueber explizite Switches sichtbar.
- `manual_review_required=true` und `manual_review_done=false`.

## Betroffene Dateien
- `scripts/tools/capture_release_first_go_firefight_real_window.ps1`
- `scripts/tests/task_837_release_first_go_firefight_real_window_review.gd`
- `docs/tasks/TASK_837_release_first_go_firefight_real_window_review.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_837_release_first_go_firefight_real_window_review.gd`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_go_firefight_real_window.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 30`
- `git diff --check`

## Risiken / offene Punkte
Der Capture erzeugt Evidenz und eine Pflichtcheckliste, bewertet aber nicht automatisch die visuelle Qualitaet. Der echte menschliche Befund aus dem PNG bleibt als Folgearbeit fuer TASK_838 offen. Die Wartezeit ist bewusst auf 30 Sekunden gesetzt, weil fruehere Captures sonst noch den Dropship-/Deboarding-Uebergang statt den stabilen First-GO-Firefight-Zustand erwischen koennen.
