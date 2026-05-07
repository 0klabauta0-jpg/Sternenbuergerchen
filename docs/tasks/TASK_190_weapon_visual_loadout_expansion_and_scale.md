# TASK_190 - Weapon Visual Loadout Expansion and Scale

## Ziel
Weitere Waffen sollen als saubere Loadout- und 2.5D-Visual-Optionen eingebunden werden, inklusive grosser Waffen wie Panzerfaust/Rocket Launcher, falls passende Modelle bereitstehen.

Der Fokus liegt auf sichtbarer Auswahl, korrekter Modellskalierung und sauberer Trennung von Visuals, Loadout-Daten und Combat-Werten.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_174 - Character Helmet and Blaster Attachment Visuals
- TASK_175 - NPC Loadout Attachments
- TASK_176 - FOB Loadout Weapon Preview Selector
- TASK_189 - Medic Adjacent Tile Healing Rule

## Kontext
Aktuell sind SMG und Medictool im kleinen FOB-Loadout-Slice sichtbar. `LoadoutModifierResolver` kennt weitere abstrakte Waffenformeln wie `rifle` und `special`, aber die sichtbare Auswahl und die 2.5D-Attachments sind noch eng begrenzt.

Dieser Task erlaubt neue Waffen, ohne sofort Ballistik, Munition oder grosses Balancing umzubauen.

## Umfang
1. Waffenvertrag erweitern:
   - Neue stabile IDs definieren, z. B. `rifle`, `smg`, `medictool`, `rocket_launcher`, `grenade_launcher`, `shotgun`, `sniper` oder projektpassende Namen.
   - Alias-Regeln fuer deutsche Begriffe wie `panzerfaust` auf eine interne ID abbilden.
   - Jede ID bekommt Rolle, Preview, Visual-Loadout und optional vorhandene Loadout-Modifier.
2. Asset-Import klein halten:
   - Nur Modelle/Previews importieren, die wirklich genutzt werden.
   - GLB bevorzugen.
   - Lizenz und Quelle dokumentieren.
   - Keine absoluten Benutzerpfade in Runtime, Mapping oder Tests.
3. Scale- und Socket-Kalibrierung:
   - Jede Waffe bekommt explizite Scale/Rotation/Offset-Werte.
   - Kleine Handwaffen sitzen am `RightHandSocket`.
   - Grosse Waffen wie Panzerfaust/Rocket Launcher duerfen eine eigene Hand-/Back-/Shoulder-Regel bekommen, aber nur dokumentiert und testbar.
   - Waffen duerfen nicht als riesige Balken durch Units, Boden oder Nachbar-NPCs schneiden.
4. FOB-Loadout:
   - #13 LOADOUT zeigt neue Waffen mit Preview.
   - Lange Namen kurz halten.
   - UI bleibt Loadout-Staging, nicht Combat-Autoritaet.
5. 2.5D-Mission:
   - Friendly und enemy NPCs koennen sichtbare Waffenvarianten tragen.
   - Missing-Asset-Zaehler bleiben sichtbar.
   - Modellscale passt zu NPC-Scale aus TASK_171 bis TASK_174.
6. Gameplay-Grenze:
   - Wenn neue Combat-Modifier noetig sind, klein in `LoadoutModifierResolver` halten.
   - Keine Projektilphysik, Munition oder Splash-Damage in diesem Task.

## Nicht-Ziele
- Keine komplette Waffenbalance.
- Keine Ballistik oder Projektilsimulation.
- Keine Explosionen oder Area-Damage fuer Panzerfaust.
- Kein Massenimport ganzer Asset-Packs.
- Keine Gegner-Loadout-KI.

## Akzeptanzkriterien
- [x] Mindestens zwei neue Waffenoptionen sind als stabile IDs definiert.
- [x] Panzerfaust/Rocket Launcher ist als ID/Alias vorbereitet oder mit bereitgestelltem Modell sichtbar eingebunden.
- [x] Jede neue sichtbare Waffe hat Preview, Visual-Mapping und explizite Scale-/Socket-Kalibrierung.
- [x] #13 LOADOUT bleibt lesbar und nutzt Projektpfade fuer Previews.
- [x] 2.5D-NPCs tragen Waffen ohne schwebende, riesige oder falsch ausgerichtete Modelle.
- [x] Visual-Loadouts erzeugen keine SimulationRoot-Commands oder Effects.
- [x] Ein TASK_190-Verifier prueft IDs, Projektpfade, Mapping, Missing-Asset-Diagnose und Scale-Grenzen.

## Erwartete Dateien
- `scripts/core/weapon_data.gd`
- `scripts/command/loadout_modifier_resolver.gd`
- `scripts/meta/fob_screen.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `data/npc_unit_visual_mapping.json`
- `docs/assets/local_asset_curation_import_plan.md`
- optional `docs/assets/weapon_visuals_inventory.md`
- `scripts/tests/task_190_weapon_visual_loadout_expansion_and_scale.gd`
- `docs/tasks/TASK_190_weapon_visual_loadout_expansion_and_scale.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_190_weapon_visual_loadout_expansion_and_scale.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_176_fob_loadout_weapon_preview_selector_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_175_npc_loadout_attachment_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/test_weapon_data.gd`
- [ ] Manueller Sichtcheck fuer Handwaffen und grosse Waffen in 2.5D.
- [x] `git diff --check`

## Umsetzung
- Neue stabile IDs: `sniper` und `rocket_launcher`.
- Aliase: `panzerfaust`, `raketenwerfer`, `rocket`, `rocketlauncher` -> `rocket_launcher`; `sniper_rifle`, `scharfschuetzengewehr`, `praezisionsgewehr` -> `sniper`.
- Importiertes Subset: `Assets/used/npc/weapon_pack/models/sniper.glb`, `rocketlauncherModern.glb`, passende Preview-PNGs und Lizenz.
- #13 LOADOUT zeigt jetzt `SMG`, `Rifle`, `Sniper`, `Rocket` und `Medictool` mit kurzen Labels und Projektpfad-Previews.
- `TerrainMap3DView` normalisiert Waffen-IDs fuer Visual-Loadouts; `sniper` nutzt `RightHandSocket`, `rocket_launcher` nutzt `BackSocket`.
- Die neuen Visual-Loadouts bleiben frei von Combat-Feldern; kleine Loadout-Modifier existieren nur im bestehenden Modifier-Pfad.

## Risiken
- Grosse Waffen brauchen andere Sockets/Offsets als Blaster. Einfach dieselbe Kalibrierung zu verwenden, wird sichtbar falsch.
- Wenn neue Waffen direkt Combat-Regeln bekommen, kann der Task ausufern. Visual/Loadout zuerst, Balancing separat.

## Naechster Schritt
Nach TASK_190 kann TASK_191 die Befehlskette und das Mission-Feedback mit den neuen sichtbaren Rollen/Waffen zusammen pruefen.
