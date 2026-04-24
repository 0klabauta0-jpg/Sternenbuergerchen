# TASK_117 - Dropship-Deploy als SimulationRoot-Effects

## Ziel
Embark, Insertion und Deboarding des Dropships sollen nicht mehr direkt im Tactical-/UI-Controller durch `global_position`, `visible` und Laufzeitregistrierung committed werden. Stattdessen fordert die UI den Vorgang an; die Gameplay-Wahrheit laeuft ueber explizite Commands/Effects im `SimulationRoot`.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/DESIGN_NOTES.md`
- Lies `docs/tasks/TASK_096_meta_missionmap_dropship_und_charactersheet_recovery.md`
- Lies `docs/tasks/TASK_106_dropship_lz_insertion_und_verzoegerte_aktivierung.md`
- Lies `docs/tasks/TASK_116_runtime_systeme_aus_tests_herausloesen.md`
- Pruefe den Git-Status

## Kontext
- Der aktuelle Dropship-Pfad erzeugt ein gutes sichtbares Spielgefuehl, committed aber Teile des Gameplay-Zustands im Tactical-Controller.
- Besonders kritisch sind direkte Positions-/Sichtbarkeitswechsel und Runtime-Aktivierung waehrend Embark/Deboard.
- Laut Architektur ist `SimulationRoot` die autoritative Stelle fuer State-Mutationen; UI darf anzeigen und Commands setzen.

## Aufgabe

### 1. Dropship-Effect-Vertrag definieren
- Fuehre kleine, explizite Effect- oder Command-Typen fuer den bestehenden V1-Pfad ein.
- Der Vertrag muss unit_id, Zielposition, Sichtbarkeit/Aktivierung und optional Fireteam-/Craft-Kontext enthalten.
- Keine Fahrzeug-Simulation einfuehren.

### 2. SimulationRoot als Commit-Ort nutzen
- Positionswechsel von Units waehrend Embark/Deboard laufen ueber `SimulationRoot`.
- Sichtbarkeit oder Runtime-Aktivierung, sofern gameplay-relevant, laeuft ueber denselben autoritativen Pfad.
- Bestehende Registries (`UnitRegistry`, `FTLRegistry`) bleiben die Lookup-Basis.

### 3. Tactical-/Meta-Controller entschlacken
- Der Tactical-Controller darf Dropship-Animation, UI-Texte und Preview-Visualisierung behalten.
- Er darf aber in der Live-Mission keine Gameplay-Positions- oder Aktivierungswahrheit direkt schreiben.
- Preview-Modus bleibt non-authoritative und darf sichtbar simulieren, solange er keine echte Runtime-Aktivierung registriert.

### 4. Bestehenden Flow erhalten
- LZ, Approach, Dropship-Visual, Aussteigen und anschliessendes Starten aktiver Phasen bleiben erhalten.
- Abgesetzte Units verschwinden weiter aus der Dropship-Karte und erscheinen in der Mission am vorgesehenen Ort.

## Nicht-Ziele
- keine echte Dropship-Physik
- kein abschiessbares Dropship
- keine neue Fahrzeugarchitektur
- keine Persistenz fuer Flugpfade
- kein Umbau des gesamten Meta-Layers

## Akzeptanzkriterien
- In der Live-Mission schreibt der Tactical-Controller keine Unit-Deploy-Positionen mehr direkt als Gameplay-Commit.
- Dropship-Deboarding und Runtime-Aktivierung laufen ueber `SimulationRoot`-Queue/Effect-Pfad.
- Preview bleibt non-authoritative.
- Bestehende Dropship-/Meta-Verifier laufen weiter oder werden gezielt um den neuen autoritativen Commit-Pfad erweitert.
- Multiplayer-Vorbereitung wird verbessert: Der Server kann den Deploy-Zustand eindeutig als State-Mutation verarbeiten.

## Betroffene Bereiche
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd` bzw. neuer Produktivpfad nach TASK_116
- `scripts/tests/mission_test_setup.gd`
- `scripts/meta/meta_layer_flow.gd`
- Dropship-/Meta-Verifier, vor allem Recovery- und Flow-Verifier

## Lokale Prueflogik
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_117_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_114_meta_recovery_verifier.gd`

## Umsetzung
- `SimulationRoot` verarbeitet jetzt die Effects `dropship_embark_unit` und `dropship_deploy_unit`.
- Embark/Presence/Deploy in der Live-Mission werden vom Tactical-Controller nur noch als Effects enqueued; direkte Positions- und Sichtbarkeits-Commits bleiben auf den Preview-Modus begrenzt.
- Deploy-Effects aktivieren die Unit autoritativ ueber `UnitRegistry`, `RuntimeLeader` und `FTLRegistry`, bevor Loadout-Modifier als bestehender Effect folgen.
- Die Fireteam-UI bekommt nach Runtime-Aktivierung einen kurzen Refresh-Puffer, damit die Anzeige erst nach dem autoritativen Effect-Commit auf sichtbare Units reagiert.
- `scripts/tests/task_117_verifier.gd` prueft den neuen Effect-Vertrag fuer bekannte, aber noch nicht registrierte Dropship-Units.

## Git-Schritte nach lokaler Pruefung
- `git status`
- `git add` nur relevante Dateien
- `git commit -m "Route dropship deploy through SimulationRoot"`
- `git push`
- `docs/IMPLEMENTATION_STATUS.md` erst nach Umsetzung aktualisieren
