# TASK_093 – Discipline: Hold-Fire-Disziplinbrueche

## Ziel
Units mit niedrigem `discipline`-Wert brechen gelegentlich Hold-Fire-Befehle und feuern trotzdem,
obwohl sie in einer Phase stehen, die kein Feuern erlaubt (z.B. APPROACH, HOLD).

## Status: ERLEDIGT

## Kontext
- `test_unit.gd` hat `discipline` als Export (0.0–1.0, Default 0.5)
- `_can_unit_attack()` in `mission_combat_loop_driver.gd` (Zeile ~315) prueft `get_fire_status()`
- Wenn `fire_status != "fire_at_will"` → Unit darf nicht feuern
- Phase APPROACH setzt `fire_status = "hold_fire"`, Phase ASSAULT → `fire_at_will`, Phase HOLD → `hold_fire`
- Aktuell wird Hold-Fire **immer** respektiert – keine Zufallsbrueche

## Mechanik
- Pro Tick bei `fire_status == "hold_fire"` und Feind in Sicht:
  - Wuerfle: `randf() < DISCIPLINE_BREAK_BASE_CHANCE * (1.0 - discipline)`
  - discipline=1.0 → 0% Bruchwahrscheinlichkeit
  - discipline=0.0 → DISCIPLINE_BREAK_BASE_CHANCE (z.B. 8% pro Tick)
- Bei Bruch: Unit feuert einmal, danach Cooldown bevor naechster Bruch moeglich
- Bruch wird als Event sichtbar gemacht (z.B. "UNIT bricht Feuerstopp!" / "FEUERSTOPP GEBROCHEN!")

## Implementierung
1. `mission_combat_loop_driver.gd`:
   - In `_can_unit_attack()` oder separat: Discipline-Bruch-Check
   - Neues Dictionary `_discipline_break_cooldown: Dictionary` pro Unit
   - Bei Bruch: Effect trotzdem enqueuen, aber Event-Text anzeigen

2. `test_unit.gd`: Getter `get_discipline()` sicherstellen

## Dateien (voraussichtlich betroffen)
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/npc/test_unit.gd` (nur Getter, falls fehlend)

## Akzeptanzkriterien
- [ ] Units mit discipline=1.0 brechen Hold-Fire nie
- [ ] Units mit discipline=0.1 brechen Hold-Fire gelegentlich
- [ ] Bruch hat Cooldown (kein Dauerfeuer trotz Hold)
- [ ] Bruch-Event wird als Text/Label sichtbar
- [ ] Bestehende fire_at_will-Logik bleibt unberuehrt
