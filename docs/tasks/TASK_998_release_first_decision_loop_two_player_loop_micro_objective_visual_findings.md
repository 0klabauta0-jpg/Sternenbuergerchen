# TASK_998 - Release First Decision Loop Two Player Loop Micro Objective Visual Findings

## Ziel / Problem
TASK_997 macht den Micro-Objective-Outcome im echten Fenster reviewbar, aber daraus entstehen noch keine konkreten Sichtbefunde.

TASK_998 soll trennen: Ist `SICHERN`/`DRUECKEN`/`SAMMELN`-Outcome fuer einen Spieler im Fenster lesbar, oder braucht der Micro-Objective-Blick vorher engen Visual Polish?

## Sinnhaftigkeit / Ursache
Ein technisch gueltiger Capture sagt noch nicht, ob der Spieler nach einem Micro-Objective wirklich versteht, was passiert ist und was als naechstes zu tun ist. TASK_998 macht aus Capture plus manueller Sichtnotiz einen kleinen, nachvollziehbaren Befund.

## Umfang
- Neuer read-only Micro-Objective-Visual-Findings-Service fuer TASK_998.
- Auswertung von TASK_997-Capture-Snapshot plus manuellen Review-Notizen.
- Positive Findings und konkrete Issues fuer:
  - korrektes Fenster
  - sichtbare Micro-Objective-Outcome-Zeile
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
- `docs/tasks/TASK_997_release_first_decision_loop_two_player_loop_micro_objective_real_window_capture.md`
- `docs/tasks/TASK_996_release_first_decision_loop_two_player_loop_micro_objective_outcome_slice.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_998 blockiert ehrlich, wenn TASK_997 nicht review-ready/read-only ist.
- Review-ready Source ohne manuelle Notizen bleibt `needs_manual_review`.
- Manuelle Notizen mit Reibungen routen zu `TASK_999 - Release First Decision Loop Two Player Loop Micro Objective Visual Polish`.
- Saubere manuelle Notizen akzeptieren den Befund fuer `TASK_999 - Release First Decision Loop Two Player Loop Micro Objective Playability Slice`.
- Snapshot erzeugt keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_visual_findings.gd`
- `scripts/tests/task_998_release_first_decision_loop_two_player_loop_micro_objective_visual_findings.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_998_release_first_decision_loop_two_player_loop_micro_objective_visual_findings.gd`
- Regression: TASK_997, TASK_996, TASK_995
- `git diff --check`

## Risiken / offene Punkte
- TASK_998 bewertet nur vorhandene Review-Notizen; echte UI-Verbesserung folgt erst bei Reibung.
- Naechster sinnvoller Schritt: je nach Befund `TASK_999 - Release First Decision Loop Two Player Loop Micro Objective Visual Polish` oder `TASK_999 - Release First Decision Loop Two Player Loop Micro Objective Playability Slice`.
