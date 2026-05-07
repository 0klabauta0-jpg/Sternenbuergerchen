# TASK_284 - Gameplay Truth Architecture Boundary Audit

## Scope
Geprueft wurden UI, Meta-UI, Editor, Visualizer, Terrain-View, Multiplayer-Command/Snapshot-Pfade und die neuen Tactical-/AirAsset-/Loadout-Datenwege. Der Audit bewertet Architekturgrenzen, setzt aber bewusst keine grossen Gameplay-Fixes um.

## Findings

### Blocker
- Keine Blocker gefunden.

### Important
- `scripts/core/simulation_root.gd:958` bis `scripts/core/simulation_root.gd:1006` wendet Server-Snapshots clientseitig auf `_last_server_state`, Objective-Spiegel und Unit-Fallbacks an. Risiko: Wenn spaeter echte Host-Authority-Units ohne eigenen `apply_remote_snapshot()` in diesen Fallback laufen, koennte ein Mirror-Pfad wie Runtime-Wahrheit wirken. Suggested fix: Fallback weiter als Client-Mirror dokumentieren und in Folge-Gates pruefen, dass produktive Units entweder `apply_remote_snapshot()` besitzen oder nur auf Nicht-Authority-Clients gespiegelt werden. Kein Patch in diesem Audit, weil `apply_multiplayer_snapshot()` keine Commands/Effects enqueued und der bestehende Snapshot-Vertrag diesen Mirror-Pfad erwartet.
- `scripts/tests/mission_tactical_sandbox_controller.gd:4641`, `scripts/tests/mission_tactical_sandbox_controller.gd:4867` und `scripts/tests/mission_tactical_sandbox_controller.gd:7489` bleiben ein breiter historischer Controller/Playtest-Adapter, der AirAssetStatus lokal berechnet und Commands/Effects an `SimulationRoot` uebergibt. Risiko: Neue UI- oder Editor-Slices duerfen dieses Muster nicht kopieren, sonst entsteht eine zweite Wahrheit ausserhalb der Runtime. Suggested fix: Fuer produktive Folgearbeiten die Entscheidung in Runtime-/Resolver-Schichten halten und den Controller nur als Adapter/Smoke-Orchestrator behandeln.

### Cleanup
- `scripts/ui/contextual_help_service.gd:58`, `scripts/ui/contextual_help_service.gd:68`, `scripts/ui/contextual_help_service.gd:118` und `scripts/ui/contextual_help_popup.gd:31` verwalten nur Help-Modus, Global-Help, Payload und Popup-Layout. Kein Befund; der Guard scannt diese Dateien auf Runtime-Mutation, damit Help nicht spaeter Gameplay-State setzt.
- `scripts/tactical/visuals/fireteam_order_visualizer.gd:45`, `scripts/tactical/visuals/fireteam_order_visualizer.gd:53`, `scripts/tactical/visuals/fireteam_order_visualizer.gd:106` und `scripts/tactical/visuals/fireteam_order_visualizer.gd:143` kopieren Plan-/Area-Dictionaries und zeichnen daraus Cache/Hit-Tests. Kein Befund; es bleibt Anzeigezustand ohne `SimulationRoot`-Queue.
- `scripts/editor/map_editor.gd:478`, `scripts/editor/map_editor.gd:1152` bis `scripts/editor/map_editor.gd:1191` und `scripts/editor/map_editor.gd:1377` bis `scripts/editor/map_editor.gd:1384` arbeiten an Map-/Scenario-Authoringdaten und Live-Test-Buttons. Kein Befund; der Editor speichert Authoringdaten und ruft keine Runtime-Command-Queue direkt an.
- `scripts/mission/mission_dropship_effect_adapter.gd:52`, `scripts/mission/mission_dropship_effect_adapter.gd:68` und `scripts/mission/mission_dropship_effect_adapter.gd:83` sind erlaubte Adapter-Punkte: Sie bauen AirAsset-/Dropship-Effects mit `runtime_authority = "SimulationRoot"` und `ui_sets_gameplay_truth = false`.

## Authority Lines
- `SimulationRoot` ist die Runtime-Authority fuer Command-Queue, Effect-Queue, Objective-/Unit-Spiegelung und AirAssetStatus: `scripts/core/simulation_root.gd:119`, `scripts/core/simulation_root.gd:136`, `scripts/core/simulation_root.gd:144`, `scripts/core/simulation_root.gd:409`, `scripts/core/simulation_root.gd:476`, `scripts/core/simulation_root.gd:2615`.
- Multiplayer-Clients koennen keine Tactical-State-Keys als Commands einschleusen. `scripts/multiplayer/multiplayer_command_contract.gd:57` bis `scripts/multiplayer/multiplayer_command_contract.gd:86` blockiert unter anderem `fireteam_plan_status`, `breakout_state`, `communication_events`, `air_asset_status`, VFX/SFX-Events und Editor-LZ-Quellen.
- CommanderIntent -> FireteamExecutionPlan -> UnitAction bleibt Daten-/Intent-Pipeline, keine UI-Wahrheit. Die Contract-Anker liegen in `docs/dev/commander_fireteam_delegation_contract.md`, `scripts/command/commander_intent.gd:217`, `scripts/tactical/fireteam_execution_plan.gd:207`, `scripts/tactical/fireteam_execution_plan.gd:252` und `scripts/tactical/fireteam_execution_plan.gd:294`.
- BreakoutState bleibt visual/snapshot-orientiert: `scripts/tactical/tactical_breakout_resolver.gd:184` bis `scripts/tactical/tactical_breakout_resolver.gd:185` markiert `ui_sets_gameplay_truth = false` und `runtime_authority = "SimulationRoot"`.
- TacticalCommunicationEvent bleibt Ereignis-/Feedbackdaten: `scripts/tactical/tactical_communication_event.gd:118` liefert Snapshots fuer Anzeige, Bubble/Map-Feedback und Multiplayer-Mirror.
- AirAssetStatus hat klare Runtime-Quelle: `scripts/mission/air_asset_status.gd:209` bis `scripts/mission/air_asset_status.gd:212` markiert `runtime_authority` und `ui_sets_gameplay_truth = false`; destructive Updates laufen ueber `SimulationRoot._apply_air_asset_status_update_effect()`.
- Loadout/Gewicht bleibt Daten- und Resolver-Wahrheit: `scripts/command/loadout_modifier_resolver.gd:140` berechnet Gewicht; `scripts/meta/fob_screen.gd:2373` bis `scripts/meta/fob_screen.gd:2384` liest diese Werte fuer Anzeige. Character Card/Formattierung zeigt Profile, schreibt aber keine Runtime-State-Queue.

## Guard
`scripts/tests/task_284_gameplay_truth_architecture_boundary_audit.gd` prueft:
- Task/Status/Roadmap/Report-Anker.
- Verbotene Mutationsmuster in `scripts/ui`, `scripts/meta`, `scripts/editor` und `scripts/tactical/visuals`.
- Help-/Tooltip-Schicht ohne Runtime-Authority-Begriffe.
- Multiplayer-State-Key-Blockliste.
- UI-only Help-Popup-Aktion ohne `SimulationRoot.command_queue` oder `SimulationRoot.effects_queue`.
- Tactical Multiplayer-Snapshot-Apply ohne Client-Commands oder Client-Effects.

Der Runner `scripts/tests/run_task_284_truth_boundary_scan.ps1` fuehrt den Audit-Guard, den Multiplayer-Authority-Verifier und `git diff --check` aus.
