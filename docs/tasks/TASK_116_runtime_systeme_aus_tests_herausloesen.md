# TASK_116 - Runtime-Systeme aus scripts/tests herausloesen

## Ziel
Produktive Missions- und Taktiksysteme sollen nicht laenger unter `scripts/tests` liegen. Dieser Task verschiebt die bereits spielpraegenden Runtime-Komponenten in klare Produktivpfade, ohne Verhalten, Datenvertraege oder Szenenablauf fachlich zu aendern.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/DESIGN_NOTES.md`
- Lies `docs/tasks/TASK_109_tacticalstancecontroller_und_panel.md`
- Lies `docs/tasks/TASK_110_fireteammovementcontroller_und_bewegungsmuster.md`
- Lies `docs/tasks/TASK_111_fireteamsecuritycontroller_und_overwatch.md`
- Lies `docs/tasks/TASK_112_contacttracker_und_contactmapoverlay.md`
- Lies `docs/tasks/TASK_113_flankvulnerabilityresolver_und_sektorstrafen.md`
- Pruefe den Git-Status

## Kontext
- Mehrere Systeme unter `scripts/tests` sind inzwischen echte Spielsysteme: Behavior Resolver, Coordination Manager, Ad-hoc Controller, Stance Controller, Movement Controller, Security Controller, Contact Tracker, Contact Overlay, Overwatch Controller, Flank Resolver und Order Visualizer.
- Die Bezeichnung `tests` verschleiert, dass diese Skripte produktive Runtime- oder Darstellungsrollen haben.
- Dieser Task ist bewusst ein Ordnungs- und Importpfad-Slice. Er darf keine neue Architektur erfinden und kein Verhalten veraendern.

## Aufgabe

### 1. Zielpfade festlegen
- Lege kleine, sprechende Produktivpfade fest, z.B. `scripts/tactical/` fuer taktische Laufzeit- und Resolver-Systeme und einen Unterpfad fuer rein lesende Overlays/Visualizer.
- Nutze vorhandene Namens- und `class_name`-Vertraege weiter, sofern kein klarer Konflikt besteht.

### 2. Produktive Skripte verschieben
- Verschiebe nur produktiv genutzte Runtime-/Tactical-Skripte aus `scripts/tests`.
- Verifier und reine Testskripte bleiben in `scripts/tests`.
- Passe alle `preload("res://scripts/tests/...")`-Referenzen auf die neuen Pfade an.

### 3. Szenen und Verifier aktualisieren
- Passe Szenen- und Testreferenzen an, ohne Szenenstruktur oder Verhalten umzubauen.
- Verifier duerfen weiter unter `scripts/tests` liegen, sollen aber die neuen Produktivpfade laden.

### 4. Keine fachlichen Aenderungen
- Keine neuen Datenmodelle.
- Keine Umbenennung von Signalen, Methoden oder Dictionary-Feldern, ausser sie ist rein pfadbedingt unvermeidbar.
- Keine Aenderung an Combat-, Movement-, Security-, Contact- oder UI-Verhalten.

## Nicht-Ziele
- kein Refactor von `MissionTacticalSandboxController`
- kein Auslagern von Gameplay-Entscheidungen aus UI/Driver in diesem Task
- kein neuer Autoload
- keine neue Scene-Struktur
- keine Veraenderung der Verifier-Erwartungen ausser Pfadupdates

## Akzeptanzkriterien
- Produktive Runtime-/Tactical-Systeme liegen nicht mehr unter `scripts/tests`.
- Alle betroffenen `preload`- und Szenenreferenzen zeigen auf die neuen Produktivpfade.
- Bestehende Verifier fuer TASK_109 bis TASK_115 laufen unveraendert inhaltlich weiter.
- Das Git-Diff zeigt im Wesentlichen Moves und Pfadupdates, keine fachlichen Umbauten.
- Die Roadmap fuer spaetere Tasks kann auf die neuen Produktivpfade verweisen.

## Umsetzung
- Produktive Tactical-/Runtime-Skripte wurden nach `scripts/tactical/` verschoben:
  - `ad_hoc_order_controller.gd`
  - `contact_tracker.gd`
  - `fireteam_behavior_resolver.gd`
  - `fireteam_coordination_manager.gd`
  - `fireteam_movement_controller.gd`
  - `fireteam_security_controller.gd`
  - `flank_vulnerability_resolver.gd`
  - `overwatch_controller.gd`
  - `tactical_stance_controller.gd`
- Rein lesende Visuals liegen jetzt unter `scripts/tactical/visuals/`:
  - `contact_map_overlay.gd`
  - `fireteam_order_visualizer.gd`
- `MissionTacticalSandboxController`, `MissionCombatLoopDriver` und die Verifier bleiben unter `scripts/tests`, laden aber die produktiven Systeme jetzt aus `scripts/tactical`.
- Relevante Task-/Status-Doku verweist auf die neuen Produktivpfade.
- Der lokale Godot-Global-Script-Class-Cache wurde fuer die neuen Pfade aktualisiert, damit die verschobenen `class_name`-Skripte nicht gegen alte Cache-Eintraege kollidieren.

## Betroffene Bereiche
- `scripts/tests/*` produktive Tactical-/Runtime-Skripte
- neue Produktivordner unter `scripts/tactical/`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- betroffene Verifier unter `scripts/tests/task_10x_verifier.gd`
- `scenes/tests/mission_reactivity_test.tscn`, falls Ressourcenpfade direkt eingetragen sind

## Lokale Prueflogik
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_109_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_110_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_111_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_112_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_113_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_115_verifier.gd`

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Move tactical runtime systems out of tests"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren
