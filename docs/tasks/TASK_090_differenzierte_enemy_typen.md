# TASK_090 – Differenzierte Enemy-Typen

## Ziel
Statt eines einzigen `ENEMY_DEFAULT_PRESET` werden 6 verschiedene Enemy-Archetypen eingefuehrt,
jeweils mit unterschiedlichen Skill-Werten, Waffen und Traits.

## Status: ERLEDIGT

## Kontext
- `unit_roster_presets.gd` hat aktuell nur `ENEMY_DEFAULT_PRESET` (accuracy=0.4, speed=0.3, leadership=0.2, toughness=0.5)
- Alle Gegner in `get_preset()` bekommen identische Stats via `team_bravo`-Fallback
- `weapon_data.gd` (TASK_086) liefert drei Waffentypen: smg, rifle, rail_gun
- `test_unit.gd` unterstuetzt bereits awareness, recognition, stealth, discipline

## Enemy-Archetypen
| Typ       | Accuracy | Speed | Toughness | Leadership | Waffe     | Besonderheit |
|-----------|----------|-------|-----------|------------|-----------|-------------|
| Standard  | 0.40     | 0.35  | 0.50      | 0.10       | rifle     | Ausgewogen  |
| Scout     | 0.30     | 0.60  | 0.30      | 0.05       | smg       | Schnell, fragil |
| Heavy     | 0.35     | 0.20  | 0.80      | 0.10       | rail_gun  | Langsam, zaeh |
| Sniper    | 0.70     | 0.15  | 0.30      | 0.05       | rifle     | Hohe Accuracy, langsam |
| Medic     | 0.25     | 0.40  | 0.40      | 0.15       | smg       | Niedrige Accuracy |
| Officer   | 0.45     | 0.30  | 0.50      | 0.60       | rifle     | Hohe Leadership |

## Implementierung
1. `unit_roster_presets.gd`:
   - 6 Enemy-Preset-Dictionaries als Konstanten
   - Mapping von Enemy-Slot-Index oder Unit-ID zu Archetyp
   - `get_preset()` waehlt Archetyp basierend auf Unit-ID-Suffix oder konfigurierbar

2. `mission_test_setup.gd`:
   - Enemy-Units erhalten unterschiedliche Presets statt des einheitlichen Fallbacks
   - Verteilung z.B. nach Slot: Slot 1-2 Standard, Slot 3 Scout, Slot 4 Heavy, etc.

## Dateien (voraussichtlich betroffen)
- `scripts/npc/unit_roster_presets.gd`
- `scripts/tests/mission_test_setup.gd` (ggf.)

## Akzeptanzkriterien
- [ ] Mindestens 6 verschiedene Enemy-Presets vorhanden
- [ ] Gegner in der Mission haben unterschiedliche Stats und Waffen
- [ ] Bestehende Preset-Logik fuer Friendlies bleibt unberuehrt
- [ ] Headless-Verifier bestaetigt unterschiedliche Stats auf Enemy-Units
