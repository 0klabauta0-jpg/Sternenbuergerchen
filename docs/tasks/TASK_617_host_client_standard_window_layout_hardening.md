# TASK_617 - Host Client Standard Window Layout Hardening

## Ziel / Problem
Nach TASK_616 ist der sichtbare Host/Client-Re-Capture gruen, aber der reproduzierbare Standard-Launchpfad ist noch fragil: `launch_host_client_two_window_review.ps1` schreibt standardmaessig zwei `1280x720`-Fenster mit `client_x = 1380`. Auf einem 2560px-Desktop passt das nicht sauber nebeneinander und kann den naechsten Multiplayer-Sichttest wieder unnoetig schief starten.

## Sinnhaftigkeit / Ursache
Der letzte erfolgreiche Re-Capture wurde mit einem vorher manuell kleineren `tmp`-Launchplan erzeugt. Fuer ein angenehm spielbares und reviewbares Multiplayer-Gefuehl muss aber der Standard-Dry-Run/Launchplan selbst gute Fenster erzeugen. Sonst testen wir zufaellige lokale Reste statt den echten Workflow.

## Umfang
- Der Host/Client-Launchhelper berechnet bei Bedarf ein effektives Fensterlayout aus der Primaer-Monitor-Arbeitsflaeche.
- Wenn die angeforderte Standardbreite rechts oder unten aus dem Bildschirm laufen wuerde, werden Fensterbreite/-hoehe und Client-X fuer sichtbare Side-by-Side-Fenster angepasst.
- Der Launchplan meldet `requested_window_layout` und `window_layout_auto_fit`, damit der Unterschied zwischen Wunsch- und effektivem Layout pruefbar bleibt.
- Der Real-Run-Capture-Helper hebt die gefundenen Host-/Client-Fenster vor dem Desktop-Capture explizit an, damit Browser/andere Fenster den Beleg nicht verdecken.
- Kein Gameplay-State wird im Tool, Plan, Report oder Verifier erzeugt.

## Nicht-Ziele
- Kein Netcode- oder Sync-Fix.
- Kein neuer Screenshot-Vergleichsalgorithmus.
- Kein erzwungener Fenstertest in headless Verifiern.
- Kein Ueberschreiben fremder Godot-/Editor-Prozesse.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_616_host_client_visible_ui_real_run_review.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der Standard-Dry-Run schreibt ein Launchplan-Layout, dessen Host- und Client-Fenster in die Primaer-Arbeitsflaeche passen.
- Der Plan enthaelt das angeforderte und das effektiv genutzte Fensterlayout.
- Der Auto-Fit ist als Review-/Tooling-Evidence dokumentiert und bleibt read-only.
- TASK_617-Verifier prueft Script, Planfelder, Contract, Status, Roadmap und Bericht.

## Betroffene Dateien
- `docs/tasks/TASK_617_host_client_standard_window_layout_hardening.md`
- `scripts/tools/launch_host_client_two_window_review.ps1`
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/tests/task_617_host_client_standard_window_layout_hardening.gd`
- `scripts/tests/task_611_host_client_two_window_launch_helper.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_617_host_client_standard_window_layout_hardening.gd`
- Regression: `task_611_host_client_two_window_launch_helper.gd`
- Regression: `task_616_host_client_visible_ui_real_run_review.gd`
- `git diff --check`

## Risiken / offene Punkte
- PowerShell kann die Primaer-Arbeitsflaeche nur abfragen, wenn `System.Windows.Forms` verfuegbar ist. Wenn nicht, bleibt der alte angeforderte Plan bestehen und das Manifest meldet `screen.available = false`.
- Der Auto-Fit macht den sichtbaren Test reproduzierbarer, ersetzt aber keinen menschlichen Host/Client-Spielgefuehltest.
