# TASK_954 - Decision Overlay Real Window Visual Findings

## Ziel / Problem
TASK_953 kann den Decision-Overlay-Real-Window-Recapture als Manifest auswerten. Es fehlt noch der kleine Findings-Schnitt, der aus diesem Capture und optionalen manuellen Notizen entscheidet, ob wir direkt in einen Playability-Smoke gehen koennen oder vorher einen visuellen Follow-up-Polish brauchen.

## Sinnhaftigkeit / Ursache
Ein Screenshot allein bringt das Spiel nicht weiter, wenn der naechste Schritt unklar bleibt. TASK_954 trennt deshalb technische Capture-Evidence von Spielerlesbarkeit: Quelle kaputt blockiert, Quelle gut aber Sichtbefund offen bleibt offen, Sichtbefund mit Reibung erzeugt einen Polish-Folgepunkt, sauberer Sichtbefund fuehrt zum Smoke.

## Umfang
- Read-only Analyzer `DecisionOverlayRealWindowVisualFindings`.
- Bewertung von TASK_953-Source-Schema, TASK_952-Polish-Quelle und Style.
- Optionale manuelle Review-Notizen fuer Sichtbarkeit, Farbruhe, Mission-Control-Lesbarkeit, Command-Bedienbarkeit und Read-only-Grenze.
- Empfehlung fuer `TASK_955 - Decision Overlay Real Window Polish Followup` oder `TASK_955 - Decision Overlay Playability Smoke`.

## Nicht-Ziele
- Kein automatisches Faken einer manuellen Sichtabnahme.
- Kein neues HUD-Panel.
- Kein Command-, Movement-, Fire-, Damage- oder Multiplayer-State.
- Kein neuer Screenshot-Capture.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_953_decision_overlay_real_window_recapture.md`
- `docs/tasks/TASK_952_decision_overlay_f6_visual_polish.md`

## Akzeptanzkriterien
- Fehlende oder falsche TASK_953-Quelle blockiert mit klaren Issues.
- Review-ready TASK_953-Quelle ohne manuelle Notizen bleibt `needs_manual_review`.
- Manuelle Reibungen routen zu `TASK_955 - Decision Overlay Real Window Polish Followup`.
- Sauberer manueller Befund routet zu `TASK_955 - Decision Overlay Playability Smoke`.
- Snapshot bleibt read-only und erzeugt keine Gameplay-, Movement-, Combat- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/decision_overlay_real_window_visual_findings.gd`
- `scripts/tests/task_954_decision_overlay_real_window_visual_findings.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_954_decision_overlay_real_window_visual_findings.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_953_decision_overlay_real_window_recapture.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_952_decision_overlay_f6_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_954 bewertet nur vorhandene Capture-/Review-Daten. Der echte Spieler-Smoke kommt erst als naechster Schritt, sobald entweder ein sauberer Sichtbefund vorliegt oder die benannten visuellen Reibungen in einem Polish-Follow-up erledigt sind.
