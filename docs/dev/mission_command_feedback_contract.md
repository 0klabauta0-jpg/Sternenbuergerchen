# Mission Command Feedback Contract

Status: TASK_191

## Zweck
Dieser Vertrag beschreibt, wo Mission-Command-Feedback angezeigt wird und welche Schicht die Wahrheit haelt. UI liest Snapshots und formatiert kurze Statuszeilen; Gameplay-Zustand bleibt bei TacticalController, AreaOrder/Waypoint-Daten und SimulationRoot.

## Datenfluss
1. #16 Command Matrix oder Map-Interaktion erzeugt einen `FireteamWaypoint`, `AreaOrder` oder einen kurzen Ad-hoc-Befehl.
2. `MissionTacticalSandboxController` haelt Auswahl, Planning-State, AreaOrder-Status und aktive Execution-Snapshots.
3. `FireteamMovementController`, `AreaOrderResolver` und `FireteamSecurityController` erzeugen nur Ausfuehrungs-/Sicherungszustand, keine UI-Wahrheit.
4. `TerrainMap3DView` erhaelt `order_visual_payload` und rendert kurze Marker, Linien und Flaechen.
5. #17 Selected Fireteam zeigt Details zum ausgewaehlten Fireteam: Bewegung, Security, Flank, Area-/Waypoint-Fortschritt.
6. #18 Mission Control zeigt Missions-/Ziel-/letzte-Command-Lage und die naechsten erlaubten Schritte.

## Fensterrollen
| Bereich | Rolle | Textregel |
| --- | --- | --- |
| #16 Command Matrix | Kurze Befehle und direkte Buttons | Verb + Zieltyp, keine Erklaertexte. |
| #17 Selected Fireteam | Ausfuehrungsstatus des ausgewaehlten Fireteams | Kompakte Codes plus Area-/Waypoint-Details. |
| #18 Mission Control | Missionslage, Ziel, letzte Aktion, GO/Drop-Kontext | Mehrzeilig, aber kurz und widerspruchsfrei. |
| Mission Map | Weltanker, Flaechen und Fortschrittsmarker | Labels knapp halten, keine Tutorialtexte. |

## Snapshot-Regel
`get_command_feedback_snapshot()` ist der Headless-Pruefpunkt fuer Auswahl, #16/#17/#18-Texte, geplante/visualisierte Waypoints und AreaOrders. `TerrainMap3DView.get_render_snapshot()` spiegelt die selektierten Fireteams ueber `order_selected_fireteam_ids` und den aktiven Order-Phase-Index.

## Grenzen
- Keine neue Area-Semantik.
- Keine zweite UI-seitige Gameplay-Wahrheit.
- Keine langen Weltlabels.
- Enemy-Inspect bleibt vom Friendly-Befehlspfad getrennt.
