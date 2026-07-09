# TASK_970 - Release First Decision Loop Two Visual Findings

## Ziel / Problem
TASK_969 liefert den Real-Window-Capture-Rahmen fuer den zweiten Decision-Griff. TASK_970 schneidet daraus einen konkreten Spielerbefund: Ist `2ND` sichtbar und lesbar, bleibt `GO` wirklich getrennt, und ist das Feedback nach der zweiten Bestaetigung verstaendlich?

## Sinnhaftigkeit / Ursache
Der Review-Pfad soll das Spiel angenehmer und spielbarer machen, nicht nur Gates sammeln. Nach dem Capture brauchen wir einen kleinen Findings-Schnitt, der Reibung gezielt zu Visual Polish routet oder einen sauberen Zustand zum naechsten Playability-Smoke freigibt.

## Umfang
- Read-only Findings-Analyzer fuer TASK_969-Capture-Snapshots.
- Manuelle Sichtnotizen fuer `2ND`, Confirm, `GO`-Trennung, Post-Confirm-Feedback, HUD-Read-only-Grenze und Spielerlesbarkeit.
- Routing zu `TASK_971 - Release First Decision Loop Two Visual Polish` bei Reibung.
- Routing zu `TASK_971 - Release First Decision Loop Two Playability Smoke` bei sauberem Befund.

## Nicht-Ziele
- Keine Aenderung am Runtime-Button.
- Keine UI-Polish-Implementierung.
- Keine Command-, Movement-, Combat-, Damage- oder Multiplayer-Mutation.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_969_release_first_decision_loop_two_real_window_capture.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/mission/release_first_decision_loop_two_visual_findings.gd`

## Akzeptanzkriterien
- Fehlende oder nicht reviewbare TASK_969-Source blockiert.
- Reviewbare TASK_969-Source ohne manuelle Notizen bleibt `needs_manual_review`.
- Manuelle Reibungen routen zu `TASK_971 - Release First Decision Loop Two Visual Polish`.
- Sauberer manueller Befund routet zu `TASK_971 - Release First Decision Loop Two Playability Smoke`.
- Der Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_visual_findings.gd`
- `scripts/tests/task_970_release_first_decision_loop_two_visual_findings.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_970_release_first_decision_loop_two_visual_findings.gd`
- Regressionen: TASK_969, TASK_968, TASK_967
- `git diff --check`

## Risiken / offene Punkte
- TASK_970 wertet den Befund, poliert aber nicht selbst. Wenn Reibung sichtbar ist, muss TASK_971 gezielt die betroffenen HUD-Flaechen verbessern.
