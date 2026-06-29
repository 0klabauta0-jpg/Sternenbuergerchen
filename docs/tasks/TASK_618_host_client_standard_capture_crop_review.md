# TASK_618 - Host Client Standard Capture Crop Review

## Problem
Der TASK_617-Standardlauf zeigt Host und Client nebeneinander mit sichtbarer Mission-Welt, aber das zentrale Beweisbild ist ein kompletter Desktop-Capture. Browser, Taskleiste und andere Fenster erzeugen visuellen Laerm und machen Host-/Client-Vergleiche unnoetig schwer.

## Ursache
`capture_host_client_two_window_real_run.ps1` schrieb bisher nur den Desktop-Screenshot. Die bereits bekannten Host-/Client-Fensterrechtecke wurden nicht genutzt, um saubere Fenster-Ausschnitte fuer Review, Bericht und Folgefindings zu erzeugen.

## Umfang
- Standard-Real-Run-Capture erzeugt zusaetzlich Host- und Client-Fenster-PNGs.
- Manifest meldet Host-/Client-Screenshotpfade, Crop-Status und ob die Ausschnitte geschrieben wurden.
- Der laufende HTML-Bericht dokumentiert den Standardlauf-Befund und den naechsten sichtbaren Reibungspunkt.
- Keine Runtime-, Peer-, Command-, Objective-, Cargo-, Combat-, Movement- oder UI-Wahrheit wird mutiert.

## Nicht-Ziele
- Kein Netcode- oder Sync-Fix.
- Kein neuer Multiplayer-Lobby-Flow.
- Kein Gameplay-Commit im Capture-/Reportpfad.
- Der sichtbare Role-/Peer-Badge im Missionsfenster bleibt ein eigener Folge-Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_617_host_client_standard_window_layout_hardening.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `capture_host_client_two_window_real_run.ps1` enthaelt einen Crop-Pfad fuer Host und Client.
- Manifest enthaelt `host_screenshot_path`, `client_screenshot_path`, `host_screenshot_written`, `client_screenshot_written`, `host_crop_status`, `client_crop_status`.
- Ein echter Standardlauf kann `tmp/host_client_two_window_host_review.png` und `tmp/host_client_two_window_client_review.png` schreiben.
- Der Bericht nennt den belegten Befund: saubere Crops sind reviewbar; Host und Client sind im Fenster noch nicht ausreichend als Rolle/Peer/Team unterscheidbar.

## Betroffene Dateien
- `docs/tasks/TASK_618_host_client_standard_capture_crop_review.md`
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/tests/task_618_host_client_standard_capture_crop_review.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 10`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_618_host_client_standard_capture_crop_review.gd`
- Regression: `task_617_host_client_standard_window_layout_hardening.gd`
- Regression: `task_614_host_client_two_window_real_run_review.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Crop-PNGs sind lokale `tmp/`-Artefakte und werden nicht versioniert.
- Auf ungewoehnlichen Multi-Monitor-Layouts kann ein Fenster ausserhalb des Primaer-Screens liegen; der Crop-Status muss das melden statt Erfolg zu behaupten.
- Naechster sinnvoller Gameplay-/UI-Schritt: `TASK_619 - Host Client Role Peer Badge HUD`, damit Host/Client-Fenster im Spielbild selbst unterscheidbar sind.
