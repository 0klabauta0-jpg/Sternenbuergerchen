# TASK_959 - First Decision Playability Smoke

## Ziel / Problem
TASK_958 trennt den echten First-Decision-Fensterbefund von technischer Capture-Evidence. Es fehlt der kleine Smoke, der nach akzeptiertem Befund prueft, ob die erste Entscheidung im Spielablauf wirklich als spielbarer Griff funktioniert.

## Sinnhaftigkeit / Ursache
Der Spieler soll vor `GO` lesen koennen, was als Naechstes sinnvoll ist, warum, wohin das Fireteam geht und was erst nach `GO` passiert. Ohne Smoke koennten `NEXT`, `WHY`, Preview, Empfehlung und Post-GO-Feedback einzeln sauber wirken, aber im Ablauf trotzdem auseinanderfallen.

## Umfang
- Read-only Analyzer `FirstDecisionPlayabilitySmoke`.
- Akzeptiert nur TASK_958-Findings mit Status `accepted_for_first_decision_playability_smoke`.
- Bewertet einen Playthrough-Trace fuer `NEXT`, `WHY`, Choice-Zeilen, Empfehlung, Ziel-/Pfadpreview, Risk-/Line-of-Fire-Gruende, Preview-vor-GO-Grenze, GO-Bedienbarkeit, Post-GO-Feedback, Hotpath-Ruhe und HUD-Read-only-Grenze.
- Routet bei bestandenem Smoke zu `TASK_960 - First Decision Release Playable Slice`.

## Nicht-Ziele
- Kein neuer Screenshot-Capture.
- Kein automatisches Ersetzen des manuellen TASK_958-Befunds.
- Kein neuer Command-, Movement-, Fire-, Damage- oder Multiplayer-State.
- Kein grosses Missions- oder Combat-Rewrite.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_958_first_decision_real_playthrough_visual_findings.md`
- `docs/tasks/TASK_957_first_decision_real_playthrough_capture.md`

## Akzeptanzkriterien
- Fehlende oder nicht akzeptierte TASK_958-Findings blockieren den Smoke.
- Akzeptierte Findings ohne Trace bleiben `needs_smoke_run`.
- Vollstaendige Trace-Evidence setzt `smoke_passed`.
- Fehlende Pflichtchecks erzeugen konkrete Issues und `smoke_regression_found`.
- Snapshot bleibt `read_only` und erzeugt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/first_decision_playability_smoke.gd`
- `scripts/tests/task_959_first_decision_playability_smoke.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_959_first_decision_playability_smoke.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_958_first_decision_real_playthrough_visual_findings.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_957_first_decision_real_playthrough_capture.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_959 ist ein Gate, kein neuer Content. Wenn der Smoke bestanden ist, sollte TASK_960 den ersten Decision-Griff in einen kleinen release-spielbaren Slice zusammenziehen; bei Regressionsbefund muss TASK_960 eng am belegten Smoke-Fund nachpolieren.
