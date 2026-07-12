# TASK_1173 - First Engagement Feedback Release Recapture

## Ziel / Problem
Nach TASK_1172 ist der erste Feindkontakt im aktuellen Release-Kontext lesbar. Der naechste Spielergriff ist der erste Feuerentscheid: Das Spiel muss erkennen lassen, ob das Fireteam feuert, wartet oder blockiert ist, welches Ziel betroffen ist und ob Deckung, Distanz oder LOS die Entscheidung bestimmen.

## Ursache / Sinnhaftigkeit
TASK_543 liefert diese Combat-Information bereits als Headless-Snapshot. Sie ist aber noch nicht mit dem TASK_1172-Handoff sowie aktuellem Export- und Host-/Client-Capture-Kontext als ein durchgehender Release-Flow gebuendelt. Ohne diesen Anschluss ist die Kette Move -> Contact -> Engagement im gegenwaertigen Build nicht gezielt pruefbar.

## Umfang
- Neuen read-only Snapshot `get_mission_first_engagement_feedback_release_recapture_snapshot()` bereitstellen.
- TASK_1172-Handoff, TASK_543-Engagement-Feedback, Release-Provenance und vorhandene Host-/Client-Artefakte auswerten.
- Feuerstatus, Ziel-/Blockgrund, FireEvent und Deckung-/Range-/LOS-Kontext in einem Contract sichtbar machen.
- Der Verifier darf leichte Handoff-Fixtures fuer TASK_1172 und TASK_543 uebergeben; TASK_543 bleibt die schwere echte Engagement-Regression.

## Nicht-Ziele
- Keine neuen Commands, Contacts, FireEvents, DamageEvents oder Multiplayer-Wahrheit erzeugen.
- Kein Combat-Rewrite, kein HUD-Redesign und keine Aenderung an der Entscheidung des Combat-Resolvers.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1172_first_contact_readability_release_recapture.md`
- `docs/tasks/TASK_543_mission_first_engagement_feedback_pass.md`
- `docs/superpowers/specs/2026-07-12-first-engagement-release-recapture-design.md`

## Akzeptanzkriterien
- Der Snapshot liefert `schema = sternenbuergerchen.mission_first_engagement_feedback_release_recapture.v1` und `task_id = TASK_1173`.
- TASK_1172 meldet `ready_for_first_engagement_recapture = true`; TASK_543 bleibt `pass`.
- Ein sichtbarer Feuerstatus sowie Ziel-/Blockgrund, FireEvent oder konkrete Warte-/Blockursache und Deckung-/Range-/LOS-Kontext sind vorhanden.
- Release-Provenance und getrennte Host-/Client-Artefakte sind aktuell und vollstaendig; fuer den Feuerkontakt wird `first_fire_converged` verlangt.
- Der Snapshot bleibt read-only und veraendert keine Command-/Effect-Queues.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1173_first_engagement_feedback_release_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_1173_first_engagement_feedback_release_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_1172_first_contact_readability_release_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_543_mission_first_engagement_feedback_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_1173 beweist Contract- und Release-Readability, keinen menschlichen Pixel-Sichttest im Fenster.
- TASK_543 ist weiterhin teuer; seine Laufzeit wird in diesem Task nicht kaschiert oder umgebaut.
