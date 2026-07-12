# TASK_1172 - First Contact Readability Release Recapture

## Ziel / Problem
TASK_1171 belegt, dass `GO` den ersten Move annimmt und laufende Bewegung lesbar wird. Der naechste spielbare Moment ist der erste Feindkontakt danach: Der Spieler muss sehen, dass ein Kontakt entstanden ist, wo er ungefaehr liegt, wie sicher die Meldung ist und warum der Kontakt taktisch relevant ist.

## Sinnhaftigkeit / Ursache
Der alte TASK_542-First-Contact-Snapshot existiert bereits, ist aber noch nicht an den aktuellen TASK_1171-Handoff, Release-Provenance und Host-/Client-Release-Kontext gebunden. Ohne diesen Anschluss bleibt die Kette Preview -> GO -> Bewegung -> Kontakt nicht als heutiger Release-Flow belegt.

## Umfang
- Neuen read-only Snapshot `get_mission_first_contact_readability_release_recapture_snapshot()` bereitstellen.
- Bestehende Quellen buendeln: TASK_1171-Handoff, TASK_542 First-Contact-Readability, Release-Provenance und FirstContact-Capture-Artefakte.
- Der Verifier darf einen bereits bewiesenen TASK_1171-Handoff und einen TASK_542-Contact-Readability-Snapshot als leichte Fixture uebergeben; TASK_542 bleibt die schwere Regression fuer echte Kontakt-Erzeugung.
- Der Snapshot selbst darf nur lesen und keine Kontakte, Commands, Effects, Fire- oder Damage-Events erzeugen.

## Nicht-Ziele
- Kein neues Contact-System.
- Kein Combat-/Damage-Polish.
- Kein neues HUD-Layout und kein neuer Capture-Flow.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1171_first_move_execution_feedback_release_recapture.md`
- `docs/tasks/TASK_542_mission_first_contact_readability_pass.md`

## Akzeptanzkriterien
- Der Snapshot liefert `schema = sternenbuergerchen.mission_first_contact_readability_release_recapture.v1` und `task_id = TASK_1172`.
- TASK_1171 wird als Handoff-Quelle gelesen und muss `ready_for_first_contact_recapture = true` melden.
- TASK_542 wird als Contact-Readability-Quelle gelesen und bleibt `pass`; der schwere echte Repro-Kontakt wird separat durch TASK_542 geprueft.
- Kontaktanzahl, erster Kontakt, Report-Text, Overlay-/Primary3D-Sichtbarkeit und taktischer Kontext sind sichtbar.
- Release-Provenance passt zu Git-HEAD und FirstContact-Capture-Kontext ist vorhanden.
- Der Snapshot ist read-only und mutiert keine Command-/Effect-Queues.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1172_first_contact_readability_release_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_1172_first_contact_readability_release_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_1171_first_move_execution_feedback_release_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_542_mission_first_contact_readability_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_1172 belegt den ersten Kontakt, nicht den ersten Schusswechsel und nicht die finale Combat-Lesbarkeit.
- Der TASK_1172-Verifier nutzt leichte Handoff-Fixtures, damit der Recapture nicht denselben schweren Contact-/Release-Pfad mehrfach stapelt; echter Contact und Release-Capture-Kontext bleiben ueber TASK_542, TASK_1171 und vorhandene Host-/Client-Artefakte gebunden.
