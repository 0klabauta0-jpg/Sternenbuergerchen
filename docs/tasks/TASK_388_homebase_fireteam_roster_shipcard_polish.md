# TASK_388 - Homebase Fireteam Roster Shipcard Polish

## Ziel
Homebase soll im Manual-Test-Fluss noch ruhiger und direkter werden: Fireteamkarten in `#10 FIRETEAMS` zeigen keine Editor-/Statusfloskeln mehr, Fireteam-Assign-/Clear-Buttons verschwinden, der Dropship-Pilot kann per Drag & Drop zurueck in `Available Operators`, das Roster wird sortierbar, Missionsslots zaehlen Operatoren plus Piloten sichtbar korrekt, und die Dropship-Karte bekommt wieder einen lokalen Send-Button fuer den Missionsstart.

## Sinnhaftigkeit
Der FOB-Bypass funktioniert nur, wenn die Homebase-UI wie ein Staging-Board wirkt und nicht wie ein Debug-/Editorfenster. Die State-Wahrheit bleibt dabei in den bestehenden Homebase-/Aircraft-/Direct-Payload-Daten; die Aenderungen sind bewusst UI- und Bedienvertrag.

## Umfang
- Homebase-Fireteamkarten blenden Loadout-/Lead-/Members-/Kit-/Payload-/Top-Operator-Hilfstexte aus.
- `Assign` und `Clear` im Fireteam-Fenster werden sichtbar entfernt; Drag & Drop bleibt der primaere Bedienweg.
- Assigned-Pilot-Karten bleiben Drag-Quellen und koennen auf `Available Operators` gedroppt werden, um die Pilotenzuweisung zu loesen.
- `Available Operators` erhaelt eine kompakte Sortierauswahl fuer Leader Score, Tutor Score, Pilot Score, XP und Name.
- Mission-Slot-Anzeige zeigt die echte Nutzung inklusive Piloten, auch wenn die Nutzung ueber dem Limit liegt.
- Dropship-Shipcards bekommen wieder einen lokalen `Send`-Button; `Clear` bleibt entfernt.
- Direct-Homebase-Payloads werden pro Dropship gehalten, damit mehrere Dropships gleichzeitig eigene Fireteamkarten und Boarding-Fuellstand anzeigen.

## Akzeptanz
- Sichtbare Homebase-Fireteamkarten enthalten keine `Loadout`, `Lead`, `Members`, `Kit`, `Payload` oder `Top Operator` Texte.
- Fireteam-Assign-/Clear-Buttons sind nicht sichtbar.
- Ein zugewiesener Dropship-Pilot kann per Drag-Drop auf das Roster zurueckgelegt werden und erscheint wieder unter `Available Operators`.
- Roster-Sortierung kann nach Leader/Tutor/Pilot hoch/niedrig, XP und Name umschalten.
- Bei fuenf Operatoren plus Pilot zeigt der Mission-Brief sechs belegte Slots.
- Der Dropship-Send-Button startet bei Mission-Ziel den Direct-Mission-Start.
- Zwei Dropships koennen parallel je eine Fireteamkarte halten; das erste Dropship wird beim Drop auf das zweite nicht geleert.

## Betroffene Dateien
- `docs/tasks/TASK_388_homebase_fireteam_roster_shipcard_polish.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_388_homebase_fireteam_roster_shipcard_polish.gd`
- bestehende Homebase-Regressionstests, falls deren UI-Erwartung angepasst werden muss.

## Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_388_homebase_fireteam_roster_shipcard_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_387_homebase_flightdeck_payload_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_384_homebase_flightdeck_boarding_hotfix.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_382_homebase_direct_mission_flightdeck_display.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_381_homebase_fireteam_loadout_flightdeck_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_355_homebase_direct_ux_payload_truth.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_347_homebase_direct_staging_start_guard.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_383_homebase_flightdeck_fireteam_card_single_owner.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_386_homebase_flightdeck_member_portraits.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_354_homebase_direct_loadout_regression_matrix.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_349_homebase_direct_staging_real_flightdeck_craft_gate.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Die Sortierwerte nutzen bestehende Profilwerte (`skill_values`, `function_scores`, `platform_values`, `progression`) und fuehren keine neue Charakterwahrheit ein.
- `Tutor Score` ist in diesem Slice ein UI-Ranking aus Coordinator-/Leadership-/Speech-/Discipline-Werten, weil noch kein eigenstaendiger Tutor-Wert existiert.
