# TASK_482 - Mission Briefing Data Contract

## Status: IMPLEMENTIERT

## Ziel / Problem
Missionen brauchen vor dem Start ein editierbares Briefing mit Lagebild, optionalem Hintergrundbild, terrain-only Minimap-Modus und Loadout-Empfehlungen, ohne dass UI oder Editor zweite Gameplay-Wahrheiten speichern.

## Sinnhaftigkeit / Ursache
Der naechste spielbare Szenario-Slice mit Luftabwehr, Outpost-Besetzung und Frachtanflug braucht eine klare Pre-Mission-Schicht. Bevor ein sichtbares Briefing-Panel entsteht, muss der Scenario-Save/Load-Pfad stabil wissen, welche Daten dazu gehoeren.

## Umfang
- `MissionScenarioData` erhaelt ein normalisiertes `briefing`-Payload.
- Briefing-Save/Load validiert projektlokale Hintergrundbilder und erlaubte Minimap-Modi.
- Loadout-Empfehlungen normalisieren kanonische `WeaponData`-IDs, ohne visuelle IDs als Gameplay-Waffen zu behandeln.
- Der Map Editor bekommt kleine Authoring-API-Haken fuer spaetere UI-Arbeit.
- Leere optionale Air-Risk-Threat-Zone-Felder werden nicht mehr serialisiert, damit sie nicht als gespeicherte Player-LZ missverstanden werden.
- Ein Verifier sichert Roundtrip, Editor-Speicherung, Dokumentation und Terrain-Nichtduplikation.

## Nicht-Ziele
- Kein sichtbares Mission-Briefing-Fenster.
- Kein Bildauswahl-Dialog.
- Kein Minimap-Rendering und kein Painting/Annotation-Tool.
- Keine automatische Loadout-Aenderung aus Empfehlungen.

## Relevante Contracts / Dokumente
- `docs/dev/mission_briefing_contract.md`
- `docs/dev/loadout_playability_rules.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- Szenarien koennen `briefing` speichern, laden und ueber `get_briefing()` normalisiert lesen.
- `background_image_path` ist leer oder ein vorhandener `res://`-Projektpfad.
- `minimap_mode` erlaubt nur `terrain_only` oder `none`.
- `recommended_loadout.weapon_ids` nutzt kanonische `WeaponData`-IDs wie `sniper`, `rocket_launcher`, `rail_gun`, `medictool`, `rifle`, `smg` oder `none`.
- Briefing-Daten kopieren keine Terrain-Tiles, Marker oder Patrol-Paths.
- Map-Editor-Authoring kann Briefing-Daten setzen, lesen und mit dem Szenario speichern.

## Betroffene Dateien
- `scripts/mission/mission_scenario_data.gd`
- `scripts/tactical/enemy_team_tactics_profile.gd`
- `scripts/editor/map_editor.gd`
- `scripts/tests/task_482_mission_briefing_data_contract.gd`
- `docs/dev/mission_briefing_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_482_mission_briefing_data_contract.gd`
- relevante Mission-Scenario-Regressionen
- `git diff --check`

## Risiken / offene Punkte
- Die sichtbare Map-Editor-UI fuer Bildauswahl, Briefing-Text und Minimap-Anmerkungen ist Folgetask.
- Die Briefing-Minimap ist nur als Contract vorbereitet; Render- und Painting-Regeln muessen separat umgesetzt werden.
