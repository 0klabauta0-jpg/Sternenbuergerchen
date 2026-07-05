# BUGFIX - Singleplayer Release Homebase Start Bootstrap

## Ziel / Problem
Im exportierten Release landet `Einzelspieler` in der Homebase-/FOB-Transfer-Vorbereitung, ohne dass ein spielbarer Startzustand garantiert ist. Wenn lokaler Roster, Dropship, Pilot oder Boarding fehlen, zeigt die Readiness mehrere `STOP`-Zustaende und der Spieler kann nicht sinnvoll fortfahren.

## Ursache
Der Testpfad setzt Roster, Fireteam, Dropship und Pilot in den Verifiern explizit. Der echte Singleplayer-Start verlaesst sich dagegen auf vorhandene Runtime-/Save-Daten und initialisiert keine spielbare Standard-Mission, wenn diese Daten leer oder unvollstaendig sind.

## Umfang
- Lokalen Singleplayer-Erststart mit Default-Roster absichern.
- Ein Default-Dropship mit Pilot auf Homebase bereitstellen.
- Ein kleines Default-Fireteam als Homebase-direct Payload vormerken.
- Boarding fuer diesen Bootstrap als fertig markieren, damit `Start` sofort nutzbar ist.

## Nicht-Ziele
- Kein neues Missionssystem.
- Kein Combat- oder Dropship-Rewrite.
- Keine UI als neue Gameplay-Wahrheit; die Meta-Flow-Schicht erzeugt den Startzustand, die Homebase zeigt ihn nur an.

## Akzeptanzkriterien
- `meta_layer_test.tscn` startet im Singleplayer mit Roster, Fireteam, Dropship und Pilot.
- `HomebaseScreen.can_request_mission_start(craft_id)` ist fuer das Bootstrap-Dropship wahr.
- Der bestehende Homebase-to-Mission-Handoff bleibt gruen.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`

## Lokale Pruefung
- `godot --headless --script res://scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `godot --headless --script res://scripts/tests/task_538_homebase_to_mission_launch_handoff_smoke.gd`

## Risiken / offene Punkte
- Der Bootstrap ist bewusst klein und nur fuer einen leeren lokalen Singleplayer-Start gedacht. Spaeter sollte daraus ein klareres Kampagnen-/Briefing-Setup werden.
