# TASK_207 - NPC Rank Skill Badge Derivation

## Ziel
NPCs sollen kleine Rang-/Faehigkeitsbadges bekommen, die aus vorhandenen Werten, Rollen oder Loadouts abgeleitet werden. Der Spieler soll schnell sehen: guter Heiler, guter Schuetze, Pilot, Engineer, Heavy usw.

Der erste Vertrag zeigt maximal drei beste/ wichtigste Badges pro NPC.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_096 - Recovery Loop
- TASK_114 - Meta Recovery Integration
- TASK_164 - UI Theme and Component Library
- TASK_176 - FOB Loadout Weapon Preview Selector
- TASK_189 - Medic Adjacent Tile Healing Rule
- TASK_196 - Rank and Particle Asset Subset Import
- TASK_197 - Curated Asset Catalog and Usage Mapping

## Kontext
Das Kenney Ranks Pack ist als Assetquelle geplant. Badges sollen aber nicht manuell beliebig gesetzt werden, sondern nachvollziehbar aus NPC-Daten entstehen. Dadurch bleibt die Anzeige spaeter mit Loadout, Medic-Rolle, Pilot-Faehigkeit oder Shooter-Werten konsistent.

## Umfang
1. Badge-Kategorien:
   - `medic`
   - `shooter`
   - `pilot`
   - `engineer`
   - `leader`
   - `heavy` oder `support`
   - optional `scout`, `sniper`, `rookie`, `veteran`
2. Ableitungsregel:
   - Aus vorhandenen Skills/Traits/Loadout/Role-Feldern deterministisch Top 3 waehlen.
   - Wenn Werte fehlen: sichere Defaults, z. B. Loadout-Rolle vor Zufall.
   - Keine Badge-Anzeige darf Gameplaywerte heimlich veraendern.
3. UI-Orte:
   - Homebase Character Sheet.
   - FOB Loadout/NPC-Karte.
   - #17 Selected Fireteam.
   - optional kompakte Mission-Map-Badges, wenn lesbar.
4. Assetbindung:
   - Badge-IDs werden ueber Asset-Katalog/Rank-Pack-Subset auf PNGs gemappt.
   - Missing-Badge-Fallback sichtbar oder diagnostisch.
5. Editor-/Datenpflege:
   - Falls NPC-Werte im Editor sichtbar sind, zeigt der Editor abgeleitete Badges read-only an.
   - Keine separate manuelle Badge-Wahrheit.
6. Verifier:
   - Top-3-Auswahl deterministisch.
   - Medic bekommt Medic-Badge bei passender Rolle.
   - Rifle/Sniper/Heavy bekommen passende Shooter-/Waffenbadges.
   - Pilot/Engineer werden aus Werten bevorzugt, wenn stark.

## Nicht-Ziele
- Kein komplettes RPG-Skillsystem.
- Keine Level-Ups oder XP.
- Keine neue Balance fuer Medic, Shooter oder Pilot.
- Keine grossen UI-Karten mit langen Erklaertexten.
- Keine manuelle Badge-Auswahl als Gameplay-Wahrheit.

## Akzeptanzkriterien
- [x] Es gibt eine zentrale, testbare Badge-Derivation pro NPC.
- [x] Maximal drei Primaerbadges werden pro NPC angezeigt.
- [x] Badges entstehen aus vorhandenen Werten, Rollen oder Loadouts.
- [x] Homebase/FOB/#17 koennen Badges anzeigen, ohne neue Gameplay-Wahrheit zu speichern.
- [x] Missing-Badge-Assets brechen UI und Tests nicht.
- [x] Ein TASK_207-Verifier prueft Top-3-Logik, Asset-IDs und UI-Datenbindung.

## Erwartete Dateien
- `scripts/meta/npc_rank_badge_resolver.gd`
- `data/rank_particle_asset_catalog.json`
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/fob_screen.gd`
- `scripts/ui/tactical_ui_theme.gd`
- `scripts/tests/task_207_npc_rank_skill_badge_derivation.gd`
- `docs/tasks/TASK_207_npc_rank_skill_badge_derivation.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_207_npc_rank_skill_badge_derivation.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_196_rank_particle_asset_subset_import_verifier.gd`
- [ ] Manueller Sichtcheck Homebase/FOB/#17 fuer Badge-Lesbarkeit.
- [x] `git diff --check`

## Risiken
- Zu viele Badges machen die UI unruhig. Drei starke Badges sind das Ziel.
- Wenn Badges manuell gepflegt werden, driften sie von den echten NPC-Daten weg.

## Naechster Schritt
Nach TASK_207 kann TASK_208 die Enemy-Tactics-Reihe als integrierten Playability-Smoke pruefen.
