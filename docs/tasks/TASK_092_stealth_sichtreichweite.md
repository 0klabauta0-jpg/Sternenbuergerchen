# TASK_092 – Stealth: Reduzierte Sichtreichweite

## Ziel
Der `stealth`-Wert einer Unit reduziert die effektive Sichtreichweite, mit der Gegner sie erkennen koennen.
Hoher Stealth → Gegner muessen naeher kommen, bevor sie die Unit sehen.

## Status: OFFEN

## Kontext
- `test_unit.gd` hat `stealth` als Export (0.0–1.0, Default 0.5)
- `contact_range` in `mission_combat_loop_driver.gd` ist ein globaler Export (Default 180.0)
- LOS-Check: `_los_system.has_line_of_sight_between_nodes(attacker, target, contact_range, terrain_registry)`
- Aktuell ist `contact_range` fuer alle Units gleich

## Mechanik
- Effektive Sichtreichweite auf ein Ziel = `contact_range * (1.0 - target.stealth * STEALTH_RANGE_REDUCTION_FACTOR)`
  - stealth=0.0 → volle Reichweite
  - stealth=1.0 → Reichweite um z.B. 50% reduziert (STEALTH_RANGE_REDUCTION_FACTOR = 0.5)
- Stealth wirkt **defensiv**: der Stealth-Wert des **Ziels** reduziert die Reichweite des **Angreifers**
- Bestehende `contact_range` bleibt als Basis-Maximum

## Implementierung
1. `mission_combat_loop_driver.gd`:
   - LOS-Check in `_is_in_contact_range()` oder `_pick_target_from_units()` anpassen
   - Statt globalem `contact_range` → `_get_effective_range(attacker, target)` berechnen
   - `target.get_stealth()` abfragen (oder `get_signature_control_evasion_modifier()` wiederverwenden)

2. `test_unit.gd`: Getter `get_stealth()` sicherstellen

## Dateien (voraussichtlich betroffen)
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/npc/test_unit.gd` (nur Getter, falls fehlend)

## Akzeptanzkriterien
- [ ] Units mit stealth=0.0 werden auf voller Reichweite erkannt (keine Regression)
- [ ] Units mit stealth=0.8 werden erst bei deutlich geringerem Abstand erkannt
- [ ] Stealth wirkt auf das Ziel, nicht auf den Angreifer
- [ ] Headless-Verifier bestaetigt unterschiedliche effektive Reichweiten
