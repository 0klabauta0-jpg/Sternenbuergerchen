# TASK_1051 - Planning State Signal Fanout Guard

## Befund und Aenderung

Ein aktiver Missions-Planning-Update setzte bereits den State am aktiven TacticalController, baute danach aber auch die unsichtbaren Homebase-, FOB- und Map-Screens vollstaendig neu auf. Bei LZ-Setzen kostete das rund 13,2 Sekunden.

Im aktiven Missionskontext aktualisiert der Listener jetzt nur noch die autoritative Planning-State-Kopie, die aktive Mission und den Transporttimer. Meta-Screens werden bei Rueckkehr weiter ueber ihren bestehenden Refresh-Pfad aktualisiert.

## Ergebnis

LZ-Platzierung: rund 13,8 s auf rund 1,0 s. `_emit_planning_state_changed()` liegt bei rund 453 ms. Die LZ-/Drop-/Deboard-Stage schliesst im Trace nach rund 17,5 s ab.

## Grenzen

Keine Aenderung an Planning-Wahrheit, Commands, Simulation oder Multiplayer-Autoritaet. Der Guard betrifft nur unsichtbare Meta-UI-Refreshes waehrend einer aktiven Mission.
