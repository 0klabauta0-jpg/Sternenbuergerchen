# TASK_087 – Loadout-Pipeline und Waffen-Sprites

## Ziel
Die beiden offenen Punkte aus TASK_086 (Waffenmodell) schliessen:
1. FOB-Loadout-Daten (`weapon_1`, `weapon_2`, `armor`) an Missions-Units durchreichen
2. Visuelle Waffen-Sprites an den Units in der Missionsszene rendern

## Status: ERLEDIGT

## Kontext
- Die FOB-UI (`fob_screen.gd`) speichert pro Fireteam-Mitglied bereits `weapon_1`/`weapon_2`/`armor` in `member_loadouts`
- `meta_layer_flow.gd` → `_configure_mission_instance()` uebergibt bisher nur `selected_team_unit_ids`, `selected_team_fireteam_ids` und `map_file_path` an `MissionSetup`
- `mission_test_setup.gd` wendet Unit-Presets via `unit_roster_presets.gd` an, aber keine per-Unit-Loadout-Daten aus der FOB
- `test_unit.gd` hat seit TASK_086 `weapon_1_id`/`weapon_2_id` Exports und `apply_identity_config()` liest sie – aber niemand setzt sie zur Laufzeit
- `weapon_data.gd` liefert Asset-Pfade (`get_asset_path()`) und Sprite-Scale (`get_sprite_scale()`) und wird jetzt fuer die Missions-Visualisierung genutzt

## Teilaufgaben

### A) Loadout-Pipeline (FOB → Mission)
1. `meta_layer_flow.gd`: In `_configure_mission_instance()` die `member_loadouts` aus `fob_screen.get_fireteam_definitions()` auslesen und an `MissionSetup` uebergeben
2. `mission_test_setup.gd`: Neue Property `member_loadouts: Dictionary` empfangen; beim Unit-Setup via `apply_identity_config()` die Werte `weapon_1`/`weapon_2`/`armor` pro Unit setzen
3. Abwaertskompatibel: wenn keine Loadout-Daten vorliegen, Fallback auf Roster-Defaults

### B) Waffen-Sprites
1. `test_unit.gd`: Beim Spawn oder nach `apply_identity_config()` ein `Sprite2D`-Child fuer die aktive Waffe erzeugen
2. Asset-Pfad und Scale aus `weapon_data.gd` beziehen (`get_asset_path(weapon_id, direction)`, `get_sprite_scale(weapon_id)`)
3. Richtung aus Unit-Blickrichtung ableiten (bestehende Facing-Logik falls vorhanden, sonst Default "SE")
4. Schienenkanone muss visuell doppelt so gross sein (Scale 2x aus WeaponData)
5. Sprite-Position relativ zur Unit passend zum Kenney-Isometric-Stil offsetten

## Dateien (voraussichtlich betroffen)
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/mission_test_setup.gd`
- `scripts/npc/test_unit.gd`
- `scripts/core/weapon_data.gd` (nur Lesezugriff)

## Akzeptanzkriterien
- [x] Units in der Mission tragen die in der FOB gewaehlte Waffe
- [x] Waffen-Sprite ist an der Unit sichtbar (korrekte Richtung, korrekte Skalierung)
- [x] Schienenkanone erscheint doppelt so gross wie Sturmgewehr
- [x] Ohne FOB-Daten (direkter Szenenstart) bleiben Default-Waffen aktiv
- [x] Headless-Verifier bestaetigt korrekte weapon_id auf Unit nach Setup
- [x] is_fireteam_lead wird aus lead_unit_id der FOB-Daten gesetzt
