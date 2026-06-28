# TASK_537 - Pre-Mission F6 Screenshot Visual Audit

## Status: IMPLEMENTIERT

## Ziel / Problem
Der Pre-Mission-Startflow ist funktional und kompakt, aber der echte Sichttest im Godot-Fenster ist noch nicht als pruefbarer Arbeitsstand festgehalten. Damit die UI nicht wieder in schwer lesbare Zustandslisten zurueckfaellt, braucht der Startflow einen kleinen Visual-Audit-Snapshot.

## Sinnhaftigkeit / Ursache
Die Review-Probleme kamen oft aus vermischten UI-/Runtime-Pfaden und schwer lesbaren Zwischenzustaenden. Dieser Task macht die sichtbaren Startflow-Regeln testbar, ohne Gameplay-Wahrheit in die UI zu verschieben.

## Umfang
- `HomebaseTestScreen` expose't einen read-only `get_pre_mission_visual_audit_snapshot()`.
- Der Snapshot prueft Mission-Deck-Ueberlauf, Ueberlappung mit Arbeitsbereichen, Readiness-Chip-Struktur, Statusfarben-Kontrast und Startbutton/Readiness-Konsistenz.
- Readiness-Chip-Snapshots enthalten zusaetzlich die Textfarbe fuer Kontrast-Regressionen.
- Der Rolling-HTML-Bericht nennt TASK_537 als erledigten Zwischenstand und haelt den echten manuellen Screenshot-Sichttest als naechste offene Sichtpruefung fest.

## Nicht-Ziele
- Kein neues Mission-Start-Gate.
- Kein Screenshot-Automationsframework.
- Keine Aenderung an Dropship-, Loadout-, Team- oder Missionsruntime-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_briefing_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_536_startflow_icon_status_color_polish.md`
- `docs/tasks/TASK_535_pre_mission_fullhd_startflow_visual_pass.md`

## Akzeptanzkriterien
- Der Visual-Audit-Snapshot ist read-only und markiert `ui_sets_gameplay_truth = false`.
- Blockierter und startbereiter Startflow liefern reproduzierbare Audit-Checks.
- Kein Mission-Deck-Ueberlauf und keine Ueberlappung mit Roster, Fireteams oder Flightdeck.
- Readiness-Chips haben Icon, Statusfarbe, Textfarbe, Tooltip und ausreichenden Kontrast.
- Startbutton-Text, Disabled-State und Farbe passen zur Readiness.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_537_pre_mission_f6_screenshot_visual_audit.gd`
- `docs/dev/mission_briefing_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_537_pre_mission_f6_screenshot_visual_audit.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_536_startflow_icon_status_color_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_535_pre_mission_fullhd_startflow_visual_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Snapshot ersetzt keinen menschlichen Blick auf einen echten FullHD-F6-Screenshot. Der naechste visuelle Schritt sollte deshalb ein konkreter Screenshot-/Fenster-Sichttest mit gezielten UI-Korrekturen sein.
