# TASK_118 - Combat-Entscheidungen aus MissionCombatLoopDriver herausloesen

## Ziel
Der `MissionCombatLoopDriver` soll nicht laenger der Ort sein, an dem die eigentlichen Combat-Entscheidungen entstehen. Ziel ist ein kleiner Runtime-Schnitt, der Zielwahl, Feuerfreigabe, Medic-Support, Contact-Gates und Overwatch nachvollziehbar in produktive Resolver/Controller verschiebt und den Driver auf Orchestrierung/Glue reduziert.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/DESIGN_NOTES.md`
- Lies `docs/tasks/TASK_095_combat_medic_support.md`
- Lies `docs/tasks/TASK_111_fireteamsecuritycontroller_und_overwatch.md`
- Lies `docs/tasks/TASK_112_contacttracker_und_contactmapoverlay.md`
- Lies `docs/tasks/TASK_113_flankvulnerabilityresolver_und_sektorstrafen.md`
- Lies `docs/tasks/TASK_116_runtime_systeme_aus_tests_herausloesen.md`
- Pruefe den Git-Status

## Kontext
- `MissionCombatLoopDriver` entscheidet aktuell pro Tick ueber viele Kernfragen: Bleedout, Leadership, Detection, Contact Tracking, Medic-Support, Enemy Advance, Friendly Standard Behavior, Overwatch, normale Angriffe und Combat Resolution.
- Damage und Heal werden zwar ueber `SimulationRoot` committed, aber die taktische Entscheidung liegt zu stark im Driver.
- Designziel ist: Der Spieler gibt Commander-Befehle, FTL/Teamqualitaet und Runtime-Kontext entscheiden ueber die Umsetzung.

## Aufgabe

### 1. Verantwortlichkeiten schneiden
- Identifiziere im Driver die kleinsten fachlichen Bloecke, die als produktive Resolver/Controller ausgelagert werden koennen.
- Bevorzugte erste Schnitte:
  - Target/Fire Decision Resolver
  - Medic Support Resolver
  - Contact Gate / Fire Permission Resolver
  - Enemy Behavior Resolver, falls klein genug
- Bestehende Systeme wie `ContactTracker`, `OverwatchController` und `FlankVulnerabilityResolver` sollen konsumiert werden, nicht dupliziert.

### 2. Driver auf Orchestrierung reduzieren
- Der Driver sammelt pro Tick Kontext, ruft Resolver auf und enqueued autoritative Commands/Effects.
- Er soll nicht mehr selbst komplexe Scores, Zielwahl und Sonderregeln inline besitzen.
- Statuslabels und Debug-Events duerfen im Driver bleiben, solange sie nicht zur Gameplay-Wahrheit werden.

### 3. Autoritativen Pfad erhalten
- Alle resultierenden State-Mutationen laufen weiter ueber `SimulationRoot.enqueue_command()` oder `SimulationRoot.enqueue_effect()`.
- Keine direkte Mutation an `TestUnit` fuer Damage, Heal, Movement oder Combat-Status.
- Resolver liefern Daten/Entscheidungen; sie committen nicht still seitlich.

### 4. Verhalten nicht grob veraendern
- Dieser Task ist eine strukturelle Entflechtung.
- Bestehende Combat-Verifier muessen nach der Auslagerung weiter dieselben fachlichen Ergebnisse sehen.
- Falls ein Verhalten korrigiert werden muss, nur mit klarer Akzeptanz und eigenem Test.

## Nicht-Ziele
- kein komplettes neues Combat-System
- keine echte Ballistik
- keine neue Waffenarchitektur
- keine Gegner-KI-Neuerfindung
- keine tiefe Morale- oder Social-Simulation
- keine UI-Politur

## Akzeptanzkriterien
- `MissionCombatLoopDriver` enthaelt deutlich weniger inline Combat-Entscheidungslogik.
- Zielwahl, Feuerfreigabe und Medic-Entscheidungen liegen in kleinen produktiven Resolvern/Controllern.
- Damage, Heal und Movement werden weiterhin autoritativ ueber `SimulationRoot` committed.
- Bestehende Verifier fuer Combat, Medic, Contact, Overwatch und Flank laufen weiter.
- Neue Resolver sind ohne Szene mit kleinen Headless-Verifiern pruefbar.

## Betroffene Bereiche
- `scripts/tests/mission_combat_loop_driver.gd` bzw. neuer Produktivpfad nach TASK_116
- produktive Tactical-/Combat-Resolver unter neuem Runtime-Pfad
- `scripts/core/simulation_root.gd` nur falls Effect-Vertraege minimal ergaenzt werden muessen
- Combat-/Medic-/Contact-/Flank-Verifier

## Lokale Prueflogik
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_118_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/medic_support_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_111_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_112_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_113_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`

## Umsetzung
- `scripts/tactical/combat_fire_decision_resolver.gd` uebernimmt Zielwahl, Friendly-Contact-Gate, Feuerfreigabe und Damage-Effect-Payload-Aufbau inklusive spotted-Malus, Misidentification-Callback und Flank-Modifikatoren.
- `scripts/tactical/medic_support_resolver.gd` uebernimmt Medic-Rollen-/Tool-Pruefung, Priorisierung, Reichweitenpruefung und Move-/Heal-Action-Entscheidung.
- `MissionCombatLoopDriver` sammelt weiter Tick-Kontext, fuehrt Detection-/Cooldown-Zustaende, enqueued Commands/Effects und zeigt Events, delegiert aber die Kernentscheidungen an die Resolver.
- `scripts/tests/task_118_verifier.gd` prueft die neuen Resolver ohne Missionsszene fuer Medic-Actions, Contact-Gate und Damage-Effect-Payload.
- Bestehende autoritative Mutationen bleiben unveraendert ueber `SimulationRoot.enqueue_command()` und `SimulationRoot.enqueue_effect()`.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Extract combat decisions from mission driver"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren
