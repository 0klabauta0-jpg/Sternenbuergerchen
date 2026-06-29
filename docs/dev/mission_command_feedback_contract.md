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

## Frontier-Probe-Multiplayer-F6-Hover-Panel-Polish
TASK_566 macht aus dem echten TASK_565-F6-Befund einen kleinen Hover-/Panel-Polish. Der sichtbare Mission-Teamchip darf nur kompakte Owner-/Spawn-Tokens zeigen, damit #18 Mission Control nicht unruhig umbricht; die vollstaendige Erklaerung muss im Tooltip und im read-only Snapshot bleiben. `get_frontier_probe_multiplayer_f6_hover_panel_polish_snapshot()` darf Teamchip-Hover, sichtbare Textlaenge, Tooltip-Volltext, Panel-Bounds und Bottom-HUD-Weltverdeckung pruefen, aber keine Runtime-, Peer-, Objective-, Cargo-, Combat-, Command- oder Gameplay-Wahrheit speichern. Der naechste Lesbarkeitsschritt ist TASK_567 fuer First-Move-/Threat-Preview.

## Frontier-Probe-First-Move-Threat-Preview-Readability
`get_frontier_probe_first_move_threat_preview_readability_snapshot()` ist der Headless-Pruefpunkt fuer TASK_567. Der Snapshot darf nur den bestehenden TASK_540-First-Move-Snapshot, Waypoint-Intent-Preview, Command-Feedback und `TerrainMap3DView.get_render_snapshot()` zusammenfassen. Er muss `ui_sets_gameplay_truth = false` setzen und darf keine Kontakte erzeugen, kein GO ausfuehren und keine Command-Queue mutieren. Erwartete Lesbarkeit: Vor `GO` ist ein Risk-State (`safe`, `risky`, `suicidal` oder `unknown`) sichtbar, der kurze HUD-/Order-Text nennt Risiko plus ETA/Distanz, `unknown` hat einen erklaerten Grund, und Primary3D meldet Ghost-/Path-Preview sowie vorhandene Threat-Line-Zaehler.

## Frontier-Probe-Risky-Contact-Preview-Fixture
TASK_568 belegt dieselbe First-Move-Threat-Preview mit echten ContactTracker-Daten aus der Frontier-Probe-Mission-Fixture. Die Fixture darf Gegnerpositionen und ContactTracking fuer den Testzustand vorbereiten, aber der Preview-Snapshot bleibt read-only: kein `GO`, keine Command-Queue-Mutation, kein UI-seitiges Gegnerwissen. Erwartete Lesbarkeit: Ein bekannter Kontakt erzeugt `risky` mit mindestens einer Exposure-/Threat-Line; drei bekannte klare Kontakte erzeugen `suicidal` mit mindestens drei Exposure-/Threat-Lines; HUD-/Order-Text und Primary3D-Zaehler spiegeln denselben Zustand.

## Frontier-Probe-Threat-Preview-Visual-Review
TASK_569 macht die TASK_568-Gefahrensprache im Visualpfad pruefbar. `TerrainMap3DView.get_render_snapshot()` muss Risk-State-Zaehler, Line-Role-Zaehler und Line-Color-Key-Zaehler fuer Waypoint-Intent-Preview-Linien liefern. Die Visuals bleiben read-only: kein `GO`, keine Contact-Erzeugung, keine Gameplay-Mutation. Erwartete Lesbarkeit: Risky-Linien werden gelb/risky getoent, Suicidal-Linien rot/suicidal, blockierte Linien grau, Friendly-Fire orange; die urspruenglichen Line-Rollen bleiben als Diagnose erhalten.

## Hold-Fire-Discipline-Mission-Bridge
TASK_570 verbindet die bestehenden taktischen Fire-Rules mit dem Live-Missionspfad. Fire-Rules sind Mission-Command-Kontext pro Fireteam und werden nur bei expliziter Setzung in Behavior-Metadaten, Movement-State und `UnitCommand.fire_rule` geschrieben. UI/Preview duerfen diese Werte anzeigen, aber keine Unit- oder Combat-Wahrheit speichern. Der echte Befehl laeuft weiter ueber `SimulationRoot.enqueue_command()`.

Erwartete Rule-Abbildung: `hold` und `return` setzen `UnitCommand.fire_status = hold_fire`; `free` und `suppress` setzen `fire_at_will`. `CombatFireDecisionResolver` blockiert `hold`, erlaubt `return` nur bei aktivem Incoming-Fire-Fenster des Fireteams und behandelt `free`/`suppress` als feuerbereit. `suppress` ist in TASK_570 noch kein vollstaendiges Suppression-/Ammo-System, sondern ein durchgereichter Fire-Rule-Zustand fuer den naechsten Gameplay-Slice. Contact-Decision-Diagnostik muss `attacker_fire_rule`, `attacker_fire_status` und `attacker_return_fire_window_active` sichtbar machen.

## Fire-Rule-Controls-Readability-Polish
TASK_571 macht die TASK_570-Fire-Rules im Missions-HUD bedienbar. Die vier Command-Grid-Controls `HF`, `RF`, `FW` und `SUP` duerfen nur den bestehenden `MissionTacticalSandboxController.set_selected_fireteams_fire_rule()`-Pfad ausloesen. Sie duerfen keine Movement-, Combat-, Unit- oder Command-Queue-Wahrheit direkt schreiben.

`get_fire_rule_controls_readability_snapshot()` ist der Headless-Pruefpunkt fuer die Bedienung. Der Snapshot muss `ui_sets_gameplay_truth = false` setzen, die aktuell ausgewaehlten Fireteams, den Fire-Rule-Konsens, den bestehenden Fire-Rule-Snapshot und die Button-Zustaende melden. Erwartete Lesbarkeit: ohne Fireteam-Auswahl sind die Buttons deaktiviert; mit eindeutiger Auswahl ist genau die gesetzte Fire-Rule aktiv; bei gemischter Mehrfachauswahl darf kein einzelner Button faelschlich aktiv wirken.

## Fire-Rule-F6-Readability-Smoke
TASK_572 prueft die TASK_571-Controls im FullHD-F6-Kontext. `get_fire_rule_f6_readability_snapshot()` darf nur Control-Bounds, Button-Zustaende, Tooltips/Help-Metadaten und bestehende Command-/Fire-Rule-Snapshots zusammenfassen. Der Snapshot muss `ui_sets_gameplay_truth = false` setzen und darf keine Fire-Rule, Movement-, Combat- oder Command-Queue-Entscheidung ausloesen.

Erwartete Lesbarkeit: `HF`, `RF`, `FW` und `SUP` sind sichtbar, bleiben im #16 Command Matrix Panel, bleiben innerhalb FullHD, bilden eine kompakte ROE-Gruppe, ueberlappen nicht mit #17 Selected Fireteam oder #18 Mission Control, behalten Tooltip-/Help-Erklaerungen und zeigen bei eindeutiger Auswahl genau eine aktive Fire-Rule. Der Smoke ersetzt keinen menschlichen Screenshot-Test, macht aber offensichtliche Layout-/Panel-Kollisionen automatisiert sichtbar.

## Fire-Rule-Manual-Screenshot-Notes
TASK_573 nutzt den laufenden HTML-Zwischenbericht als manuelle Sichttest-Workbench fuer die Fire-Rule-/ROE-Buttons im F6-Missionsbild. Der Bericht darf Screenshotpfad, Viewport, aktive Rule, Button-Erkennbarkeit, Tooltip-/Hover-Eindruck, Command-Flow, Threat-Preview-Zusammenspiel, Panel-/Weltverdeckung, Ratings und Follow-up-Entscheidungen exportieren, aber keine Fire-Rule-, Combat-, Movement-, Command- oder Gameplay-Wahrheit speichern.

Erwartete Struktur: exportierbare `fire_rule_manual.*` Controls, eine freie `notes.fire_rule_manual_review`-Notiz und eine klare Markierung, dass der echte manuelle Screenshot erst durch User/Playtest bestaetigt wird. Ein nachfolgender Polish-Task darf nur konkrete, exportierte Sichtbefunde anwenden.

## Fire-Rule-Real-F6-Screenshot-Review
TASK_574 erzeugt eine reproduzierbare Fire-Rule-/ROE-F6-Evidence fuer den bestehenden Mission-Tactical-Pfad. Der Capture-Smoke darf den TASK_572-Readability-Snapshot, einen echten nicht-headless Viewport-Readback oder ein markiertes Headless-Evidence-Board und ein lokales PNG/JSON-Manifest unter `tmp/` zusammenfassen, aber keine Fire-Rule-, Combat-, Movement-, Command- oder Gameplay-Wahrheit speichern.

Erwartete Struktur: `tmp/fire_rule_f6_real_review.png`, `tmp/fire_rule_f6_real_review.json`, `readability_gate`, `selected_fire_rule_consensus`, Button-Labels, aktive Button-Regeln, `viewport_readback_available`, `manual_review_required = true` und `manual_review_done = false`. Der naechste Polish-Slice darf nur konkrete Befunde aus Screenshot, Manifest oder HTML-Workbench-Export anwenden.

## Fire-Rule-Evidence-Polish-Findings
TASK_575 wendet nur den belegten TASK_574-Folgepunkt an: Der aktive ROE-/Fire-Rule-Button muss staerker sichtbar sein als inaktive Buttons. Zulaessig sind visuelle Button-Affordance, Snapshot-Metadaten und Manifestfelder fuer Style-ID, aktive Affordance und Visual-Weight. Nicht zulaessig sind neue Fire-Rule-, Combat-, Movement-, Command-Queue- oder Gameplay-Wahrheit im HUD.

Erwartete Struktur: Der aktive Button meldet `fire_rule_active_affordance_v1`, inaktive Buttons melden `fire_rule_inactive_affordance_v1`, `get_fire_rule_f6_readability_snapshot()` enthaelt `active_button_affordance_count`, `active_affordance_style_id`, `active_affordance_style_ids`, `active_button_visual_weight` und den Check `active_rule_affordance_stronger`. TASK_574 darf diese Werte im lokalen Manifest ausgeben, ohne den manuellen Review als erledigt zu markieren.

## Suppress-Fire-Preview-Readability
TASK_576 macht den vorhandenen `SUP`-Fire-Rule-Zustand vor `GO` lesbar. Die Preview darf nur aus bestehender Fireteam-Auswahl, gesetzter Fire-Rule und Waypoint-Intent-Preview abgeleitet werden. Sie darf keinen GO ausfuehren, keine Command-Queue beschreiben, keine Ammo-/Suppression-Wirkung simulieren und keine Combat- oder Movement-Wahrheit im HUD speichern.

Erwartete Struktur: `get_suppress_fire_preview_readability_snapshot()` enthaelt `fire_rule = suppress`, `enabled`, `preview_text`, `pressure_state`, `radius_world`, `selected_order_text`, `first_waypoint_preview` und `ui_sets_gameplay_truth = false`. Der sichtbare Text im Selected-Fireteam-Ordertext darf knapp `SUP AREA ...` nennen. Ohne aktive `suppress`-Rule darf kein stale `SUP AREA` erscheinen. Der naechste Sicht-Slice ist TASK_577 fuer echte F6-/Visual-Evidence, nicht fuer ein grosses Suppression-/Ammo-System.

## Suppress-Fire-Visual-Evidence
TASK_577 erzeugt eine reproduzierbare lokale Visual-Evidence fuer die TASK_576-`SUP AREA`-Preview. Der Capture darf `get_suppress_fire_preview_readability_snapshot()`, `get_frontier_probe_first_move_threat_preview_readability_snapshot()` und `TerrainMap3DView.get_render_snapshot()` zusammenfassen, ein echtes nicht-headless Viewport-Readback oder ein markiertes Headless-Evidence-Board schreiben und die Artefaktpfade im laufenden HTML-Zwischenbericht nennen.

Erwartete Struktur: Das Manifest unter `tmp/suppress_fire_visual_evidence.json` enthaelt `capture_type = suppress_fire_visual_evidence`, `read_only = true`, `ui_sets_gameplay_truth = false`, `suppress_preview_gate`, `threat_preview_gate`, `preview_text`, `fire_rule`, `pressure_state`, `radius_world`, `render_preview_visual_count`, `render_preview_path_line_count`, `viewport_readback_available`, `generated_evidence_board`, `manual_review_required = true` und `manual_review_done = false`. Der Capture darf keinen `GO` ausfuehren und keine Suppression-/Ammo-/Combat-Wirkung behaupten. TASK_578 ist nur fuer belegte Visual-Polish-Findings vorgesehen.

## Suppress-Fire-Visual-Polish-Findings
TASK_578 wendet den belegten TASK_577-Folgepunkt an: Die `SUP AREA`-Preview muss im Primary3D-/F6-Blick als eigene read-only Area sichtbar und im Render-Snapshot messbar sein. Zulaessig sind Preview-Entry-Metadaten, eine transparente Area-Markierung, Render-Zaehler und Report-/Manifestfelder. Nicht zulaessig sind neue Suppression-Wirkung, Ammo-Verbrauch, Combat-Mutation, Movement-Mutation oder ein GO-Commit aus der Preview.

Erwartete Struktur: Waypoint-Intent-Preview-Entries duerfen ein `suppress_preview`-Dictionary tragen, wenn `fire_rule = suppress` und ein Ziel existiert. `TerrainMap3DView.get_render_snapshot()` enthaelt `waypoint_intent_preview_suppress_area_count`; die passende Entry enthaelt `suppress_area.visible = true`, `visual_key = suppress_area_v1`, `target_position`, `radius_world`, `radius_3d`, `pressure_state` und `read_only = true`. TASK_580 darf die Visual-ID auf `suppress_area_v2` anheben, solange die Area weiterhin read-only bleibt.

## Suppress-Fire-Manual-F6-Review
TASK_579 macht den menschlichen SUP-Area-Sichtreview im laufenden HTML-Zwischenbericht exportierbar. Der Review darf Screenshotpfad, Viewport, Pflichtchecks, Farbe-/Alpha-Bewertung, Groesse-/Ueberdeckungsbewertung, Statussprache, naechste Prioritaet und Freitextnotizen sammeln. Er darf keine Gameplay-Wahrheit erzeugen, keine Preview bestaetigen, keinen `GO` ausfuehren und kein Suppression-/Ammo-/Combat-Verhalten behaupten.

Erwartete Struktur: Der Bericht enthaelt Exportfelder unter `suppress_fire_manual.*`, mindestens `screenshot_done`, `sup_rule_selected`, `move_preview_visible`, `area_visible`, `no_go_committed`, `screenshot_path`, `viewport`, `visual_key`, `color_alpha_notes`, `size_overlap_notes`, `status_language_notes` und `followup`. Choice-Gruppen duerfen `area_color`, `area_size`, `status_clarity` und `next_priority` heissen. Die Freitextnotiz nutzt `notes.suppress_fire_manual_review`. TASK_580 bleibt fuer belegte Visual-Tuning-Findings reserviert.

## Suppress-Fire-Visual-Tuning-Findings
TASK_580 wendet den belegten SUP-Area-Lesbarkeitsfund aus der lokalen F6-Evidence an: Die transparente Area ist im dichten Raster/Stationsbild zu schwach als eigener Zielbereich erfassbar. Zulaessig sind reine Visual-Tuning-Daten wie staerkere transparente Fuellung, Outline, Achsenlinien und Render-Snapshot-Metadaten. Nicht zulaessig sind neue Suppression-Semantik, Ammo-Verbrauch, Combat-Mutation, Movement-Mutation oder ein `GO` aus der Preview.

Erwartete Struktur: `TerrainMap3DView.get_render_snapshot()` enthaelt weiter `waypoint_intent_preview_suppress_area_count`. Die passende Entry enthaelt `suppress_area.visible = true`, `visual_key = suppress_area_v2`, `fill_alpha`, `outline_alpha`, `surface_offset`, `outline_surface_offset`, `outline_visible = true`, `outline_segment_count`, `axis_line_count >= 2`, `boundary_marker_count >= 4`, `pressure_state`, `radius_world`, `radius_3d` und `read_only = true`.

## Suppress-Fire-Intent-Outcome-Smoke
TASK_581 traegt `SUP` nach der Preview als read-only Intent/Outcome-Diagnose durch den Combat-/Resolver-Pfad. `CombatFireDecisionResolver.build_fire_rule_outcome_diagnostic()` darf fuer `fire_rule = suppress` `outcome_label = suppress_pressure_intent` melden. `MissionCombatLoopDriver.get_contact_decision_diagnostics_snapshot()` darf diese Diagnose anhaengen und flache Keys wie `suppress_intent_active`, `suppress_pressure_intent_visible`, `suppress_effect_applied`, `suppression_effect_payload_enqueued`, `ammo_consumed` und `suppress_damage_modifier_applied` ausgeben.

Erwartete Struktur: `get_suppress_fire_intent_outcome_snapshot()` enthaelt `fire_rule_outcome`, `contact_decision_diagnostics`, `diagnostics_text`, `compact_combat_line`, `outcome_label = suppress_pressure_intent`, `suppress_intent_active = true`, `suppress_effect_applied = false`, `suppression_effect_payload_enqueued = false`, `ammo_consumed = false`, `suppress_damage_modifier_applied = false`, `read_only = true` und `ui_sets_gameplay_truth = false`. Mission-Control oder die kompakte Combat-HUD-Zeile duerfen `SUP` nennen. Nicht zulaessig sind echte Suppression-Wirkung, Ammo-Verbrauch, Damage-Modifikation, AAR-Messwerte oder eine zweite UI-seitige Combat-Wahrheit.

## Suppress-Fire-Outcome-AAR-Diagnostic-Stub
TASK_582 macht den TASK_581-Outcome als kleinen AAR-/Debug-Anker zaehlbar. Gezaehlt werden nur deduplizierte Contact-Decision-Diagnostics mit `status = fired`, aktiver SUP-Absicht und `outcome_label = suppress_pressure_intent`. Snapshot-Lesezugriffe, Preview, Cooldown und blockierte Decisions duerfen den Count nicht erhoehen.

Erwartete Struktur: `MissionCombatLoopDriver.get_suppress_fire_outcome_aar_diagnostic_snapshot()` enthaelt `schema = sternenbuergerchen.suppress_fire_outcome_aar_diagnostic.v1`, `suppress_fire_outcome_count`, `suppress_fire_outcome_by_fireteam`, `last_suppress_fire_outcome`, `dedupe_key_count`, `read_only = true`, `ui_sets_gameplay_truth = false`, `no_suppression_effect_payload = true`, `no_ammo_consumption = true` und `no_suppress_damage_modifier = true`. `get_suppress_fire_outcome_aar_diagnostic_snapshot()` im Mission-Controller darf daraus ein Test-/Report-Gate bauen, aber keinen Gameplay-State mutieren. Nicht zulaessig sind echtes Debriefing, Ammo-Verbrauch, Suppression-Effect-Payloads, Damage-Modifikation oder eine UI-seitige zweite Combat-Wahrheit.

## Suppress-Fire-AAR-Report-Panel-Readability
TASK_583 macht den TASK_582-Zaehler als kleine Debriefing-/Report-Vorstufe lesbar. Der Mission-Controller darf aus dem read-only AAR-Diagnostic-Snapshot ein kompaktes Report-Panel-Snapshot bauen: Titel, Summary, Count-Chips, Fireteam-Zeilen und einen kurzen Grenztext. Das Panel bleibt reine Praesentation und darf keine Mission-Result-, Combat-, Ammo- oder Suppression-Wahrheit speichern.

Erwartete Struktur: `get_suppress_fire_aar_report_panel_snapshot()` enthaelt `report_panel.schema = sternenbuergerchen.suppress_fire_aar_report_panel.v1`, `title = SUP AAR`, `summary_text`, `detail_text`, `count_label`, `chips`, `fireteam_rows`, `suppress_fire_outcome_count`, `read_only = true` und `ui_sets_gameplay_truth = false`. Der Detailtext muss klarstellen, dass dieser Slice keine Ammo, keine echte Suppression und keinen Damage-Mod erzeugt. Nicht zulaessig sind ein vollstaendiges Debriefing-System, neue Mission-Result-Mutationen oder UI-seitige Combat-Wahrheit.

## Mini-AAR-Combat-Metrics-Shell
TASK_584 fuehrt SUP nicht als alleinstehenden Report-Wert weiter, sondern sammelt die wichtigsten vorhandenen Kampfmetriken in einer kleinen read-only Mini-AAR-Schale. Der Mission-Controller darf dafuer bestehende FireEvents, das TASK_583-SUP-Panel, Friendly-Fire-Risiko, Fireteam-Member-Status und vorhandene MissionResult-Felder zusammenfassen. Der Snapshot bleibt reine Vorschau-/Report-Diagnostik und darf keine Mission-Result-, Combat-, Ammo-, Suppression-, XP- oder Skill-Wahrheit erzeugen.

Erwartete Struktur: `get_mini_aar_combat_metrics_snapshot()` enthaelt `schema = sternenbuergerchen.mini_aar_combat_metrics.v1`, `summary_text`, `metrics`, `rows`, `fire_events`, `sup_panel`, `status_metrics`, `mission_result`, `read_only = true` und `ui_sets_gameplay_truth = false`. `metrics` muss mindestens `shots_fired`, `hit_count`, `friendly_fire_event_count`, `friendly_fire_risk_count`, `suppress_fire_outcome_count`, `wounded_count`, `down_count` und `extracted_count` enthalten. Nicht zulaessig sind ein vollstaendiger Debriefing-Screen, MissionResult-Mutationen, XP-/Skill-Vergabe, Ammo-Verbrauch, echte Suppression-Wirkung oder eine zweite UI-seitige Combat-Wahrheit.

## Mini-AAR-Debrief-Screen-Stub
TASK_585 macht die TASK_584-Mini-AAR-Schale als kleine Debrief-Screen-Struktur lesbar. Der Mission-Controller darf aus `get_mini_aar_combat_metrics_snapshot()` eine kompakte Praesentationsstruktur mit Titel, Summary, Rows, Chips und Grenztext bauen. Der Stub ist nur eine UI-/Report-Vorstufe und darf keine Navigation, MissionResult-Mutation, XP-/Skill-Vergabe, Ammo- oder Suppression-Wahrheit erzeugen.

Erwartete Struktur: `get_mini_aar_debrief_screen_snapshot()` enthaelt `schema = sternenbuergerchen.mini_aar_debrief_screen_stub.v1`, `source_schema = sternenbuergerchen.mini_aar_combat_metrics.v1`, `screen`, `summary_text`, `rows`, `chips`, `limit_text`, `mini_aar`, `read_only = true` und `ui_sets_gameplay_truth = false`. `screen` muss mindestens `title_text`, `subtitle_text`, `summary_text`, `rows`, `chips`, `limit_text`, `layout_key`, `primary_action_label` und `secondary_action_label` enthalten. Nicht zulaessig sind ein vollstaendiger Debriefing-Screen, Return-to-Homebase-Handoff, XP-/Skill-Vergabe, Ammo-Verbrauch, echte Suppression-Wirkung oder eine zweite UI-seitige Combat-Wahrheit.

## Debrief-Return-Homebase-Handoff
TASK_586 macht den vorhandenen Meta-Rueckweg vom Debrief in die Homebase pruefbar. `MetaLayerFlow.get_debrief_return_homebase_handoff_snapshot()` darf nur bestehende Meta-Screen-, Signal-, MissionResult- und aktive-Mission-Zustaende lesen. Der Snapshot darf keine Navigation ausloesen und keine Mission-, XP-, Skill-, Ammo-, Suppression- oder UI-Wahrheit erzeugen. Der Testhelfer `request_debrief_return_homebase_for_test()` nutzt ausschliesslich den bestehenden Return-Handler und ist kein zweiter Navigationspfad.

Erwartete Struktur: `get_debrief_return_homebase_handoff_snapshot()` enthaelt `schema = sternenbuergerchen.debrief_return_homebase_handoff.v1`, `current_meta_view`, `target_meta_view = homebase`, `return_action_available`, `return_signal_connected`, `homebase_visible`, `debrief_visible`, `navigation_visible`, `active_mission_released`, `last_mission_result`, `debrief_mission_result`, `mission_result_preserved`, `read_only = true` und `ui_sets_gameplay_truth = false`. Vor dem Return muss Debrief sichtbar und Homebase verborgen sein; nach dem Return muss Homebase sichtbar, Debrief verborgen und die Meta-Navigation wieder sichtbar sein. TASK_587 bleibt fuer sichtbaren Debrief-Polish vorgesehen.

## Debrief-Visual-Polish
TASK_587 verbessert nur die Lesbarkeit des vorhandenen Debrief-Screens. `DebriefTestScreen.get_debrief_visual_polish_snapshot()` darf Summary-Chips, kompakte Labeltexte, Button-Rollen und Hintergrund-/Panel-Lesbarkeit melden. Der Snapshot darf keine Navigation ausloesen, kein MissionResult veraendern und keine XP-, Skill-, Ammo-, Suppression- oder Combat-Wahrheit erzeugen.

Erwartete Struktur: `get_debrief_visual_polish_snapshot()` enthaelt `schema = sternenbuergerchen.debrief_visual_polish.v1`, `layout_key = debrief_visual_polish_v1`, `summary_chip_count`, `summary_chips`, `result_text`, `team_status_text`, `primary_action_label`, `secondary_action_label`, `read_only = true` und `ui_sets_gameplay_truth = false`. Erwartete Lesbarkeit: mindestens fuenf Summary-Chips, kompakter Ergebnistext, kompakter Teamstatus, Homebase als primaere Aktion, FOB als sekundaere Aktion und weiterhin dimmed-background/readability policy. TASK_588 bleibt fuer die Bruecke von Mini-AAR-Kampfmetriken in den sichtbaren Meta-Debrief vorgesehen.

## Debrief-AAR-Data-Bridge
TASK_588 fuehrt die vorhandene TASK_585-Mini-AAR-Debrief-Struktur in den sichtbaren Meta-Debrief. `MetaLayerFlow` darf aus der aktiven Mission nur den read-only Snapshot `get_mini_aar_debrief_screen_snapshot()` uebernehmen und als `mini_aar_debrief` in das MissionResult kopieren. `DebriefTestScreen` darf diesen Payload als AAR-Summary, Chips, Rows und Grenztext anzeigen. Der Debrief bleibt Presenter und darf keine Mission-, Combat-, XP-, Ammo-, Skill- oder Suppression-Wahrheit erzeugen.

Erwartete Struktur: `MetaLayerFlow._build_mission_result()` enthaelt bei vorhandenem Snapshot `mini_aar_debrief.schema = sternenbuergerchen.mini_aar_debrief_screen_stub.v1`, `read_only = true` und `ui_sets_gameplay_truth = false`. `DebriefTestScreen.get_debrief_aar_data_bridge_snapshot()` enthaelt `schema = sternenbuergerchen.debrief_aar_data_bridge.v1`, `layout_key = debrief_aar_bridge_v1`, `source_schema`, `aar_summary_text`, `aar_chip_count`, `aar_row_count`, `aar_limit_text`, `read_only = true` und `ui_sets_gameplay_truth = false`. Erwartete Lesbarkeit: Summary enthaelt FIRE und SUP, mindestens fuenf Chips, mindestens vier Rows, ehrlicher Grenztext mit Keine XP/keine Ammo/keine echte Suppression und kein Rueckfall im TASK_587-Visual-Polish-Gate.

## Debrief-AAR-F6-Visual-Evidence
TASK_589 macht die sichtbare TASK_588-AAR-Sektion reproduzierbar pruefbar. `DebriefTestScreen.get_debrief_aar_visual_evidence_snapshot()` darf nur Layout- und Lesbarkeitsdaten der Debrief-AAR-Sektion melden: Panel-, AAR-, Button-Rects, kompakte Textlaengen, Chip-/Row-Anzahl und Bridge-Gate. Der Snapshot darf keine Navigation ausloesen, keine MissionResult-Daten veraendern und keine XP-, Ammo-, Skill-, Combat- oder Suppression-Wahrheit erzeugen. Der zugehoerige Verifier darf PNG/Manifest unter `tmp/` schreiben; Headless-Evidence-Boards ersetzen keinen finalen menschlichen Sichtentscheid.

Erwartete Struktur: `get_debrief_aar_visual_evidence_snapshot()` enthaelt `schema = sternenbuergerchen.debrief_aar_visual_evidence.v1`, `layout_key = debrief_aar_visual_evidence_v1`, `bridge_gate`, `source_schema`, `panel_rect`, `aar_section_rect`, `aar_summary_rect`, `aar_chip_strip_rect`, `aar_rows_rect`, `aar_limit_rect`, `button_row_rect`, `button_gap`, `aar_summary_text`, `aar_chip_count`, `aar_row_count`, `manual_review_required = true`, `manual_review_done = false`, `read_only = true` und `ui_sets_gameplay_truth = false`. Erwartete Gates: TASK_588-Bridge gruen, alle AAR-Controls im Panel, AAR vor ButtonRow, kein Button-Overlap, kompakte Summary/Rows/Limit und mindestens fuenf Chips.

## Debrief-AAR-Layout-Polish
TASK_590 wendet belegten Layout-Polish aus der TASK_589-Evidence an. `DebriefTestScreen` darf die AAR-Summary nur als Presenter normalisieren: aus Quelltexten wie `AAR | FIRE ...` wird genau eine sichtbare `AAR | ...`-Zeile, nicht `AAR: AAR | ...`. Summary, Rows und Grenztext bekommen stabile Clip-/Overrun-Regeln und Style-Metadaten, damit der Debrief knapp scanbar bleibt. Der Snapshot ist read-only und darf keine Mission-, Combat-, XP-, Ammo-, Skill- oder Suppression-Wahrheit erzeugen.

Erwartete Struktur: `get_debrief_aar_layout_polish_snapshot()` enthaelt `schema = sternenbuergerchen.debrief_aar_layout_polish.v1`, `layout_key = debrief_aar_layout_polish_v1`, `bridge_gate`, `visual_gate`, `source_schema`, `aar_summary_text`, `summary_has_duplicate_prefix = false`, `aar_rows_text`, `aar_limit_text`, Textlaengen, Chip-/Row-Anzahl, Button-Gap, AAR-Section-Hoehe, `style_ids`, `read_only = true` und `ui_sets_gameplay_truth = false`. Erwartete Gates: TASK_588-Bridge gruen, TASK_589-Visual-Evidence gruen, Prefix sauber, Summary/Rows/Limit kompakt, `debrief_aar_summary_v2`, `debrief_aar_rows_v2`, `debrief_aar_limit_v2` gesetzt und mindestens fuenf AAR-Chips sichtbar.

## Debrief-AAR-Player-Review-Notes
TASK_591 macht den echten Spielerblick auf den Debrief-AAR-Block im laufenden HTML-Bericht exportierbar. Der Bericht darf Screenshotpfad, Viewport, Pflichtchecks, Ratings, Folgeprioritaet und freie Notizen sammeln. Diese Daten sind Playtest-/Review-Arbeitsnotizen und duerfen keine Mission-, Combat-, XP-, Ammo-, Skill-, Fireteam- oder Suppression-Wahrheit erzeugen.

Erwartete Struktur: `docs/reports/project_review_status_2026_06_28.html` enthaelt einen sichtbaren `TASK_591 Debrief-AAR Player-Review`-Block mit Export-Keys unter `debrief_aar_manual.*`, darunter `screenshot_path`, `viewport`, `summary_prefix_checked`, `chips_checked`, `rows_checked`, `limit_checked`, `return_flow_checked`, `summary_notes`, `chip_notes`, `rows_limit_notes`, `return_flow_notes` und `followup`. Auswahlgruppen sollen `debrief_aar_manual.result`, `debrief_aar_manual.summary_rating`, `debrief_aar_manual.chip_rating`, `debrief_aar_manual.rows_limit_rating` und `debrief_aar_manual.next_polish_priority` exportieren. Ein Freitextfeld unter `notes.debrief_aar_manual_review` sammelt offene Spieler-/Reviewer-Notizen. TASK_592 bleibt fuer belegte Findings aus diesem Export vorgesehen.

## Grenzen
- Keine neue Area-Semantik.
- Keine zweite UI-seitige Gameplay-Wahrheit.
- Keine langen Weltlabels.
- Enemy-Inspect bleibt vom Friendly-Befehlspfad getrennt.
