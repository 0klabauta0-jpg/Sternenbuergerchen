# TASK_442 - Fireteam Engage Behavior Control

## Ziel / Problem

`Engage` soll nicht mehr wie ein generischer Gruppen-Move wirken. Der Befehl bedeutet: Feinde auf dem Weg und im markierten Gebiet bekaempfen, ohne Besitzpflicht fuer die Area.

## Sinnhaftigkeit / Ursache

Nach TASK_432 wurde `Engage` zur sichtbaren Baseline absichtlich direkt wie `Move` ausgefuehrt. Das war gut, um Flank-Altlasten zu entfernen, blockiert jetzt aber die gewuenschten C/N/A-Unterschiede fuer echtes Angriffsverhalten.

## Umfang

- `Engage` bekommt eine eigene kontrollierte Runtime-Doktrin im Mission-Tactical-Pfad.
- C/N/A bleiben harte Startwerte aus `fireteam_behavior_modes_contract.md`.
- Buddy-Teams bleiben die Basis: keine absichtlichen Einzelgaenger ausser spaeter bei explizitem `Flank`.
- Feuer ist `fire_at_will`; Ziele im aktiven Engage-Gebiet haben Prioritaet.
- Feindkontakt fuer Engage darf bis zur Waffenreichweite erkannt und beschossen werden, sofern LOS frei ist.

## Nicht-Ziele

- Kein neuer Flank-Algorithmus.
- Keine Skill-/Mut-/Leadership-Skalierung.
- Kein finaler Take-Rewrite.
- Kein LimboAI-Umstieg fuer eigene Fireteams.

## Engage V1

- `Cautious`: kurze Buddy-Bounds, hohe Deckungswertung, Waffe im Aim, langsam.
- `Normal`: Buddy-Bounds/ueberschlagenes Vorgehen, normale Geschwindigkeit, Waffe im Aim.
- `Aggressive`: Fireline/Rush, Wirkung vor Deckung, schnell, Waffe im Aim.
- Alle Varianten duerfen bei LOS und Waffenreichweite sofort feuern.

## Take-Abgrenzung

`Take` bleibt in diesem Task nur beschrieben: Gebiet kontrollieren/besitzen, danach in `Defend` uebergehen. Die tiefe Take-Ausfuehrung folgt in einem separaten Slice.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/tasks/TASK_432_fireteam_muzzle_flash_and_baseline_attack_movement.md`
- `docs/tasks/TASK_441_fireteam_map_tool_drill_rebuild.md`

## Akzeptanzkriterien

- `Engage + C` erzeugt kurze Buddy-Bounds mit zwei bewegenden und zwei sichernden Mitgliedern.
- `Engage + N` erzeugt normales Bounding.
- `Engage + A` erzeugt eine gemeinsame Fireline-/Rush-Bewegung.
- Engage-Commands tragen sichtbare Doktrin-Diagnosefelder.
- Engage-Commands bleiben `fire_at_will` und `aimed`.
- Zielwahl priorisiert Feinde im Engage-Gebiet und nutzt Waffenreichweite fuer Attackability.
- Bestehendes `Take` bleibt als direkte Baseline intakt.

## Betroffene Dateien

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_432_fireteam_muzzle_flash_and_baseline_attack_movement.gd`
- `scripts/tests/task_442_fireteam_engage_behavior_control.gd`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_442_fireteam_engage_behavior_control.gd`
- relevante Regressionen fuer TASK_432/TASK_429/TASK_123
- `git diff --check`

## Risiken / offene Punkte

- Area-Engage hat weiterhin eine einfache Approach-/Engage-State-Maschine; feinere Crawl-/Bound-Phasen innerhalb grosser Areas brauchen spaeter einen eigenen Area-Movement-Slice.
- Take braucht als naechstes eine gleich harte C/N/A-Kontrollmatrix.
