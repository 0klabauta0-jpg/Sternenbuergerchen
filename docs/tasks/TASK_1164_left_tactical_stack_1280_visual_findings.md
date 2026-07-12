# TASK_1164 - Left Tactical Stack 1280 Visual Findings

## Ziel / Problem
TASK_1163 belegt den linken taktischen Stack im exportierten 1280x720-Host/Client-Release. Jetzt sollen die sichtbaren Folgepunkte als kleiner, read-only Befundvertrag geschnitten werden, damit der naechste Polish nicht aus Bauchgefuehl entsteht.

## Sinnhaftigkeit / Ursache
Host- und Client-Fensterbilder zeigen Mini-Cards, Primaerfokus und Ereignislog grundsaetzlich brauchbar. Gleichzeitig bleiben einzelne Details im Spielerblick dicht: die Mini-Card-Detail-/Member-Zeile ist klein, der Eventlog-Filterbereich wirkt gedrungen und das kombinierte Desktop-Capture kann durch fremde Fenster ueberlagert werden.

## Umfang
- Read-only Visual-Findings-Service fuer TASK_1164.
- Controller-Snapshot, der TASK_1163 als Quelle nutzt.
- Befunde fuer positive Sichtpunkte, Issue-Liste, Primaer-Issue und empfohlenen naechsten Task.
- Keine Layout-Aenderung in diesem Task.

## Nicht-Ziele
- Kein weiteres Mini-Card- oder Eventlog-Layout in TASK_1164.
- Kein neuer Capture-Harness.
- Keine Commands, Effects, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.
- Keine automatische menschliche Abnahme aus technischer Evidence ohne Review-Notizen.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1163_left_tactical_stack_1280_release_recapture.md`

## Akzeptanzkriterien
- `scripts/mission/left_tactical_stack_1280_visual_findings.gd` liefert Schema `sternenbuergerchen.left_tactical_stack_1280_visual_findings.v1`.
- Fehlende oder falsche TASK_1163-Quelle blockiert.
- Review-ready Quelle ohne Notizen bleibt `needs_left_stack_visual_review`.
- Sichtbare Reibung routet zu `TASK_1165 - Left Tactical Stack 1280 Detail Polish`.
- Saubere Notizen koennen als `accepted_for_left_stack_acceptance_slice` enden.
- Controller exportiert `get_left_tactical_stack_1280_visual_findings_snapshot()`.
- Snapshot bleibt read-only und erzeugt keine Gameplay- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/left_tactical_stack_1280_visual_findings.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1164_left_tactical_stack_1280_visual_findings.gd`
- `docs/tasks/TASK_1164_left_tactical_stack_1280_visual_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1164_left_tactical_stack_1280_visual_findings.gd`
- Regressionen: TASK_1163, TASK_1162, TASK_222, `git diff --check`.

## Risiken / offene Punkte
TASK_1164 verbessert noch nicht das Bild selbst. Der konkrete Bildpolish wird bewusst als TASK_1165 geschnitten, damit nur belegte Mini-Card-/Eventlog-Details angefasst werden.
