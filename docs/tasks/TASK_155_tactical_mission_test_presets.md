# TASK_155 - Tactical Mission Test Presets

## Ziel
Es entstehen kleine, reproduzierbare taktische Missions-Presets, damit Attack Area, Defend Area, Contact/Patrol, Dropship-Insertion und Objective-Capture ohne vollstaendigen Editor schnell getestet werden koennen.

## Status: GEPLANT

## Voraussetzung
- `TASK_121 - Area Order Marker`
- `TASK_122 - Defend Area Semantik`
- `TASK_123 - Attack Area Semantik`
- `TASK_124 - Area Feedback in #17 Selected Fireteam`
- `TASK_108 - PatrolEditorTool und Pre-Contact-Patrol`
- `docs/mission_editor_authoring_audit.md`

## Kontext
Headless-Verifier pruefen einzelne Systeme, ersetzen aber keine schnell ladbaren Playtest-Situationen. Bevor ein groesserer Editor entsteht, brauchen wir kleine Presets, die denselben Live-Missionspfad nutzen.

LZ bleibt Spieleraktion und wird nicht im Preset gespeichert.

## Umfang
1. Preset-Liste definieren:
   - `attack_area_two_contacts`
   - `defend_area_contact_relay`
   - `patrol_contact_transition`
   - `dropship_insertion_first_contact`
   - `take_area_objective`
2. Jedes Preset beschreibt:
   - Map-Datei
   - Objective-Marker oder Objective-Position
   - Gegner-Setup auf bestehenden Test-Units
   - Wellen-/Delay-Konfiguration
   - Patrol-Zuordnung
   - optionale Testnotizen fuer manuelle Checks
3. Preset-Loader fuer Tests:
   - laedt Presetdaten
   - setzt `MissionTestSetup.map_file_path`
   - konfiguriert EnemyWaveController/Patrols deterministisch
   - startet keine gespeicherte LZ
4. Kleine Headless-Verifier:
   - Presets sind parsebar
   - referenzierte Maps existieren
   - Objective und Enemy-Setups werden in der Live-Mission sichtbar
   - Mission startet ohne automatische Spieler-LZ

## Nicht-Ziele
- Kein vollstaendiger Editor.
- Kein neuer Combat-Loop.
- Kein Speichern von LZ, Area Orders oder Spieler-Wegpunkten.
- Kein Meta-Kampagnen-Save.

## Architekturregeln
- Presets sind Test-/Authoringdaten, nicht Runtime-Wahrheit.
- SimulationRoot bleibt autoritativ fuer laufende Commands und Effects.
- UI/Editor darf Presets laden, aber keine versteckte Gameplay-Logik halten.

## Akzeptanzkriterien
- [ ] Mindestens drei taktische Presets koennen headless geladen werden.
- [ ] Ein Attack-Area-Preset platziert Gegner so, dass ein Engage/Take-Area-Test reproduzierbar ist.
- [ ] Ein Patrol-Preset weist Gegnern Patrol-Pfade zu und stoppt diese bei Kontakt.
- [ ] Ein Dropship-Preset startet ohne gespeicherte LZ; die LZ muss weiterhin im Missionsflow gesetzt werden.
- [ ] Bestehende Area-/Contact-/Dropship-Verifier bleiben gruen.

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_155_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_121_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_123_verifier.gd`

## Dateien (voraussichtlich)
- `data/mission_presets/*.json`
- `scripts/tests/mission_preset_loader.gd`
- `scripts/tests/task_155_verifier.gd`

## Risiken
- Presets duerfen nicht zu einer zweiten Missionsimplementierung werden. Sie sollen nur vorhandene Live-Missionseinstiege reproduzierbar konfigurieren.
