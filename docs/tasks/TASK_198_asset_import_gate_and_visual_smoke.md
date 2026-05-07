# TASK_198 - Asset Import Gate and Visual Smoke

## Ziel
Die neue Asset-Erweiterung bekommt ein Abschluss-Gate: Godot importiert die Assets sauber, Kataloge sind loadbar, keine lokalen Quellpfade sind uebrig, und die wichtigsten UI-/Mission-/2.5D-Verwendungsorte koennen die Assets sichtbar referenzieren.

Der Task ist ein Smoke fuer TASK_193 bis TASK_197.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_193 - Asset Source Inventory and Availability Matrix
- TASK_194 - Space Modular and Station Setpiece Import
- TASK_195 - UI Input and Cursor Asset Availability Pass
- TASK_196 - Rank and Particle Asset Subset Import
- TASK_197 - Curated Asset Catalog and Usage Mapping

## Umfang
1. Import-Gate:
   - `godot_console.exe --headless --path . --import`
   - Keine fehlenden Ressourcen.
   - Keine `.import`-Fehler fuer neue PNG/GLB-Assets.
2. Pfad-Gate:
   - Keine `C:\Users\...`-Pfade in Runtime, Data, Tests oder Docs ausser explizit in Quellen-/Inventar-Dokumenten.
   - Keine Referenzen auf lokale Pictures-Ordner in `data/*.json`.
3. Katalog-Gate:
   - `curated_asset_catalog` und Teilkataloge loadbar.
   - Pflichtkategorien vorhanden.
   - Maximalmengen aus Importtasks eingehalten.
4. Visual-Smoke:
   - UI/Icon/Input/Cursor-Beispiele strukturell loadbar.
   - Rank-/Role-Badges loadbar.
   - Particles loadbar.
   - Setpiece-GLBs loadbar und mit plausibler Groesse.
   - Keine stillen Missing-Asset-Fallbacks fuer kuratierte Eintraege.
5. Manuelle Sichtcheckliste:
   - Ein kurzer Check fuer FOB/Homebase/Mission-HUD-Icons.
   - Ein kurzer Check fuer Mission Map Cursor/Prompts/Badges.
   - Ein kurzer Check fuer 3D-Setpiece-Preview, falls angelegt.

## Nicht-Ziele
- Keine neuen Asset-Imports.
- Keine neuen Features.
- Kein Gameplay-Balancing.
- Kein Ersatz fuer einzelne TASK_193 bis TASK_197-Verifier.

## Akzeptanzkriterien
- [x] Godot-Import laeuft sauber.
- [x] Alle kuratierten Katalogeintraege sind loadbar oder bewusst dokumentarisch.
- [x] Keine lokalen absoluten Pfade in Runtime/Data/Tests.
- [x] Import-Maximalmengen aus TASK_194 bis TASK_196 werden eingehalten.
- [x] UI/Input/Cursor/Ranks/Particles/Setpieces bestehen strukturellen Smoke.
- [x] Manuelle Sichtcheckliste ist dokumentiert.

## Erwartete Dateien
- `scripts/tests/task_198_asset_import_gate_visual_smoke.gd`
- `docs/manual_checks/asset_expansion_visual_smoke.md`
- `docs/tasks/TASK_198_asset_import_gate_and_visual_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_198_asset_import_gate_visual_smoke.gd`
- [x] Sichtcheckliste dokumentiert unter `docs/manual_checks/asset_expansion_visual_smoke.md`; manueller GUI-Durchlauf bleibt offen.
- [x] `git diff --check`

## Umsetzung
- `scripts/tests/task_198_asset_import_gate_visual_smoke.gd` prueft den zentralen Katalog, Pflichtkategorien, Godot-Importmetadaten, Import-Maximalmengen, Texture-/PackedScene-Loadbarkeit, sichtbares Mesh-Grundsignal fuer GLB-Samples und Missing-Asset-Diagnose.
- `docs/manual_checks/asset_expansion_visual_smoke.md` dokumentiert den manuellen Sichtcheck fuer FOB/Homebase/Mission-HUD-Icons, Input/Cursor, Rank-Badges, Particles, Setpieces, Weapon-Visuals und Terrain-Referenzen.
- Die Runtime-Daten `data/terrain_3d_asset_mapping.json`, `data/npc_unit_visual_mapping.json` und `data/rank_particle_asset_catalog.json` enthalten keine lokalen Pictures-Quellen mehr, sondern Projektpfade oder Doku-Verweise.
- Das Gate importiert keine neuen Assets und verdrahtet keine neue UI-/Gameplay-Nutzung.

## Offene manuelle Pruefung
- Der dokumentierte GUI-Sichtcheck aus `docs/manual_checks/asset_expansion_visual_smoke.md` wurde nicht interaktiv ausgefuehrt.

## Risiken
- Ein Abschluss-Smoke findet Integrationsprobleme, lokalisiert sie aber schlechter als die Einzelverifier.
- Wenn zu viele Assets auf einmal importiert wurden, wird das Review unuebersichtlich. Deshalb Maximalmengen und Diff-Stat pruefen.

## Naechster Schritt
Nach TASK_198 sind die neuen Assetquellen kontrolliert im Projekt verfuegbar und koennen von UI-, Mission- und Visual-Tasks genutzt werden.
