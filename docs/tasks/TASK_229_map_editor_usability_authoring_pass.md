# TASK_229 - Map Editor Usability Authoring Pass

## Ziel
Der Map-Editor soll in einem Bedienbarkeits-Pass geprueft und geglaettet werden: Werkzeuge, Hoehen, Kanten, Marker, Patrols, Scenario-Felder, Save/Load, Live-Test und Fehlermeldungen muessen gut benutzbar sein.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_158 - Editor to Live Mission Scenario
- TASK_163 - Map Editor Module Split
- TASK_183 - Editor Hill Authoring Patch
- TASK_185 - Hill Visuals and Edge Lines Patch
- TASK_200 - Enemy Team Tactics Contract and Editor Config
- TASK_228 - Multiplayer Editor Map Manifest Download Consent

## Kontext
Der Editor ist inzwischen funktional und modularer, aber viele neue Systeme landen dort: Huegel, Deckung, Enemy-Taktik, Multiplayer-Maps, FoW-Relevanz und vielleicht Flug-/Hoehenschichten. Bevor er weiter waechst, braucht er einen Bedienbarkeits-Pass.

## Umfang
1. Werkzeugfluss:
   - Terrain Brush.
   - Hoehe/Edge: Hang, Cliff, None.
   - Marker/Patrol.
   - Scenario-/Enemy-Panel.
   - Save/Load/Live-Test.
2. Feedback:
   - Aktives Werkzeug klar sichtbar.
   - Brushgroesse und aktueller Tile-Kontext sichtbar.
   - Fehler beim Speichern/Validieren knapp und hilfreich.
   - Kein langer Hilfetext im Arbeitsbereich.
3. Validierung:
   - Map prueft Startbereiche, Objectives, Enemy-Waves, Patrols, Hoehenkanten, Walkability.
   - FoW-relevante Sichtblocker/Deckung koennen diagnostisch angezeigt werden.
   - Multiplayer-Map-Manifest kann aus Editor-Daten entstehen.
4. Undo/Redo-Vorbereitung:
   - Wenn kein vollstaendiges Undo umgesetzt wird, wenigstens Datenvertrag fuer Tile-Patches und Werkzeugaktionen dokumentieren.
5. Sichtcheck:
   - 32x32-Map bauen.
   - Hoegel mit Mauer/Fels/Sand.
   - Enemy-Wave mit Profil.
   - Save, Load, Live-Test, Multiplayer-Manifest.
6. Verifier:
   - Bestehende Editor-Roundtrips bleiben gruen.
   - Neue Usability-Snapshots pruefen Tool-State und Validierungsdiagnosen.

## Nicht-Ziele
- Kein kompletter Godot EditorPlugin-Umbau.
- Kein frei veroeffentlichter Workshop.
- Kein grosses Redesign.
- Kein FoW-Runtime-System, nur editorseitige Vorbereitung/Diagnose.

## Akzeptanzkriterien
- [x] Editor zeigt aktives Werkzeug, Brushgroesse und Tile-Kontext klar an.
- [x] Hoehen-/Edge-/Object-Painting bleibt roundtrip-sicher.
- [x] Scenario-/Enemy-/Marker-/Patrol-Felder haben Validierungsdiagnosen.
- [x] Save/Load/Live-Test bleiben aus dem Editor erreichbar.
- [x] Multiplayer-Map-Manifest kann vorbereitet oder diagnostiziert werden.
- [x] Ein TASK_229-Verifier prueft Tool-State, Validierung, Roundtrip und Live-Test-Vorbereitung.

## Erwartete Dateien
- `scripts/editor/map_editor.gd`
- `scripts/editor/map_editor_height_tool.gd`
- `scripts/editor/map_editor_marker_tool.gd`
- `scripts/editor/map_editor_patrol_tool.gd`
- `docs/manual_checks/map_editor_usability_authoring_checklist.md`
- `scripts/tests/task_229_map_editor_usability_authoring_pass.gd`
- `docs/tasks/TASK_229_map_editor_usability_authoring_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_229_map_editor_usability_authoring_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_163_map_editor_module_split_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_183_editor_hill_authoring_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_158_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_200_enemy_team_tactics_contract_and_editor_config.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_228_multiplayer_editor_map_manifest_download_consent.gd`
- [ ] Manueller Editor-Sichtcheck nach Checkliste.
- [x] `git diff --check`

## Risiken
- Editor-Politur kann schnell in Redesign ausufern. Fokus bleibt Bedienbarkeit der bestehenden Tools.
- Undo/Redo ist gross; wenn noetig als eigene Folgereihe schneiden.
- Der implementierte Undo-Vertrag dokumentiert bewusst nur den aktuellen Single-Tile-Patch-Scope; vollstaendiges Undo/Redo bleibt ausserhalb dieses Tasks.

## Naechster Schritt
Nach TASK_229 kann TASK_230 Flug-/Hoehenschichten und Air-/Dropship-Interaktion auditieren.
