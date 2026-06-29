# TASK_572 - Fire Rule F6 Readability Smoke

## Ziel / Problem
Die neuen `HF`/`RF`/`FW`/`SUP`-Fire-Rule-Controls aus TASK_571 muessen im FullHD-Missionsbild nicht nur funktionieren, sondern lesbar sitzen: sichtbar, kompakt, hover-/help-faehig und ohne Panel-/Weltblick-Kollision.

## Sinnhaftigkeit / Ursache
TASK_571 beweist die Bedienlogik, aber nicht den echten F6-/HUD-Kontext. Gerade kleine Command-Buttons koennen technisch korrekt sein und sich trotzdem schlecht anfuehlen, wenn sie im Grid zu eng, unklar oder an einer falschen Stelle stehen.

## Umfang
- Read-only F6-Audit-Snapshot fuer Fire-Rule-Controls.
- FullHD-Bounds, Command-Panel-Bounds, Button-Groessen und Button-Gruppe pruefen.
- Sichtbarkeit, aktive Fire-Rule, Tooltip-/Help-Metadaten und kurze Labels pruefen.
- Bestehende TASK_571-Bedienlogik und TASK_557/TASK_566-F6-Lesbarkeitsmuster wiederverwenden.
- HTML-Zwischenbericht auf TASK_572 aktualisieren.

## Nicht-Ziele
- Kein neues Fire-Rule-System.
- Kein visueller Komplettumbau der Command-Matrix.
- Kein neuer Combat-, Suppression- oder Ammo-Pfad.
- Kein manueller Screenshot als erledigt behaupten.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_571_fire_rule_controls_readability_polish.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `get_fire_rule_f6_readability_snapshot()` liefert einen read-only Snapshot.
- Alle vier Fire-Rule-Buttons sind im FullHD-Viewport sichtbar und bleiben im Command-Panel.
- Die Button-Gruppe ist kompakt und ueberlappt nicht mit Selected-Fireteam- oder Mission-Control-Panel.
- Labels bleiben kurz; Tooltips und Help-IDs erklaeren die Bedeutung.
- Ein eindeutiger Fire-Rule-Konsens zeigt genau einen aktiven Button.
- TASK_571-Regressionspfad bleibt gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_572_fire_rule_f6_readability_smoke.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `scripts/tests/task_572_fire_rule_f6_readability_smoke.gd`
- `scripts/tests/task_571_fire_rule_controls_readability_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Dieser Smoke misst den FullHD-HUD-Zustand automatisiert, ersetzt aber keinen menschlichen Screenshot-/Spielgefuehl-Test.
- `suppress` bleibt weiter ein Rule-/Diagnosezustand, bis ein eigener Gameplay-Slice Suppression/Ammo konkretisiert.
