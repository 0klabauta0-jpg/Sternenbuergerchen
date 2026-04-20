# TASK_085 – Charakterbogen Combat-Integration (get_combat_effects)

## Ziel
Convenience-Methode `get_combat_effects()` auf `TestUnit` bereitstellen, die das combat_effects-Sub-Dictionary
aus dem Charakterbogen-Bundle sicher zurueckgibt.

## Status: DONE

## Aenderungen
- `scripts/npc/test_unit.gd`: Neue Methode `get_combat_effects() -> Dictionary`
  - Gibt `speed_multiplier`, `hit_modifier`, `evasion_modifier`, `damage_taken_multiplier` zurueck
  - Fallback auf neutrale Defaults wenn Bundle leer

## Verifikation
- Headless Godot Test bestanden (alle combat_effects-Werte korrekt fuer unterschiedliche Unit-Profile)
