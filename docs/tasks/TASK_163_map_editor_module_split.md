# TASK_163 - Map Editor Module Split

## Ziel
Der interne Map-Editor soll vor weiteren Authoring-Features in kleine, verhaltensneutrale Module geteilt werden. Ziel ist bessere Wartbarkeit, nicht neue Editor-Funktionalitaet.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/mission_editor_authoring_audit.md`
- Lies `docs/reviews/strategic_review_ui_assets_multiplayer_2026_05_03.md`
- Pruefe den Git-Status

## Kontext
- `scripts/editor/map_editor.gd` verwaltet Terrain-Painting, Hoehen, Edges, Marker, Patrols, Scenario-Panel, Save/Load und 2.5D-View.
- Der Editor ist intern und wichtig fuer schnelle taktische Tests.
- Neue Authoring-Features wuerden den Monolithen weiter vergroessern.

## Umfang
1. Kleine Module definieren:
   - Terrain Brush Tool
   - Height/Edge Tool
   - Marker/Patrol Tool
   - Mission Scenario Panel
   - File Dialog / Load-Save Controller
   - 2.5D View Adapter
2. Bestehende Methoden schrittweise verschieben.
3. Oeffentliche Editor-Methoden fuer bestehende Verifier stabil halten.
4. Keine Datenvertragsaenderung an `TerrainMapData` oder `MissionScenarioData`.

## Nicht-Ziele
- Keine neue UI-Funktion.
- Kein Godot-EditorPlugin.
- Kein Spieler-Map-Editor.
- Kein neuer Szenariovertrag.

## Architekturregeln
- Terrain bleibt `TerrainMapData`.
- Szenario bleibt `MissionScenarioData`.
- LZ bleibt Spielerentscheidung und wird nicht im Editor gespeichert.
- 2.5D-View bleibt Darstellung/Picking, nicht Gameplay-Wahrheit.

## Akzeptanzkriterien
- `map_editor.gd` verliert klar erkennbare Verantwortungsbloecke an neue kleine Skripte.
- Bestehende Editor-to-Live-Verifier bleiben gruen.
- Gespeicherte Map-/Scenario-Dateien roundtrippen unveraendert.
- Kein neuer Gameplay-State landet in Map- oder Scenario-Dateien.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_163_map_editor_module_split_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_157_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_158_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_159_verifier.gd`
- [ ] Manuelle Editor-Sichtpruefung nach `docs/manual_checks/editor_to_live_mission_checklist.md` nicht im Headless-Durchlauf ausgefuehrt

## Ergebnis
- `scripts/editor/map_editor_primary_view_adapter.gd` kapselt 2.5D-Primary-View-Setup, Legacy-2D-Sichtbarkeit, View-Refresh, Selection-Spiegelung und Picking-Fallback.
- `scripts/editor/map_editor_height_tool.gd` kapselt Height-/Edge-Patch-Building fuer das Hoehenwerkzeug.
- `scripts/editor/map_editor_patrol_tool.gd` kapselt Patrol-Waypoint-Finden, Hinzufuegen, Verschieben und Entfernen auf `TerrainMapData`.
- `scripts/editor/map_editor_marker_tool.gd` kapselt Marker-Hit-Test, belegte Markerpositionen und die Suche nach der naechsten freien Markerposition.
- `scripts/tests/task_163_map_editor_module_split_verifier.gd` prueft diese Modulgrenzen ohne neue Editor-Funktionalitaet.
- `docs/dev/map_editor_module_split.md` dokumentiert die neuen Modulgrenzen und die bewusst nachgelagerten Schnitte fuer Scenario-Panel und File-Dialog/Load-Save.
- `TerrainMapData`, `MissionScenarioData`, Map-/Scenario-JSON-Vertraege und LZ-Regel bleiben unveraendert.

## Risiken
- Godot-Szenenpfade und dynamisch erzeugte UI-Controls koennen bei Moves brechen.
- Besser mehrere kleine Commits als ein grosser Editor-Umbau.
