# TASK_955 - Decision Overlay Playability Smoke

## Ziel / Problem
Nach TASK_954 kann der Decision-Overlay-Sichtbefund als sauber fuer einen Playability-Smoke gelten. Es fehlt ein kleiner Smoke-Gate, der nicht mehr nur fragt, ob das Overlay sichtbar ist, sondern ob der erste Entscheidungsgriff spielbar gelesen werden kann.

## Sinnhaftigkeit / Ursache
Das Projekt soll sich wie ein kleines rundes Spiel anfuehlen. Dafuer muss der Spieler vor `GO` verstehen: wohin geht das Fireteam, warum ist der Zug sicher/riskant/suizidal, welche Wahl ist sinnvoll, und was passiert erst nach der Bestaetigung. TASK_955 macht genau diese Fragen pruefbar, ohne Gameplay-Wahrheit im HUD zu erzeugen.

## Umfang
- Read-only Service `DecisionOverlayPlayabilitySmoke`.
- Gate auf akzeptierte TASK_954-Findings.
- Smoke-Trace-Felder fuer Zielpreview, Pfad, Risk-Level, Line-of-Fire-Gruende, beste Wahl, GO-Grenze, Command-Surfaces, Post-GO-Feedback und Hotpath-Ruhe.
- Klare Empfehlung zu `TASK_956 - First Decision Micro Scenario Polish`.

## Nicht-Ziele
- Kein automatisierter echter Maus-/Fenster-Playtest.
- Kein neues Combat-, Movement- oder Command-System.
- Kein neuer HUD-State.
- Kein Multiplayer-Feature in diesem Slice.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_954_decision_overlay_real_window_visual_findings.md`

## Akzeptanzkriterien
- Fehlende oder nicht akzeptierte TASK_954-Findings blockieren den Smoke.
- Akzeptierte Findings ohne Trace bleiben `needs_smoke_run`.
- Vollstaendiger Trace setzt `gate = smoke_passed`.
- Regressionsflags wie gebrochene GO-Grenze oder fehlendes Post-GO-Feedback routen zu `TASK_956 - First Decision Micro Scenario Polish`.
- Snapshot bleibt read-only und erzeugt keine Gameplay-, Movement-, Combat- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/decision_overlay_playability_smoke.gd`
- `scripts/tests/task_955_decision_overlay_playability_smoke.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_955_decision_overlay_playability_smoke.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_954_decision_overlay_real_window_visual_findings.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_953_decision_overlay_real_window_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_955 ist ein Smoke-Gate, kein echter Real-Window-Playtest. Der naechste Schritt sollte den First-Decision-Micro-Scenario-Polish aus Smoke-Evidence konkret machen und danach wieder sichtbar im Spiel pruefen.
