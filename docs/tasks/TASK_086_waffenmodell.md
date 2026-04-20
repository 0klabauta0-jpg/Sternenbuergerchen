# TASK_086 – Waffenmodell (WeaponData)

## Ziel
Per-Waffe Kampfwerte statt globaler Konstanten im Combat-Loop.
Drei Waffentypen mit individuellen Stats, Asset-Zuordnung und Display-Namen.

## Status: DONE

## Waffentypen
| ID        | Display-Name      | Damage | Hit-Chance | Feuerrate (Ticks) | Reichweite | Asset               | Skalierung |
|-----------|-------------------|--------|------------|-------------------|------------|---------------------|------------|
| smg       | Maschinenpistole  | 25     | 0.40       | 6                 | 140        | weapon_gun_*        | 1x         |
| rifle     | Sturmgewehr       | 40     | 0.45       | 10                | 180        | weapon_rifle_*      | 1x         |
| rail_gun  | Schienenkanone    | 70     | 0.35       | 18                | 260        | weapon_rifle_*      | 2x         |

## Aenderungen
- **NEU** `scripts/core/weapon_data.gd`: Statische Waffen-Registry mit Katalog, Getter-Methoden, Normalisierung
- `scripts/npc/test_unit.gd`:
  - Neue Exports `weapon_1_id`, `weapon_2_id` (Default: "rifle")
  - Getter: `get_weapon_1_id()`, `get_weapon_2_id()`, `get_active_weapon_id()`
  - `apply_identity_config()` liest `weapon_1`/`weapon_1_id` und `weapon_2`/`weapon_2_id`
- `scripts/tests/mission_combat_loop_driver.gd`:
  - Laedt `WEAPON_DATA_SCRIPT`, nutzt aktive Waffe des Angreifers fuer damage/hit_chance/ticks
  - Neue Hilfsmethode `_get_unit_active_weapon_id()`
- `scripts/meta/fob_screen.gd`:
  - "Sonderwaffe" → "Schienenkanone" umbenannt
  - Weapon-ID `special` → `rail_gun` migriert (abwaertskompatibel via Normalisierung)

## Verifikation
- `scripts/tests/test_weapon_data.gd`: 15/15 Tests bestanden (headless Godot)
