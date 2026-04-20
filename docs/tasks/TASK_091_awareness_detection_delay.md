# TASK_091 – Awareness: Detection-Delay

## Ziel
Der `awareness`-Wert einer Unit bestimmt, wie schnell sie feindliche Kontakte erkennt.
Hohe Awareness → sofortige Erkennung; niedrige Awareness → verzoegertes Engagement.

## Status: ERLEDIGT

## Kontext
- `test_unit.gd` hat `awareness` als Export (0.0–1.0, Default 0.5)
- Kontakterkennung geschieht aktuell sofort in `_find_first_contact_pair()` (`mission_combat_loop_driver.gd`, Zeile ~488)
- `_can_unit_attack()` prueft vital_state und fire_status, aber **keine Wahrnehmungsverzoegerung**
- LOS-Check via `_los_system.has_line_of_sight_between_nodes()` ist rein geometrisch

## Mechanik
- Wenn eine Unit zum ersten Mal eine feindliche Unit im LOS/Range sieht, beginnt ein Detection-Timer
- Detection-Delay = `(1.0 - awareness) * MAX_DETECTION_DELAY_TICKS`
  - awareness=1.0 → 0 Ticks Delay (sofort)
  - awareness=0.0 → MAX_DETECTION_DELAY_TICKS (z.B. 15 Ticks)
- Erst nach Ablauf des Timers kann die Unit angreifen
- Timer wird pro Attacker-Target-Paar getrackt
- Timer wird zurueckgesetzt wenn Sichtkontakt verloren geht

## Implementierung
1. `mission_combat_loop_driver.gd`:
   - Neues Dictionary `_detection_progress: Dictionary` (key: "attacker_id:target_id", value: remaining_ticks)
   - In `_can_unit_attack()` oder `_find_first_contact_pair()`: Detection-Delay pruefen
   - Pro Tick: Detection-Zaehler fuer aktive Sichtpaare dekrementieren
   - Sichtpaare ohne LOS zuruecksetzen

2. `test_unit.gd`: Getter `get_awareness()` (existiert vermutlich bereits)

## Dateien (voraussichtlich betroffen)
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/npc/test_unit.gd` (nur Getter, falls fehlend)

## Akzeptanzkriterien
- [ ] Units mit awareness=1.0 greifen sofort an (keine Regression)
- [ ] Units mit awareness=0.2 haben messbaren Delay vor erstem Schuss
- [ ] Detection-Timer wird pro Paar getrackt und bei Sichtverlust zurueckgesetzt
- [ ] Headless-Verifier bestaetigt unterschiedliche Engagement-Timings
