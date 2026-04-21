# TASK_095 – Combat Medic Support

## Ziel
Combat-Medic-Units sollen im laufenden Kampf nahe Verbuendete mit niedrigem Vitalstatus
automatisch stabilisieren, statt nur als reiner Archetyp ohne Gameplay-Wirkung zu existieren.

## Status: ERLEDIGT

## Kontext
- `unit_roster_presets.gd` enthaelt bereits den Enemy-Archetyp `Medic`
- `test_unit.gd` unterstuetzt `fit`, `down`, `bleedout` und `respawn`, aber keine Heilung
- `simulation_root.gd` verarbeitet `damage`, `bleedout` und `respawn`, aber noch keinen heal-/stabilize-Effekt
- `mission_combat_loop_driver.gd` hat bereits Kontakt-, Respawn- und Leadership-Logik, aber keine Support-Rollenwirkung

## Mechanik
- Units mit Rolle `Combat Medic` oder einem Rollennamen mit `medic`/`sanitaeter` gelten als Medic
- Ein Medic kann nur supporten, wenn er selbst `fit` ist und kein Support-Cooldown aktiv ist
- Prioritaet der Ziele:
  1. nahe `down`-Verbuendete in Reichweite
  2. sonst stark verletzte `fit`-Verbuendete unter 65% HP
- Support sendet einen autoritativen `heal`-Effect an `SimulationRoot`
- Heal auf `down`-Units hebt sie wieder auf `fit`, solange der Heal vor `bleedout` verarbeitet wird
- Cooldown verhindert permanentes Heilen pro Tick

## Implementierung
1. `simulation_root.gd`
   - neuer `heal`-Effect in `_apply_effect()`
   - `_apply_heal_effect()` mit Team-Guard und `apply_heal()`-Aufruf auf der Unit

2. `test_unit.gd`
   - `apply_heal(amount, heal_context)` ergaenzt
   - `down` -> `fit` Revive bei positivem Heal
   - neues Signal `healed_applied(...)`

3. `mission_combat_loop_driver.gd`
   - Medic-Range, Heal-Amount, Cooldown und Event-Farbe
   - `_try_enqueue_medic_support()` plus Zielwahl fuer downed/wounded Allies
   - Cooldown-Verwaltung und Event-Ausgabe fuer Heal-Events

4. `medic_support_verifier.gd`
   - Heal vor Bleedout
   - Heal-Queue fuer downed Ally
   - Cooldown blockiert Immediate Repeat

## Dateien
- `scripts/core/simulation_root.gd`
- `scripts/npc/test_unit.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/medic_support_verifier.gd`

## Akzeptanzkriterien
- [x] `heal`-Effects werden autoritativ ueber `SimulationRoot` verarbeitet
- [x] Heal auf `down`-Units setzt sie wieder auf `fit`, solange kein Bleedout vorher greift
- [x] Medics waehlen bevorzugt nahe downed Allies, danach stark verwundete Allies
- [x] Support-Cooldown verhindert mehrfaches Heilen in direkt aufeinanderfolgenden Ticks
- [x] Heal-/Patch-Events werden sichtbar gemacht