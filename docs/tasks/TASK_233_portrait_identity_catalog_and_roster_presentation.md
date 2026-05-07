# TASK_233 - Portrait Identity Catalog and Roster Presentation

## Ziel
Die vorhandenen Character-Portraits und Identity-Daten sollen als stabiler Katalog fuer 20 bis 30 Start-NPCs verfuegbar werden. Roster, Character Sheet, Homebase und FOB sollen diese Portraits sauber anzeigen koennen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_164 - UI Theme and Component Library
- TASK_193 - Asset Source Inventory and Availability Matrix
- TASK_197 - Curated Asset Catalog and Usage Mapping
- TASK_207 - NPC Rank Skill Badge Derivation
- TASK_232 - Start Roster Generation Contract

## Kontext
Im Projektordner `Assets/Char` liegen aktuell 88 PNG-Dateien. Das reicht mengenmaessig fuer 20 bis 30 individuelle Start-NPCs. Was fehlt, ist ein sauberer Katalog mit IDs, Crops, Runtime-Pfaden, Maximalgroessen und Zuordnung zu `MetaUnitProfile.portrait_path`.

## Umfang
1. Portrait-Inventar:
   - Alle Portrait-PNGs unter `res://Assets/Char/` erfassen.
   - Dateigroessen und Aufloesungen dokumentieren.
   - Nicht geeignete oder doppelte Bilder markieren.
2. Katalog:
   - Stabile Portrait-IDs.
   - `res://`-Pfade.
   - optional Tags: medic, pilot, engineer, heavy, leader, civilian, cybernetic.
3. UI-Vertrag:
   - Character Sheet nutzt 96x120 oder klaren Zielcrop.
   - Roster-Karten nutzen kleinere Thumbnails.
   - Keine UI-Layouts wegen grossen Originalbildern sprengen.
4. Performance:
   - Grosse PNGs nicht unbedacht in jeder Karte voll laden.
   - Optional Thumbnail-/Importstrategie fuer Roster-Listen vorbereiten.
5. Generator-Anbindung:
   - TASK_232 kann Portraits eindeutig oder mit kontrollierten Wiederholungen vergeben.
   - Fehlende Portraits bekommen Fallback.
6. Verifier:
   - Mindestens 30 gueltige Portrait-Kandidaten.
   - Alle Pfade loadbar.
   - Keine lokalen absoluten Pfade.

## Nicht-Ziele
- Keine Bildbearbeitung aller Portraits.
- Keine KI-Neugenerierung.
- Kein kompletter Art-Style-Pass.
- Kein Animation-/3D-Skin-Mapping.

## Umsetzung
- `data/portrait_identity_catalog.json` enthaelt 30 Start-Roster-Kandidaten mit stabilen IDs, `res://Assets/Char/...`-Pfaden, Scan-Groessen, Tags und Diagnosen fuer grosse Quellen.
- `docs/assets/portrait_identity_inventory.md` dokumentiert den Scan von 88 PNG-Dateien, Aufloesungsverteilung und feste UI-Zielgroessen.
- `scripts/meta/portrait_identity_catalog.gd` validiert den Katalog, loest Fallbacks, laedt Texturen und liefert deterministic Seed-Assignments.
- `MetaUnitProfile` fuehrt `portrait_id` zusaetzlich zu `portrait_path`; `StartRosterGenerator` weist beide Felder deterministisch zu.
- `CharacterSheetView` und `NPCCompactCard` nutzen den Katalog-Helper fuer feste Portrait-Rechtecke: 96x120, 64x64 und 38x38.

## Akzeptanzkriterien
- [x] Portrait-Katalog enthaelt mindestens 30 gueltige Kandidaten.
- [x] Alle Runtime-Pfade sind `res://`.
- [x] Character Sheet und Roster koennen Portraits laden, ohne Layout zu sprengen.
- [x] Generator kann Portrait-IDs deterministisch zuweisen.
- [x] Fehlende oder zu grosse Portraits werden diagnostiziert.
- [x] Ein TASK_233-Verifier prueft Katalog, Loadbarkeit und Mindestmenge.

## Erwartete Dateien
- `data/portrait_identity_catalog.json`
- `docs/assets/portrait_identity_inventory.md`
- `scripts/meta/portrait_identity_catalog.gd`
- `scripts/meta/character_sheet_view.gd`
- `scripts/meta/npc_compact_card.gd`
- `scripts/tests/task_233_portrait_identity_catalog_and_roster_presentation.gd`
- `docs/tasks/TASK_233_portrait_identity_catalog_and_roster_presentation.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_233_portrait_identity_catalog_and_roster_presentation.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_232_start_roster_generation_contract.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_207_npc_rank_skill_badge_derivation.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_176_fob_loadout_weapon_preview_selector_verifier.gd`
- [ ] Manueller Sichtcheck Character Sheet/Roster mit mehreren Portraits.
- [x] `git diff --check`

## Risiken
- Die Originaldateien sind teils gross. Roster-Listen koennen sonst unnoetig schwer werden.
- Uneinheitliche Bildausschnitte brauchen eventuell spaeter einen eigenen Crop-/Thumbnail-Pass.

## Naechster Schritt
Nach TASK_233 kann TASK_234 Roster-Persistenz und New-Team-Reset speichern.
