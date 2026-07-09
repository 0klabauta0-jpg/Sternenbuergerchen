# TASK_974 - Release First Decision Loop Two Recapture Visual Findings

## Ziel / Problem
TASK_973 liefert den Recapture-Rahmen fuer den zweiten Griff. Dieser Task schneidet daraus den eigentlichen Spielerbefund: Ist `2ND -> GO -> Feedback` im echten Fenster gut genug lesbar, oder braucht es noch engen Visual Polish?

## Sinnhaftigkeit / Ursache
Headless-Smoke und Capture-Manifest reichen nicht als Spielerurteil. Der Review muss Reibungen wie fehlende Smoke-Zeile, schwaches Post-GO-Feedback oder unklare `GO`-Trennung in konkrete, bearbeitbare Findings uebersetzen.

## Umfang
- Read-only Findings-Analyzer fuer TASK_974.
- Bewertung einer TASK_973-Recapture-Source plus manueller Sichtnotizen.
- Routing:
  - offene Review bleibt bei TASK_974
  - belegte Reibung geht zu `TASK_975 - Release First Decision Loop Two Recapture Visual Polish`
  - sauberer Sichtbefund geht zu `TASK_975 - Release First Decision Loop Two Acceptance Slice`
- Doku-Verankerung in Status, Roadmap und Decision-/Command-Contracts.

## Nicht-Ziele
- Kein neuer Capture.
- Kein UI-Polish in diesem Task.
- Keine Commands, Movement-, Combat-, Damage- oder Multiplayer-Mutation.
- Keine automatische manuelle Abnahme.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_973_release_first_decision_loop_two_real_window_recapture.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/mission/release_first_decision_loop_two_recapture_visual_findings.gd`

## Akzeptanzkriterien
- Fehlende oder nicht reviewbare TASK_973-Source blockiert.
- Reviewbare Source ohne manuelle Notizen bleibt `needs_manual_review`.
- Belegte Reibungen routen zu TASK_975 Visual Polish.
- Saubere manuelle Review routet zu TASK_975 Acceptance Slice.
- Der Snapshot bleibt read-only und erzeugt keine Gameplay- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_recapture_visual_findings.gd`
- `scripts/tests/task_974_release_first_decision_loop_two_recapture_visual_findings.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_974_release_first_decision_loop_two_recapture_visual_findings.gd`
- Regressionen: TASK_973, TASK_972, TASK_971
- `git diff --check`

## Risiken / offene Punkte
- Der Analyzer bewertet Sichtnotizen, ersetzt aber keinen echten menschlichen Fensterblick. Der naechste Schritt haengt vom Befund ab: enger Polish oder Acceptance Slice.
