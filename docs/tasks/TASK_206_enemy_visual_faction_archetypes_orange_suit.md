# TASK_206 - Enemy Visual Faction Archetypes Orange Suit

## Ziel
Enemy-NPCs sollen visuell klar als Gegenteam erkennbar sein. Als erster Standard soll der orange Raumanzug-Typ verwendet werden, waehrend die weissen/hellen Raumanzuege fuer Friendly- oder neutrale NPCs erhalten bleiben.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_171 - NPC 3D Asset Mapping
- TASK_172 - NPC Visual Fixture and Scale
- TASK_173 - NPC Skin and Variant Mapping
- TASK_174 - Character Helmet and Blaster Attachment Visuals
- TASK_175 - NPC Loadout Attachments
- TASK_190 - Weapon Visual Loadout Expansion and Scale
- TASK_193 - Asset Source Inventory and Availability Matrix

## Kontext
Im Projekt/Assetbestand gibt es bereits Astronauten-/Raumanzug-Skins sowie orange Varianten. Aktuell nutzen Friendly und Enemy teils aehnliche Modelle/Skins. Fuer Lesbarkeit und spaeter Multiplayer braucht es klare Faction-Archetypen: Weiss/hell fuer eigene Seite, Orange fuer Gegenseite als Basis.

Zusaetzliche Archetypen wie Robot, Alien, Zombie oder Soldier sollen inventarisiert und vorbereitet werden, aber nicht alle sofort produktiv importiert werden.

## Umfang
1. Faction-Archetypen:
   - `friendly_space_suit_white`
   - `enemy_space_suit_orange`
   - optional vorbereitet: `enemy_robot`, `enemy_alien`, `enemy_zombie`, `enemy_soldier`
   - Jeder Archetyp bekommt Modell, Skin, Scale, Socket-Kompatibilitaet und Fallback.
2. Orange-Gegenteam:
   - Orange Raumanzug wird Standard fuer normale Gegner.
   - Weisse/helle Varianten bleiben fuer Player-/Friendly-NPCs.
   - Teamfarben duerfen als kleine UI-/Badge-Ergaenzung kommen, nicht als einziger Unterschied.
3. Mapping:
   - `data/npc_unit_visual_mapping.json` oder Nachfolge-Katalog bekommt stabile Archetype-IDs.
   - Enemy-Waves/Profile aus TASK_200 koennen Visual-Archetyp referenzieren.
   - Keine absoluten lokalen Assetpfade.
4. Character-Sheet-Vorbereitung:
   - Character Sheet oder Selected-Fireteam-Panel kann Archetyp/Preview anzeigen, wenn der bestehende UI-Pfad das ohne Redesign erlaubt.
   - Kein neues grosses Charakterdatenblatt in diesem Task erzwingen.
5. Verifier:
   - Enemy-Default nutzt orange Variante.
   - Friendly-Default bleibt heller/anderer Suit.
   - Scale bleibt innerhalb bestehender NPC-Grenzen.
   - Missing-Asset-Diagnose bleibt sichtbar.

## Nicht-Ziele
- Kein kompletter Charaktereditor.
- Kein Massenimport aller Character-Skins.
- Keine Animationserweiterung.
- Keine Gameplaywerte aus Skinfarbe.
- Keine Faction-Story oder Dialogsysteme.

## Akzeptanzkriterien
- [x] Enemy-Default-Archetyp nutzt eine orange Raumanzug-Variante.
- [x] Friendly-Default bleibt klar unterscheidbar.
- [x] Robot/Alien/Zombie/Soldier sind mindestens als moegliche Archetypen inventarisiert oder als spaetere IDs vorbereitet.
- [x] Weapon-/Helmet-Sockets funktionieren mit dem orange Enemy-Archetyp.
- [x] 2.5D-Mission zeigt Enemy/Friendly unterscheidbar ohne riesige Scale-Unterschiede.
- [x] Ein TASK_206-Verifier prueft Mapping, Projektpfade, Scale, Socket-Kompatibilitaet und Missing-Asset-Fallback.

## Erwartete Dateien
- `data/npc_unit_visual_mapping.json`
- `docs/assets/npc_faction_archetype_inventory.md`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_test_setup.gd`
- `scripts/tests/task_206_enemy_visual_faction_archetypes_orange_suit.gd`
- `docs/tasks/TASK_206_enemy_visual_faction_archetypes_orange_suit.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_206_enemy_visual_faction_archetypes_orange_suit.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_175_npc_loadout_attachment_verifier.gd`
- [ ] Manueller 2.5D-Sichtcheck Friendly vs. Enemy.
- [x] `git diff --check`

## Risiken
- Orange Skins koennen zu Racer- statt Raumanzug-Look wirken; der Task soll das inventarisieren und sichtbar pruefen.
- Wenn mehrere Archetypen gleichzeitig importiert werden, wird der Diff schnell gross. Erst orange Enemy sauber machen.

## Naechster Schritt
Nach TASK_206 kann TASK_207 Rank-/Skill-Badges pro NPC ableiten und anzeigen.
