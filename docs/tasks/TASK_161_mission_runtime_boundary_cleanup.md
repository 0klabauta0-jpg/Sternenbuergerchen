# TASK_161 - Mission Runtime Boundary Cleanup

## Ziel
Die produktive Missionssteuerung soll aus dem Eindruck eines Test-Harness herauswachsen. `MissionTacticalSandboxController` bleibt zunaechst funktional gleich, wird aber in klare Produktivrollen und kleine Adapter-Skripte geschnitten, damit Multiplayer-, UI- und 2.5D-Arbeit nicht weiter in einem Monolithen landen.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies `docs/PROJECT_BRIEF.md`
- Lies `docs/ARCHITECTURE.md`
- Lies `docs/CODEX_RULES.md`
- Lies `docs/IMPLEMENTATION_STATUS.md`
- Lies `docs/reviews/strategic_review_ui_assets_multiplayer_2026_05_03.md`
- Pruefe den Git-Status

## Kontext
- `scripts/tests/mission_tactical_sandbox_controller.gd` ist produktiver Missionscontroller, liegt aber unter `scripts/tests` und ist sehr gross.
- Er enthaelt Input, Selection, HUD, Fireteam-Karten, Dropship-Flow, Area Orders, Meta-Transfer-Visuals und Snapshot-Bridges.
- Fuer Multiplayer muss klar sein, welcher Teil nur lokalen Input erzeugt, welcher Teil Commands anfordert und welcher Teil nur darstellt.

## Umfang
1. Zielpfade festlegen:
   - `scripts/mission/` fuer Missionslaufzeit-Glue.
   - `scripts/tactical/ui/` oder vorhandene passende Pfade fuer reine Tactical-UI-Adapter.
   - `scripts/tactical/visuals/` weiter fuer read-only Visualisierung.
2. Kleine Rollen extrahieren:
   - Command/Input-Adapter fuer Commander-/FTL-Befehle.
   - Selection-/Fireteam-Panel-Adapter.
   - Dropship-Visual-/Presence-Adapter, ohne neue Gameplay-Mutation.
   - Playability-Snapshot-Bridge zur 2.5D-View.
3. Szenenreferenzen und Verifier anpassen.
4. Keine fachlichen Verhaltensaenderungen.

## Nicht-Ziele
- Kein neuer Multiplayer-Code.
- Kein neues Combat-System.
- Kein kompletter Rewrite des Controllers.
- Keine Aenderung an Command-Dictionary-Vertraegen.
- Keine Entfernung der 2D-Runtime-Anker.

## Architekturregeln
- UI erzeugt oder zeigt Commands, aber committed keinen Gameplay-State.
- `SimulationRoot` bleibt autoritative Mutationsstelle.
- `TerrainMap3DView` bleibt read-only Spiegelung.
- Verifier bleiben unter `scripts/tests`.

## Akzeptanzkriterien
- Produktive Missionssteuerungs-Slices liegen nicht mehr ausschliesslich unter `scripts/tests`.
- Die bestehende Live-Mission startet unveraendert.
- `TASK_158`, `TASK_159`, `TASK_160` Verifier bleiben gruen.
- Diff zeigt nachvollziehbare Moves/Extraktionen statt Feature-Umbau.
- Neue Dateien haben klare Verantwortung und keine zyklische UI-Gameplay-Kopplung.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_159_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_158_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`

## Ergebnis
- `MissionTacticalSandboxController` bleibt funktional an der bestehenden Szene haengen, delegiert aber vier produktive Grenzrollen an kleine Adapter ausserhalb von `scripts/tests`.
- `scripts/mission/mission_primary_view_bridge.gd` kapselt die 2.5D-Primary-View-Bridge fuer Picking, LZ-/Dropship-Visuals, Mission-Status, Order-Payloads, Contact-Payloads und das Unterdruecken alter 2D-Readability-Overlays.
- `scripts/mission/mission_dropship_effect_adapter.gd` baut und enqueued die bestehenden Dropship-Effects und registriert bekannte Units weiter am `SimulationRoot`, ohne neue Dropship-Gameplay-Semantik einzufuehren.
- `scripts/mission/mission_command_input_guard.gd` kapselt die lokale Host/Observer-Entscheidung fuer Command-Eingabe und Planning-Editierbarkeit.
- `scripts/tactical/ui/fireteam_selection_adapter.gd` kapselt Fireteam-Klick-/Lasso-Auswahl und das rein visuelle Selektionsspiegeln an Units.
- Command-Dictionary-Vertraege, Szenenpfade und 2D-Runtime-Anker bleiben unveraendert.

## Risiken
- Zu grosser Schnitt kann viele Szenenpfade anfassen. Deshalb zuerst nur Rollen extrahieren, keine Logik neu erfinden.
- `class_name`- und Szenenressourcen muessen nach Moves sauber aktualisiert werden.
- Der grosse Tactical-Controller ist weiterhin gross; dieser Task zieht bewusst erste produktive Adapter heraus, ersetzt aber noch keinen spaeteren Controller-Split.
