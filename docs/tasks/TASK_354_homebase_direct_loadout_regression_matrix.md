# TASK_354 - Homebase Direct Loadout Regression Matrix

## Ziel
Die Homebase-Direct-Loadout-Kette soll mit einer breiteren Headless-Testmatrix gegen echte Randfaelle abgesichert werden.

## Status: IMPLEMENTIERT

## Problem
`TASK_350` prueft den erfolgreichen Export eines bewusst gesetzten Loadouts, aber noch nicht die kritischen Randfaelle aus dem Review: echte UI-Dropdown-Auswahl, mehrere Fireteams mit nur einem Flightdeck-Payload, unveraenderte Profil-Defaults und Modifier-Aufloesung.

## Ursache
Der erste Verifier war bewusst fokussiert, um den Exportvertrag schnell zu schliessen. Fuer die naechsten Fixes brauchen wir Tests, die Scope, Defaults und Gameplay-Wirkung gemeinsam absichern.

## Umfang
- Neue oder erweiterte Headless-Tests fuer:
  - zwei Fireteams ausgewaehlt, nur eines im Homebase-Dropship
  - Medic bleibt ohne Spieleraktion bei `smg` + `medictool`
  - Auswahl ueber echte `OptionButton`-Callback-/Metadata-Pfade statt nur privatem Setter
  - `MissionSetup.unit_loadout_modifiers_by_unit_id` bzw. `LoadoutModifierResolver` sieht Homebase-Loadouts korrekt
  - FOB-Fallback bleibt isoliert
- Bestehende Task-350-Assertions behalten, aber nicht duplizierend aufblasen.

## Umsetzung
- `scripts/tests/task_354_homebase_direct_loadout_regression_matrix.gd` baut eine Homebase-Direct-Matrix mit zwei Fireteams, einem echten Flightdeck-Payload und einem separat editierten Nicht-Payload-Fireteam.
- Mindestens eine Loadout-Aenderung laeuft ueber echte `OptionButton`-Metadata und das `item_selected`-Signal statt ueber den privaten Homebase-Setter.
- Der Mission-Start prueft `MissionSetup.member_loadouts` und `MissionSetup.get_unit_loadout_modifiers_dict(...)` fuer UI-Override und Medic-Profil-Defaults.
- Ein FOB-Start mit gleichzeitig vorhandenem Homebase-Direct-Payload stellt sicher, dass FOB-Fallback-Loadouts isoliert bleiben.

## Akzeptanzkriterien
- [x] Testmatrix faengt den Payload-Scope-Fehler aus TASK_351 ab.
- [x] Testmatrix faengt den Medictool-Default-Fehler aus TASK_352 ab.
- [x] Mindestens eine UI-nahe Dropdown-Aenderung wird ohne privaten Setter geprueft.
- [x] Loadout-Modifikatoren werden fuer Homebase-Direct mindestens stichprobenartig validiert.
- [x] Tests bleiben schnell genug fuer lokale Headless-Regressionslaeufe.

## Erwartete Dateien
- `scripts/tests/task_354_homebase_direct_loadout_regression_matrix.gd`
- ggf. `scripts/tests/task_350_homebase_loadout_contract_export.gd`
- ggf. kleine Test-Helper in bestehenden Testdateien, falls lokal etabliert

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_354_homebase_direct_loadout_regression_matrix.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_350_homebase_loadout_contract_export.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_351_homebase_direct_payload_scope_contract.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_352_homebase_loadout_defaults_preserve_unit_profiles.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Die Tests sollen Verhalten absichern, nicht interne Private-Helper zementieren.
- Kein Produktcode wurde fuer TASK_354 geaendert. Die Matrix bleibt ein Headless-Verhaltensgate; finale visuelle Dropdown-Balance ist weiter manueller UI-Sichtcheck.
