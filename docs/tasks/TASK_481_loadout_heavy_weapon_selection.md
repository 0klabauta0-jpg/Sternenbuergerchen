# TASK_481 - Loadout Heavy Weapon Selection

## Ziel / Problem
Scharfschuetzengewehr, Raketenwerfer und die bestehenden schweren Waffen sollen in Homebase/FOB-Loadouts direkt als spielbare Optionen erkennbar, auswählbar und visuell abgesichert sein.

## Sinnhaftigkeit / Ursache
Der naechste Vertical-Slice-Gedanke mit Luftabwehr und Outpost braucht klare Rollenentscheidungen: schnelle SMGs, Reichweitenwaffen, schwere Anti-Armor-Waffen und Support-Tools muessen nicht nur im Contract existieren, sondern im Loadout-UI mit Werten und Preview-Assets nachvollziehbar sein.

## Umfang
- Bestehende `LoadoutContract`-Optionen fuer Sniper/Rocket/Railgun absichern.
- Sniper- und Rocket-Werte als unterschiedliche Rollen schaerfen.
- FOB-Preview-Pfad aus `WeaponData` lesen, damit UI und Gameplay-Daten denselben Katalog verwenden.
- Vorhandene projektlokale Preview-/GLB-Assets pruefen.

## Nicht-Ziele
- Keine neue Waffenmechanik, Munition, Ballistik oder Projektilphysik.
- Keine neue AA-/Outpost-Mission in diesem Task.
- Keine neuen Asset-Imports.

## Relevante Contracts / Dokumente
- `docs/dev/loadout_playability_rules.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- Homebase- und FOB-Loadout-Optionen enthalten `sniper`, `rocket_launcher`, `rail_gun`, `medictool`, `rifle`, `smg` und `none` dort, wo sie laut Contract erlaubt sind.
- Sniper hat laengere Reichweite und Praezisionsrolle; Rocket ist langsam/schwer und Anti-Armor.
- Sniper- und Rocket-Preview-Pfade laden projektlokale Texturen.
- Sniper- und Rocket-Visual-Loadouts zeigen auf vorhandene GLB-Assets.
- FOB-Preview-Controls nutzen `WeaponData.get_preview_path()`.

## Betroffene Dateien
- `scripts/core/weapon_data.gd`
- `scripts/command/loadout_contract.gd`
- `scripts/command/loadout_modifier_resolver.gd`
- `scripts/meta/fob_screen.gd`
- `scripts/tests/task_481_loadout_heavy_weapon_selection.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_481_loadout_heavy_weapon_selection.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_176_fob_loadout_weapon_preview_selector_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_353_shared_loadout_contract_helper.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_175_npc_loadout_attachment_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/test_weapon_data.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die finale optische Groesse von Sniper/Rocket an der Hand beziehungsweise am Ruecken braucht weiter einen manuellen 2.5D-Sichtcheck.
- Railgun nutzt weiterhin das vorhandene Heavy-Blaster-Visual und kein eigenes neues Preview-Asset.
