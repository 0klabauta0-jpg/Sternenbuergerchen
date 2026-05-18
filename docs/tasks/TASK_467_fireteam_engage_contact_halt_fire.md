# TASK_467 - Fireteam Engage Contact Halt Fire

## Ziel / Problem

Im manuellen Drill laeuft ein Fireteam bei `Engage` weiterhin bis zwischen die Gegner und kippt danach in `DEF 360`, ohne sichtbar den Kampf anzunehmen. `Feuer frei` allein reicht nicht: Wenn Gegner gesehen/erkannt sind, muss `Engage` den Marsch brechen und aus einer sinnvollen Distanz feuern.

## Sinnhaftigkeit / Ursache

TASK_466 beweist, dass der reine Live-Combat-Pfad feuern und Damage anwenden kann. Der aktuelle Fehler liegt im Zusammenspiel aus Movement-Execution und Kontakt: aktive Move-/Engage-Kommandos laufen weiter zum Zielslot, obwohl ein attackierbarer Gegner in LOS/Reichweite liegt. Dadurch wird der Wegpunkt abgeschlossen oder Auto-Defend aktiviert, bevor das Verhalten wie ein Angriff wirkt.

## Umfang

- `Engage`-Movement pausiert bei echtem, attackierbarem Kontakt in LOS und Waffenreichweite.
- Pausierte Units halten aktuelle Positionen, behalten `fire_at_will`, Aim-/Engage-Posture und source `engage`.
- Der Wegpunkt darf waehrend dieser Kontaktpause nicht als erreicht/abgeschlossen gelten und nicht sofort Auto-`DEF 360` ausloesen.
- Die Diagnose muss erkennbar machen, dass der Engage wegen Kontakt haelt.

## Nicht-Ziele

- Keine finale Cover-Suche oder Cover-Priorisierung in diesem Slice.
- Kein neues Sequenzsystem fuer Bounding/raupenartiges Vorgehen.
- Keine Gegner-KI- oder Animationserweiterung.
- Kein LimboAI-Wechsel.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_465_fireteam_engage_resume_contact_progress.md`
- `docs/tasks/TASK_466_fireteam_live_defend_contact_fire_damage.md`

## Akzeptanzkriterien

- Ein aktiver `Engage` gegen einen erreichbaren Feind in LOS/Reichweite stoppt Bewegung auf aktuellen Positionen statt durch den Gegner zu laufen.
- Friendly Units behalten `source_command_type = engage`, `fire_at_will`, Aim-/Combat-Posture und koennen dadurch feuern.
- `_update_active_phase_execution()` schliesst den Wegpunkt waehrend der Engage-Kontaktpause nicht ab.
- `get_fireteam_movement_state()` meldet einen Contact-Halt-Status.
- Regressionen fuer TASK_465/TASK_466 bleiben gruen.

## Betroffene Dateien

- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_467_fireteam_engage_contact_halt_fire.gd`
- `scripts/tests/task_466_fireteam_live_defend_contact_fire_damage.gd` (Regression-Verifier stabilisiert Timing von Fire-Diagnose zu Damage)
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_467_fireteam_engage_contact_halt_fire.gd`
- TASK_465/TASK_466-Regressionen
- `git diff --check`

## Risiken / offene Punkte

Der Slice stoppt Kampfbewegung bei Kontakt, entscheidet aber noch nicht final, ob Deckung oder direkte Schussposition besser ist. Das muss als eigener Doctrine-/Cover-Slice nachgezogen werden.
