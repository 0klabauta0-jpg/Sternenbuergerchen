# TASK_679 - Mission Interaction Progress Readability

## Ziel / Problem
Nach TASK_678 gibt es echten Runtime-Fortschritt fuer Station-Computer und Cargo-Hold. Der naechste Fallstrick ist Lesbarkeit: Der Spieler muss im Missionsbild schnell erkennen, dass eine Interaction gerade laeuft, wie weit sie ist und welches Fireteam sie haelt.

## Sinnhaftigkeit / Ursache
Runtime-Progress, Use-Feedback und Mission-Control-HUD liefen zwar durch denselben bestehenden Snapshot-Pfad, hatten aber noch keinen expliziten Lesbarkeitsvertrag. Ohne kompakten Readability-Snapshot koennen COM-/CARGO-Zeilen technisch korrekt sein, aber im FullHD-HUD untergehen oder zu lang werden.

## Umfang
- Read-only Snapshot `get_mission_interaction_progress_readability_snapshot()`.
- Kompakte Progress-Zeile fuer `COM`/`CARGO` mit Prozent, Hold-Zeit und Fireteam-Token.
- Export in `get_command_feedback_snapshot()`.
- Einspeisung in die bestehende Mission-Control-ACT-Zeile.
- Headless Manifest unter `tmp/mission_interaction_progress_readability.json`.

## Nicht-Ziele
- Kein echter manueller FullHD-Sichttest.
- Keine neue UI-Gameplay-Wahrheit.
- Kein neuer Interaction-State und kein Door-/Animationssystem.
- Kein Umbau des Mission-Control-HUDs.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_678_mission_interaction_runtime_progress.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Station-Computer zeigt bei 50% Fortschritt eine kurze COM-Zeile mit Prozent, Hold-Zeit und Fireteam-Token.
- Cargo-Hold zeigt bei 50% Fortschritt eine kurze CARGO-Zeile mit Prozent, Hold-Zeit und Fireteam-Token.
- Beide Zeilen bleiben unter dem definierten Zeichenbudget.
- `get_command_feedback_snapshot()` exportiert die Readability-Daten.
- Die Mission-Control-ACT-Zeile enthaelt den aktiven Interaction-Progress.
- Snapshot und Manifest markieren sich als read-only und setzen keine Gameplay-Wahrheit.
- Das Manifest markiert den echten manuellen FullHD-Review weiter als offen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_679_mission_interaction_progress_readability.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_679_mission_interaction_progress_readability.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_678_mission_interaction_runtime_progress.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Verifier ist ein Headless-Lesbarkeitsvertrag, kein echter Augen-Test im laufenden Fenster.
- Der echte FullHD-Sichtlauf und ein Editor-Inspector fuer Interaction-Bindings bleiben sinnvolle Folgearbeit.
