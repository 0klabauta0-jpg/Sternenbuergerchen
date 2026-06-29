# TASK_551 - Combat HUD Tooltip Style Polish

## Ziel / Problem
TASK_548 bis TASK_550 machen die Combat-HUD-Detailhilfe korrekt, hoverbar und im HTML-Bericht manuell notierbar. Im Fenster ist aber noch zu wenig sichtbar, dass die kompakten Combat-Zeilen in #17 Selected Fireteam und #18 Mission Control eine Detailhilfe besitzen.

Ziel dieses Tasks ist ein kleiner Stil-Polish: Die vorhandenen Combat-HUD-Labels sollen eine dezente, konsistente Hover-Affordance bekommen, ohne ein neues Tooltip-System oder neue Gameplay-Wahrheit einzufuehren.

## Sinnhaftigkeit / Ursache
Kompakte HUD-Codes sind nur dann angenehm, wenn der Spieler schnell erkennt, wo Details erreichbar sind. Ein leichter Akzent, Outline und stabile Style-Metadaten verbessern die Lesbarkeit, ohne die Panels wieder mit Text zu fuellen.

## Umfang
- Bestehenden Combat-HUD-Tooltip-Label-Contract erweitern.
- Selected-Fireteam- und Mission-Control-Combat-Labels erhalten dieselbe kleine Stil-Signatur.
- F6-Visual-Audit-Snapshot bekommt Style-/Affordance-Daten fuer Regressionen.
- Rolling-HTML-Bericht, Status, Roadmap und Contract werden aktualisiert.

## Nicht-Ziele
- Kein neues Popup-/Tooltip-Rendering.
- Kein Screenshot wird als erledigt behauptet.
- Keine Combat-, Contact-, Damage- oder Movement-Logik.
- Kein Redesign der gesamten Mission-UI.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_551_combat_hud_tooltip_style_polish.md`
- `docs/tasks/TASK_550_combat_hud_manual_screenshot_notes_pass.md`
- `docs/tasks/TASK_549_combat_hud_f6_visual_audit.md`

## Akzeptanzkriterien
- Combat-HUD-Tooltip-Labels bleiben hoverbar und bekommen eine stabile `combat_hud_tooltip_style_id`.
- Beide HUD-Panels nutzen dieselbe Style-Signatur.
- Der Style nutzt die bestehende Tactical-UI-Palette und bleibt kurz/lesbar.
- TASK_549-Gate bleibt gruen.
- TASK_551-Smoke laeuft gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_551_combat_hud_tooltip_style_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_551_combat_hud_tooltip_style_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_549_combat_hud_f6_visual_audit.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task prueft den Stil ueber Theme-/Snapshot-Daten und ersetzt keinen echten menschlichen F6-Sichttest.
- Wenn der native Godot-Tooltip spaeter visuell nicht reicht, braucht es einen separaten Task fuer ein eigenes, gerendertes HUD-Tooltip-Overlay.
