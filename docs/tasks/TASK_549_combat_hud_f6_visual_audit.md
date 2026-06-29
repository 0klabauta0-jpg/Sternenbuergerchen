# TASK_549 - Combat HUD F6 Visual Audit

## Ziel / Problem
TASK_548 macht die kompakten Combat-HUD-Codes erklaerbar, aber der bisherige Beweis ist ein Headless-Daten-/Tooltip-Smoke. Fuer ein angenehmes, spielbares Missionsbild muss zusaetzlich abgesichert werden, dass die Detailhilfe im 1920x1080-F6-Layout an den richtigen HUD-Stellen haengt, nicht aus dem Bildschirm laeuft und die Panels nicht ueberlaedt.

## Sinnhaftigkeit / Ursache
Das Spiel wird besser, wenn Combat-Feedback nicht nur korrekt ist, sondern im laufenden Fenster schnell lesbar bleibt. Ein automatisierter F6-Visual-Audit kann keinen menschlichen Screenshot ersetzen, aber er kann die wichtigsten Layout- und Tooltip-Vertraege regressionsfest machen.

## Umfang
- #17 Selected Fireteam und #18 Mission Control behalten denselben Combat-Detail-Tooltip.
- Die Tooltip-Labels sind hover-faehig und clippen/kuerzen sichtbaren Headertext statt Layout zu sprengen.
- Ein read-only Audit-Snapshot prueft FullHD-Bounds, Panel-Ueberlappung, Label-Sichtbarkeit, Tooltip-Zeilenbudget und TASK_548-Gate.
- Der laufende HTML-Zwischenbericht wird auf TASK_549 aktualisiert.

## Nicht-Ziele
- Kein neues Popup-System.
- Kein manueller Screenshot wird als erledigt behauptet.
- Keine neue Combat-, Contact-, Damage- oder Movement-Entscheidung.
- Kein visueller Stil-Redesign der gesamten Mission-UI.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_549_combat_hud_f6_visual_audit.md`
- `docs/tasks/TASK_548_combat_hud_visual_detail_tooltip_pass.md`
- `docs/tasks/TASK_537_pre_mission_f6_screenshot_visual_audit.md`

## Akzeptanzkriterien
- `get_combat_hud_f6_visual_audit_snapshot()` ist read-only und setzt keine UI-Gameplay-Wahrheit.
- TASK_548-Tooltip-Gate bleibt gruen.
- Selected-Fireteam- und Mission-Control-Labels sind sichtbar, hover-faehig und innerhalb ihrer Panels.
- Selected-Fireteam- und Mission-Control-Panels liegen im 1920x1080-Viewport und ueberlappen sich nicht.
- Tooltip-Text ist identisch, kurz und hat eine geschaetzte FullHD-Preview-Flache innerhalb des Viewports.
- Der TASK_549-Smoke laeuft gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_549_combat_hud_f6_visual_audit.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_549_combat_hud_f6_visual_audit.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_548_combat_hud_visual_detail_tooltip_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task bleibt ein automatisierter Layout-/Tooltip-Audit. Ein echter menschlicher F6-/Screenshot-Check fuer Stil, Gefuehl und Hover-Verhalten bleibt sinnvoll.
- Godots native Tooltip-Darstellung selbst wird nicht gerendert oder pixelgenau gemessen; geprueft wird die Daten-/Bounds-Grundlage.
