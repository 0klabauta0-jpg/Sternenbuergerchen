# TASK_958 - First Decision Real Playthrough Visual Findings

## Ziel / Problem
TASK_957 liefert den reproduzierbaren Capture-/Review-Rahmen fuer den ersten Decision-Playthrough. Es fehlt der read-only Befundschnitt, der aus dem echten Fensterblick und manuellen Notizen entscheidet, ob der erste Griff bereits smoke-ready ist oder ob ein enger UI-Polish folgen muss.

## Sinnhaftigkeit / Ursache
Ein Capture-Manifest allein beweist noch nicht, ob der Spieler `NEXT`, `WHY`, Choice-Zeilen, Preview-Grenze und `GO` angenehm lesen kann. TASK_958 trennt deshalb technische Capture-Evidence von menschlichem Sichtbefund und verhindert, dass offene oder widerspruechliche Screenshots still als akzeptiert gelten.

## Umfang
- Read-only Analyzer `FirstDecisionRealPlaythroughVisualFindings`.
- Validierung einer TASK_957-Source mit TASK_956-Micro-Scenario-Basis.
- Manuelle Review-Notizen fuer Sichtbarkeit, Empfehlung, Preview-vor-GO-Grenze, Command-Bedienbarkeit und HUD-Read-only-Grenze.
- Routing zu `TASK_959 - First Decision Real Playthrough Polish Followup` oder `TASK_959 - First Decision Playability Smoke`.

## Nicht-Ziele
- Kein neuer Screenshot-Capture.
- Kein automatisches Akzeptieren ohne manuelle Sichtnotizen.
- Kein neues HUD-Panel.
- Kein Command-, Movement-, Fire-, Damage- oder Multiplayer-State.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_957_first_decision_real_playthrough_capture.md`
- `docs/tasks/TASK_956_first_decision_micro_scenario_polish.md`

## Akzeptanzkriterien
- Fehlende oder falsche TASK_957-Source blockiert mit klaren Issues.
- Review-ready Source ohne Sichtnotizen bleibt `needs_manual_review`.
- Belegte Sichtreibungen routen zu einem engen TASK_959-Polish-Followup.
- Sauberer manueller Sichtbefund routet zum TASK_959-First-Decision-Playability-Smoke.
- Snapshot bleibt `read_only` und setzt keine UI-/Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/first_decision_real_playthrough_visual_findings.gd`
- `scripts/tests/task_958_first_decision_real_playthrough_visual_findings.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_958_first_decision_real_playthrough_visual_findings.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_957_first_decision_real_playthrough_capture.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_956_first_decision_micro_scenario_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_958 ersetzt weiterhin keinen echten Nutzer-Playtest. Bei sauberem Befund muss TASK_959 den Spielbarkeits-Smoke fuer die erste Entscheidung pruefen; bei Reibung muss TASK_959 ein enger Polish-Followup bleiben.
