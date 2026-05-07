# TASK_205 - Weapon Fire VFX Muzzle Flash Particles

## Ziel
Waffenfeuer soll sichtbares Muzzle-Flash-/Schussfeedback bekommen. Dafuer wird ein kleines Particle-Pack-Subset kuratiert importiert und an autoritative Fire-Events gehaengt.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_174 - Character Helmet and Blaster Attachment Visuals
- TASK_175 - NPC Loadout Attachments
- TASK_190 - Weapon Visual Loadout Expansion and Scale
- TASK_196 - Rank and Particle Asset Subset Import
- TASK_204 - Enemy Tactics Multiplayer Authority Snapshot Patch

## Kontext
Im lokalen Kenney Particle Pack liegen Muzzle-, Smoke-, Spark- und Trace-Grafiken. Fuer den ersten Patch reicht ein kleines Muzzle-Flash-Subset. Wichtig ist die Grenze: Particles zeigen Schuesse an, aber sie sind kein Damage-, Hit- oder Heal-System.

## Quellen
- Kenney Particle Pack, kuratiert ueber TASK_193/TASK_196
- Muzzle-Grafiken wie `muzzle_01.png` bis `muzzle_05.png` als bevorzugtes erstes Subset

## Zielpfade
- `Assets/curated/kenney/particles/muzzle/`
- `docs/assets/weapon_fire_vfx_inventory.md`
- optional `data/weapon_fire_vfx_catalog.json`

## Umfang
1. Asset-Subset:
   - Maximal 8 Muzzle-/Flash-Grafiken.
   - Optional maximal 4 Smoke/Spark/Trace-Ergaenzungen, wenn direkt genutzt.
   - Lizenz, Quelle und Zielpfade dokumentieren.
2. Fire-Event-Vertrag:
   - VFX triggert auf autoritativem Fire-Event oder Snapshot-Fire-Event aus TASK_204.
   - Hit/Miss darf sichtbar unterschiedlich werden, aber Damage bleibt im Combat-System.
   - Keine VFX-Ausloesung durch reine UI-Hover oder Preview.
3. Socket/Position:
   - Muzzle-Flash sitzt an Waffen-/Handsocket oder an einem dokumentierten Barrel-Offset.
   - Grosse Waffen duerfen eigene Offsets bekommen.
   - Friendly und Enemy funktionieren identisch.
4. 2.5D-Darstellung:
   - Kurzer Flash, keine Dauerpartikel, keine riesigen Texturen.
   - Rotation orientiert sich an Facing/Target-Richtung.
   - Schussfeedback verdeckt Unit und Ziel nicht dauerhaft.
5. Verifier:
   - Assets loadbar.
   - Keine lokalen Quellpfade.
   - Fire-Event erzeugt genau ein VFX-Token/Snapshot.
   - Snapshot-Anwendung zeigt VFX, ohne Combat neu zu entscheiden.

## Nicht-Ziele
- Keine Projektilphysik.
- Keine Ballistik.
- Keine Explosionen oder Area-Damage.
- Kein vollstaendiges Partikelsystem fuer alle Status.
- Kein Massenimport des gesamten Particle Packs.

## Akzeptanzkriterien
- [x] Muzzle-Flash-Subset liegt unter `Assets/curated/kenney/particles/muzzle/`.
- [x] Alle Muzzle-Assets haben stabile IDs und dokumentierte Lizenz/Quelle.
- [x] Friendly- und Enemy-Schuesse erzeugen sichtbares Muzzle-Feedback.
- [x] VFX wird aus Fire-Events/Snapshots getrieben, nicht aus clientseitiger Combat-Auswertung.
- [x] Weapon-Socket/Offset ist pro Loadout dokumentiert oder ableitbar.
- [x] Ein TASK_205-Verifier prueft Asset-Loadbarkeit, Event-Bindung und Snapshot-Grenze.

## Erwartete Dateien
- `Assets/curated/kenney/particles/muzzle/`
- `docs/assets/weapon_fire_vfx_inventory.md`
- `data/weapon_fire_vfx_catalog.json`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_205_weapon_fire_vfx_muzzle_flash_particles.gd`
- `docs/tasks/TASK_205_weapon_fire_vfx_muzzle_flash_particles.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_205_weapon_fire_vfx_muzzle_flash_particles.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_204_enemy_tactics_multiplayer_authority_snapshot_patch.gd`
- [ ] Manueller 2.5D-Sichtcheck fuer SMG/Rifle/Enemy-Schuss.
- [x] `git diff --check`

## Risiken
- Muzzle-Flash kann bei falschem Offset im Koerper oder am Boden sitzen.
- Zu grosse/helle Particles machen die Mission Map unruhig.
- VFX darf Combat-Events nicht ersetzen.

## Naechster Schritt
Nach TASK_205 kann TASK_206 Feindfraktionen visuell klarer unterscheiden.
