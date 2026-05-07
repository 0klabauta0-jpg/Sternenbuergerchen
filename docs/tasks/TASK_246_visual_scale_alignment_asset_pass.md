# TASK_246 - Visual Scale Alignment Asset Pass

## Ziel
Alle neu eingebundenen und bereits kritischen Visual-Assets sollen einen gemeinsamen Groessen- und Ausrichtungspass bekommen: NPCs, Helme, Blaster, weitere Waffen, Muzzle-Flash/Particles, Audio-Emitter-Punkte und Background-Crops.

Der Pass soll auf der bisherigen Helm-/Blaster-/NPC-Kalibrierung aufbauen und dieselben Diagnose-Ideen weiterfuehren.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_172 - NPC Animation Scale Helmets and Enemy Visuals
- TASK_173 - NPC Animation Skeleton Socket Contract
- TASK_174 - Character Helmet and Blaster Attachment Visuals
- TASK_175 - NPC Loadout Attachments
- TASK_190 - Weapon Visual Loadout Expansion and Scale
- TASK_205 - Muzzle Flash Particle Effects
- TASK_245 - Background Image Catalog and Screen Usage

## Kontext
Bei Helm, Blaster und NPC-Groesse wurde bereits sichtbar, dass Asset-Import allein nicht reicht. Neue Waffen, Partikel, Audio-Emitter und Backgrounds brauchen denselben disziplinierten Pass: Skalierung, Achsen, Socket-Sitz, Rand/Crop, Lesbarkeit und Diagnosezaehler.

## Umfang
1. NPC- und Attachment-Pass:
   - Friendly-/Enemy-NPC-Skala gegen Tile- und Cover-Groesse pruefen.
   - Helm-Sitz, Blaster-Sitz, Sniper/Rocket/Medictool-Sitz gegen Sockets pruefen.
   - Orange/weisse Raumanzugtypen und Gegner-Varianten einbeziehen, soweit vorhanden.
2. Waffen- und VFX-Pass:
   - Muzzle-Flash sitzt am Lauf, nicht in Hand/Mitte/Tile.
   - Projektil-/Impact-/Explosion-Visuals haben plausible Hoehe und Richtung.
   - Audio-Emitter-Ort folgt dem gleichen Ereigniskontext wie Muzzle-Flash.
3. Hintergrund-Pass:
   - Crop-Anchor pro Screen pruefen.
   - Kein wichtiges Bildmotiv liegt unter festem Hauptfenster.
   - Keine dynamische Fenster-/Layoutverschiebung durch Background-Aspect.
4. Terrain-/Hoehen-Kontext:
   - NPCs, Mauern, Waffenvisuals und VFX sitzen auf `height_level + object_height` bzw. dem vorhandenen visuellen Anker.
   - Huegel, Klippen und Randhoehen aus TASK_182 bis TASK_185 nicht durch Visual-Offsets kaschieren.
5. Dokumentation:
   - `docs/reviews/asset_scale_alignment_matrix.md` mit Asset, Socket/Anchor, Scale, Rotation, Offset, Status, Sichtcheck.
   - Offene Sichtbefunde als Folgepunkte markieren.
6. Verifier:
   - Resource-Load, Scale-Grenzen, Socket-Verfuegbarkeit, Attachment-Zaehler, Missing-Asset-Zaehler.
   - Background-Groessen/Crop-Metadaten und feste Fenster-Constraints pruefen.

## Nicht-Ziele
- Keine neue Gameplay-Mechanik.
- Keine finalen Animation-Retargets.
- Keine grosse UI-Neugestaltung.
- Keine automatische Bildbearbeitung ausser benoetigten Import-/Max-Size-Einstellungen.

## Akzeptanzkriterien
- [x] Eine Alignment-Matrix dokumentiert alle relevanten NPC-, Weapon-, VFX- und Background-Assets.
- [x] Helmet/Blaster/Sniper/Rocket/Medictool-Sockets bleiben pruefbar und projektlokal.
- [x] Muzzle-Flash, Schuss-Sound und Impact nutzen kompatible Ankerdaten.
- [x] Background-Crops veraendern keine festen Hauptfenster-Groessen.
- [x] Huegel-/Hoehenanker werden nicht durch visuelle Sonderoffsets gebrochen.
- [x] Ein TASK_246-Verifier prueft Resource-Ladung, Skala, Sockets, Missing-Assets und Background-Metadaten.

## Erwartete Dateien
- `docs/reviews/asset_scale_alignment_matrix.md`
- `data/npc_unit_visual_mapping.json`
- `data/background_image_catalog.json`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_246_visual_scale_alignment_asset_pass_verifier.gd`
- `docs/manual_checks/visual_scale_alignment_checklist.md`
- `docs/tasks/TASK_246_visual_scale_alignment_asset_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_246_visual_scale_alignment_asset_pass_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_174_character_helmet_blaster_attachment_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_190_weapon_visual_loadout_expansion_and_scale.gd`
- [ ] Manueller 2.5D-/Full-HD-Sichtcheck.
- [x] `git diff --check`

## Umsetzung
- `docs/reviews/asset_scale_alignment_matrix.md` dokumentiert NPC-Skala, Helm-/Blaster-/Sniper-/Rocket-/Medictool-Sockets, Muzzle-/Audio-Anker, Background-Crops und Terrain-Hoehenanker.
- `scripts/tests/task_246_visual_scale_alignment_asset_pass_verifier.gd` prueft Mapping-Resource-Ladung, Scale-Grenzen, Socket-Verfuegbarkeit, VFX-/Audio-Kompatibilitaet, Background-Crop-Metadaten und feste Hauptfenster-Groessen.
- `docs/manual_checks/visual_scale_alignment_checklist.md` haelt die offenen Sichtchecks separat, damit Headless-Verifikation und manuelle Lesbarkeit nicht vermischt werden.
- `scripts/tests/task_174_character_helmet_blaster_attachment_verifier.gd` wurde an den TASK_190-Vertrag angepasst: der Blaster-Kit-Import bleibt 4 GLBs, das Mapping fuehrt jetzt 6 sichtbare Weapon-Visual-GLBs inklusive Sniper und Rocket.

## Risiken
- Headless-Tests koennen Lesbarkeit nur indirekt pruefen; manueller Sichtcheck bleibt Pflicht.
- Visuelle Offsets duerfen Gameplay-Hoehe, LOS, Cover oder Tile-Wahrheit nicht veraendern.
- Mehr VFX und Audio-Emitter koennen Performance-Probleme verdecken, wenn sie nicht in TASK_249 gemessen werden.

## Naechster Schritt
Nach TASK_246 prueft TASK_247, ob wirklich jede verwendete Datei im Projektordner liegt und ueber `res://` erreichbar ist.
