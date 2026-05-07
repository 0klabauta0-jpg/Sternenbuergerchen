# TASK_197 - Curated Asset Catalog and Usage Mapping

## Ziel
Alle kuratierten und vorhandenen Asset-Sets werden ueber einen zentralen, testbaren Asset-Katalog verfuegbar gemacht.

Verfuegbar heisst hier: Systeme koennen Assets ueber stabile IDs und `res://`-Pfade finden, ohne lokale Ordner zu scannen, absolute Benutzerpfade zu kennen oder still falsche Fallbacks zu verwenden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_193 - Asset Source Inventory and Availability Matrix
- TASK_194 - Space Modular and Station Setpiece Import
- TASK_195 - UI Input and Cursor Asset Availability Pass
- TASK_196 - Rank and Particle Asset Subset Import
- TASK_190 - Weapon Visual Loadout Expansion and Scale, falls Waffenvisuals eingebunden werden

## Umfang
1. Zentraler Katalog:
   - `data/curated_asset_catalog.json` oder mehrere kleine fachliche Kataloge mit gemeinsamer Struktur.
   - Kategorien: `ui`, `input_prompt`, `cursor`, `rank_badge`, `particle`, `setpiece`, `weapon_visual`, `terrain_existing`.
   - Pro Eintrag: ID, Kategorie, Projektpfad, Quelle, Lizenzreferenz, Zielsystem, optionale Scale-/Size-Hinweise.
2. Resolver/Helper:
   - Kleiner read-only Asset-Catalog-Helper, falls noetig.
   - Keine SceneTree-Scans.
   - Keine lokalen Dateisystempfade.
3. Usage Mapping:
   - FOB/Homebase/Mission-HUD.
   - Map-Editor Tools.
   - Mission-Map Visualizer.
   - NPC-Karten und Role-Badges.
   - 2.5D Setpiece-/Weapon-Visuals.
4. Fehlende Assets:
   - Katalog-Resolver gibt Diagnose statt still falscher Fallbacks.
   - Bestehende Missing-Asset-Zaehler in `TerrainMap3DView` bleiben erhalten.
5. Verifier:
   - Jeder Katalogeintrag ist loadbar oder als rein dokumentarisch markiert.
   - Pflichtkategorien sind vorhanden.
   - Keine lokalen absoluten Pfade.
   - Keine doppelte ID.

## Nicht-Ziele
- Keine neuen Imports.
- Keine UI-Rewrites.
- Kein automatischer Asset-Browser fuer Spieler.
- Kein Runtime-Scanning der Projektordner.
- Keine Gameplay-Regeln aus Asset-Kategorien ableiten.

## Akzeptanzkriterien
- [x] Ein zentraler kuratierter Asset-Katalog existiert.
- [x] Alle Eintraege nutzen stabile IDs und `res://`-Pfade.
- [x] UI/Input/Cursor/Ranks/Particles/Setpieces sind auffindbar.
- [x] Doppelte IDs und lokale Pfade werden im Verifier abgelehnt.
- [x] Fehlende Assets erzeugen Diagnose statt stillem Fallback.
- [x] Ein TASK_197-Verifier prueft Katalogstruktur und Loadbarkeit.

## Erwartete Dateien
- `data/curated_asset_catalog.json`
- optional `scripts/assets/curated_asset_catalog.gd`
- `scripts/tests/task_197_curated_asset_catalog_usage_mapping_verifier.gd`
- `docs/assets/asset_usage_mapping.md`
- `docs/tasks/TASK_197_curated_asset_catalog_and_usage_mapping.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_197_curated_asset_catalog_usage_mapping_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_195_ui_input_cursor_asset_availability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_196_rank_particle_asset_subset_import_verifier.gd`
- [x] `git diff --check`

## Umsetzung
- `data/curated_asset_catalog.json` ist der zentrale Einstiegspunkt. Er bindet `data/ui_asset_catalog.json`, `data/rank_particle_asset_catalog.json` und `data/space_setpiece_catalog.json` ueber explizite Source-Catalog-Regeln ein.
- `scripts/assets/curated_asset_catalog.gd` baut daraus read-only einen flachen Katalog mit Kategorien `ui`, `input_prompt`, `cursor`, `rank_badge`, `particle`, `setpiece`, `weapon_visual` und `terrain_existing`.
- Der Helper scannt keine Projektordner und gibt fuer fehlende IDs oder fehlende Pfade Diagnosewerte zurueck, statt stille Fallbacks zu verwenden.
- `docs/assets/asset_usage_mapping.md` dokumentiert Kategorie-Mapping, Zielsysteme und Resolver-Vertrag.
- `scripts/tests/task_197_curated_asset_catalog_usage_mapping_verifier.gd` prueft Source-Catalogs, Pflichtkategorien, Pflicht-IDs, Loadbarkeit aller Resource-Eintraege, Missing-Asset-Diagnose und lokale-Pfad-Freiheit.

## Risiken
- Ein zu grosser Katalog kann zur zweiten UI-/Renderer-Wahrheit werden. Er darf nur Pfade und Metadaten bereitstellen.
- Wenn Kataloge automatisch Projektordner scannen, werden Importentscheidungen wieder unscharf.

## Naechster Schritt
Nach TASK_197 prueft TASK_198 Import, Loadbarkeit und sichtbare Verfuegbarkeit der gesamten Asset-Erweiterung.
