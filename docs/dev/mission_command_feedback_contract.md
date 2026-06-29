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

## Insertion-/First-Order-Readability
`get_mission_insertion_first_order_readability_snapshot()` ist der Headless-Pruefpunkt fuer den ersten spielbaren Missionsmoment nach dem Homebase-Launch. Der Snapshot darf nur bestehende Planning-, Dropship-Karten-, Command-Feedback- und Render-Snapshots zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Commands enqueuen. Erwartete Lesbarkeit: Dropship-Payload vorhanden, Card sichtbar, LZ-Zustand sichtbar, Drop ohne LZ blockiert, ausgewaehltes Fireteam sichtbar, erste Order-Kontrollen vorhanden, und nach LZ-Setzung ein sichtbarer LZ-Marker plus bereiter Drop-Button.

## First-Move-Decision-Readability
`get_mission_first_move_decision_readability_snapshot()` ist der Headless-Pruefpunkt fuer die erste Move-/GO-Entscheidung nach dem Deboarding. Der Snapshot darf nur bestehende Selection-, Deploy-, Command-Feedback-, Waypoint-Intent- und Visualizer-Snapshots zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf GO nicht ausfuehren. Erwartete Lesbarkeit: ausgewaehltes Fireteam ist deployed und runtime-aktiv, geplante Waypoints existieren, Waypoint-Intent-Preview und visualisierte Waypoints sind vorhanden, und GO ist fuer die geplante Order bereit.

## First-Move-Execution-Feedback
`get_mission_first_move_execution_feedback_snapshot()` ist der Headless-Pruefpunkt fuer die erste laufende Move-Ausfuehrung nach GO. Der Snapshot darf nur bestehende Command-Feedback-, Phase-Execution-, Movement-, OrderPlan- und Visualizer-Snapshots zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Commands enqueuen. Erwartete Lesbarkeit: GO wurde ueber `execute_selected_fireteam_orders()` angenommen, das ausgewaehlte Fireteam hat einen aktiven Execution-State, der Movement-State zeigt Ziel/Progress-/Readability-Daten, und das sichtbare Feedback benennt laufende oder angenommene Ausfuehrung.

## First-Contact-Readability
`get_mission_first_contact_readability_snapshot()` ist der Headless-Pruefpunkt fuer den ersten taktisch relevanten Feindkontakt nach Bewegung. Der Snapshot darf nur bestehende Contact-, FireteamContact-, Command-Feedback-, Tactical-Communication-/Eventlog-, Cover-, Security-, LOS-/Heatmap- und Render-Snapshots zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Kontakte erzeugen oder Commands enqueuen. Erwartete Lesbarkeit: ausgewaehltes Fireteam hat mindestens einen Contact-Eintrag mit Detection-State, Position, Confidence und Report-Text; Overlay/Primary3D spiegelt Kontakte; und Feedback/Eventlog oder Security/Cover-Kontext zeigt, warum der Kontakt taktisch relevant ist.

## Grenzen
- Keine neue Area-Semantik.
- Keine zweite UI-seitige Gameplay-Wahrheit.
- Keine langen Weltlabels.
- Enemy-Inspect bleibt vom Friendly-Befehlspfad getrennt.
