# TASK_962 - Release First Decision Playtest Findings

## Ziel / Problem
TASK_961 kann den integrierten First-Decision-Playtest als Manifest bewerten, aber der naechste Arbeitsschritt braucht einen klaren Befund: Ist der erste kleine Release-Griff gut genug fuer den naechsten spielbaren Loop, oder muessen konkrete Reibungen gezielt poliert werden?

## Sinnhaftigkeit / Ursache
Ohne Findings entsteht wieder eine Task-Kette, die nur Gates sammelt. TASK_962 schneidet deshalb den Spielerbefund aus der TASK_961-Evidence, ohne Akzeptanz zu faken und ohne Gameplay-Wahrheit im Review-Pfad zu erzeugen.

## Umfang
- Read-only Analyzer `ReleaseFirstDecisionPlaytestFindings`.
- Auswertung einer TASK_961-Quelle mit `integrated_playtest_passed` oder `integrated_playtest_regression_found`.
- Manuelle Review-Notizen fuer Fensterinhalt, Homebase-bis-Mission, Dropship/LZ/Drop, First-Decision-Preview, GO/Post-GO, Performance, HUD-Read-only-Grenze, Multiplayer-Grenze und Spielerlesbarkeit.
- Routing zu `TASK_963 - Release First Decision Integrated Polish Followup` oder `TASK_963 - Release First Decision Next Playable Loop`.

## Nicht-Ziele
- Kein neuer Playtest-Capture.
- Kein Export- oder Shortcut-Umbau.
- Kein Command-, Movement-, Combat-, Damage-, Mission- oder Multiplayer-State.
- Keine automatische manuelle Abnahme.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_961_release_first_decision_integrated_playtest.md`
- `docs/tasks/TASK_960_first_decision_release_playable_slice.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Fehlende oder nicht reviewbare TASK_961-Quelle blockiert.
- Gute TASK_961-Quelle ohne manuelle Review bleibt `needs_manual_review`.
- TASK_961-Regressionen bleiben als konkrete Findings sichtbar und routen zu engem Polish.
- Saubere manuelle Review akzeptiert den ersten Decision-Griff fuer den naechsten kleinen spielbaren Loop.
- Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_playtest_findings.gd`
- `scripts/tests/task_962_release_first_decision_playtest_findings.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_962_release_first_decision_playtest_findings.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_961_release_first_decision_integrated_playtest.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_960_first_decision_release_playable_slice.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_962 erzeugt keine echte Sichtabnahme. Wenn der User/Playtest die Review-Notizen nicht bestaetigt, bleibt der Stand bewusst offen.
- Der naechste Task sollte nicht wieder nur einen weiteren Gate bauen, wenn TASK_962 akzeptiert: Dann ist `TASK_963 - Release First Decision Next Playable Loop` sinnvoller als noch mehr First-Decision-Mikropolish.
