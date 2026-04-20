# TASK_088 – Leadership-Bonus auf Fireteam-Mitglieder

## Ziel
Der Fireteam-Lead verteilt einen kleinen Leadership-Bonus auf alle Mitglieder seines Fireteams.
Wenn der Lead ausfaellt (down/bleedout), wird der Bonus sofort entfernt.

## Status: OFFEN

## Kontext
- `test_unit.gd` hat `skill_leadership` (0.0–1.0) und `fireteam_id`
- `_skills.leadership` wird in `_build_skills()` gesetzt, aber aktuell **nirgends fuer Bonus-Logik genutzt**
- Fireteam-Lead wird in FOB via `lead_unit_id` pro Definition gesetzt
- `_find_first_contact_pair()` in `mission_combat_loop_driver.gd` iteriert ueber alle friendly/enemy Units

## Mechanik
- Leadership-Bonus = `lead.skill_leadership * LEADERSHIP_BONUS_FACTOR`
- Bonus wirkt auf:
  - `hit_modifier`: +bonus (besser treffen)
  - `speed_multiplier`: +bonus * 0.5 (leicht schneller)
- Nur auf Mitglieder des **gleichen Fireteams**, nicht auf den Lead selbst
- Wenn Lead vital_state != "fit" → Bonus entfernen
- Bonus ist **nicht kumulierbar** (nur ein Lead pro Fireteam)

## Implementierung
1. `test_unit.gd`:
   - Neues Property `_leadership_bonus: float = 0.0`
   - `apply_leadership_bonus(bonus: float)` / `clear_leadership_bonus()`
   - `get_combat_effects()` und Einzelgetter beruecksichtigen `_leadership_bonus`

2. `mission_combat_loop_driver.gd` (oder neues Hilfsskript):
   - Pro Tick pruefen: Lead alive? → Bonus auf Fireteam-Mitglieder verteilen
   - Lead down? → Bonus entfernen
   - Lookup ueber `get_fireteam_id()` und `UnitRegistry` oder direkte Unit-Listen

## Dateien (voraussichtlich betroffen)
- `scripts/npc/test_unit.gd`
- `scripts/tests/mission_combat_loop_driver.gd`

## Akzeptanzkriterien
- [ ] Fireteam-Mitglieder erhalten hit_modifier-Bonus proportional zur Leadership des Leads
- [ ] Bonus wird entfernt wenn Lead ausfaellt
- [ ] Lead selbst erhaelt keinen Bonus
- [ ] Units ohne Fireteam oder ohne Lead sind unbeeinflusst
- [ ] Headless-Verifier bestaetigt Bonus-Anwendung und -Entfernung
