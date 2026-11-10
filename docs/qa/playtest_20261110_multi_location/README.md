# AP8 — lang lebende Orte und unabhaengige Reisen

Runtime: bestehender Reiseowner je craft_id, Fleetfassade als Index/Fokusprojektion. Szenenregister nur Lookup; lokale SimulationRoots bleiben zustaendig. Ortscallbacks binden ihre Szene explizit und benutzen deren aktuellen Controllerstate; Wechsel der Ansicht ersetzt keinen Ort. Verborgene HUD-Projektion und SubViewport-Rendering sind aus, Physik und laufende Auftraege bleiben an. Ein neuer Anflug erbt keinen fremden Landeauftrag.

Belege: Fleet-Domain8/0. Echter Zweiortlauf mit groesserem isoliertem Skirmishteam43/0: zwei reale Schiffe, normale Boarding-/Launch-/Quantum-/Anflug-/LZ-Befehle; Satellit A, Handel B, A-B-A erhaelt Szenen und aktuelle Positionen; Hintergrundticks laufen, A kehrt physisch heim, B bleibt. Nur der bestehende Skirmish-Boarding-Testhelper kuerzt die getrennte Basisvorbereitung ab. Kampagnen-Zweiausflug mit echten beiden NPCs und zweimal Continue152/0. Originale Zwei-Personen-Kampagne unveraendert.

Gleicher-Ort-Variante43/0: beide Schiffe teilen eine Szene; zweite Landung auf belegtem Schiff abgelehnt, anderer freier Ort akzeptiert. Eintritt neuer Personen erhaelt bereits aktive Units und deren State. Vorherige Fehler: fremdes drop_ship_requested/LZ wurde uebernommen (behoben); erster Positionsvergleich fror versehentlich legitime Sicherungsbewegung ueber eine ganze Reise ein (jetzt unmittelbar um die Sichtwechsel gemessen).

Nativer D3D12-Lauf,1920x1080, gleiche reale Zweiortroute43/0 ohne Enginefehler. Je30s nach Laden, mit leichter Kamerabewegung an Missionsorten:

| Geladene Orte | Samples | Frame-P95 ms | P99 ms | Max ms | Godot static MB |
|---|---:|---:|---:|---:|---:|
| Basis |1958|27.283|46.104|238.167|687.1|
| Basis+Satellit |5588|10.539|22.599|579.739|793.6|
| Basis+Satellit+Handel |4708|12.913|25.852|431.821|844.9|

Das sind bounded Messungen auf diesem Desktop, kein Last-/Release-PASS: Spitzen und Kaltstart bleiben sichtbar, Basisphase ist nicht shaderwarm mit spaeteren Phasen vergleichbar. Eine Ansicht rendert; weitere Orte behalten ihren laufenden lokalen Tick. Rohlogs/world-native und Bilder/native-world unter output/playtest_20261110. Native Bilder zeigten ausserdem zu weiten Startzoom und fehlendes Handelsensemble; gezielter AP5-Nachtrag folgt vor AP9.

Checkpointentscheidung: get_world_checkpoint_guard beruecksichtigt alle Reisen. Waehrend irgendein Schiff auswaerts ist, wird kein scheinbarer Basischeckpoint geschrieben; die Kampagnenhilfe zeigt den Grund. Auch eine Mehrschiffflotte an der Basis bleibt bis zum vollstaendigen Flottencheckpoint explizit gesperrt (alter Serializer speichert genau ein Schiff). Bestehender letzter Save wird nicht geloescht oder ueberschrieben. Kein Multiplayer-/PvP-Fertigversprechen.
