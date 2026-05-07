# TASK_280 - Tactical Profile Editor Scenario Authoring

## Ziel
Editor und Missionsszenarien sollen taktische Profile und Air-Asset-Risiken authoren koennen: Enemy-Taktik, Fireteam-Defaults, LZ-Risiko, Heavy-Weapon-Threat, Air-Asset-Verlustfolgen und Kommunikationsintensitaet.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_155 - Mission Scenario Data Contract
- TASK_156 - Mission Editor Scenario Panel MVP
- TASK_200 - Enemy Team Tactics Contract and Editor Config
- TASK_229 - Map Editor Usability Authoring Pass
- TASK_272 - Multi Fireteam Coordinated Area Plan
- TASK_277 - Dropship Freighter Anti Armor Threat Contract
- TASK_279 - LZ Security Air Asset Tactical Playability Smoke

## Kontext
Wenn Taktiksysteme nur im Testsetup existieren, werden sie nicht gut nutzbar. Der Editor soll fuer Missionen definieren koennen, welche Enemy-Gruppen halten, patrouillieren, druecken, sichern oder Air Assets bedrohen.

## Umfang
1. Editor-Felder:
   - Enemy-Taktikprofil.
   - Security/Facing.
   - Heavy/AT-role flag.
   - LZ threat zone optional.
   - Communication intensity.
   - Air asset risk profile.
2. Scenario-Daten:
   - Speichern/Laden.
   - Validierung.
   - Defaults fuer alte Szenarien.
3. UI:
   - Kompakte Auswahlfelder, keine Textwand.
   - Help-Popups fuer Profile und Risiken.
   - Warnung bei unfairen Kombinationen.
4. Runtime-Glue:
   - MissionTestSetup liest Profile.
   - SimulationRoot/Resolver nutzen validierte Daten.
   - Keine Editor-UI als Runtime-Wahrheit.
5. Verifier:
   - Roundtrip Save/Load.
   - Alte Szenarien bleiben kompatibel.
   - Fehlende Profile fallbacken sichtbar.

## Nicht-Ziele
- Kein kompletter Mission-Designer.
- Keine neuen Enemy-Modelle.
- Keine freie Skriptsprache im Editor.
- Keine dynamische Kampagnen-KI.

## Akzeptanzkriterien
- [x] Editor/Szenario kann taktische Profile und Air-Asset-Risiko speichern.
- [x] Alte Szenarien bekommen sichere Defaults.
- [x] Unfaire oder unvollstaendige Profile werden validiert und gemeldet.
- [x] Runtime liest nur validierte Daten.
- [x] Help-Popups erklaeren Profilfelder.
- [x] Verifier prueft Roundtrip und Fallbacks.

## Erwartete Dateien
- `scripts/mission/mission_scenario_data.gd`
- `scripts/editor/...`
- `data/tactical_profile_catalog.json`
- `scripts/tests/task_280_tactical_profile_editor_scenario_authoring.gd`
- `docs/tasks/TASK_280_tactical_profile_editor_scenario_authoring.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_280_tactical_profile_editor_scenario_authoring.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_156_verifier.gd`
- [x] `git diff --check`

## Risiken
- Zu viele Profilfelder ueberladen den Editor.
- Editor-Daten duerfen keine laufende Simulation duplizieren.

## Naechster Schritt
Nach TASK_280 kann TASK_281 Multiplayer- und Authority-Grenzen fuer taktische Planung absichern.
