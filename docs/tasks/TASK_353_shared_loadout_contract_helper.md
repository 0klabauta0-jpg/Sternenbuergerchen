# TASK_353 - Shared Loadout Contract Helper

## Ziel
FOB und Homebase sollen denselben Loadout-Contract-Helper fuer `armor`, `weapon_1`, `weapon_2`, Aliasse, Labels und Defaults nutzen.

## Status: IMPLEMENTIERT

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

## Umsetzung
- `scripts/command/loadout_contract.gd` ist der gemeinsame Contract fuer Armor-/Weapon-Normalisierung, Member-Loadouts, UI-Optionen, Labels und Defaults.
- FOB und Homebase behalten ihre unterschiedlichen Default-Strategien (`smg/smg` vs. `rifle/none`), beziehen Normalisierung und Optionen aber aus demselben Helper.
- `WeaponData` bleibt der kanonische Weapon-ID-Katalog. `special`/`sonderwaffe`/`support_lmg` normalisieren fuer UI und Export auf `rail_gun`.
- `LoadoutModifierResolver` verwendet den Helper ebenfalls. Nur der Resolver mappt den kanonischen `rail_gun` explizit weiter auf seinen bestehenden internen Balance-Formula-Key `special`, damit alte Modifier-Balance und TASK_107 kompatibel bleiben.

## Akzeptanzkriterien
- [x] FOB und Homebase verwenden dieselbe Normalisierung fuer `armor`, `weapon_1`, `weapon_2`.
- [x] `rail_gun` / `special` wird bewusst behandelt, nicht still zu `rifle`.
- [x] UI-Optionen und exportierte Werte sind konsistent.
- [x] Bestehende Loadout-Verifier bleiben gruen.
- [x] Neue Tests decken mindestens Alias-Normalisierung und Default-Konsistenz ab.

## Erwartete Dateien
- Neuer oder bestehender Contract-Helper unter `scripts/meta/`, `scripts/core/` oder `scripts/command/`
- `scripts/meta/fob_screen.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/command/loadout_modifier_resolver.gd`, falls Normalisierung dort angepasst wird
- `scripts/tests/task_353_shared_loadout_contract_helper.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_353_shared_loadout_contract_helper.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_350_homebase_loadout_contract_export.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_316_fob_fireteam_staging_migration.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/medic_support_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_107_verifier.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Nicht zu gross schneiden: Der Task soll den Contract vereinheitlichen, nicht das ganze Loadout-System neu designen.
- Balance-Defaults bleiben kontextgebunden und getestet. Der einzige bewusst getrennte Wert ist der interne Resolver-Formula-Key `special` fuer den kanonischen `rail_gun`.
