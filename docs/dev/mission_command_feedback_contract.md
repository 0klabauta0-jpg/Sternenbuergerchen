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

## First-Engagement-Feedback
`get_mission_first_engagement_feedback_snapshot()` ist der Headless-Pruefpunkt fuer die erste Combat-Entscheidung nach dem ersten Kontakt. Der Snapshot darf nur bestehende FireEvent-, ContactDecision-, Cover-, Security-, Command-Feedback-, Tactical-Communication- und Render-Snapshots zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Damage-/Fire-Entscheidung selbst erzeugen. Erwartete Lesbarkeit: Bei `fired` sind Angreifer, Ziel, Waffe, FireEvent und Range-/LOS-/Cover-Kontext sichtbar; bei `waiting` oder `blocked` sind Cooldown, Blockgrund oder Kandidat sichtbar; Mission-Control-/Command-Feedback benennt die Entscheidung kurz.

## Fire-/Cover-Visual-Polish
`get_mission_fire_cover_visual_polish_snapshot()` ist der Headless-Pruefpunkt fuer die sichtbare Fire-/Cover-Lesbarkeit nach der ersten Combat-Entscheidung. Der Snapshot darf nur den bestehenden First-Engagement-Snapshot und `TerrainMap3DView.get_render_snapshot()` zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine FireEvents, Damage-Events oder Befehle erzeugen. Erwartete Lesbarkeit: FireTrace ist sichtbar und duenn, Impact hat Ziel-Fokus plus kurzes Statuslabel, Unit-Badges liefern Text/Farbe/Style, und Range-/LOS-/Cover-Kontext bleibt weiter erreichbar.

## Fire-/Cover-Integrated-Flow
`task_545_mission_fire_cover_integrated_flow_smoke.gd` prueft denselben Fire-/Cover-Visual-Polish-Snapshot im echten ersten Spielerpfad von Homebase ueber Dropship, LZ, Deboarding, Move, Contact und Engagement. Der Smoke darf nur bestehende Test-Hilfswege nutzen, keine neue Gameplay-Entscheidung einfuehren und keinen manuellen F6-/Screenshot-Sichttest behaupten.

## Combat-HUD-Density
`get_mission_combat_feedback_hud_density_snapshot()` ist der Headless-Pruefpunkt fuer kompaktere Combat-Feedback-Zeilen in #17 Selected Fireteam und #18 Mission Control. Der Snapshot darf nur bestehende ContactDecision-, Cover- und FireEvent-Snapshots zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine FireEvents, Damage-Events, Befehle oder Kontaktentscheidungen erzeugen. Erwartete Lesbarkeit: Eine kurze Zeile benennt FIRE, WAIT, NO FIRE oder CONTACT und behaelt Cover, LOS und Range als kompakte Tokens sichtbar. Die Zeile muss in Mission Control und Selected Fireteam auftauchen und innerhalb des HUD-Zeichenbudgets bleiben.

## Multi-Fireteam-Combat-HUD-Consistency
`get_multi_fireteam_combat_hud_consistency_snapshot()` ist der Headless-Pruefpunkt fuer TASK_547. Der Snapshot darf nur den bestehenden Combat-HUD-Density-Snapshot, Fireteam-Statuskarten und Mission-Dropship-Cards zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Dropship-, Combat-, Damage- oder Selection-Entscheidung erzeugen. Erwartete Lesbarkeit: mindestens zwei Fireteams bleiben als Auswahl sichtbar, mindestens zwei Dropship-Cards bleiben eindeutig, die Dropship-Payload-Fireteams passen zur Auswahl, und die kompakte Combat-Zeile erscheint weiterhin in #17 und #18.

## Combat-HUD-Detail-Tooltip
`get_combat_hud_visual_detail_tooltip_snapshot()` ist der Headless-Pruefpunkt fuer TASK_548. Der Snapshot darf nur bestehende Combat-HUD-Density-, ContactDecision-, Cover- und FireEvent-Daten sowie die Label-Tooltips von #17 Selected Fireteam und #18 Mission Control zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Combat-, Damage-, Contact- oder UI-State-Entscheidung erzeugen. Erwartete Lesbarkeit: Die kompakte HUD-Zeile bleibt kurz, waehrend beide HUD-Panels denselben kurzen Detail-Tooltip mit Fire-State, Cover, Range, LOS und Flank-Kontext erhalten.

## Combat-HUD-F6-Visual-Audit
`get_combat_hud_f6_visual_audit_snapshot()` ist der Headless-Pruefpunkt fuer TASK_549. Der Snapshot darf nur den TASK_548-Tooltip-Snapshot, Control-/Label-Bounds und HUD-Layout-Metadaten zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Combat-, Damage-, Contact-, Movement- oder UI-State-Entscheidung erzeugen. Erwartete Lesbarkeit: #17 und #18 haben sichtbare, hover-faehige Combat-HUD-Labels, dieselbe Tooltip-Payload, FullHD-konforme Panel-/Tooltip-Bounds und keine Ueberlappung zwischen Selected-Fireteam- und Mission-Control-Panel. Ein manueller Screenshot bleibt als separater Sichttest markiert.

## Combat-HUD-Manual-Screenshot-Notes
TASK_550 nutzt den laufenden HTML-Zwischenbericht als manuelle Sichttest-Workbench fuer Combat-HUD-Tooltip und Panel-Lesbarkeit. Der Bericht darf Screenshotpfad, Viewport, Hover-Ergebnis, Stilnotizen und Follow-up-Entscheidungen exportieren, aber keine Runtime- oder Gameplay-Wahrheit speichern. Erwartete Struktur: exportierbare `combat_hud_manual.*` Controls, eine freie `notes.combat_hud_manual_review`-Notiz und eine klare Markierung, dass der manuelle Screenshot erst durch den User/Playtest bestaetigt wird.

## Combat-HUD-Tooltip-Style
TASK_551 erweitert den bestehenden Combat-HUD-Tooltip-Label-Contract um eine dezente visuelle Hover-Affordance. #17 Selected Fireteam und #18 Mission Control muessen dieselbe `combat_hud_tooltip_style_id` tragen, hoverbar bleiben, Text clippen und ihre Style-Metadaten im `get_combat_hud_f6_visual_audit_snapshot()` read-only melden. Der Style darf nur vorhandene HUD-Labels markieren; er erzeugt kein neues Tooltip-System und keine Combat-/Contact-/Gameplay-Wahrheit.

## Mission-Objective-Interaction-Readability
`get_mission_objective_interaction_readability_snapshot()` ist der Headless-Pruefpunkt fuer TASK_552. Der Snapshot darf nur bestehende `ObjectiveStatus`-, `MissionScenarioRuntimeGates`-, Command-Feedback- und `TerrainMap3DView`-Snapshots zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Objective-, Cargo-, Combat- oder Command-Entscheidung erzeugen. Erwartete Lesbarkeit: Mission Control zeigt eine kompakte `AA | COM | OBJ`-Zeile, das ausgewaehlte Tile zeigt auf das Objective, der Take-Control-Anker bleibt sichtbar, der Computer-Hold nennt Status und Haltezeit, und der Primary-3D-Objective-Ring spiegelt denselben Capture-Fortschritt.

## Mission-Cargo-Extract-Readability
`get_mission_cargo_extract_readability_snapshot()` ist der Headless-Pruefpunkt fuer TASK_553. Der Snapshot darf nur bestehende `MissionCargoTouchdownBridge`-, `MissionScenarioRuntimeGates`-, Command-Feedback- und `TerrainMap3DView`-Snapshots zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Cargo-, Objective-, Combat- oder Command-Entscheidung erzeugen. Erwartete Lesbarkeit: Mission Control zeigt eine kompakte `CARGO ...`-Zeile fuer blocked/inbound/hold/ready/departing/departed, der Cargo-Hold-Fortschritt bleibt vom Completion-State getrennt, Primary3D spiegelt den aktiven Cargo-Zustand, und `departed` komplettiert CargoBridge plus Scenario-Gate konsistent.

## Frontier-Probe-Integrated-Objective-Playthrough
`get_frontier_probe_integrated_objective_playthrough_snapshot()` ist der Headless-Pruefpunkt fuer TASK_554. Der Snapshot darf nur bestehende TASK_552-/TASK_553-Snapshots, `MissionScenarioRuntimeGates`, Command-Feedback und `TerrainMap3DView` zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Objective-, Cargo-, Combat-, Team- oder Command-Entscheidung erzeugen. Erwartete Lesbarkeit: AA, Computer und Cargo-Gates sind im finalen Zustand gemeinsam komplett; Mission Control zeigt AA/COM/OBJ und CARGO im selben Statusbild; Cargo `ready` komplettiert noch nicht, `departed` komplettiert CargoBridge plus Runtime-Gates; Primary3D behaelt Objective-Status sichtbar und entfernt aktive Cargo-Visuals nach Departure.

## Frontier-Probe-Multiplayer-Objective-Ownership
`get_frontier_probe_multiplayer_objective_ownership_snapshot()` ist der Headless-Pruefpunkt fuer TASK_555. Der Snapshot darf nur den integrierten TASK_554-Snapshot, `MissionMultiplayerTeamOwnershipContract`, `MissionTeamChipPresenter` und die Frontier-Probe-Scenario-Daten zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Peer-, Team-, Objective-, Cargo-, Combat- oder Command-Entscheidung erzeugen. Erwartete Lesbarkeit: Alpha bleibt player-assignable attacker auf `spawn_alpha`; Bravo bleibt solo/coop NPC-defender auf `spawn_bravo`, ist aber in PvP Peer 2 zuweisbar; Mission-Team-Chip nennt beide Owner und Spawnmarker; Computer- und Cargo-Gates gehoeren zum Alpha-Pfad; die Bravo-Air-Defense-Gruppe besitzt die AA-Bedrohung.

## Frontier-Probe-Host-Client-Objective-Handoff
`FrontierProbeHostClientHandoffContract.build_snapshot()` ist der Headless-Pruefpunkt fuer TASK_556. Der Contract darf nur bestehende `MultiplayerSession`-Assignments, `SimulationRoot`-Network-Command-Ergebnisse, TASK_555-Ownership und `MultiplayerSnapshotContract`-Apply-Daten bewerten. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Session, Peer-, Objective-, Cargo-, Combat- oder Command-Entscheidung ausloesen. Erwartete Lesbarkeit: Host Peer 1 bleibt Alpha, Peer 2 bleibt Bravo, Peer 2 darf Bravo-Befehle serverseitig einreichen, Peer 2 darf Alpha nicht kommandieren, State-Mutations bleiben abgelehnt, und der Client akzeptiert Objective-/MissionResult-Snapshotdaten aus dem Serverzustand.

## Frontier-Probe-Multiplayer-F6-Readability
`get_frontier_probe_multiplayer_f6_readability_snapshot()` ist der Headless-Pruefpunkt fuer TASK_557. Der Snapshot darf nur TASK_555-Ownership, relevante TASK_549-F6-Layoutchecks, `get_command_feedback_snapshot()` und vorhandene Control-Bounds zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Peer-, Objective-, Cargo-, Combat-, Command- oder UI-State-Entscheidung ausloesen. Erwartete Lesbarkeit: Mission-Team-Chip ist sichtbar und nennt Host Peer 1, Peer 2, `spawn_alpha` und `spawn_bravo`; Mission Control zeigt AA/COM/OBJ/CARGO; Selected Fireteam zeigt den gewaehlten Fireteam-Kontext; und Teamchip, Mission Control sowie Selected Fireteam bleiben im FullHD-Missionslayout ohne kritische Ueberlappung lesbar.

## Frontier-Probe-Multiplayer-Manual-Screenshot-Notes
TASK_558 nutzt den laufenden HTML-Zwischenbericht als manuelle Sichttest-Workbench fuer den Frontier-Probe-MP-F6-Blick. Der Bericht darf Screenshotpfad, Viewport, Host/Client-Kontext, Teamchip-Lesbarkeit, Objective-/Cargo-Lesbarkeit, Selected-Fireteam-Kontext, Panel-Ueberlappung, Hover-/Stilnotizen und Follow-up-Entscheidungen exportieren, aber keine Runtime-, Peer-, Objective-, Cargo-, Combat- oder Gameplay-Wahrheit speichern. Erwartete Struktur: exportierbare `mp_f6_manual.*` Controls, eine freie `notes.mp_f6_manual_review`-Notiz und eine klare Markierung, dass der manuelle Screenshot erst durch User/Playtest bestaetigt wird.

## Frontier-Probe-Multiplayer-Teamchip-Tooltip-Polish
`get_frontier_probe_multiplayer_teamchip_tooltip_snapshot()` ist der Headless-Pruefpunkt fuer TASK_560. Der Snapshot darf nur den TASK_557-F6-Readability-Snapshot, `MissionTeamChipPresenter`, `get_command_feedback_snapshot()` und die vorhandenen Label-Metadaten zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Peer-, Team-, Objective-, Cargo-, Combat-, Command- oder Gameplay-Entscheidung ausloesen. Erwartete Lesbarkeit: Der sichtbare Mission-Teamchip bleibt kurz, waehrend der Tooltip Host Peer 1, Peer 2, `spawn_alpha` und `spawn_bravo` nennt; das Label ist hoverbar, traegt eine stabile Tooltip-Style-ID und bleibt read-only.

## Frontier-Probe-Multiplayer-Manual-Visual-Review-Guide
TASK_561 erweitert den laufenden HTML-Zwischenbericht um eine gefuehrte MP-F6-Sichtpruefung. Der Bericht darf Detailchecks, Ratings und eine naechste Polish-Prioritaet fuer Teamchip-Hover, Objective/Cargo, Selected Fireteam, Dropship-/Panel-Dichte und Weltverdeckung exportieren, aber keine Runtime-, Peer-, Objective-, Cargo-, Combat-, Command- oder Gameplay-Wahrheit speichern. Erwartete Struktur: exportierbare `mp_f6_manual.*` Detailfelder, `mp_f6_manual.next_polish_priority`, die freie `notes.mp_f6_manual_review`-Notiz und eine klare Markierung, dass der echte Screenshot-/Hover-Test erst durch User/Playtest bestaetigt wird.

## Frontier-Probe-Multiplayer-F6-Visual-Evidence-Capture
TASK_562 erzeugt eine reproduzierbare MP-F6-Visual-Evidence-Basis fuer den Frontier-Probe-Slice. Der Capture-Smoke darf den bestehenden FullHD-F6-Testzustand, TASK_557-Readability, TASK_560-Teamchip-Tooltip und ein lokales PNG/JSON-Manifest unter `tmp/` zusammenfassen, aber keine Runtime-, Peer-, Objective-, Cargo-, Combat-, Command- oder Gameplay-Wahrheit speichern. Erwartete Struktur: `tmp/frontier_probe_mp_f6_visual_evidence.png`, `tmp/frontier_probe_mp_f6_visual_evidence.json`, Readability-/Tooltip-Gates, ein Readback-/Evidence-Board-Flag und eine klare Markierung, dass der echte manuelle Review weiterhin offen ist.

## Frontier-Probe-Multiplayer-F6-Evidence-Report-Preview
TASK_563 macht die TASK_562-Artefakte im laufenden HTML-Zwischenbericht sichtbar. Der Bericht darf das lokale PNG referenzieren und PNG-/Manifest-Pfade, Viewport, Readability-/Tooltip-Gates, Viewport-Readback-Status, Evidence-Board-Status und manuellen Review-Status exportieren. Er darf keine Runtime-, Peer-, Objective-, Cargo-, Combat-, Command- oder Gameplay-Wahrheit speichern und darf den menschlichen F6-/Hover-Test nicht als erledigt markieren. TASK_564 poliert danach die Evidence-Lesbarkeit; der naechste echte Sichtreview-Slice ist TASK_565.

## Frontier-Probe-Multiplayer-Apply-Visual-Polish-Findings
TASK_564 darf nur belegte visuelle Reibung aus TASK_562/TASK_563 anwenden. Der aktuelle belegte Befund ist das zu kontextarme Headless-Evidence-Board. Zulaessig sind deshalb Region-Outlines, Raster, Swatch-Leiste, Manifest-Regionen und HTML-Legende fuer Review-Lesbarkeit. TASK_564 darf keine Runtime-, Peer-, Objective-, Cargo-, Combat-, Command- oder Gameplay-Wahrheit speichern und darf den menschlichen F6-/Hover-Test nicht als erledigt markieren. Der naechste echte Sichtreview-Slice ist TASK_565.

## Frontier-Probe-Multiplayer-Real-F6-Screenshot-Review
TASK_565 nutzt einen echten nicht-headless Viewport-Readback aus TASK_562 als belegbaren F6-Sichtbefund. Der Screenshot darf UI-Widersprueche, Paneldichte und Hover-Kandidaten fuer den laufenden HTML-Zwischenbericht markieren, aber keine Runtime-, Peer-, Objective-, Cargo-, Combat-, Command- oder Gameplay-Wahrheit speichern. Der belegte Fix ist der #17-Selected-Fireteam-Widerspruch: Statuszeile und sichtbare Member-Cards muessen denselben read-only Fireteam-Unit-Fallback verwenden, damit bei sichtbaren Karten nicht `keine Einheiten aktiv` steht. Der echte Hover-/Panel-Polish bleibt ein eigener TASK_566-Follow-up und wird durch TASK_565 nicht als abgeschlossen behauptet.

## Grenzen
- Keine neue Area-Semantik.
- Keine zweite UI-seitige Gameplay-Wahrheit.
- Keine langen Weltlabels.
- Enemy-Inspect bleibt vom Friendly-Befehlspfad getrennt.
