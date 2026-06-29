# TASK_615 - Host Client Real Run Findings

## Ziel / Problem
Der erste echte TASK_614-Lauf schrieb zwar `real_run_done = true`, der Desktop-Capture zeigte aber keine lesbaren Host-/Client-Spiel-Fenster, sondern Godot-Konsolen auf einem fremden Desktop/Browser. Ursache war ein Launchplan mit `godot_console.exe`; fuer sichtbare Zwei-Fenster-Reviews braucht der Real-Run-Pfad ein GUI-Binary und muss die gestarteten Fenster vor dem Capture nach vorne holen.

## Sinnhaftigkeit / Ursache
TASK_614 hat den Review-Lauf reproduzierbar gemacht, aber noch nicht abgesichert, dass der sichtbare Beleg wirklich das Spiel zeigt. Ein Screenshot, der nur Konsolenfenster oder Hintergrund-Apps zeigt, ist fuer Multiplayer-Spielgefuehl, F6-Lesbarkeit und Performance-Beurteilung zu schwach.

## Umfang
- `launch_host_client_two_window_review.ps1` bevorzugt fuer neue Plaene `godot.exe` vor `godot_console.exe`.
- `capture_host_client_two_window_real_run.ps1` ersetzt bei `-Launch` ein geplantes `godot_console.exe` automatisch durch ein benachbartes `godot.exe`, falls vorhanden.
- Der Capture-Helper bringt gestartete Fenster vor dem Screenshot nach vorne und auf die Planposition.
- Das Manifest nennt geplantes Binary, sichtbares Binary, Console-Replacement und Fenster-Fokus-/Positionierungsstatus.
- HTML-Zwischenbericht und Contract dokumentieren den Finding-/Fix-Pfad.
- Ein nachfolgender GUI-Capture darf neue sichtbare UI-Befunde liefern, wird aber als Folgearbeit dokumentiert statt in diesem Tooling-Slice mitgefixt.

## Nicht-Ziele
- Kein Multiplayer-Gameplay-Fix.
- Kein neuer Netcode.
- Kein automatisches Urteil, dass UI/Performance gut sind.
- Kein Schliessen fremder Godot-/Editor-Prozesse.
- Keine Runtime-, Peer-, Command-, Combat-, Objective-, Cargo- oder UI-Wahrheit im Tool, Manifest oder Bericht.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_614_host_client_two_window_real_run_review.md`
- `docs/tasks/TASK_611_host_client_two_window_launch_helper.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- TASK_615-Taskdatei dokumentiert den belegten Befund `godot_console.exe` / Konsolen-Capture.
- Launcher bevorzugt `godot.exe` fuer sichtbare Runs.
- Real-Run-Helper meldet im Manifest `planned_godot_bin`, `visible_godot_bin`, `console_binary_replaced`, `window_focus_attempted` und `window_position_attempted`.
- Dry-Run bleibt fensterlos und read-only.
- Bei geplantem Console-Binary kann der Launchpfad ein GUI-Binary ableiten, ohne den TASK_611-Plan selbst zu mutieren.
- HTML-Bericht exportiert TASK_615-Findings- und Fix-Felder.
- TASK_615-Verifier laeuft gruen.

## Betroffene Dateien
- `docs/tasks/TASK_615_host_client_real_run_findings.md`
- `scripts/tools/launch_host_client_two_window_review.ps1`
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/tests/task_615_host_client_real_run_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- Report-Regressionstests unter `scripts/tests/`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_615_host_client_real_run_findings.gd`
- Regression: `task_614_host_client_two_window_real_run_review.gd`
- Regression: `task_613_host_client_two_window_visual_polish_findings.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- Regression: `task_598_homebase_progression_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Fenster-Fokus ist unter Windows nicht absolut garantiert, wenn andere Apps Fokus erzwingen. Das Manifest meldet deshalb Fokus-/Positionierungsversuche statt ein gutes UI-Urteil zu behaupten.
- Der echte visuelle Host-/Client-Spielbefund bleibt nach diesem Tooling-Fix weiterhin manuell zu bewerten. Im ersten GUI-Capture nach dem Fix waren beide Spiel-Fenster sichtbar, aber die Client-Weltflaeche blieb schwarz; das gehoert in TASK_616.
