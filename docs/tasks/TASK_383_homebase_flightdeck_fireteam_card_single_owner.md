# TASK_383 - Homebase Flightdeck Fireteam Card Single Owner

## Ziel
Wenn ein Fireteam in der Homebase auf eine Dropship-Karte im Flightdeck gezogen wird, soll die sichtbare Fireteam-Karte nicht mehr parallel in `#10 FIRETEAMS` bleiben. Die Karte wandert visuell zum Dropship und zeigt dort wieder den Boarding-/Payload-Fortschritt.

## Sinnhaftigkeit
Das ist sinnvoll, weil Task 382 die Payload direkt auf der Shipcard sichtbar gemacht hat, dabei aber nur eine kompakte Textreihe erzeugte. Fuer die Bedienung ist die Fireteam-Karte selbst die mentale Wahrheit: zuerst in `#10`, dann auf der Dropship-Karte, danach als Payload im Missionsstart.

## Umsetzung
- Homebase blendet Fireteams aus `#10 FIRETEAMS` aus, sobald sie im Homebase-Direct-Flightdeck-Payload liegen.
- Dropship-Shipcards rendern Payload-Fireteams wieder als kompakte `FOBFireteamCard` mit Status, Member-Zeilen und Progressbars.
- Entfernen des Payloads bewegt die Karte wieder zurueck nach `#10`.
- Die Datenwahrheit bleibt der bestehende Homebase-Direct-Staging-State; die UI erzeugt keine zweite Fireteam- oder Boarding-Wahrheit.

Hinweis: TASK_384 erweitert diesen Zustand um zeitbasiertes, sequentielles Boarding pro Operator, Mini-Portraets auf der Dropship-Payload-Karte und kompakte zweispaltige Shipcards.

## Akzeptanz
- Vor dem Dropship-Drop ist die Fireteam-Karte in `#10` sichtbar.
- Nach dem Dropship-Drop ist dieselbe Fireteam-Visual-Wahrheit nur noch am Flightdeck sichtbar.
- Die Dropship-Karte zeigt Member-Fortschritt fuer das geboardete Fireteam.
- Nach Entfernen aus dem Dropship erscheint die Fireteam-Karte wieder in `#10`.

## Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_383_homebase_flightdeck_fireteam_card_single_owner.gd`
- Relevante Homebase-Regressionen fuer Task 355, 381 und 382.
- `git diff --check`
