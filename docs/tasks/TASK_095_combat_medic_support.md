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
- Ein Medic kann nur supporten, wenn er selbst `fit` ist, ein `medictool` in `weapon_1` oder `weapon_2` ausgeruestet hat und kein Support-Cooldown aktiv ist
- Die eigentliche Heal-Reichweite betraegt jetzt genau 2 Kartenfelder
- Prioritaet der Ziele:
  1. nahe `down`-Verbuendete in Reichweite
  2. sonst der am staerksten verletzte `fit`-Verbuendete unter 65% HP
- Liegt das hoechste Prioritaetsziel ausserhalb der Heal-Reichweite, laeuft der Medic aktiv in eine kurze Support-Distanz an
- `medictool` ist im FOB-Loadout-Dropdown waehlbar, belegt wie gewuenscht einen Waffenslot und nutzt visuell das Pistolenmodell in Rot
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
   - Medic-Range, Heal-Amount, Cooldown, Move-Anlauf und Event-Farbe
   - `_try_enqueue_medic_support()` plus slotgebundene Tool-Pruefung, tiefere Zielwahl und Anlauf auf Ziele ausserhalb der Reichweite
   - Cooldown-Verwaltung und Event-Ausgabe fuer Heal-Events

4. `weapon_data.gd`, `fob_screen.gd`, `loadout_modifier_resolver.gd`, `unit_roster_presets.gd`
   - neues `medictool` als loadout-faehiger Slot-Gegenstand
   - Dropdown-/Resolver-Support fuer den neuen Slot-Gegenstand
   - Default-Medic-Presets fuehren das Tool in einem Waffenslot

5. `medic_support_verifier.gd`
   - Dropdown enthaelt `medictool`
   - Heal nur mit `medictool`
   - Medic-Anlauf ausserhalb der Reichweite
   - tiefere Priorisierung bei mehreren verwundeten Zielen

## Dateien
- `scripts/core/simulation_root.gd`
- `scripts/core/weapon_data.gd`
- `scripts/meta/fob_screen.gd`
- `scripts/command/loadout_modifier_resolver.gd`
- `scripts/npc/unit_roster_presets.gd`
- `scripts/npc/test_unit.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/medic_support_verifier.gd`

## Akzeptanzkriterien
- [x] `heal`-Effects werden autoritativ ueber `SimulationRoot` verarbeitet
- [x] Heal auf `down`-Units setzt sie wieder auf `fit`, solange kein Bleedout vorher greift
- [x] Medics waehlen bevorzugt nahe downed Allies, danach stark verwundete Allies
- [x] Medics koennen fuer dringende Ziele ausserhalb der Reichweite aktiv anlaufen
- [x] Heilen setzt jetzt ein im Waffenslot ausgeruestetes `medictool` voraus
- [x] `medictool` ist im FOB-Loadout-Dropdown auswaehlbar
- [x] Support-Cooldown verhindert mehrfaches Heilen in direkt aufeinanderfolgenden Ticks
- [x] Heal-/Patch-Events werden sichtbar gemacht
