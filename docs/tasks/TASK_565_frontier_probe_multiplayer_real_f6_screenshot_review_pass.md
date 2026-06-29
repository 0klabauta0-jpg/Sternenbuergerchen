# TASK_565 - Frontier Probe Multiplayer Real F6 Screenshot Review Pass

## Status: IMPLEMENTIERT

## Ziel / Problem
TASK_562 kann in dieser Umgebung ohne `--headless` einen echten FullHD-F6-Viewport-Readback erzeugen. Der reale Screenshot zeigt eine konkrete Reibung: #17 Selected Fireteam meldet `keine Einheiten aktiv`, obwohl darunter sichtbare Member-Cards fuer dasselbe Fireteam stehen.

## Sinnhaftigkeit / Ursache
Der Status-Text und die Member-Cards nutzen nicht exakt denselben Lesepfad. Die Cards koennen bei einer einzelnen Fireteam-Auswahl ueber `_get_fireteam_units(...)` Mitglieder finden, waehrend `_build_fireteam_status_text()` nur `_get_selected_friendly_units(...)` verwendet und dadurch im Real-F6-Screenshot leer laufen kann.

## Umfang
- Real-F6-Screenshot-Readback als TASK_565-Beleg festhalten.
- #17 Selected-Fireteam-Status auf denselben Fireteam-Unit-Fallback wie die sichtbaren Member-Cards bringen.
- Screenshot-/Manifest-Status im HTML-Bericht auf echten Viewport-Readback aktualisieren.
- Verifier fuer den sichtbaren Widerspruch und den Fix ergaenzen.

## Nicht-Ziele
- Kein generelles HUD-Redesign.
- Keine neue Gameplay-Wahrheit in UI oder Report.
- Keine Aenderung an Fireteam-Auswahl, Dropship-State, Runtime-State oder Multiplayer-Authority.
- Kein erzwungener manueller Hover-Abschluss.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_557_frontier_probe_multiplayer_f6_readability_pass.md`
- `docs/tasks/TASK_562_frontier_probe_multiplayer_f6_visual_evidence_capture.md`
- `docs/tasks/TASK_564_frontier_probe_multiplayer_apply_visual_polish_findings.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- TASK_562 kann ohne `--headless` ein echtes FullHD-PNG mit `viewport_readback_available = true` und `generated_evidence_board = false` erzeugen.
- #17 Selected Fireteam zeigt bei sichtbaren Member-Cards nicht mehr `keine Einheiten aktiv`.
- Der Status-Text nennt Karten/Mitglieder und Lead-/Drop-State aus denselben Unit-Daten wie die Cards.
- Der Fix bleibt read-only und veraendert keinen Gameplay-State.
- Status, Roadmap, Contract, Report und Verifier sind aktualisiert.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_565_frontier_probe_multiplayer_real_f6_screenshot_review_pass.gd`
- `docs/tasks/TASK_565_frontier_probe_multiplayer_real_f6_screenshot_review_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --path . --script scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_565_frontier_probe_multiplayer_real_f6_screenshot_review_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der echte Hover-Teil ist weiterhin ein manueller Check. TASK_565 nutzt den realen Viewport-Readback und behebt den ersten belegten sichtbaren Widerspruch.
- Naechster sinnvoller Schritt ist `TASK_566 - Frontier Probe Multiplayer F6 Hover And Panel Polish Pass`.
