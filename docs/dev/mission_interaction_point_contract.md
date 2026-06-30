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
- Echte Breach-/Use-Bedienung und Door-Animationen bleiben eigene Slices.

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

## Naechste Slices
- Echter FullHD-Fenster-Sichtlauf fuer Interaction-Labels im Editor und Missionsbild mit menschlichem Sichtentscheid.
