# TASK_389 - Homebase Card Wide Drop Targets

## Ziel
Homebase Drag & Drop soll im Manual-Test robuster werden: Operatoren koennen in `#10 FIRETEAMS` direkt auf den Fireteam-Kopf oder auf vorhandene Member-Karten gezogen werden, und Fireteam-Karten koennen auf jede sichtbare Flaeche einer Dropship-Karte gezogen werden.

## Sinnhaftigkeit
Der FOB-Bypass lebt davon, dass Karten wie physische Spielsteine funktionieren. Wenn Drop-Ziele nur auf kleinen Teilflaechen reagieren, fuehlt sich das Board fragil an und erzeugt falsche State-Wahrnehmung. Die Aenderung bleibt UI-Input-Glue; Fireteam-, Payload- und Boarding-State bleiben in den bestehenden Homebase-Daten.

## Umfang
- Fireteam-Karten in `#10 FIRETEAMS` bekommen explizite Operator-Drop-Zonen fuer Kopf/Header und Member-Bloecke.
- Drop auf den Fireteam-Kopf fuegt den Operator dem Fireteam hinzu und setzt ihn als Lead.
- Drop auf eine vorhandene Member-Karte oder deren Block fuegt den Operator demselben Fireteam hinzu bzw. verschiebt ihn dorthin.
- Member-Card-Drop-Signale werden mit korrekter Signatur behandelt.
- Dropship-Shipcards akzeptieren Fireteam-Karten auf der ganzen Karte und auf relevanten Kindflaechen, nicht nur auf einzelnen Spezialzonen.

## Akzeptanz
- Ein Operator aus `Available Operators` wird beim Drop auf den Fireteam-Header Mitglied dieses Fireteams und Lead.
- Ein Operator aus `Available Operators` wird beim Drop auf einen vorhandenen Fireteam-Member Mitglied dieses Fireteams.
- Ein Operator, der bereits in einem anderen Fireteam steckt, kann per Drop auf einen Member in das Ziel-Fireteam wechseln.
- Eine Fireteam-Karte kann auf Titel, Pilotbereich, Payloadbereich oder freien Hintergrund einer Dropship-Karte gedroppt werden und landet auf genau diesem Dropship.
- Bestehende Payload-/Boarding- und Single-Owner-Regeln bleiben unveraendert.

## Betroffene Dateien
- `docs/tasks/TASK_389_homebase_card_wide_drop_targets.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/fob_fireteam_card.gd`
- `scripts/meta/homebase_team_drop_panel.gd`
- `scripts/meta/homebase_unit_drop_target.gd`
- `scripts/tests/task_389_homebase_card_wide_drop_targets.gd`

## Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_389_homebase_card_wide_drop_targets.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_388_homebase_fireteam_roster_shipcard_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_387_homebase_flightdeck_payload_polish.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_384_homebase_flightdeck_boarding_hotfix.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_383_homebase_flightdeck_fireteam_card_single_owner.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_381_homebase_fireteam_loadout_flightdeck_polish.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Header-Drop setzt Lead explizit. Falls spaeter eine getrennte "nur adden" vs. "Lead setzen" UI gewuenscht wird, braucht das eine sichtbare Zielmarkierung.
- Die neue Drop-Ziel-Verbreiterung darf keine neue Gameplay-Wahrheit einfuehren; sie ruft nur bestehende Homebase-Zuweisungs- und Payload-Pfade auf.
