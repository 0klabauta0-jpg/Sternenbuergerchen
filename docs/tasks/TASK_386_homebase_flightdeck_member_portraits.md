# TASK_386 - Homebase Flightdeck Member Portraits

## Ziel
Die Fireteam-Karte im Homebase-Flightdeck-Dropship soll die Mini-Portraets direkt links neben den Operator-Namen zeigen, statt als separate Portrait-Leiste ueber den Namen.

## Sinnhaftigkeit
Der Wunsch ist sinnvoll, weil die Dropship-Payload-Karte im Manual Test dichter und schneller lesbar sein soll. Die Operator-Zeile verbindet Portrait, Name, Boarding-Status und Fortschritt dann direkt miteinander.

## Umfang
- Separate Portrait-Leiste in Dropship-Payload-Fireteamkarten entfernen.
- Pro Boarding-Member-Zeile ein kleines Portrait direkt vor dem Namen rendern.
- Bestehende Payload-/Boarding-Metadaten erhalten, damit die vorhandenen Verifier weiter greifen.

## Akzeptanz
- Jede Payload-Member-Zeile hat genau ein Mini-Portraet links vom Namen.
- Die Payload-Karte zeigt weiterhin ein Mini-Portraet pro Operator.
- Es gibt keine separate Portrait-Leiste ueber den Namen.
- Boarding-Progress, Status und bestehende Flightdeck-Regressionen bleiben unveraendert funktionsfaehig.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_386_homebase_flightdeck_member_portraits.gd`

## Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_386_homebase_flightdeck_member_portraits.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_384_homebase_flightdeck_boarding_hotfix.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_383_homebase_flightdeck_fireteam_card_single_owner.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_382_homebase_direct_mission_flightdeck_display.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Der Headless-Test prueft Struktur und Clipping-Vertrag, nicht die finale optische Balance. Ein manueller FullHD-Sichtcheck bleibt fuer Abstand, Cropping und Portraetgroesse sinnvoll.
