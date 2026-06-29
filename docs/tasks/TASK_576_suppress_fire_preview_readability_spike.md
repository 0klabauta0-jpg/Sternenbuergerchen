# TASK_576 - Suppress Fire Preview Readability Spike

## Ziel / Problem
`SUP` ist nach TASK_570 bis TASK_575 als Fire-Rule vorhanden, durchgereicht und im HUD bedienbar. Fuer den Spieler ist vor `GO` aber noch nicht lesbar, was `SUP` in der aktuellen Bewegungsentscheidung praktisch bedeutet.

## Sinnhaftigkeit / Ursache
Feuerdisziplin soll ein taktischer Hebel sein, kein versteckter Schalter. Bevor ein groesseres Suppression-/Ammo-System gebaut wird, braucht `SUP` eine kleine Preview-Lesbarkeit: Bereich, Zielpunkt, ETA/Distanz und Druckstatus.

## Umfang
- Read-only Suppress-Fire-Preview fuer den vorhandenen Waypoint-Intent-Preview-Pfad.
- Kompakter `SUP AREA`-Text im bestehenden Selected-Fireteam-Ordertext.
- Snapshot fuer Tests: aktive Fire-Rule, Zielbereich, Radius, Pressure-State, Preview-Text und Read-only-Grenze.
- HTML-Zwischenbericht auf TASK_576/TASK_577 fortschreiben.

## Nicht-Ziele
- Kein Ammo-System.
- Kein echtes Unterdrueckungsfeuer-Resolver-Rewrite.
- Keine Damage-/Combat-Mutation aus der UI.
- Kein neues grosses Command-Panel.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/tactical_command_rules_contract.md`
- `docs/tasks/TASK_575_fire_rule_evidence_polish_findings.md`

## Akzeptanzkriterien
- Bei aktiver Fire-Rule `suppress` und geplantem Move erscheint vor `GO` ein kompakter `SUP AREA`-Preview-Text.
- Der Snapshot meldet `fire_rule = suppress`, `enabled = true`, Zielposition, Radius und Pressure-State.
- Die Preview bleibt read-only und fuehrt kein `GO` aus.
- Ohne `suppress` ist keine falsche Suppress-Preview aktiv.
- Bestehende First-Move-/Threat-Preview bleibt gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_576_suppress_fire_preview_readability_spike.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_576_suppress_fire_preview_readability_spike.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_567_frontier_probe_first_move_threat_preview_readability_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_575_fire_rule_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Dies ist nur eine Preview-Lesbarkeit. Echte Suppression-Wirkung, Ammo-Verbrauch und AAR-Messwerte bleiben Folgearbeit.
- Ein echter F6-Sichttest muss spaeter pruefen, ob `SUP AREA` im HUD nicht zu viel Text erzeugt.
