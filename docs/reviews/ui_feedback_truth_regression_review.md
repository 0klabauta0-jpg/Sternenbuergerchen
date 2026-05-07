# TASK_286 - UI Feedback Truth Regression Review

## Scope
Review von Mission-HUD `#16`/`#17`/`#18`, Map-Overlays, Fireteamleader-Bubbles, TacticalCommunicationEvent, Contextual Help, Character Card, FOB-Loadout und Editoranzeigen. Ziel war die Grenze: UI darf lesen, anzeigen und erlaubte Commands ausloesen, aber keine autoritative Gameplay-Wahrheit halten.

Die Review-Kategorien aus dem Task sind abgedeckt: stale UI state, duplicate truth, missing snapshot, direct mutation und confusing disabled reason.

## Findings

### Blocker
- Keine Blocker gefunden.

### Important
- `scripts/tests/mission_tactical_sandbox_controller.gd:5304`, `scripts/tests/mission_tactical_sandbox_controller.gd:6074` und `scripts/tests/mission_tactical_sandbox_controller.gd:6285` sind aktuell der zentrale Auswahl- und Feedbackpfad. `get_command_feedback_snapshot()` und `TerrainMap3DView.get_render_snapshot().order_selected_fireteam_ids` spiegeln dieselbe `_selected_fireteam_ids`-Liste. Risiko: Neue Panels koennen spaeter leicht eigene Selection-Kopien einfuehren. Suggested fix: Neue Mission-HUD-Elemente duerfen Selection nur ueber `get_command_feedback_snapshot()` oder den bestehenden Controller setzen/lesen; kein Panel soll eigene Fireteam-Auswahl persistieren.
- `scripts/ui/mission_command_hierarchy_contract.gd:108` bis `scripts/ui/mission_command_hierarchy_contract.gd:219` markiert Hierarchie, Aktionen und Button-Metadaten mit `visual_only = true` und `ui_sets_gameplay_truth = false`. Das ist sauber, aber die Disabled-Reason-Texte sind Teil der Spielerfuehrung. Risiko: Wenn ein Button zwar disabled ist, aber keinen spezifischen Grund liefert, wirkt das wie stale UI. Suggested fix: Bei neuen Actions `resolve_disabled_reason()` erweitern und im Verifier weiter pruefen, dass disabled Actions nicht leer begruendet sind.
- `scripts/ui/comic_bubble_runtime_gate.gd:27`, `scripts/ui/comic_bubble_runtime_gate.gd:83` und `scripts/ui/comic_bubble_runtime_gate.gd:125` speichern lokale Cooldown-Keys. Das ist legitimer Presentation-State, keine Gameplay-Wahrheit. Risiko: Der Cooldown darf nie als taktische Suppression, Funkblockade oder Morale-State interpretiert werden. Suggested fix: Runtime-Gate-Snapshots bleiben UI-Diagnose; taktische Kommunikation bleibt ueber TacticalCommunicationEvent/SimulationRoot getrennt.
- `scripts/ui/fireteamleader_feedback_bubble_resolver.gd:47` bis `scripts/ui/fireteamleader_feedback_bubble_resolver.gd:107` liest Charakterkontext fuer Text, Dauer und Praezision. Das setzt keine Combat-Werte, kann aber nach Gameplay klingen, weil Modifier-Namen im Payload stehen. Suggested fix: Payloads duerfen diese Werte nur als copy/visual metadata tragen; keine Resolver downstream darf daraus Damage, Accuracy, Morale oder Command-Verfuegbarkeit ableiten.

### Cleanup
- `scripts/terrain/terrain_map_3d_view.gd:437`, `scripts/terrain/terrain_map_3d_view.gd:602`, `scripts/terrain/terrain_map_3d_view.gd:2669` und `scripts/terrain/terrain_map_3d_view.gd:2732` sind read-only Renderpfade. Bubbles ohne `visual_only`, falschen Display-Type, Text oder Anchor werden ignoriert. TacticalCommunicationEvent rendert nur `map_marker`-Channel. Suggested fix: Bei neuen Overlay-Typen denselben Filterstil verwenden und im Render-Snapshot zaehlen.
- `scripts/meta/fob_screen.gd:976`, `scripts/meta/fob_screen.gd:2373` und `scripts/meta/fob_screen.gd:2380` zeigen Loadout-Gewicht aus `LoadoutModifierResolver`, setzen aber keine Combat-Werte. `scripts/meta/character_sheet_formatter.gd:100` formatiert Combat-Effects als Text aus dem Profil. Suggested fix: Loadout-Auswahl und Character Card bleiben Display/Meta-Authoring; Mission-Combat-Werte laufen weiter ueber bestehende Loadout-/SimulationRoot-Effekte.
- `scripts/tests/mission_tactical_sandbox_controller.gd:7489`, `scripts/tests/mission_tactical_sandbox_controller.gd:7929` und `scripts/tests/mission_tactical_sandbox_controller.gd:8072` sind erlaubte Command-Ausloesepunkte. Sie sind keine UI-Wahrheit, aber die Namen liegen im Testcontroller. Suggested fix: Bei spaeterer Produktivextraktion diese Einstiegspunkte explizit als Command-Sender kapseln, nicht in Anzeige-Panels kopieren.

## Positive Findings
- `get_command_feedback_snapshot()` fasst `#16`, `#17`, `#18`, Button-Hierarchie, Bubbles, Communication, Breakouts und AirAsset-Anzeige in einem pruefbaren Read-Snapshot zusammen.
- `TerrainMap3DView` dupliziert keine Order-, Contact-, FoW- oder Bubble-Wahrheit. Der Render-Snapshot ist Diagnose, nicht Authority.
- Contextual Help bleibt laut Vertrag "UI aid only" und schreibt nicht nach `SimulationRoot`.
- Editor-/Meta-/UI-/Visualizer-Pfade enthalten im gescannten Scope keine direkten autoritativen Mutation-Calls wie `enqueue_command`, `enqueue_effect`, `apply_damage` oder `apply_multiplayer_snapshot`.

## Verifier
`scripts/tests/task_286_ui_feedback_truth_regression_review.gd` prueft:
- Task/Status/Roadmap/Review-Dokumentation.
- Statische UI-/Meta-/Editor-/Visualizer-Grenzen.
- Mission-Selektion gegen Feedback-Snapshot, Command-Hierarchy und 2.5D-Render-Snapshot ohne neue `SimulationRoot`-Commands oder Effects.
- Bubble- und TacticalCommunication-Renderfilter fuer `visual_only`.
- Comic-Bubble-Cooldown als reinen UI-State ohne SimulationRoot-Seiteneffekte.
- Contextual Help sowie Character-/Loadout-Anzeige ohne Autoritaetsmutation.
