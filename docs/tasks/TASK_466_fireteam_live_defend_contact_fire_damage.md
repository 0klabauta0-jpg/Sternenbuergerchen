# TASK_466 - Fireteam Live Defend Contact Fire Damage

## Ziel / Problem

Im manuellen Drill landet das Fireteam nach `Move`/`Engage` weiterhin in `DEF 360`. Das ist als Abschlusszustand erlaubt, aber danach wirkt der Kontaktpfad kaputt: Gegner stehen in Reichweite, die Karten zeigen `Feuer frei`, trotzdem sind keine Schuesse, kein Muzzleflash und keine klare Wirkung zu erkennen.

## Sinnhaftigkeit / Ursache

TASK_465 pruefte Close-Contact-Fire mit vorbereiteter Detection. Der manuelle Fehler liegt aber im echten Live-Tick-Ablauf: Einheit sieht Gegner, ContactTracker bestaetigt, CombatLoop feuert, SimulationRoot wendet Damage an und der 3D-View zeigt den Fire-Event. Genau dieser End-to-End-Pfad muss ohne Testabkuerzung abgesichert werden.

## Umfang

- Live-Tick-Verifier fuer Auto-`DEF 360` gegen nahen Gegner ohne forcierte Detection.
- Live-Tick-Verifier fuer `Engage` gegen nahen Gegner ohne forcierte Detection.
- Schuss muss einen `fired`-Diagnoseeintrag und einen Fire-Event erzeugen.
- Damage muss beim Ziel ankommen, damit Treffer nicht nur visuell behauptet werden.
- Mission-Control/#18 soll eine Kontakt-/No-Fire-Diagnose zeigen, statt leer zu bleiben.

## Nicht-Ziele

- Keine neue Trefferanimation oder Down-Animation in diesem Slice.
- Keine finale Gegner-KI.
- Kein Umbau der Waffenbalance.
- Kein LimboAI-Wechsel.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_458_fireteam_contact_decision_diagnostics.md`
- `docs/tasks/TASK_464_fireteam_contact_scan_fire_feedback_readability.md`
- `docs/tasks/TASK_465_fireteam_engage_resume_contact_progress.md`

## Akzeptanzkriterien

- Auto-`DEF 360` feuert nach echten Combat-Ticks auf einen fitten Gegner in LOS und Waffenreichweite.
- `Engage` feuert nach echten Combat-Ticks auf einen fitten Gegner in LOS und Waffenreichweite.
- Der erste Treffer reduziert die Ziel-HP oder erzeugt einen nachvollziehbaren Damage-/Down-State.
- #18/Mission-Control hat einen lesbaren Kontaktstatus (`CONTACT FIRE`, `CONTACT WAIT` oder `NO FIRE <Grund>`).
- Wenn kein Feuer moeglich ist, nennt die Diagnose konkret `no_los`, `out_of_range`, `cooldown`, `attacker_not_engage_ready` oder Detection-/Contact-State.

## Betroffene Dateien

- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_466_fireteam_live_defend_contact_fire_damage.gd`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_466_fireteam_live_defend_contact_fire_damage.gd`
- Relevante TASK_458/TASK_464/TASK_465-Regressionen.
- `git diff --check`

## Risiken / offene Punkte

Animationen fuer Treffer/Umfallen sind bewusst Folgearbeit. Dieser Task muss zuerst beweisen, dass die Runtime-Wahrheit feuert und Damage verarbeitet.
