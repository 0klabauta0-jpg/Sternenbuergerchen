# TASK_575 - Fire Rule Evidence Polish Findings

## Ziel / Problem
TASK_574 hat eine echte Fire-Rule-/ROE-F6-Evidence erzeugt. Der sichtbare Follow-up-Befund: Die vier Controls sind vorhanden und lesbar, aber der aktive Fire-Rule-Zustand kann staerker hervorgehoben werden.

## Sinnhaftigkeit / Ursache
Feuerdisziplin ist nur dann spielbar, wenn der Spieler den aktuellen Zustand im Command-Panel ohne Raten erkennt. Die bisherige aktive Button-Pressung war funktional korrekt, aber als Sichtsignal zu subtil.

## Umfang
- Aktive Fire-Rule-Buttons erhalten einen staerkeren visuellen Affordance-State.
- Snapshot- und Manifestdaten melden diesen Affordance-State maschinell.
- Der laufende HTML-Zwischenbericht dokumentiert TASK_575 als erledigten Evidence-Polish und TASK_576 als naechsten Anschluss.

## Nicht-Ziele
- Keine Aenderung an Fire-Rule-/Combat-/Movement-Wahrheit.
- Kein neues ROE-System.
- Kein Suppression-/Ammo-System.
- Kein grosser HUD-Umbau.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_574_fire_rule_real_f6_screenshot_review_pass.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Genau der aktive ROE-Button bekommt `fire_rule_active_affordance_v1`.
- Inaktive ROE-Buttons bekommen keinen aktiven Affordance-State.
- `get_fire_rule_f6_readability_snapshot()` enthaelt Affordance-Zaehler, Style-ID und Visual-Weight.
- TASK_574-Manifest kann die neue aktive Affordance mit ausgeben.
- UI/Preview bleibt read-only und setzt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_574_fire_rule_real_f6_screenshot_review_pass.gd`
- `scripts/tests/task_575_fire_rule_evidence_polish_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_575_fire_rule_evidence_polish_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_572_fire_rule_f6_readability_smoke.gd`
- `godot_console.exe --path . --script scripts/tests/task_574_fire_rule_real_f6_screenshot_review_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der echte menschliche F6-/Hover-Spielgefuehl-Test bleibt weiterhin offen.
- `suppress` bleibt vorerst ein Fire-Rule-/Diagnosezustand; ein echter Suppress-Area-Preview-Slice ist Folgearbeit.
