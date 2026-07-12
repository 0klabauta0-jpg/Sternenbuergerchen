# TASK_1169 - Left Stack Air Anchor Release Acceptance

## Ziel / Problem
TASK_1168 hat den linken taktischen Stack luftiger verankert. Der frische Host-/Client-FirstContact-Capture nach dem Merge muss jetzt als eigener, nachvollziehbarer Release-/Sichtabschluss an diesen Polish gebunden werden.

## Sinnhaftigkeit / Ursache
Der Polish ist nur dann wirklich belastbar, wenn der exportierte 1280x720-Release auf dem aktuellen Git-HEAD laeuft und die getrennten Host-/Client-Fensterbilder den verbesserten linken Stack zeigen. Ohne diesen Abschluss bleibt die Roadmap bei "Recapture noch offen" stehen.

## Umfang
- Read-only Acceptance-Snapshot fuer TASK_1168 im aktuellen Release-Capture.
- Release-Provenance, FirstContact-Manifest und getrennte Host-/Client-Fensterbilder pruefen.
- Sichtbefund aus Host und Client festhalten.
- Naechsten sinnvollen Playability-Schritt benennen.

## Nicht-Ziele
- Kein weiteres Layout in diesem Task.
- Keine neuen Commands, Effects, Fire-/Damage-Events oder Movement-Logik.
- Keine Multiplayer-Wahrheit im UI.
- Keine automatische Pixelanalyse.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1168_left_tactical_stack_air_anchor_polish.md`
- `docs/tasks/TASK_1167_left_tactical_stack_1280_detail_visual_acceptance.md`

## Akzeptanzkriterien
- Snapshot `get_left_tactical_stack_1280_air_anchor_release_acceptance_snapshot()` existiert.
- Snapshot meldet Schema `sternenbuergerchen.left_tactical_stack_1280_air_anchor_release_acceptance.v1`.
- TASK_1168-Snapshot ist bereit.
- Release-Provenance passt zum aktuellen Git-HEAD.
- FirstContact-Capture ist `pass`, Deployment und First Fire sind konvergiert.
- Host- und Client-Fensterbilder sind getrennt vorhanden und nicht leer.
- Akzeptierte Sichtbefunde nennen Host-Linksstapel, Client-Linksstapel, Eventlog-Abstand und Multiplayer-Konsistenz.
- Snapshot erzeugt keine Commands, Effects oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1169_left_stack_air_anchor_release_acceptance.gd`
- `docs/tasks/TASK_1169_left_stack_air_anchor_release_acceptance.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- Neuer Verifier: `scripts/tests/task_1169_left_stack_air_anchor_release_acceptance.gd`
- Regression: TASK_1168, TASK_1167, TASK_1166, TASK_1109, TASK_1110
- `release_runtime_start_check.ps1 -JsonOnly`
- `capture_release_host_client_entry_playtest.ps1 -FirstContact -TimeoutSeconds 300`
- `git diff --check`

## Risiken / offene Punkte
Die Acceptance ist eine dokumentierte Sichtabnahme anhand der getrennten Fensterbilder, keine automatische Pixelbewertung. Der naechste Schritt sollte wieder Richtung spielerischer Entscheidungslesbarkeit gehen, nicht noch mehr reine HUD-Kosmetik stapeln.
