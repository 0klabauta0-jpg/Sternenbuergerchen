# TASK_394 - Per Craft Shipcard Commands

## Ziel
Dropships muessen vom Homebase-Boarding bis zum Mission-Drop vollstaendig einzeln bedienbar sein. Boarding, Send, Transit, LZ, Approach und Drop duerfen kein anderes Dropship blockieren oder dessen Payload/LZ ueberschreiben.

## Sinnhaftigkeit
Der Live-Test zeigt, dass der Spieler das System wie einzelne Schiffskarten versteht: Fireteam 1 in Dropship 1, Fireteam 2 in Dropship 2, beide parallel boarden, beide einzeln senden, beide einzeln LZ setzen und droppen. Globale Mission-Control-Befehle machen diese Zuordnung unklar und koennen weiterhin ueber globale Auswahlzustaende kollidieren.

## Umfang
- Homebase-Shipcard-Drops bleiben pro Craft bedienbar, auch wenn ein anderes Dropship noch boardet oder bereits unterwegs ist.
- Shipcard-`Send` startet einen craft-spezifischen Direct-to-Mission-Transfer und laesst andere Dropships weiter bedienbar.
- Mission-Dropshipkarten bekommen eigene kleine `LZ`, `Drop` und Approach-Buttons.
- LZ-Platzierung merkt sich das Ziel-Craft der gedrueckten Dropshipkarte bis zum Map-Klick.
- `Drop` auf einer Dropshipkarte startet nur dieses Craft und blockiert keine andere wartende Dropshipkarte.
- Mission Control `#18` bleibt als Kompatibilitaetscontainer erhalten, blendet die alten Dropship-Befehle aber aus; die sichtbaren Dropship-Befehle sind an die Dropshipkarten gebunden.

## Akzeptanz
- Fireteam 2 kann unmittelbar nach Fireteam 1 in ein anderes Homebase-Dropship gezogen werden, ohne auf Boarding-Abschluss von Fireteam 1 zu warten.
- Sobald ein Dropship fertig geboardet ist, kann sein Shipcard-`Send` gedrueckt werden; die Karte wird grau und zeigt laufenden Transit-Fortschritt statt sofort fertig zu wirken.
- Ein zweites Dropship kann waehrend des ersten Transit-/Mission-Zustands unabhaengig gesendet werden.
- In der Mission kann jedes wartende Dropship auf seiner eigenen Karte LZ/Approach/Drop bedienen.
- Zwei Dropships koennen eigene LZs haben und parallel inbound/deboarding laufen, ohne Payload, LZ oder Progress zu tauschen.

## Betroffene Dateien
- `docs/tasks/TASK_394_per_craft_shipcard_commands.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_394_per_craft_shipcard_commands.gd`

## Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_394_per_craft_shipcard_commands.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_393_direct_dropship_independence_lz_vector.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_392_parallel_boarding_transit_feedback.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_multi_dropship_cards.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_390_homebase_direct_mission_transit_cards.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_180_mission_drop_light_fixed_hud_layout_verifier.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Bestehende globale Mission-Control-Buttons bleiben vorerst als versteckter Kompatibilitaetspfad im Szenenbaum, bis alte Tests/Contracts umgezogen sind.
- Eine vollstaendige Neunutzung von Fenster `#18` ist UI-Polish und folgt nach dem stabilen Craft-Command-Vertrag.
