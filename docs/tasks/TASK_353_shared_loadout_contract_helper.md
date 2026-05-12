# TASK_353 - Shared Loadout Contract Helper

## Ziel
FOB und Homebase sollen denselben Loadout-Contract-Helper fuer `armor`, `weapon_1`, `weapon_2`, Aliasse, Labels und Defaults nutzen.

## Status: GEPLANT

## Problem
Homebase, FOB, `WeaponData` und `LoadoutModifierResolver` normalisieren Waffen und Loadouts aktuell an mehreren Stellen. Die Funktionen sind aehnlich, aber nicht identisch. Beispiele: `rail_gun` / `special`, Default-Waffe `smg` vs. `rifle`, Sekundaerdefault `none` vs. `smg`.

## Ursache
Der Loadout-Contract wurde inkrementell aus FOB heraus aufgebaut und fuer Homebase nachgezogen. Es gibt noch keinen kleinen gemeinsamen Contract-Layer, der UI und Mission auf denselben Wertebereich zwingt.

## Umfang
- Gemeinsamen Helper anlegen oder bestehenden passenden Helper erweitern, z. B. `scripts/meta/loadout_contract.gd` oder ein passender Command-/Core-Contract.
- Zentralisieren:
  - Armor-Normalisierung
  - Weapon-Normalisierung ueber `WeaponData`
  - `make_member_loadout(...)`
  - Option-Listen fuer UI
  - Labels fuer UI
  - Default-Strategie fuer Primary/Secondary
- FOB und Homebase auf den Helper umstellen, ohne grosse UI-Refactors.
- `LoadoutModifierResolver` und `WeaponData` nicht widerspruechlich duplizieren; falls Resolver eigene Balance-IDs braucht, explizit dokumentieren.

## Akzeptanzkriterien
- [ ] FOB und Homebase verwenden dieselbe Normalisierung fuer `armor`, `weapon_1`, `weapon_2`.
- [ ] `rail_gun` / `special` wird bewusst behandelt, nicht still zu `rifle`.
- [ ] UI-Optionen und exportierte Werte sind konsistent.
- [ ] Bestehende Loadout-Verifier bleiben gruen.
- [ ] Neue Tests decken mindestens Alias-Normalisierung und Default-Konsistenz ab.

## Erwartete Dateien
- Neuer oder bestehender Contract-Helper unter `scripts/meta/`, `scripts/core/` oder `scripts/command/`
- `scripts/meta/fob_screen.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/command/loadout_modifier_resolver.gd`, falls Normalisierung dort angepasst wird
- `scripts/tests/task_353_shared_loadout_contract_helper.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_353_shared_loadout_contract_helper.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_350_homebase_loadout_contract_export.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_316_fob_fireteam_staging_migration.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/medic_support_verifier.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Nicht zu gross schneiden: Der Task soll den Contract vereinheitlichen, nicht das ganze Loadout-System neu designen.
- Balance-Defaults koennen Gameplay-Auswirkungen haben; Aenderungen muessen in Tests sichtbar sein.
