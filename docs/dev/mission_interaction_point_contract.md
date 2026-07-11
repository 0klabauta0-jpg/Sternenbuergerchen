# Mission Interaction Point Contract

## Zweck
Dieser Contract beschreibt den ersten stabilen Authoring-Pfad fuer Missionsinteraktionen, die aus Map-Editor-Assets entstehen: Tueren, Computer/Konsolen und Hold-/Capture-Zonen.

Ziel ist nicht, neue Runtime-Gameplay-Wahrheit in den Editor zu legen. Der Editor setzt sichtbare, speicherbare Anker. Die Mission-Runtime liest diese Anker spaeter ueber Scenario-/Terrain-Daten und fuehrt echte Befehle weiterhin ueber `SimulationRoot` und die bestehenden Command-/Gate-Pfade aus.

## Autoritaet
- `TerrainMapData` speichert Markerpositionen und Tile-/Asset-Daten.
- `TerrainMarkerCatalog` definiert authorbare Marker-Typen, Namen, Symbole und Farben.
- Szenario-/Mission-Daten verbinden einen Marker optional mit einem Runtime-Gate, Objective oder Command.
- `SimulationRoot` bleibt die einzige Stelle, die Interaction-Fortschritt, Erfolg, Fehlschlag, Door-State oder Objective-State autoritativ aendert.
- UI, Editor und Preview-Overlays zeigen nur Lesbarkeit und senden spaeter Commands.

## Marker-Typen
- `interaction_door`: Authoring-Anker fuer eine Tuer oder ein Tuerbedienfeld.
- `interaction_computer`: Authoring-Anker fuer Computer, Konsolen, Generatoren oder Terminal-Beats.
- `interaction_hold_zone`: Authoring-Anker fuer einen timed hold, Capture-Kreis oder Sicherungsbereich.

Diese Marker sind `editor_only`, bis ein Szenario sie explizit bindet. Sie duerfen keine Runtime-Aktion durch ihre blosse Existenz ausloesen.

## Erwartete Daten
Ein gebundener Interaction Point soll spaeter mindestens diese Daten liefern:

- `interaction_id`: stabile ID fuer Szenario und Runtime.
- `marker_id`: Marker aus `TerrainMapData`.
- `interaction_type`: `door`, `computer`, `hold_zone` oder spaeter engerer Typ.
- `required_order`: z. B. `take`, `hold`, `operate`, `breach`.
- `duration_seconds`: nur fuer Hold-/Operate-Aktionen.
- `radius_world`: Bedien-/Capture-Radius.
- `required_team`: optional, z. B. `player`, `enemy`, `any`.
- `gate_id`: optionaler Scenario-Gate-Link wie AA aus, Computer gehalten, Cargo erlaubt.
- `asset_hint`: optionaler Hinweis auf Tile-/Object-Asset, etwa Door-Closed/Open-Familie.

## Runtime-Regeln
- Naehe, Bedienzeit, Ownership und Fehlschlag werden nicht im Editor entschieden.
- Ein Fireteam darf einen Interaction Point nur ueber einen echten Command oder ein Scenario-Gate benutzen.
- Door-Animationen duerfen aus Closed/Half/Open-Assetfamilien abgeleitet werden, brauchen aber einen Runtime-State ausserhalb der Tile-Wahrheit.
- Computer-/Hold-Fortschritt muss aus der Mission-Runtime kommen und darf im HUD nur read-only angezeigt werden.
- Multiplayer muss Host-/Server-Autoritaet behalten: Client-UI darf Interactions vorschlagen, aber nicht selbst committen.

## Scenario Binding
- Scenario-Dateien duerfen `vertical_slice.interaction_points` nutzen, um Marker, Step/Gate und Bedienart explizit zu verbinden.
- `MissionInteractionPointBinding` normalisiert diese Bindings und kann bei fehlenden expliziten Bindings aus bekannten `vertical_slice.flow_steps` eine read-only Ableitung bauen.
- Frontier Probe nutzt drei explizite Bindings: AA-Shutdown-Zone, Station-Computer und Cargo-Landing-Hold.
- Der Binding-Snapshot liefert `available`, `blocked`, `in_progress` oder `complete` anhand vorhandener Runtime-Gates und optionaler Interaction-Runtime-Stati.
- Der Snapshot darf fuer Debug, HUD-Preview und Verifier gelesen werden, setzt aber keinen Gate-, Door-, Computer- oder Objective-State.

## Preview und Lesbarkeit
- Der Editor darf Door-/Computer-/Hold-Marker mit Symbol, Farbe und Label zeigen.
- Die Mission darf Interactions als Objective-/Next-Interaction-Hinweis anzeigen.
- Preview- und HUD-Texte muessen `ui_sets_gameplay_truth = false` einhalten.
- Performance-Regel: Markerlisten duerfen gecacht oder dirty aktualisiert werden, aber nicht als per-frame SceneTree-Vollscan wachsen.

## Runtime Use State
- `MissionInteractionRuntimeUseState` verbindet den Binding-Snapshot mit Terrain-Markerpositionen, aktiven Fireteam-Ankern und optionalen Interaction-Runtime-Stati.
- Der Snapshot liefert `usable`, `out_of_range`, `blocked`, `in_progress`, `interrupted`, `complete` oder `unknown`.
- Naehe wird aus `radius_world` und dem naechsten erlaubten Fireteam abgeleitet.
- Ein noch offenes oder als aktiv markiertes Scenario-Gate allein ist kein laufender Use: `in_progress` entsteht erst aus einem expliziten Interaction-Runtime-State des laufenden Waypoints. Ein Fireteam im Radius bleibt davor `usable` und kann den Befehl bewusst planen.
- `required_team` begrenzt, welches Team eine Interaction bedienen darf; `any` oder leer erlaubt jedes Team.
- Der Snapshot bleibt read-only: `SimulationRoot`/Scenario-Gates entscheiden weiterhin ueber echten Fortschritt, Abschluss und Fehlschlag.
- `MissionTacticalSandboxController.get_mission_interaction_runtime_use_state_snapshot()` ist eine on-demand Fassade fuer Verifier, Debug und spaetere UI-Preview, kein neuer HUD-Hotpath.

## Use Feedback
- `MissionInteractionUseFeedback` uebersetzt den Runtime-Use-State in eine kurze Spieler-/Verifier-Zeile.
- Feedback-Prioritaet ist `in_progress`, `usable`, `blocked`, `interrupted`, `out_of_range`, `complete`, `unknown`.
- Der Presenter liefert `feedback_line`, `detail_text`, `action_label`, `severity`, `can_prompt_use` und `primary_interaction_id`.
- `MissionTacticalSandboxController.get_mission_interaction_use_feedback_snapshot()` und `get_command_feedback_snapshot().mission_interaction_use_feedback` exportieren denselben read-only Snapshot.
- Der Presenter darf keine Interaktion starten und keine Scenario-Gates setzen. Echte Use-Commands bleiben ein separater Slice.

## Use Intent
- `MissionTacticalSandboxController.create_selected_mission_interaction_use_intent(interaction_id = "")` erzeugt aus einer nutzbaren Interaction einen geplanten Fireteam-Waypoint.
- Der Intent nutzt das gebundene `required_order`: `take`, `defend`, `move`, `flank`; `hold` wird zu `defend`, `operate`/`breach` zu `take`.
- Der Intent setzt keine Scenario-Gates, keinen Door-State und keinen Objective-Erfolg. Er erzeugt nur einen Command-Intent, der weiterhin GO und den bestehenden Mission-Tactical-Pfad braucht.
- `get_mission_interaction_use_intent_snapshot()` und `get_command_feedback_snapshot().mission_interaction_use_intent` exportieren den letzten Intent samt `accepted`, `blocked_reason`, `command_type`, `waypoint_id` und `requires_go`.
- Blockierte oder ausser Reichweite liegende Interactions duerfen keinen Waypoint erzeugen.

## Runtime Progress
- Use-Intent-Waypoints tragen `duration_seconds`, `step_id`, `gate_id`, `required_state`, `interaction_type` und `required_team` als Metadaten und setzen `hold_duration_seconds`.
- Laufende Interaction-Waypoints melden ihren Fortschritt ueber `MissionCombatLoopDriver.update_mission_interaction_runtime_progress(payload)`.
- Der Driver exportiert `get_mission_interaction_runtime_states()` und `get_mission_interaction_runtime_state_snapshot()` fuer Binding-/Use-State-Snapshots.
- `holding`/`operating` und Completion kommen aus der laufenden Runtime-Ausfuehrung, nicht aus HUD-Text.
- Bei Completion setzt der Driver den passenden Scenario-Step-State; Cargo-Hold aktualisiert zusaetzlich den Cargo-Touchdown-State.
- UI liest diesen Zustand weiter ueber `get_mission_interaction_runtime_use_state_snapshot()` und setzt keine Gameplay-Wahrheit.

## Progress Readability
- `MissionTacticalSandboxController.get_mission_interaction_progress_readability_snapshot()` uebersetzt den primaeren Use-Feedback-Eintrag in eine kurze Anzeigezeile.
- Die Anzeigezeile enthaelt Interaction-Token, Fortschritt, Hold-Zeit und Fireteam-Token, zum Beispiel `COM 50% 9/18s FT1`.
- `get_command_feedback_snapshot()` exportiert den Readability-Snapshot und die aktuelle `mission_interaction_progress_line`.
- Die Mission-Control-ACT-Zeile darf diese kompakte Progress-Zeile aufnehmen, bleibt aber ein Anzeige-/Feedbackpfad.
- Der Snapshot ist read-only, markiert `ui_sets_gameplay_truth = false` und veraendert weder Scenario-Gates noch Runtime-Stati.
- Headless-Verifier duerfen Zeichenbudget und Exportform pruefen; der echte manuelle FullHD-Sichtlauf bleibt separat zu bestaetigen.

## Objective Gate Snapshot
- `MissionInteractionObjectiveGate` verbindet Binding-, Use-State-, Feedback-, Scenario-Gate-, Cargo- und Intent-Snapshots zu einer read-only Objective-Fassade.
- `MissionTacticalSandboxController.get_mission_interaction_objective_gate_snapshot()` liefert den naechsten unvollstaendigen Gate-Schritt, die passende Interaction, Blocker, Cargo-Blocker und eine kurze `next_line`.
- `get_command_feedback_snapshot()` exportiert `mission_interaction_objective_gate`, `mission_interaction_objective_next_line` und `mission_interaction_objective_next_step_id`.
- Die Sequenz bleibt datengetrieben aus Scenario-Gates: `disable_air_defense`, `occupy_station_computer`, `cargo_touchdown_extract`.
- Der Snapshot darf keine Gates setzen, keine Interaktion starten und keine UI-Wahrheit speichern. Completion kommt weiter aus `MissionScenarioRuntimeGates` und Interaction-Runtime-Progress.

## Visual State Snapshot
- `MissionInteractionVisualState` uebersetzt bestehende Runtime-Use-State- und Objective-Gate-Snapshots in kurze Objektlabels fuer die Missionsansicht.
- `MissionTacticalSandboxController.get_mission_interaction_visual_state_snapshot()` liefert `entries` mit Interaction-ID, Typ, Step, Marker, Weltposition, Token, Status, Tone, Label und `is_next`.
- Tokens sind bewusst kurz: `AA`, `COM`, `CARGO`, `DOOR`, sonst `INT`.
- Statuslabels sind Anzeigezustand: `OK`, `READY`, `APPROACH`, `BLOCKED`, `INTERRUPTED` oder Fortschritt wie `9/18s`.
- Die 3D-Ansicht darf daraus Marker/Labels zeichnen und `get_render_snapshot()`-Zaehler exportieren, aber keine Scenario-Gates, Door-States, Cargo-States oder Runtime-Progress setzen.
- Der Snapshot ist read-only, markiert `ui_sets_gameplay_truth = false` und nutzt `MissionInteractionRuntimeUseState`/`MissionInteractionObjectiveGate` als Quellen.

## Object Reaction Snapshot
- `MissionInteractionObjectReaction` leitet aus dem Visual-State-Snapshot kleine Objektreaktionsdaten ab.
- `MissionTacticalSandboxController.get_mission_interaction_object_reaction_snapshot()` liefert `entries` mit Object-Kind, Reaction-State, Weltposition, Accent-Farbe, Open-Fraction und Aktiv-/Locked-Flags.
- Object-Kinds sind `computer`, `aa`, `cargo`, `door` oder `interaction`.
- Reaction-States sind Anzeigezustand: `ready`, `active`, `controlled`, `disabled`, `departed`, `open`, `locked`, `blocked`, `warning`, `idle` oder `unknown`.
- `TerrainMap3DView` darf daraus lokale Proxy-Geometrie am Interaktionspunkt zeichnen: Terminalscreen, AA-Mast, Cargo-Beacon oder Door-Slabs.
- Diese Proxies duerfen keine Tiles austauschen, keine Door-Kollision aendern, keine Scenario-Gates setzen und keine Runtime-Progress-Werte schreiben. Echte Asset-Swaps/Animationen bleiben ein eigener Slice.

## Runtime Visual Assets
- Object-Reaction-Eintraege duerfen zusaetzlich `runtime_visual_state`, `visual_asset_family`, `visual_asset_type_id`, `visual_model_path`, `visual_preview_path` und `visual_state_label` exportieren.
- Door-Visualstates sind `closed`, `half` und `open`; sie mappen auf die vorhandene Space-Station-Familie `station_set_door_single_closed`, `station_set_door_single_half` und `station_set_door_single`.
- Computer-Visualstates sind `idle`, `active` und `controlled`; sie mappen auf `station_computer` plus Screen-/Panel-Hinweise wie `IDLE`, `LINK` oder `CTRL`.
- `TerrainMap3DView` darf daraus bessere lokale Lesbarkeits-Proxies zeichnen, z. B. Computer-Fortschrittsbalken oder Door-Open-Schwelle.
- Diese Runtime-Visual-Assets bleiben read-only: sie aendern keine `TerrainMapData`, keine Collision, keine Walkability, keine LOS-Blocker und keine Scenario-Gates.

## Door Runtime Collision/LOS
- `MissionInteractionDoorRuntimeCollisionLOS` uebersetzt Door-Reaction-Eintraege in effektive Runtime-Tile-Overrides.
- Die Quelle bleibt der Runtime-/Interaction-Pfad: `SimulationRoot` -> Interaction-Runtime-State -> Visual-State -> Object-Reaction. UI und Render-Proxies setzen keine Gameplay-Wahrheit.
- Offene Door-States liefern `walkable_override = true`, `blocks_los_override = false`, `object_height_override = 0` und `collision_state = open`.
- Halbe und geschlossene Door-States bleiben fuer Bewegung und LOS blockierend.
- `TerrainRegistry` speichert diese Overrides getrennt von `TerrainMapData` und markiert betroffene Gridpositionen dirty.
- `TerrainPathfinder` und `LineOfSightSystem` muessen effektive Registry-Getter nutzen, wenn sie vorhanden sind.
- Der Contract mutiert keine gespeicherte Karte: `terrain_map_data_mutated = false`, `read_only = true`, `ui_sets_gameplay_truth = false`.
- Echte Door-Use-/Breach-Commands, Asset-Swaps und Animationen bleiben eigene Slices.

## Door Runtime State Producer
- `MissionTacticalSandboxController.get_mission_interaction_door_runtime_collision_los_snapshot()` baut den Door-Runtime-Override-Snapshot aus Object-Reaction und `TerrainRegistry`.
- `apply_mission_interaction_door_runtime_collision_los_snapshot()` wendet die effektiven Door-Overrides auf die `TerrainRegistry` an.
- Der Producer liest Runtime-Wahrheit aus dem vorhandenen Interaction-State-Pfad und schreibt nur Registry-Overrides; `TerrainMapData` und statische `TerrainTileData` bleiben unveraendert.
- Gleiche Override-Sets werden per Fingerprint uebersprungen, damit der Sync-Pfad nicht bei jedem Status-Refresh unnoetig dirty setzt.
- Der Mission-Status-Payload darf Diagnosefelder wie Override-Count, Apply-Reason und Summary exportieren. Diese Werte bleiben Feedback/Debug, nicht Gameplay-Wahrheit.
- Sichtbare Breach-/Use-Bedienung und Door-Animationen bleiben eigene Slices.

## Door Use/Breach Command Hook
- `MissionTacticalSandboxController.create_selected_mission_interaction_door_use_breach_command_hook()` ist der door-spezifische Bedien-Hook fuer nutzbare Door-Interactions.
- Der Hook nutzt den bestehenden `create_selected_mission_interaction_use_intent()`-Pfad und erzeugt keine zweite Door-, Mission- oder UI-Wahrheit.
- Der Hook bleibt read-only bis zur GO-Bestaetigung: `requires_go = true`; echte Ausfuehrung laeuft weiter ueber Waypoint, Runtime-Progress und Door Runtime State Producer.
- Door-Waypoints muessen `door_runtime_hook`, `door_runtime_state_target` und `door_runtime_producer` tragen, damit Runtime-Progress die effektiven TerrainRegistry-Overrides speisen kann.
- `get_command_feedback_snapshot()` darf Hook-Status und lesbare BREACH/GO-Zeile exportieren. Diese Werte sind Bedienfeedback, keine Gameplay-Wahrheit.
- Der Hook darf blockieren, wenn keine Door-Interaction, kein nutzbarer Use-Intent oder ein nicht unterstuetzter Door-Order-Typ vorliegt.
- Animationen und Asset-Swaps bleiben Folge-Slices.

## Door Interaction HUD Button/Shortcut
- Der sichtbare Door-Bedienpfad ist `DoorBreachButton` im CommandGrid-Slot `16.8` plus Shortcut `B`.
- Button und Shortcut duerfen keine Door-, Terrain- oder Mission-Wahrheit setzen; sie rufen nur `create_selected_mission_interaction_door_use_breach_command_hook()` auf.
- Der Button ist aktiv, wenn `get_mission_interaction_use_feedback_snapshot()` eine `usable` Door mit unterstuetztem Required-Order-Typ fuer die aktuelle Auswahl meldet.
- Der Button muss auch blockiert sichtbar bleiben, damit der Spieler erkennt, dass Door-Breach existiert, aber gerade keine nutzbare Door in Reichweite ist.
- Command-Control- und Command-Hierarchy-Snapshots muessen `breach_door`, Slot, Tooltip, Shortcut und Door-ID exportieren.
- `requires_go = true` bleibt Pflicht; echter Runtime-State entsteht erst ueber Waypoint-Ausfuehrung, Runtime-Progress und Door Runtime State Producer.

## Contextual Mission Interaction Slot
- Der bestehende CommandGrid-Slot `16.8` bleibt als `DoorBreachButton` und vorhandener Door-/Shortcut-Pfad kompatibel, dient aber fuer die aktive Missionsroute als kontextuelle Interaction-Aktion.
- `MissionTacticalSandboxController.get_primary_mission_interaction_button_snapshot()` waehlt zuerst die Interaction aus `MissionInteractionObjectiveGate.next_interaction_id`; allgemeine Feedback-Prioritaet darf einen spaeteren blockierten Cargo-Schritt nicht vor die aktive AA-/Door-/Computer-Aktion ziehen.
- `issue_primary_mission_interaction()` nutzt fuer Doors weiter den vorhandenen Door-Breach-Hook. Fuer AA, Computer und Cargo nutzt es ausschliesslich `create_selected_mission_interaction_use_intent()`.
- Der Slot bleibt ausser Reichweite sichtbar und deaktiviert. Im Radius erzeugt er nur einen Intent mit `requires_go = true`; erst die vorhandene GO-/Waypoint-Ausfuehrung publiziert Interaction-Progress und aendert Scenario-Gates.
- Ein offenes Scenario-Gate ist keine laufende Bedienung. Ohne expliziten Interaction-Runtime-State bleibt eine Fireteam im Radius `usable`, damit der Spieler die Aktion bewusst ausloesen kann.
- Button, Snapshot und Tooltip sind Bedienfeedback und besitzen keine Mission-, Gate-, Door-, Cargo- oder Combat-Wahrheit.

## Contextual Interaction HUD Semantics
- Der historische Command-Hierarchy-Pass darf den gemeinsamen Slot `16.8` nicht abschliessend als Door beschreiben. Danach richtet ein rein visueller Semantikpass Text, Tooltip, `help_id` und Metadaten wieder an dem bereits gelesenen Primary-Interaction-Snapshot aus.
- AA-Shutdown und Computer-Interactions nutzen `mission.command.take`; Cargo-Hold nutzt `mission.command.defend`. Diese Nicht-Door-Interactions duerfen weder `Breach` noch den Door-Shortcut `B` anzeigen oder exportieren.
- Nur eine Interaction mit `interaction_type = door` behaelt `mission.command.breach_door`, den sichtbaren Breach-Text und den Shortcut `B`.
- Der Semantikpass liest ausschliesslich den vorhandenen Snapshot. Er erzeugt keinen Command, setzt keine Route, kein Gate und keinen Door-/Cargo-State.

## Door Runtime Visual Animation/Asset Swap
- Door-Object-Reactions exportieren `door_animation_phase`, `door_asset_swap_state`, `door_leaf_gap_fraction`, `door_threshold_visible` und `door_runtime_collision_source`.
- Die zulaessigen Door-Visualphasen sind `closed_idle`, `opening_*_percent` und `open`; sie bilden nur den sichtbaren Runtime-Status ab.
- Der Asset-Swap-State trennt `door_closed_asset`, `door_half_open_asset` und `door_open_asset`, ohne direkt TerrainMapData, Walkability oder LOS zu mutieren.
- `TerrainMap3DView` darf Door-Proxies fuer closed/half/open unterschiedlich zeichnen: Seal bei closed, Opening-/Progress-Indikator bei half, Threshold bei open.
- Effektive Collision/LOS-Wahrheit bleibt beim Door Runtime State Producer und den `TerrainRegistry`-Overrides.
- Render-Snapshots duerfen Door-Visualfelder fuer Tests, Reports und Playtestnotizen exportieren; `door_visual_sets_gameplay_truth = false` und `ui_sets_gameplay_truth = false` bleiben Pflicht.
- Ein echter FullHD-Sichtentscheid fuer Groesse, Lesbarkeit und HUD-Overlap bleibt ein separater manueller Review-Slice.

## Door Interaction Multiplayer Authority Check
- Der Door-Breach-Hook darf fuer Netzwerkpruefung in einen `commander_command` mit `command_type = take` projiziert werden.
- Der Command darf `interaction_id`, `interaction_type`, `required_order`, `door_runtime_hook`, `door_runtime_state_target`, `door_runtime_producer` und `requires_go` als Metadaten tragen.
- Der Command darf keine verbotenen State-Mutationsfelder wie `runtime_state`, `runtime_status`, `position`, `global_position`, `visible` oder direkte Door-/Terrain-Wahrheit enthalten.
- `SimulationRoot.submit_network_command_for_peer()` und `MultiplayerCommandContract` bleiben die Autoritaet fuer Own-Team-Accept, Wrong-Team-Reject und State-Mutation-Reject.
- Clients/Button/Shortcut/GO duerfen nur Commands anstossen; die Door wird erst durch Runtime-Progress plus `MissionInteractionDoorRuntimeCollisionLOS` effektiv walkable und LOS-offen.
- `get_mission_interaction_door_multiplayer_authority_snapshot()` und `get_command_feedback_snapshot()` duerfen den technischen Authority-Status read-only exportieren.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht; der Snapshot ist Beweis-/Reportdaten, kein Gameplay-Mutator.

## Door Authority UI Feedback
- `MissionInteractionDoorMultiplayerAuthority.build_ui_feedback()` uebersetzt den read-only Authority-Snapshot in eine kurze HUD-Zeile und einen Button-Tooltip.
- Zulaessige UI-Readout-Statuswerte sind `pending`, `ready`, `accepted`, `blocked` und `open`.
- `ready` bedeutet nur: Door-Breach kann als Command vorbereitet werden und braucht weiter GO.
- `accepted` bedeutet: der Host/Authority-Pfad hat den Own-Team-Command akzeptiert; Runtime-State wird dadurch nicht im UI gesetzt.
- `blocked` muss den Reject-Grund aus `MultiplayerCommandContract` lesbar machen, zum Beispiel `peer_team_mismatch` oder `state_mutation_key:runtime_state`.
- `open` darf nur erscheinen, wenn der Door Runtime Collision/LOS Producer einen offenen Runtime-Override meldet.
- Der `DoorBreachButton` darf Tooltip und Metadaten aus diesem Readout zeigen; `get_command_feedback_snapshot()` darf dieselben Daten exportieren.
- Das Feedback bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.

## Multiplayer Door Feedback Capture
- `MissionMultiplayerDoorFeedbackCapture` vergleicht Host-, Wrong-Team-, State-Mutation- und Open-Readouts als read-only Evidence-Paket.
- Host-Feedback muss `accepted` oder `open` melden, wenn der Own-Team-Command akzeptiert wurde.
- Wrong-Team-Feedback muss `blocked` melden und den Reject-Grund aus `MultiplayerCommandContract` sichtbar machen.
- State-Mutation-Feedback muss `blocked` melden und einen `state_mutation_key:*`-Grund sichtbar machen.
- Open-Feedback darf nur `open` melden, wenn der Door Runtime Collision/LOS Producer einen offenen Runtime-Override liefert.
- `get_command_feedback_snapshot()` darf den Capture-Snapshot exportieren, aber ohne eingespeisten Capture-Kontext bleibt er ein Review-/Diagnosefeld.
- Das Capture ersetzt keinen echten Zwei-Fenster-Test; es bereitet ihn mit vergleichbaren Host-/Client-Daten vor.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Host/Client Door Real Click Workbench
- `MissionHostClientDoorRealClickWorkbench` erzeugt eine read-only Notizschale fuer den echten Host-/Client-Door-Klicklauf.
- Der Snapshot darf TASK_699-Capture-Daten als Quelle nennen, aber keine Door-, Terrain-, Multiplayer- oder Mission-Wahrheit setzen.
- Required-Checks betreffen Host-Fenster, Client-Fenster, Door-Breach-Button, Shortcut `B`, GO-Pflicht, Wrong-Team-Reject, Door-Open auf Host/Client und HUD-Lesbarkeit.
- `manual_review_done` bleibt false, bis ein Mensch die Workbench bewusst ausfuellt und den Door-Klickentscheid markiert.
- Die HTML-Workbench `docs/reports/host_client_door_real_click_workbench_2026_06_30.html` exportiert lokale JSON-Arbeitsnotizen zu Host, Client, Reject, Door-Open, Timing und naechster Polish-Aktion.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht; der echte Command-Pfad bleibt Button/Shortcut -> Hook -> GO -> SimulationRoot/Runtime-Progress.

## Host/Client Door Real Click Findings
- `MissionHostClientDoorRealClickFindings` verdichtet TASK_699-Capture und TASK_700-Workbench-Snapshot zu einem read-only Findings-Snapshot.
- Das Findings-Snapshot trennt `technical_path_gate` von `manual_click_findings_gate`, damit technische Door-Evidence nicht als menschlich bestandener Klicktest gelesen wird.
- `confirmed_findings` duerfen Host-Accept/Open, Wrong-Team-Reject, State-Mutation-Reject und Door-Open-Producer nur aus Capture-/Workbench-Daten ableiten.
- `open_manual_findings` bleiben Pflicht, solange Required-Checks in der Workbench nicht erledigt sind.
- `manual_review_required = true`, `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.
- Der empfohlene naechste Task darf aus den Findings abgeleitet werden, darf aber keine Door-, Terrain-, Mission- oder Multiplayer-Wahrheit setzen.

## Host/Client Door Real Click Manual Run Packet
- `capture_host_client_two_window_real_run.ps1` darf Door-spezifische Manual-Run-Felder in `tmp/host_client_two_window_real_run_review.json` schreiben.
- Das Packet nennt Workbench-Pfad, Findings-Manifest, erwartete Door-Button-/Shortcut-/GO-/Reject-/Open-/HUD-Felder und offene Manual-Checks.
- `door_real_click_manual_run_gate` darf nur `manual_open` oder `review_ready` melden; `door_real_click_manual_review_done` bleibt false, bis die Workbench bewusst ausgefuellt wurde.
- Das Packet ist Review-/Runbook-Evidence und darf keine Door-, Terrain-, Mission- oder Multiplayer-Wahrheit setzen.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Door Authority Feedback Polish
- `MissionInteractionDoorMultiplayerAuthority.build_ui_feedback()` liefert zusaetzlich `compact_line`, `player_hint`, `next_action`, `severity` und `reject_reason_label`.
- Diese Felder sind Anzeige-/Feedbackdaten fuer Button, Tooltip, Command-Panel, Reports und Verifier; sie setzen keine Door-, Terrain- oder Multiplayer-Wahrheit.
- Wrong-Team-Rejects muessen spielbar als Team-/Berechtigungsproblem lesbar sein, statt nur rohe Contract-Keys zu zeigen.
- State-Mutation-Rejects muessen als Client-/Runtime-State-Blocker lesbar sein.
- Ready/Accepted/Open muessen kurz bleiben: Ready nennt Shortcut plus GO, Accepted nennt Host/Runtime-Progress, Open nennt Runtime-Override.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Door Authority Compact HUD Surface
- Die sichtbare Mission-Command-Feedback-Zeile darf `mission_interaction_door_authority_ui_feedback.compact_line` bevorzugen.
- Wenn `compact_line` fehlt, muss sie auf `summary_line` zurueckfallen, damit alte Snapshots lesbar bleiben.
- Pending ohne nutzbare Door bleibt im Command-Feedback unsichtbar, um HUD-Rauschen zu vermeiden.
- `get_command_feedback_snapshot()` exportiert die tatsaechlich sichtbare Door-Zeile als `mission_interaction_door_authority_visible_line`.
- Diese Surface-Zeile bleibt Anzeige und darf keine Door-, Terrain-, Command- oder Multiplayer-Wahrheit setzen.

## Door Authority Button Affordance
- Der Door-Breach-Button darf `door_authority_ui_severity` als rein visuelle Affordance nutzen.
- Erlaubte Affordance-Tones sind `action`, `success`, `warning` und `neutral`.
- Der Button-Snapshot exportiert `door_authority_affordance_style_id`, `door_authority_affordance_tone` und `door_authority_affordance_visual_weight`.
- Affordance-Farben und Gewicht duerfen den Button hervorheben, aber keine Commands ausloesen und keine Door-, Terrain- oder Multiplayer-Wahrheit setzen.
- Der allgemeine Tactical-Button-Skin bleibt Basis; die Door-Affordance ist eine kleine Statusschicht darueber.

## Mission Door Layout/Visual Polish
- Door-Object-Reactions duerfen rein visuelle Layout-Felder exportieren: `door_visual_polish_style_id`, `door_layout_readout`, `door_layout_tone` und `door_layout_visual_weight`.
- Erlaubte Door-Layout-Tones sind `blocked`, `action` und `success`; sie stehen fuer closed, opening und open.
- `door_layout_readout` ist Spieler-/Report-Text und darf keine neue Runtime-Wahrheit erzeugen.
- `TerrainMap3DView` darf die Felder fuer Proxy-Footprint, Status-Header und Open-Clearance-Halo verwenden.
- Walkability, LOS, Cover und Object-Height bleiben beim Door Runtime Collision/LOS Producer und der effektiven `TerrainRegistry`.
- `read_only = true`, `ui_sets_gameplay_truth = false` und `door_visual_sets_gameplay_truth = false` bleiben Pflicht.

## Door/Computer/Cargo Smoke
- Der integrierte Stations-Smoke darf eine temporare Scenario-Variante mit Door, Computer und Cargo-Interaction schreiben.
- Door-Open darf als Object-Reaction und Render-Snapshot sichtbar werden, aber kein Objective-Gate ersetzen oder ueberspringen.
- Der Computer-Schritt bleibt das naechste Objective-Gate nach deaktivierter AA, auch wenn die Door vorher sichtbar geoeffnet wurde.
- Cargo-Departed schliesst den Objective-Gate-Snapshot erst nach Computer-Control ab.
- Das Smoke-Manifest bleibt Arbeits-/Test-Evidence mit `read_only = true` und `ui_sets_gameplay_truth = false`.

## Station Route Visual Evidence
- Die Stationsroute darf als FullHD-Evidence-Paket aus Mission-Testszene, Render-Snapshot, Objective-Gate-Snapshot und Command-Feedback geschrieben werden.
- Wenn ein echter Viewport-Readback im Headless-Lauf nicht verfuegbar ist, darf ein generiertes Review-Board aus denselben Snapshots geschrieben werden.
- Das Manifest muss `manual_window_review_required = true` und `manual_window_review_done = false` setzen, bis ein Mensch die echte Fensteransicht beurteilt.
- Evidence darf Door-/Computer-/Cargo-Lesbarkeit, PNG-/Manifest-Pfade und offene manuelle Checks festhalten, aber keine Runtime-Interaction dauerhaft starten und keine Gameplay-Wahrheit schreiben.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Route Window Playtest Notes
- `StationRouteWindowPlaytestNotes` erzeugt eine read-only Notizschale fuer den echten Fensterblick auf Door -> Computer -> Cargo.
- Der Snapshot nennt TASK_708-Evidence-Quellen, Required-Checks, Notizfelder, Reportpfad, Manifestpfad und `recommended_next_task`.
- Required-Checks betreffen echte Fensteransicht, Door-Lesbarkeit, Computer-/Cargo-Lesbarkeit, HUD-Overlap, Kamera/Zoom, Performance-Gefuehl und den bewusst gesetzten menschlichen Sichtentscheid.
- `manual_window_review_done` bleibt false, bis ein Mensch die Workbench ausfuellt und den Sichtentscheid bewusst markiert.
- Die HTML-Workbench `docs/reports/station_route_window_playtest_notes_2026_07_01.html` darf lokale JSON-Arbeitsnotizen exportieren, aber keine Projektdateien schreiben und keine Gameplay-Wahrheit setzen.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Route Polish Readiness Findings
- `StationRoutePolishReadinessFindings` bewertet TASK_708-Evidence und TASK_709-Fensternotizen read-only.
- Der Snapshot trennt technische Blocker, Polish-Warnungen und offene manuelle Sichtentscheidungen.
- Fehlende Evidence, falsches Schema, UI-Truth-Verletzungen, unvollstaendige Objective-Gates oder nicht sichtbares Door-Open sind technische Blocker.
- Generiertes Review-Board, fehlender Viewport-Readback und offene Fenster-Checks sind manuelle Hinweise, keine technischen Blocker.
- Ein generiertes Station-Route-Board soll `evidence_board_style_id = station_route_labeled_v1` und mindestens acht Labels liefern; sonst meldet der Readiness-Snapshot eine Polish-Warnung.
- `visual_polish_ready` darf true werden, wenn die technischen Blocker fehlen; `host_client_acceptance_ready` darf erst true werden, wenn der echte Fensterentscheid erledigt ist und keine Polish-Warnung offen ist.
- Findings duerfen `recommended_next_task` nennen, aber keine Visuals aendern, keine Runtime-Interaction starten und keine Gameplay-Wahrheit setzen.

## Station Route Evidence Board Visual Polish
- Das TASK_708-Headless-Review-Board darf pixelbasierte Labels, Legende und Statuszeilen zeichnen, um Door, Computer, Cargo und Review-Status lesbar zu machen.
- Der Board-Polish ist ein Evidence-/Review-Artefakt und darf keine Runtime-Interaction starten, keine Objective-Gates setzen und keine Gameplay-Wahrheit schreiben.
- Das Manifest nennt `evidence_board_style_id`, `evidence_board_label_count`, `read_only` und `ui_sets_gameplay_truth`.
- `station_route_labeled_v1` ist der aktuelle Mindeststandard fuer generierte Station-Route-Evidence, solange echte Viewport-Pixel im Headless-Lauf nicht verfuegbar sind.

## Station Route Host/Client Acceptance Packet
- Der vorhandene Zwei-Fenster-Capture `capture_host_client_two_window_real_run.ps1` darf das read-only Manifest um Station-Route-Acceptance-Felder erweitern.
- Das Manifest nennt Quellen aus TASK_708, TASK_709 und TASK_710, erwartete Sequenz `door_open -> computer_controlled -> cargo_departed`, Host-/Client-Pfade, Wrong-Team-Reject, Snapshot-Sync und HUD-Surfaces.
- `station_route_host_client_acceptance_review_required` bleibt true und `station_route_host_client_acceptance_review_done` bleibt false, bis ein Mensch den echten Host/Client-Lauf bewertet.
- `station_route_host_client_acceptance_gate` darf nur `manual_open` oder `review_ready` sein.
- Das Paket ist eine Run-/Review-Anleitung und darf keine Runtime-Interaction starten, keine Objective-Gates setzen, keine Peer-Wahrheit schreiben und keine Gameplay-Wahrheit mutieren.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Route Host/Client Findings
- `StationRouteHostClientFindings` bewertet das TASK_712-Acceptance-Manifest read-only.
- Der Snapshot trennt technische Paket-Blocker, Paket-Warnungen und offene manuelle Host/Client-Findings.
- Fehlendes Manifest, falsches Schema, falsche TASK_712-ID, read-only/UI-Truth-Verletzung, fehlende Door/Computer/Cargo-Sequenz oder fehlende Manual-/Review-Checks sind technische Blocker.
- `manual_open` bleibt `needs_real_run`; daraus darf kein bestandener Multiplayerbefund abgeleitet werden.
- `review_ready` mit Run-/Screenshot-Evidence wird `ready_for_findings_review`, bis ein Mensch den Befund bewusst bewertet.
- `review_done` ohne Real-Run-/Screenshot-Evidence blockiert.
- Findings duerfen `recommended_next_task` nennen, aber keine Fenster starten, keine Runtime-Interaction ausloesen, keine Objective-Gates setzen, keine Peer-Wahrheit schreiben und keine Gameplay-Wahrheit mutieren.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Route Multiplayer Scenario Guard
- Der TASK_714-Guard kombiniert die bestehende Mission-Testszene mit Station-Route-Gates, Door-Multiplayer-Authority und Multiplayer-Snapshot-Sync.
- Peer 1/Team Alpha darf den Door-Command fuer die Station-Route absenden; Peer 2/Team Bravo muss fuer denselben Alpha-Command abgewiesen werden.
- Runtime-State-Mutation im Netzwerkcommand bleibt verboten; Door-Walkability/LOS darf nur ueber den Door-Runtime-Producer oeffnen.
- Door-Open darf den Computer-Gate nicht ueberspringen; Computer-Control muss Cargo freischalten; Cargo-Departed muss `all_gates_complete` setzen.

## Station Route Empty Event Log Polish
- Das `TacticalEventLogPanel` darf im leeren Zustand visuell einklappen, damit es im echten Host/Client-Fenster keine Kartenflaeche verdeckt.
- Der eingeklappte Empty-State muss `empty_state_collapsed = true`, `visibility_mode = collapsed_empty`, `visible = false` und `mouse_filter = MOUSE_FILTER_IGNORE` im Snapshot melden.
- Sobald gefilterte Event-Eintraege existieren, muss das Panel wieder sichtbar werden und den bestehenden Scroll-/Filterpfad benutzen.
- Das Einklappen ist reines UI-Feedback. Es darf keine Tactical-Event-Wahrheit, keinen Mission-State, keinen Multiplayer-State und keine SimulationRoot-Daten mutieren.

## Station Route Run Readout Polish
- `get_command_feedback_snapshot()` darf eine kompakte `station_route_run_readout`-Fassade exportieren, die Objective-Gate- und Object-Reaction-Snapshots nur read-only zusammenfasst.
- Die Route-Line muss AA, Door, Computer, Cargo und ein `NEXT`-Token nennen, damit der Commander die Stationssequenz im HUD als eine Kette lesen kann.
- Door-, Computer- und Cargo-Status duerfen nur aus bestehenden Runtime-/Interaction-Snapshots abgeleitet werden; die Readout-Line darf keine Gates setzen, keine Interactions starten und keine Multiplayer-Wahrheit schreiben.
- Die sichtbare Command-Feedback-Zeile und die Mission-Control-Density-Line duerfen diese Route-Line anzeigen, solange `read_only = true` und `ui_sets_gameplay_truth = false` erhalten bleiben.
- Der Guard darf Server-/Client-Snapshot-Annahme pruefen, aber keine echte Fenster-Sichtbarkeit, keine Bedienqualitaet und keinen abgeschlossenen Host/Client-Playtest behaupten.
- Das Manifest bleibt read-only, fordert weiter manuelle Review und setzt keine Gameplay-Wahrheit.

## Station Route Real Host/Client Click Findings
- `StationRouteRealClickFindings` bewertet das echte TASK_712-Capture-Manifest und das TASK_716-Route-Readout-Manifest read-only.
- Der Snapshot trennt technische Blocker, Warnungen und offene manuelle Klickbefunde.
- Fehlendes Capture, fehlende Screenshots, falsche Schemas, falsche Task-IDs, fehlende Review-Checks oder read-only/UI-Truth-Verletzungen blockieren.
- Eine valide Route-Line muss AA, Door, Computer, Cargo und `NEXT DONE` enthalten, damit der echte Fensterlauf nicht ohne HUD-Route bewertet wird.
- `ready_for_click_findings_review` bedeutet nur: Capture und Route-Line sind auswertbar; der menschliche Klick-/Sichtbefund ist weiter offen.
- Findings duerfen `recommended_next_task` nennen, aber keine Fenster starten, keine Runtime-Interaction ausloesen, keine Objective-Gates setzen, keine Peer-Wahrheit schreiben und keine Gameplay-Wahrheit mutieren.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Route Door/GO/Reject Visual Polish
- Door-Authority-UI-Feedback darf Standard-Door-Token nicht doppelt ausgeben: `DOOR B->GO` statt `DOOR DOOR B->GO`.
- Benannte Door-Tokens bleiben erlaubt, zum Beispiel `DOOR A1 B->GO`.
- Die sichtbare Ready-Zeile muss die GO-Pflicht kurz nennen; der `DoorBreachButton` darf dazu im Ready-Zustand `B->GO` anzeigen.
- Open-, Host- und Blocked-Zeilen bleiben kompakt: `DOOR OPEN`, `DOOR HOST OK`, `DOOR BLOCKED ...`.
- Wrong-Team- und State-Mutation-Rejects behalten ihre lesbaren Spielergruende aus dem Door-Authority-Feedback.
- Der Polish ist reine Anzeige. Buttontext, Compact-Line, Tooltip und Capture-Erwartungen duerfen keine Commands ausloesen, keine Runtime-Interaction starten, keine Objective-Gates setzen und keine Gameplay-Wahrheit mutieren.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Route Post-Polish Recheck Guard
- `StationRoutePostPolishRecheck` bewertet TASK_718-Polish-Evidence zusammen mit dem Host/Client-Capture-Manifest read-only.
- Der Guard erkennt stale Capture-Erwartungen, wenn ein Manifest nach TASK_718 noch `DOOR DOOR B->GO` oder `DOOR DOOR OPEN` erwartet.
- `needs_capture_refresh` bedeutet: Code-/Polish-Evidence ist aktuell, aber der echte Fensterbefund muss nach dem sichtbaren Textwechsel erneuert werden.
- `ready_for_real_window_recheck` bedeutet: Capture-Erwartungen sind frisch und der menschliche Fensterentscheid bleibt offen.
- Der Guard darf keine Fenster starten, keine Runtime-Interaction ausloesen, keine Objective-Gates setzen, keine Peer-Wahrheit schreiben und keine Gameplay-Wahrheit mutieren.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Route Two-Window Visual Findings
- `StationRouteTwoWindowVisualFindings` bewertet den frischen Host/Client-Capture und den TASK_719-Recheck zusammen mit einem expliziten Sichtbefund read-only.
- Der Snapshot unterscheidet technische Blocker, offene Sichtpruefung und konkrete Visual-Polish-Punkte.
- Fehlende Capture-/Screenshot-/Recheck-Evidence blockiert, damit ein veralteter oder unvollstaendiger Fensterlauf nicht als spielbarer Befund gelesen wird.
- `needs_visual_review` bedeutet: Capture und Recheck sind bereit, aber der Host-/Client-Screenshot wurde noch nicht bewusst bewertet.
- `needs_visual_polish` bedeutet: Der Sichtbefund ist gemacht und konkrete UI-Reibungen wie Kartenueberdeckung, kleine Station-Labels, gedrungene Door-/Route-Texte oder leer wirkende Header-Platzhalter sollen vor Akzeptanz poliert werden.
- Findings duerfen `recommended_next_task` nennen, aber keine Fenster starten, keine Runtime-Interaction ausloesen, keine Objective-Gates setzen, keine Peer-Wahrheit schreiben und keine Gameplay-Wahrheit mutieren.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Route HUD Visual Polish
- TASK_722 darf den Mission-HUD-Layout-Contract, Mini-Fireteam-Karten-Dichte, Top-Nav-Placeholder-Verhalten und 3D-Label-Darstellung polieren.
- `DropLightLayoutContract.get_mission_hud_layout()` ist die Quelle fuer die kompaktere linke HUD-Spalte; Runtime-Code darf die neuen Rechtecke anwenden, aber keine Mission-, Door-, Objective- oder Multiplayer-Wahrheit daraus ableiten.
- `get_station_route_hud_visual_polish_snapshot()` fasst Fireteam-Mini-Rect, Scroll-Erhalt, Station-Label-Style, Route-Label-Backplates und Top-Nav-Placeholder read-only zusammen.
- Der Gate-Wert `ready_for_recapture` bedeutet nur: Die TASK_721-Visual-Reibungen wurden technisch adressiert und muessen im echten Host/Client-Fenster erneut beurteilt werden.
- Label-Backplates, Outline, Font-Groesse und Stagger-Abstaende sind reine Darstellung im `TerrainMap3DView`; sie duerfen keine Interactions starten, keine Objective-Gates setzen und keine Collision-/LOS-Wahrheit mutieren.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Route Host/Client Recapture Review
- `StationRouteHostClientRecaptureReview` bewertet den Nach-TASK_722-Host/Client-Capture zusammen mit dem TASK_722-HUD-Polish-Manifest read-only.
- Das Capture-Manifest muss TASK_722 und TASK_723 explizit referenzieren, `station_route_hud_polish_recapture_done = true` melden und die neuen Review-Checks fuer Fireteam-Mini-Safe-Margin, Label-Backplates und versteckten Nav-Placeholder enthalten.
- Der Snapshot unterscheidet technische Blocker, fehlenden Recapture, offenen menschlichen Sichtentscheid, Folge-Polish und Akzeptanzbereitschaft.
- Ohne expliziten `visual_review_done` bleibt der Status `needs_visual_review`; TASK_723 darf keinen bestandenen Sichttest aus technischer Evidence ableiten.
- Folge-Polish-Flags duerfen TASK_724 empfehlen, aber keine Runtime-, Door-, Objective- oder Multiplayer-Wahrheit setzen.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Route Recapture Visual Followup
- TASK_724 darf nur die sichtbaren Recapture-Reibungen polieren: TopNav-Breite, Fireteam-Mini-HUD-Footprint, Eventlog-Anschluss und Station-/Route-Label-Abstaende.
- `DropLightLayoutContract.get_mission_hud_layout()` bleibt die Quelle fuer die festen Mission-HUD-Rechtecke; Runtime-Code darf daraus keine Mission- oder Multiplayer-Wahrheit ableiten.
- `get_station_route_recapture_visual_followup_snapshot()` meldet Layout-Deltas, Label-Abstandsparameter und `ready_for_recapture` read-only.
- Label-Font, Pixel-Size, Outline, Height-Step und Stagger-Offsets sind reine Darstellung im `TerrainMap3DView`.
- Der Gate-Wert `ready_for_recapture` bedeutet nur: Der sichtbare Folge-Polish ist technisch angewendet und braucht einen frischen Host/Client-Capture.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Route Host/Client Recapture Acceptance Review
- `StationRouteRecaptureAcceptanceReview` bewertet den Nach-TASK_724-Host/Client-Capture zusammen mit dem TASK_724-Followup-Manifest read-only.
- Das Capture-Manifest muss TASK_724 und TASK_725 explizit referenzieren, `station_route_visual_followup_recapture_done = true` melden und Review-Checks fuer TopNav, Fireteam-Mini, Label-Abstand und kleinen Multiplayer-Slice enthalten.
- Der Snapshot unterscheidet technische Blocker, fehlenden Recapture, offenen menschlichen Sichtentscheid, Folge-Polish, fehlende Akzeptanzentscheidung und `accepted_for_next_slice`.
- `accepted_for_next_slice` gilt nur fuer den kleinen Station-Route-Multiplayer-Slice. Es ist keine Gesamtspiel-, Mission-Editor- oder Release-Abnahme.
- Folge-Polish-Flags duerfen TASK_726-Polish empfehlen; ein sauberer Sichtentscheid empfiehlt den naechsten kompakten Scenario-Drill.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## One-Screen Multiplayer Station Scenario Drill
- TASK_726 definiert `station_route_one_screen_multiplayer_drill` als konkreten Szenario-Datensatz fuer AA -> Door -> Computer -> Cargo.
- `StationRouteOneScreenScenarioDrill` bewertet Szenario, TASK_725-Akzeptanz und Runtime-Gate-Lauf read-only.
- Das Szenario muss Singleplayer, Coop und `multiplayer_pvp` nennen, Alpha/Bravo-Team-Slots haben und Bravo als NPC-Verteidigung mit PvP-Option tragen.
- Die Route-Tokens muessen `AA`, `DOOR`, `COM`, `CARGO` bleiben; der Runtime-Verifier muss zeigen, dass Door nicht Computer oder Cargo ueberspringt.
- `ready_for_f6_host_client_playtest` bedeutet nur: Daten-/Runtime-Kette ist bereit fuer einen sichtbaren F6/Host-Client-Playtest. Es ist kein Balancing- oder Release-Gate.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Scenario F6/Host Client Playtest Notes
- `StationScenarioF6HostClientPlaytestNotes` bewertet das TASK_726-Drillmanifest zusammen mit einem optionalen menschlichen Workbench-Export read-only.
- Ohne gueltiges TASK_726-Manifest blockiert der Snapshot. Ohne bewussten Workbench-Export bleibt er `needs_visible_playtest`.
- Required-Checks betreffen echtes F6-Fenster, Host/Client-Zwei-Fenster-Lauf, AA -> Door -> Computer -> Cargo-Lesbarkeit, Fireteam-Order-Tempo, Performance, HUD-Overlap und Wrong-Team-/Bravo-Kontext.
- Follow-up-Flags duerfen Route-/HUD-/Performance-/Sync-/Command-Feedback-Polish oder alte Harness-Modernisierung empfehlen, setzen aber keine Runtime-, Door-, Objective- oder Multiplayer-Wahrheit.
- Die HTML-Workbench `docs/reports/station_scenario_f6_host_client_playtest_notes_2026_07_01.html` exportiert lokale JSON-Arbeitsnotizen; diese Notizen sind Review-Evidence, keine Projektdateien und keine Gameplay-Wahrheit.
- `needs_followup_polish` und `ready_for_findings` empfehlen TASK_728, damit echte Notizen zuerst als Findings verdichtet werden, bevor Code-Polish daraus entsteht.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Scenario Playtest Findings
- `StationScenarioPlaytestFindings` verdichtet TASK_727-Playtestnotizen read-only zu einem Findings-Gate.
- Fehlende, blockierte oder nicht-read-only TASK_727-Notizen blockieren TASK_728.
- Offene menschliche Notizen bleiben `needs_visible_playtest`; TASK_728 darf daraus keine bestandene Sichtabnahme machen.
- Aktive Follow-up-Flags werden zu Action Items fuer Route Readability, HUD Overlap, Performance, Host/Client Sync, Command Feedback oder Harness-Modernisierung.
- Saubere erledigte Notizen ohne aktive Issue-Flags duerfen `ready_for_next_playable_slice` melden, bleiben aber Review-Evidence und keine Gameplay-Wahrheit.
- Das Manifest `tmp/station_scenario_playtest_findings.json` darf naechste Tasks empfehlen, setzt aber keine Runtime-, Door-, Objective-, Team- oder Multiplayer-Wahrheit.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Scenario Visible Playtest Run Packet
- `MissionTestSetup.apply_cmdline_scenario_override()` darf `--scenario-file=` und `--mission-scenario=` aus sichtbaren Launch-Args in `scenario_file_path` uebernehmen.
- Dieser Override ist nur ein Setup-/Authoring-Einstieg fuer die Szene; echte Runtime-Gates, Door-State, Objective-Progress und Multiplayer-Authority bleiben bei den bestehenden Runtime-Systemen.
- `launch_host_client_two_window_review.ps1 -ScenarioPath ...` muss den Scenario-Pfad als `--scenario-file=...` in Host- und Client-Fenster weiterreichen und im Launch-Plan dokumentieren.
- `prepare_station_scenario_visible_playtest_run.ps1` erzeugt ein read-only Packet mit Szenario, Workbench-URI, TASK_726/727/728-Status, Required-Checks und Start-/Capture-Kommandos.
- Der Packet-Status `ready_to_run_visible_playtest` bedeutet nur: alles ist vorbereitet, um den sichtbaren Lauf auszufuehren. Er ist keine menschliche Abnahme.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Scenario Targeted Playtest Polish
- Der Mission-Identity-Body darf die bestehende `station_route_run_readout`-Zeile prominent anzeigen, wenn der Station-Route-Drill aktiv ist.
- Diese Zeile muss aus Objective-Gate- und Object-Reaction-Snapshots stammen; der Header darf keine Gates, Door-States, Cargo-States, Teams oder Commands setzen.
- `build_station_scenario_identity_body_snapshot()` liefert Badge, Route-Line, Next-Token, Style-ID und Zeichenbudget als read-only Review-/HUD-Daten.
- Host/Client-Review-Badges wie `HOST P1 ALPHA` oder `CLIENT P2 BRAVO` bleiben im Header erhalten und werden nur mit der Route kombiniert.
- Der Capture-Befund aus TASK_729 kann daraus TASK_730-Polish ableiten, bleibt aber weiterhin keine bestandene menschliche TASK_727-Workbench-Abnahme.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Scenario Workbench Export Review
- `StationScenarioWorkbenchExportReview` bewertet nur exportierte TASK_727-Notizen und TASK_728-Findings; er startet keinen Playtest und fuellt keine Workbench automatisch aus.
- Fehlender oder offener Workbench-Export bleibt `needs_workbench_export`, selbst wenn technische Captures und TASK_730-Polish gruen sind.
- Ungueltige Schemas, falsche Task-IDs oder read-only/UI-Truth-Verletzungen blockieren.
- Aktive Issue-Flags werden auf Post-TASK_730-Folge-Slices geroutet: Route Cue, HUD Overlap, Performance Feel, Host/Client Sync, Command Feedback oder Harness Modernization.
- `ready_for_next_playable_slice` ist nur zulaessig, wenn TASK_727 erledigte, issue-freie Notizen und TASK_728 passende Findings liefern.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Scenario Route Cue Polish
- `StationScenarioRouteCuePolish` uebersetzt den bestehenden Station-Route-Readout, Objective-Gate, Use-Feedback und Progress-Readability in eine kurze `CUE ...`-Zeile.
- Die Route-Line bleibt der Ablaufstatus (`ROUTE AA > DOOR > COM > CARGO | NEXT ...`); die Cue-Line beschreibt die naechste Spielerhandlung wie Annaehern, `BREACH + GO`, Halten oder Debrief pruefen.
- `MissionTacticalSandboxController.get_command_feedback_snapshot()` exportiert `station_scenario_route_cue_line`, Detail, Next-Token und Line-Limit.
- Der Mission-HUD-Density-Snapshot darf dieselbe Cue-Zeile in der ACT-Flaeche zeigen, aber keine Scenario-Gates, Door-States, Cargo-States oder Commands setzen.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht; Completion kommt weiter aus Runtime-Gates und Interaction-Progress.

## Station Scenario HUD Overlap Pass
- Wenn die volle Station-Route bereits im Mission-Identity-Body sichtbar ist, soll die knappe Mission-Control-/ACT-Flaeche die `CUE ...`-Handlungszeile priorisieren.
- Der Density-Snapshot behaelt die volle Route als Source-Feld, markiert aber `station_route_line_deferred_to_identity = true`, wenn Route und Cue beide aktiv sind.
- Die ACT-Line darf dann die Cue-Line enthalten, soll aber nicht gleichzeitig die komplette Route-Line wiederholen.
- `get_station_scenario_hud_overlap_pass_snapshot()` exportiert Route-in-Identity, Cue-in-ACT, Linebudget und sichtbaren Linecount fuer Verifier/Reports.
- Diese Entdichtung bleibt Anzeigeverhalten: keine Scenario-Gates, keine Door-/Cargo-States, keine Commands und keine Gameplay-Wahrheit werden gesetzt.

## Station Scenario Performance Feel Pass
- `get_station_scenario_performance_feel_pass_snapshot()` kombiniert einen wiederholten Command-Feedback-Snapshot-Sample mit HUD-Density-, Route-Overlap- und Cue-Gates.
- Das Headless-Gate prueft strukturelles Reaktionsgefuehl: Snapshot-Budget, Zeichenbudget, sichtbarer Linecount, Route-in-Identity und Cue-in-ACT.
- Der Snapshot darf `performance_gate`, `ready_for_visible_playtest`, Samplezeiten und Budgetwerte exportieren, aber keine Runtime- oder UI-Wahrheit setzen.
- Das Budget kommt aus `data/performance_budget_contract.json`; maschinenabhaengige FPS/GPU-/Netzwerkstutter bleiben Godot-Profiler- und TASK_727-Fensterarbeit.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Scenario Current Report Sync Guard
- TASK_707 und TASK_714 muessen ihre Report-Anker gegen `docs/reports/project_current_state_handbook_2026_07_01.html` pruefen, solange dieser Bericht der aktuelle Iststand-/Handbuch-Report ist.
- Der Guard prueft nur Evidence-/Report-Konsistenz: TASK_707-Playtest-Anker, TASK_714-Manifest-Anker, Statusfelder und stale Reportpfade.
- Das Manifest `tmp/station_scenario_current_report_sync_guard.json` darf Reportpfade, Anker und Rebase-Status exportieren, aber keine Runtime starten und keine Gameplay-Wahrheit setzen.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Scenario Command Feedback Polish
- `StationScenarioRouteCuePolish` bleibt der einzige Presenter fuer die Stations-Cue-Zeile; TASK_736 erweitert nur Sprache und Lesbarkeitsmetadaten.
- Out-of-Range-Cues sollen Fireteam, Handlung und formatierte Distanz nennen, z. B. `CUE AA: BLUE naeher ran | 3.9km`.
- Usable-Cues sollen das Fireteam vor der Aktion nennen, z. B. `CUE DOOR: FT1 BREACH + GO`.
- Der Snapshot exportiert `distance_text`, `feedback_style_id`, `contains_distance_text` und `uses_player_action_language`, darf aber keine Objective-Gates, Door-/Cargo-States oder Commands setzen.
- Die Mission-HUD-Density darf `interaction_progress_line` als Source behalten, soll sie aber aus der knappen ACT-Zeile entfernen, wenn eine Station-Cue aktiv ist und nicht selbst `in_progress` meldet. So steht bei `CUE AA` keine Future-Cargo-Blockade direkt daneben.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Scenario Visible Cue Run Packet Refresh
- Das sichtbare TASK_729-Run-Packet darf nach TASK_736 zusaetzliche Review-Erwartungen fuer die polierte Cue-Sprache tragen, bleibt aber Besitzer des urspruenglichen Run-Packets.
- `refresh_task_id = TASK_737` und `latest_feedback_task_id = TASK_736` markieren, dass der sichtbare Lauf mit aktueller Command-Feedback-Sprache geprueft werden soll.
- `visible_feedback_expectations` darf erwartete Fragmente wie `CUE AA`, `BLUE naeher ran` und `3.9km` sowie verbotene Altfragmente wie `BLUE 3859m`, `3859m` und `CARGO blockiert` fuer die knappe Cue-/ACT-Pruefung nennen.
- Required-Checks fuer polierte Cue, versteckte Rohdistanz und ausgeblendeten Future-Cargo-Blocker sind Arbeitsnotizen fuer den menschlichen TASK_727-Lauf, keine bestandene Sichtabnahme.
- `manual_review_done` bleibt false, bis ein Mensch die TASK_727-Workbench wirklich ausfuellt und JSON exportiert.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Scenario Identity Cue Visibility Polish
- Der Mission-Identity-Body darf die aktuelle Station-Cue vor die Route setzen, damit der erste Blick die naechste Spielerhandlung liest.
- Die sichtbare Route im Identity-Body soll als neutrale Sequenz erscheinen, z. B. `ROUTE AA > DOOR > COM > CARGO | NEXT AA`, solange ein frueherer Schritt aktiv ist.
- Die volle `route_line` mit Gate-/Cargo-Status bleibt als Source im Snapshot erhalten; nur `display_route_line` wird fuer die sichtbare, ruhigere Anzeige genutzt.
- Future-Blocker wie `CARGO BLOCK`, `CARGO BLOCKED` oder `CARGO blockiert` duerfen in der sichtbaren Identity-Display-Zeile nicht mit der aktiven AA-Cue konkurrieren.
- Label-Metadaten und Command-Feedback duerfen `cue_visible`, `display_route_line` und `future_blocker_hidden_in_display` exportieren, setzen aber keine Runtime-Gates, Door-/Cargo-States oder Commands.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Scenario Identity Cue Recapture Findings
- Der Nach-TASK_738-Recapture darf als read-only Findings-Manifest zusammengefuehrt werden, wenn `tmp/host_client_two_window_real_run_review.json` realen Lauf und Host-/Client-Crops meldet.
- Das Findings-Manifest darf aktuelle Identity-Body-Snapshotdaten wie `cue_visible`, `display_route_line` und `future_blocker_hidden_in_display` aufnehmen.
- Der Status `ready_for_task_727_workbench_export` bedeutet nur: Die technische und sichtbare Evidence ist vorbereitet. Er ist keine menschliche TASK_727-Abnahme.
- `manual_review_done` bleibt false, bis die TASK_727-Workbench wirklich exportiert wurde.
- `recommended_next_task` soll zur TASK_727-Workbench fuehren; Harness-Modernisierung bleibt nur fuer belegte Start-/Capture-/Sync-Probleme.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Scenario Workbench Recapture Prefill
- Die TASK_727-Workbench darf Recapture-Felder aus TASK_739 vorbefuellen: Manifestpfad, Host-/Client-Crops, erwartete Cue, neutrale Display-Route und Recapture-Status.
- Diese Prefill-Daten sind Vergleichs- und Review-Hilfe. Sie duerfen `station_scenario_playtest.playtest_done`, `manual_review_done`, Route-Gates, Cargo-Gates, Door-State, Commands oder Peer-State nicht setzen.
- `StationScenarioF6HostClientPlaytestNotes` darf optionale Recapture-Findings im Snapshot unter `recapture_evidence` exportieren, solange `read_only = true` und `ui_sets_gameplay_truth = false` erhalten bleiben.
- Ein offener Workbench-Export bleibt `needs_visible_playtest`, auch wenn Recapture-Evidence vollstaendig ist.
- Die naechste echte Entscheidung bleibt der menschliche TASK_727-Export; TASK_740 bleibt nur bei belegtem Harness-Problem vorgesehen.

## Station Scenario Cargo Endgame Cue Polish
- Der Route-Cue-Presenter darf fuer `CARGO` eigene Endgame-Sprache erzeugen, solange er nur vorhandene Objective-/Use-/Progress-Snapshots liest.
- Erwartete Cargo-Cues sind: `halten bis Abflug` fuer laufenden Cargo-Hold, `Abflug laeuft` fuer den Abflug und `Cargo weg | Debrief` fuer Abschluss/Done.
- Der Presenter darf kurze Zeit-/Prozentfragmente aus vorhandenen Progress-Zeilen uebernehmen, aber keine Cargo-, Gate-, Mission-Result- oder Debrief-Wahrheit setzen.
- AA-/Door-/Computer-Cues bleiben kompatibel mit der bisherigen `station_route_player_action_cue_v2`-Sprache.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben Pflicht.

## Station Scenario Debrief Handoff Cue
- Der Station-Handoff-Snapshot darf Route-Readout, Route-Cue, Identity-Body und HUD-Density lesen, um den fertigen Pfad `AA > DOOR > COM > CARGO` zum Debrief zusammenzufassen.
- Erwartete Abschlusszeilen sind `CUE DONE: Cargo weg | Debrief` und `HANDOFF Debrief bereit | danach Homebase`.
- Die Handoff-Kette darf `station_route_complete`, `debrief_review` und `return_homebase` nennen, aber keine Navigation starten, keine Commands erzeugen und keine MissionResult-/Homebase-Wahrheit schreiben.
- Mission Control darf die Handoff-Zeile sichtbar fuehren, solange Source-/Snapshotdaten read-only bleiben.
- `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_navigation = false` und `creates_command = false` bleiben Pflicht.

## Mission FullHD Evidence
- Mission-Interaction-FullHD-Evidence darf aus Mission-Szene, Render-Snapshot, Visual-State-Snapshot, Object-Reaction-Snapshot und Command-Feedback ein PNG/JSON-Paket unter `tmp/` schreiben.
- Wenn ein echter Viewport-Readback nicht verfuegbar ist, darf ein generiertes Review-Board aus denselben Daten geschrieben werden.
- Das Manifest muss `manual_fullhd_review_required = true` und `manual_fullhd_review_done = false` setzen, bis ein Mensch die echte Fensteransicht beurteilt.
- Evidence darf Sichtbarkeit, Snapshot-Zaehler, Visualbudget, Pfade und offene manuelle Checks festhalten, aber keine Runtime-Interaction starten und keine Gameplay-Wahrheit schreiben.
- `ui_sets_gameplay_truth = false` bleibt Pflicht.

## Visual Polish Findings
- `MissionInteractionVisualPolishFindings` bewertet Render-Snapshot und Evidence-Manifest read-only.
- Der Snapshot trennt technische Blocker, Warnungen und offene manuelle Sichtentscheidungen.
- Fehlende Visualstates, fehlende Object-Reactions, leeres Visualbudget oder UI-Truth-Verletzungen sind technische Blocker.
- Ein offener echter FullHD-Sichtlauf ist ein manueller Hinweis und darf nicht als bestandene Sichtabnahme ausgegeben werden.
- Findings duerfen `recommended_next_task` nennen, aber keine Visuals aendern und keine Runtime-/Gameplay-Wahrheit setzen.

## Manual Sight Notes
- `MissionInteractionManualSightNotes` erzeugt eine read-only Notizschale fuer den echten FullHD-Fenster-Sichtlauf.
- Der Snapshot nennt Quellen aus Evidence und Polish-Findings, Required-Checks, Notizfelder, Reportpfad, Manifestpfad und `recommended_next_task`.
- Required-Checks betreffen echte Fensteransicht, Label-Lesbarkeit, Objekt-Proxy-Nutzen, HUD-Overlap, Proxy-Groesse und Label-Groesse.
- `manual_review_done` bleibt false, bis ein Mensch die Workbench ausfuellt und den Sichtentscheid bewusst markiert.
- Die HTML-Workbench `docs/reports/mission_interaction_manual_sight_notes_2026_06_30.html` darf lokale JSON-Arbeitsnotizen exportieren, aber keine Projektdateien schreiben und keine Gameplay-Wahrheit setzen.
- `ui_sets_gameplay_truth = false` bleibt Pflicht.

## Editor Binding Inspector
- `MapEditor.get_mission_interaction_binding_inspector_snapshot()` liest das aktuelle `MissionScenarioData.get_interaction_point_binding_snapshot()` zusammen mit der aktuellen `TerrainMapData`.
- Der Snapshot nennt `binding_count`, `bound_marker_ids`, `missing_marker_ids`, Status-/Typ-Zaehler und die Bindings des selektierten Markers.
- Das Markerpanel zeigt diese Daten read-only ueber `InteractionBindingInspectorLabel`, damit Authoring sofort sieht, ob ein Marker AA, Computer, Cargo, Door oder Hold-Zone traegt.
- Der Inspector darf fehlende Marker sichtbar machen, aber nicht automatisch reparieren, keine Gates setzen und keine Runtime-Interaktion starten.
- `get_map_editor_usability_snapshot().interaction_binding_inspector` exportiert denselben read-only Zustand fuer Verifier und HTML-Reports.

## Editor Binding Editor
- `MapEditor.get_mission_interaction_binding_editor_snapshot()` beschreibt den kleinen Authoring-Editor im Markerpanel.
- Apply/Remove wirken nur auf den aktuell selektierten Marker und schreiben `MissionScenarioData.vertical_slice.interaction_points`.
- Neue Bindings bekommen `interaction_id`, `interaction_type`, `required_order`, `duration_seconds`, `radius_world`, `required_team` und optionale Step-/Gate-Felder.
- Der Editor markiert das Scenario dirty und aktualisiert danach den read-only Binding-Inspector.
- Der Editor startet keine Interaktion, setzt keine Gates, veraendert keinen Runtime-State und meldet `ui_sets_gameplay_truth = false`.

## Editor Binding Presets
- Der Binding-Editor bietet Presets fuer Auto, Door/Breach, Computer/18s, Hold-Zone/12s, AA-Shutdown und Cargo-Landing-Hold.
- Presets fuellen nur sichtbare Authoring-Felder und werden erst mit Apply in `MissionScenarioData.vertical_slice.interaction_points` geschrieben.
- Presets duerfen `step_id`, `gate_id`, `required_state`, `requires_step_id`, Dauer, Radius und Team vorbelegen.
- Cargo-Landing-Hold setzt `requires_step_id = disable_air_defense`, damit die bestehende AA-vor-Cargo-Regel ohne JSON-Handarbeit authorbar bleibt.
- `get_mission_interaction_binding_editor_snapshot()` exportiert `available_presets`, `selected_preset_id` und `preset_preview`, bleibt aber weiter `ui_sets_gameplay_truth = false`.

## Editor FullHD Sight Evidence
- Der FullHD-Sichtpass fuer Interaction-Bindings erzeugt ein read-only Evidenzpaket aus Map-Editor-Snapshot, Inspector-Snapshot, Binding-Editor-Snapshot und sichtbaren Control-Pfaden.
- Der Verifier darf den Editor bei `1920 x 1080` instanziieren, einen Marker selektieren, ein Preset in die sichtbaren Felder laden und daraus PNG/JSON unter `tmp/` schreiben.
- Das Evidenzpaket darf Bedienbarkeit, Sichtbarkeit, Scroll-Erreichbarkeit und Preset-Dichte bewerten, aber keine Runtime-Interaction starten und keine Gameplay-Wahrheit setzen.
- `manual_fullhd_review_required = true` bleibt gesetzt, bis ein echter sichtbarer Fensterlauf mit menschlichem Sichtentscheid vorliegt.

## Editor Binding Focus Scroll
- Wenn ein Marker selektiert wird, darf der Map-Editor den vorhandenen Property-Panel-ScrollContainer auf den Interaction-Binding-Editor ausrichten.
- Preset-Apply, Binding-Apply und Binding-Remove duerfen denselben Fokus erneut setzen, damit Authoring-Aktionen sichtbares Feedback behalten.
- Der Fokus-Scroll wirkt nur auf Editor-Controls und schreibt keinen Scenario- oder Runtime-State.
- `get_mission_interaction_binding_editor_snapshot().focus_scroll` exportiert Scrollbarkeit, sichtbaren Editor-Footprint und `ui_sets_gameplay_truth = false` fuer Verifier.

## Nicht-Ziele
- Kein neues Door-State-System.
- Kein Computer-Hack-Minispiel.
- Kein Capture-/Objective-Rewrite.
- Keine Ressourcen-/Pipeline-Simulation.
- Keine neue UI-Parallelwahrheit fuer Missionsfortschritt.

## Connected Interaction Snapshot Contract
- `MissionCombatLoopDriver` bleibt Besitzer von Interaction-Progress und Scenario-Gates.
- Der Host publiziert `get_mission_interaction_runtime_state_snapshot()` als `mission_interactions` im bestehenden `SimulationRoot`-State-Snapshot.
- `MultiplayerSnapshotContract` uebernimmt nur bekannte skalare Interaction-Felder, sortiert IDs deterministisch und erzwingt `read_only = true` sowie `ui_sets_gameplay_truth = false`.
- Ein Client darf den Snapshot in seine lokale Darstellungs-/Gate-Replik anwenden, aber daraus weder Commands noch Effects erzeugen.
- Door-, Computer- und Cargo-Abschluss werden aus demselben replizierten Interaction-State rekonstruiert; die UI besitzt keine zweite Gate-Wahrheit.
- TASK_1091 prueft den echten ENet-RPC-/Snapshot-Rundweg in einer kompakten Missionsfixture. Vollstaendige 64x64-Renderwelt und Arrival-/Hold-Ausloesung bleiben getrennte Integrationspruefungen.

## Connected Interaction Arrival Hold Contract
- `SimulationRoot.network_command_accepted` meldet nur bereits validierte und enqueuete Host-Commands; Rejects erzeugen kein Signal.
- `MissionCombatLoopDriver` darf daraus einen Pending-Interaction-Eintrag anlegen, wenn Source, Interaction-ID, Unit-ID und Zielposition vollstaendig sind.
- Ankunft wird ausschliesslich an der autoritativen registrierten Unit-Position gegen `interaction_radius_world` gemessen.
- Hold-Zeit verwendet das autoritative `SimulationRoot`-Tick-Delta. Verlaesst die Unit vor Abschluss den Radius, faellt der Pending-Hold auf null zurueck.
- Abschluss laeuft ueber `update_mission_interaction_runtime_progress()` und danach ueber den TASK-1091-Snapshot. Weder Client noch UI besitzen einen Timer oder setzen Door-State.
- TASK_1092 belegt Door-Arrival/Hold ueber echte lokale ENet-RPC. Rejects erzeugen keinen Pending-State.

## Naechste Slices
- Echter FullHD-Fenster-Sichtlauf fuer Interaction-Labels im Editor und Missionsbild mit menschlichem Sichtentscheid.
