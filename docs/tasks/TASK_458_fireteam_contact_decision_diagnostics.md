# TASK_458 - Fireteam Contact Decision Diagnostics

## Ziel / Problem
- Der manuelle Fireteam-Playtest braucht eine klare Antwort auf "warum schiesst der nicht?" und "warum sieht das Team den Gegner nicht?". Kontakt, LOS, Reichweite, Cooldown, Detection und Fire-Entscheid sollen im Mission-Control-/Dev-Pfad sichtbar werden.

## Sinnhaftigkeit / Ursache
- TASK_457 hat Aim-Bereitschaft, Muzzleflash, rote Firelines und Area->Waypoint-Fortsetzung technisch angebunden.
- Im Fenster bleibt aber ohne Diagnose unklar, ob ein fehlender Schuss an LOS, Reichweite, Cooldown, Kontaktstatus, Zielauswahl oder UI/Visuals liegt.

## Umfang
- Einen read-only Combat-/Kontakt-Diagnosesnapshot im Mission-Combat-Loop bereitstellen.
- Den letzten Fire-Entscheid mit Grund (`fired`, `cooldown`, `no_contact_pair`, `no_damage_effect`, etc.) und relevanten Werten sichtbar machen.
- #18 Mission Control oder ein bestehender Dev-Snapshot soll diese Werte aus Runtime-State lesen.
- Headless-Verifier fuer Diagnoseinhalt und UI-Snapshot ergaenzen.

## Nicht-Ziele
- Keine neue Gegner-KI.
- Keine neue Fireteam-Formation oder Sequenzlogik.
- Keine finale Charakterbogen-/Skill-Skalierung.
- Keine neue Combat-Ballistik.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_457_fireteam_contact_engage_runtime_pass.md`
- `docs/tasks/TASK_438_fireteam_contact_visibility_attack_visuals.md`
- `docs/tasks/TASK_440_enemy_limbo_contact_diagnostics.md`

## Akzeptanzkriterien
- Der Combat-Loop exportiert einen aktuellen Diagnose-Snapshot fuer Kontakt-/Fire-Entscheid.
- Ein Kontakt ohne Feuer wegen Cooldown nennt den Cooldown als Grund.
- Ein Feuerentscheid nennt Angreifer, Ziel, Waffe, Kontaktstatus und Muzzle-/Fire-Event-Bezug.
- Mission-Control/Dev-Snapshot zeigt die Diagnose kompakt an, ohne Gameplay-State in der UI zu mutieren.
- Tests decken den Runtime-Snapshot und die UI-Weitergabe ab.

## Betroffene Dateien
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_458_fireteam_contact_decision_diagnostics.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_behavior_modes_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_458_fireteam_contact_decision_diagnostics.gd`
- Relevante Regressionen: TASK_457, TASK_438, TASK_440.
- `git diff --check`.

## Risiken / offene Punkte
- Der Slice erklaert Entscheidungen, repariert aber nicht automatisch alle Ursachen. Wenn der Diagnosepfad z.B. `no_los` oder `out_of_range` zeigt, folgt daraus ein eigener Behavior-/Pathing-Slice.
