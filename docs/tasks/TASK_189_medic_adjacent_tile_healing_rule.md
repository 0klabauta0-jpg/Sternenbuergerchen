# TASK_189 - Medic Adjacent Tile Healing Rule

## Ziel
Medic-Heilung darf nur auf dem benachbarten Tile wirken. Ein Medic soll nicht mehr ueber zwei Tiles hinweg sofort heilen.

Der Medic darf sich weiter zu einem verletzten Ziel bewegen, aber der eigentliche Heal-Effect wird erst erzeugt, wenn Medic und Ziel nach Terrain-Grid maximal ein Tile Abstand haben.

## Status: IMPLEMENTIERT

## Voraussetzung
- bestehende Medic-Unterstuetzung und `medic_support_verifier.gd`
- TASK_176 - FOB Loadout Weapon Preview Selector
- TASK_186 - Mission Map Unit Presence and Registry Audit
- TASK_187 - NPC Minimum Spacing and Multiplayer Authority

## Kontext
Der aktuelle Code nutzt in `MedicSupportResolver` `DEFAULT_TILE_RANGE = 2`. Der bestehende Verifier prueft sogar, dass Heilung exakt zwei Tiles weit reicht. Dieser Task setzt den neuen Vertrag: direkte Heilung nur auf Nachbar-Tile.

## Regel
1. Tile-Reichweite:
   - Standard: `tile_range = 1`.
   - Bei bestehender Manhattan-Grid-Distanz bedeutet das orthogonales Nachbar-Tile.
   - Falls diagonale Nachbarn als "benachbart" gelten sollen, muss der Task das bewusst im Codevertrag umstellen und im Verifier abdecken.
2. Fallback ohne TerrainRegistry:
   - Fallback-Weltdistanz muss zu einem Tile passen und darf nicht weiter als der alte 2-Tile-Fall reichen.
   - Wenn keine sichere Grid-Distanz bestimmbar ist, lieber nicht sofort heilen als zu weit heilen.
3. Move-to-heal:
   - Ziele ausserhalb von 1 Tile koennen weiter einen Medic-Move ausloesen.
   - Die Zielposition soll den Medic auf ein begehbares Nachbar-Tile fuehren.
   - Mindestabstand aus TASK_187 darf nicht verletzt werden.
4. Team- und Loadout-Regel:
   - Nur eigener Team-Target.
   - Nur fit Combat Medic mit `medictool`.
   - Medictool bleibt Support-Tool, keine Fernwaffe.
5. Feedback:
   - #17/#18 duerfen kurz anzeigen, dass Medic unterwegs ist oder Heilung bereit ist.
   - Keine langen Texte ueber den NPCs.

## Nicht-Ziele
- Keine neue Revive-Animation.
- Keine neue Heilungsbalance ausser Reichweite.
- Keine AOE-Heilung.
- Keine Gegner-Medic-KI, ausser bestehende Systeme nutzen denselben Resolver.
- Keine UI-Loadout-Umgestaltung.

## Akzeptanzkriterien
- [x] Medic heilt ein Ziel auf einem benachbarten Tile.
- [x] Medic heilt kein Ziel auf zwei Tiles Distanz.
- [x] Medic bewegt sich zu einem verwundeten Ziel ausserhalb von 1 Tile, statt sofort zu heilen.
- [x] Heal-Effects enthalten weiterhin `healer_unit_id`, `healer_team_id` und `support_resource = medictool`.
- [x] Medictool ist erforderlich; Combat Medic ohne Medictool heilt nicht.
- [x] Teamfremde Ziele werden nicht geheilt.
- [x] Bestehender Verifier wird auf 1-Tile-Reichweite umgestellt oder ein TASK_189-Verifier ersetzt den alten 2-Tile-Test.

## Erwartete Dateien
- `scripts/tactical/medic_support_resolver.gd`
- `scripts/tests/medic_support_verifier.gd`
- `scripts/tests/task_189_medic_adjacent_tile_healing_rule.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `docs/tasks/TASK_189_medic_adjacent_tile_healing_rule.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_189_medic_adjacent_tile_healing_rule.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/medic_support_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_176_fob_loadout_weapon_preview_selector_verifier.gd`
- [x] `git diff --check`

## Risiken
- Der Reichweitenwechsel kann bestehende Missions-Smokes veraendern, weil Medics jetzt oefter laufen muessen.
- Ohne begehbare Nachbar-Tile-Aufloesung kann ein Medic vor einem verwundeten Ziel blockieren. Das muss diagnostiziert werden statt still zu heilen.

## Umsetzung
- `MedicSupportResolver` nutzt standardmaessig `tile_range = 1` und einen auf ein Tile reduzierten World-Fallback.
- Move-to-heal erzeugt eine Zielposition auf einem begehbaren orthogonalen Nachbar-Tile des Patienten, wenn TerrainRegistry-Tiles vorhanden sind.
- Teamfremde Ziele werden bereits im Resolver verworfen; `medictool` bleibt Voraussetzung fuer Heal und Move-Support.
- `medic_support_verifier.gd` prueft den alten 2-Tile-Fall jetzt als Move-statt-Heal.
- `task_189_medic_adjacent_tile_healing_rule.gd` deckt Adjacent-Heal, 2-Tile-Move, `medictool`-Pflicht, Teamfilter und Heal-Effect-Metadaten ab.

## Naechster Schritt
TASK_190 kann weitere Waffen/Modelle sauber in Loadout und 2.5D-Visuals einhaengen.
