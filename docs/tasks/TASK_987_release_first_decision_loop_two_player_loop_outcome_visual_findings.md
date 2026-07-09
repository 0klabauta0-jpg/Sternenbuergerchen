# TASK_987 - Release First Decision Loop Two Player Loop Outcome Visual Findings

## Ziel / Problem
TASK_986 macht das kleine Szenario-Outcome im echten Fenster reviewbar, aber daraus entstehen noch keine konkreten Sichtbefunde.

Wir brauchen einen kleinen, nachvollziehbaren Schnitt: Ist Outcome-Zeile, Mini-Zielzustand und naechster Griff fuer den Spieler lesbar genug, oder braucht der Outcome-Blick vorher engen Visual Polish?

## Sinnhaftigkeit / Ursache
Ein technisch gueltiger Capture sagt noch nicht, ob der Spieler nach einer Entscheidung wirklich versteht, was passiert ist und was als naechstes zu tun ist. TASK_987 trennt technische Capture-Evidence von menschlicher Outcome-Lesbarkeit.

## Umfang
- Neuer read-only Outcome-Visual-Findings-Service fuer TASK_987.
- Auswertung von TASK_986-Capture-Snapshot plus manuellen Review-Notizen.
- Positive Findings und konkrete Issues fuer:
  - korrektes Fenster
  - sichtbare Outcome-Zeile
  - sichtbaren Mini-Zielzustand
  - sichtbare Next-Step-Zeile
  - Ergebnislesbarkeit fuer Spieler
  - HUD-read-only-Grenze
  - Multiplayer-Grenze

## Nicht-Ziele
- Kein neuer Capture.
- Kein automatischer Sichtbefund.
- Kein UI-Polish in diesem Task.
- Kein Playability-Slice mit Ablauftrace.
- Kein neuer Command-, Movement-, Combat- oder Multiplayer-Pfad.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_986_release_first_decision_loop_two_player_loop_outcome_real_window_capture.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_987 blockiert ehrlich, wenn TASK_986 nicht review-ready/read-only ist.
- Review-ready Source ohne manuelle Notizen bleibt `needs_manual_review`.
- Manuelle Notizen mit Reibungen routen zu `TASK_988 - Release First Decision Loop Two Player Loop Outcome Visual Polish`.
- Saubere manuelle Notizen akzeptieren den Befund fuer `TASK_988 - Release First Decision Loop Two Player Loop Outcome Playability Slice`.
- Snapshot erzeugt keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_outcome_visual_findings.gd`
- `scripts/tests/task_987_release_first_decision_loop_two_player_loop_outcome_visual_findings.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_987_release_first_decision_loop_two_player_loop_outcome_visual_findings.gd`
- Regression: TASK_986, TASK_985, TASK_984
- `git diff --check`

## Risiken / offene Punkte
- TASK_987 bewertet nur vorhandene Review-Notizen; echte UI-Verbesserung folgt erst bei Reibung.
- Naechster sinnvoller Schritt: je nach Befund `TASK_988 - Release First Decision Loop Two Player Loop Outcome Visual Polish` oder `TASK_988 - Release First Decision Loop Two Player Loop Outcome Playability Slice`.
