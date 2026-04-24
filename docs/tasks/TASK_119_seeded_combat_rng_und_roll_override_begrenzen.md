# TASK_119 - Seeded Combat RNG und roll_override begrenzen

## Ziel
Combat soll wieder als nachvollziehbare, aber echte Wahrscheinlichkeit funktionieren. Feste Live-`roll_override`-Werte sollen aus normalen Angriffen verschwinden; deterministische Tests erhalten stattdessen einen kontrollierten Seed- oder Test-Roll-Pfad.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/DESIGN_NOTES.md`
- Lies `docs/tasks/TASK_030_damage_modell.md`
- Lies `docs/tasks/TASK_047_skill_wirkung_combat.md`
- Lies `docs/tasks/TASK_087_loadout_pipeline_waffen_sprites.md`
- Lies `docs/tasks/TASK_118_combat_entscheidungen_aus_mission_driver_herausloesen.md`
- Pruefe den Git-Status

## Kontext
- Aktuell setzen normale Angriffe und Overwatch feste `roll_override`-Werte.
- Dadurch wird Trefferwahrscheinlichkeit im Live-Pfad faktisch zu einem Schwellenwert.
- Fuer Tests ist deterministisches Verhalten wichtig, aber fuer Spielgefuehl, Skillwirkung und Teamqualitaet braucht Combat echte Varianz.

## Aufgabe

### 1. Seeded RNG im autoritativen Pfad einfuehren
- Fuehre einen kleinen RNG-Pfad ein, der im autoritativen Combat/Damage-Pfad verwendet wird.
- Der RNG muss fuer Verifier deterministisch seedbar sein.
- Im spaeteren Multiplayer muss der Server/autoritative Tick die Quelle sein.

### 2. Live-roll_override entfernen
- Entferne feste `roll_override`-Werte aus normalem Live-Combat und Overwatch.
- `roll_override` darf nur noch fuer explizite Tests, Debug-Utilities oder gezielte Verifier-Payloads genutzt werden.
- Falls `roll_override` im Effect-Vertrag bleibt, muss der Verwendungszweck klar begrenzt sein.

### 3. Tests stabil halten
- Bestehende Verifier sollen nicht zufaellig flappen.
- Wo bisher feste Rollwerte Stabilitaet erzeugt haben, setze stattdessen Seed oder explizite Test-Payloads.
- Neue Tests sollen pruefen:
  - gleicher Seed -> gleiches Ergebnis
  - anderer Seed -> potentiell anderes Ergebnis
  - Live-Pfade senden keine festen Rollwerte mehr

### 4. Spielwerte nicht neu balancen
- Trefferchance-, Cover-, Skill-, Waffen- und Flankenformeln bleiben in diesem Task fachlich gleich.
- Es geht nur um die Zufallsquelle und den Missbrauch von `roll_override`.

## Nicht-Ziele
- kein neues Ballistiksystem
- keine Waffenbalance
- keine neue Schadensformel
- keine UI fuer Wahrscheinlichkeiten
- kein kompletter Determinismus-/Replay-Framework-Ausbau

## Akzeptanzkriterien
- Normale Angriffe und Overwatch im Live-Pfad setzen kein festes `roll_override` mehr.
- Combat-RNG ist fuer Tests deterministisch seedbar.
- Bestehende Combat-Verifier laufen stabil.
- `DamageModel.resolve_hit()` bleibt klein und testbar.
- Die Architektur bleibt server-authoritative vorbereitbar.

## Betroffene Bereiche
- `scripts/core/damage_model.gd`
- `scripts/core/simulation_root.gd`
- Combat-/Overwatch-Resolver oder Driver nach TASK_118
- Verifier, die bisher feste Rollwerte erwarten

## Lokale Prueflogik
- `godot_console.exe --headless --path . --script scripts/tests/task_087_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_111_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_113_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/medic_support_verifier.gd`
- Neuer Verifier fuer seeded Combat-RNG und Live-`roll_override`-Grenzen.

## Umsetzung
- `SimulationRoot` besitzt jetzt einen seedbaren Combat-RNG (`combat_rng_seed`, `set_combat_rng_seed()`, `get_next_combat_roll()`).
- Der autoritative Damage-Pfad zieht ohne expliziten `roll_override` einen Roll aus diesem RNG.
- `roll_override` bleibt nur als expliziter Test-/Debug-Pfad im Damage-Effect-Vertrag erhalten.
- Normale Fire-Decision-Payloads und Overwatch-Damage-Effects setzen keinen festen `roll_override` mehr.
- Trefferchance-, Cover-, Skill-, Waffen- und Flankenformeln wurden nicht neu balanciert.

## Verifikation
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_119_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_087_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_111_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_113_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/medic_support_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_118_verifier.gd`

Hinweis: `task_087_verifier.gd` meldet weiterhin bekannte Setup-Warnungen und einen Godot-Add-Child-Fehler, zaehlt aber alle 34 Checks als bestanden.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Use seeded RNG for combat rolls"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren
