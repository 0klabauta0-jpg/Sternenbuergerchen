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

## Nicht-Ziele
- Kein neues Door-State-System.
- Kein Computer-Hack-Minispiel.
- Kein Capture-/Objective-Rewrite.
- Keine Ressourcen-/Pipeline-Simulation.
- Keine neue UI-Parallelwahrheit fuer Missionsfortschritt.

## Naechste Slices
- Editor-Inspector fuer Interaction-Point-Bindings.
- FullHD-Readability-Pass fuer Interaction-Labels im Missionsbild.
