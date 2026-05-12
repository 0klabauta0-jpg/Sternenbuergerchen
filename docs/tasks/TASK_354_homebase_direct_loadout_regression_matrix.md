# TASK_354 - Homebase Direct Loadout Regression Matrix

## Ziel
Die Homebase-Direct-Loadout-Kette soll mit einer breiteren Headless-Testmatrix gegen echte Randfaelle abgesichert werden.

## Status: GEPLANT

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

## Akzeptanzkriterien
- [ ] Testmatrix faengt den Payload-Scope-Fehler aus TASK_351 ab.
- [ ] Testmatrix faengt den Medictool-Default-Fehler aus TASK_352 ab.
- [ ] Mindestens eine UI-nahe Dropdown-Aenderung wird ohne privaten Setter geprueft.
- [ ] Loadout-Modifikatoren werden fuer Homebase-Direct mindestens stichprobenartig validiert.
- [ ] Tests bleiben schnell genug fuer lokale Headless-Regressionslaeufe.

## Erwartete Dateien
- `scripts/tests/task_354_homebase_direct_loadout_regression_matrix.gd`
- ggf. `scripts/tests/task_350_homebase_loadout_contract_export.gd`
- ggf. kleine Test-Helper in bestehenden Testdateien, falls lokal etabliert

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_354_homebase_direct_loadout_regression_matrix.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_350_homebase_loadout_contract_export.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_351_homebase_direct_payload_scope_contract.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_352_homebase_loadout_defaults_preserve_unit_profiles.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Die Tests sollen Verhalten absichern, nicht interne Private-Helper zementieren.
- Falls TASK_351/352 vorher noch nicht implementiert sind, darf dieser Task als Test-first-Vorbereitung bewusst rot starten, muss aber am Ende gruen dokumentiert werden.
