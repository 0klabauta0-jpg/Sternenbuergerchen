# TASK_443 - Fireteam Take Behavior Control

## Ziel / Problem

`Take` soll als Besitz-/Kontrollbefehl neu geschnitten werden. Der Befehl bedeutet nicht nur Kampf, sondern: Punkt oder Area erreichen, Gegner dort entfernen, das Gebiet kontrollieren und danach in eine verteidigbare Lage kommen.

## Sinnhaftigkeit / Ursache

Nach TASK_442 ist `Engage` als Kampfbewegung getrennt. `Take` ist noch zu nah an der alten direkten Baseline und feuert wie `Engage` zu frueh auf maximale Waffenreichweite. Dadurch fehlt der spielerische Unterschied zwischen "Gegner dort bekaempfen" und "diesen Raum besitzen".

## Umfang

- `Take` bekommt eine eigene kontrollierte Runtime-Doktrin im Mission-Tactical-Pfad.
- C/N/A steuern Formation, Tempo, Deckungsgewichtung und Feuerdistanz.
- `Take` verwendet Buddy-Teams, ausser aggressiv als Sturm-/Fireline.
- `Take` priorisiert Area-Kontrolle und schiesst erst auf technische Optimalreichweite, statt wie `Engage` auf maximale Reichweite zu arbeiten.
- Area-Take-Kommandos erhalten dieselben Diagnose-/Range-Felder wie Waypoint-Take.

## Nicht-Ziele

- Kein finaler Raum-Clearing-Algorithmus mit Tuer-/Sektorlogik.
- Kein Skill-/Mut-/Leadership-Einfluss.
- Kein Flank.
- Kein vollstaendiger Defend-Folge-Slice; bestehende Secured-/Security-Logik bleibt erhalten.

## Take V1

- `Cautious`: kurze Buddy-Bounds von der freundlichen Seite, hohe Deckungswertung, Waffe im Aim, niedrige technische Feuerdistanz.
- `Normal`: Buddy-Bounds/ueberschlagenes Vorgehen, normale Geschwindigkeit, Waffe im Aim, mittlere technische Feuerdistanz.
- `Aggressive`: Sturm-/Fireline, alle ruecken gemeinsam vor, Deckung ist nachrangig, hoehere Feuerdistanz als C/N.
- `Take` ist `fire_at_will`, aber Combat-Attackability wird fuer den Befehl durch eine Optimalreichweiten-Policy begrenzt.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/tasks/TASK_442_fireteam_engage_behavior_control.md`

## Akzeptanzkriterien

- `Take + C` erzeugt kurze Buddy-Bounds mit zwei bewegenden und zwei sichernden Mitgliedern.
- `Take + N` erzeugt normales Bounding.
- `Take + A` erzeugt eine gemeinsame Sturm-/Fireline-Bewegung.
- Take-Commands tragen sichtbare Doktrin-Diagnosefelder.
- Take-Commands tragen eine `engagement_range_factor`-Policy, die Feuer gegen Ziele ausserhalb der technischen Optimalreichweite blockiert.
- Area-Take-Kommandos nutzen dieselbe Take-Range-Policy.
- Bestehende Engage-Doktrin bleibt unveraendert.

## Betroffene Dateien

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/npc/unit_command.gd`
- `scripts/tactical/combat_fire_decision_resolver.gd`
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_429_fireteam_behavior_modes_runtime.gd`
- `scripts/tests/task_432_fireteam_muzzle_flash_and_baseline_attack_movement.gd`
- `scripts/tests/task_443_fireteam_take_behavior_control.gd`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_443_fireteam_take_behavior_control.gd`
- relevante Regressionen fuer TASK_442/TASK_432/TASK_429/TASK_123
- `git diff --check`

## Risiken / offene Punkte

- Die Optimalreichweiten-Faktoren sind erste technische Startwerte, keine finale Waffenballistik.
- "Wenn beschossen, frueher reagieren" bleibt als spaeterer Kontakt-/Suppression-Slice offen.
- Area-Take nutzt weiterhin die bestehende Approach-/Occupy-State-Maschine; feinere Clearing-Schritte folgen spaeter.
