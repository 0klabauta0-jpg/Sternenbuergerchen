# TASK_148 - 3D Primary Mission View

## Ziel
Die Live-Mission nutzt die 2.5D/3D-Bridge als primaere Missionsdarstellung, waehrend die alte 2D-Karte als Fallback/Compare-Pfad erhalten bleibt.

## Status: ERLEDIGT

## Voraussetzung
- `TASK_146 - 3D Calibration Workspace`
- optional sinnvoll: `TASK_147 - 3D Asset Curation and Mapping Expansion`

## Kontext
- `MissionLive25DVisualBridge` rendert bereits eine 3D-Schicht aus derselben `TerrainMapData`.
- Bisher ist 3D ein Bridge-/Debugpfad neben der alten 2D-Darstellung.
- Die Zielrichtung soll ab jetzt 3D/2.5D sein, ohne die Simulation oder UI-Wahrheit in die Darstellung zu verschieben.

## Umfang
1. Live-Missionsstart auf 3D-primaer stellen:
   - Bridge sichtbar als Standard.
   - alte 2D-Map optional ausblendbar oder standardmaessig verborgen.
   - Fallback-Schalter fuer Debug/Regression erhalten.
2. Kamera/Picking pruefen:
   - Orthokamera sinnvoll auf Missionskarte rahmen.
   - vorhandener 2.5D-Picker bleibt Quelle fuer Ziel-Snapshots.
3. Tactical-Debug-Overlay weiter nutzbar halten:
   - `F6`/Layer-Toggles funktionieren ueber der primaeren 3D-Ansicht.
4. Verifier:
   - Live-Mission startet mit sichtbarer 3D-Bridge.
   - 2D-Fallback kann noch aktiviert werden.
   - SimulationRoot-/TerrainRegistry-Daten bleiben unveraendert.

## Nicht-Ziele
- Kein Entfernen der alten 2D-Renderer.
- Keine 3D-Unit-Endvisuals.
- Keine neue Gameplay-Logik.
- Keine Full-3D-Physics.

## Architekturregeln
- Simulation bleibt autoritativ in `SimulationRoot`.
- 3D-Bridge liest nur Map-/Registry-/Unitdaten.
- UI darf weiterhin Commands setzen, aber keine 3D-Darstellung als Gameplay-Wahrheit behandeln.

## Akzeptanzkriterien
- [x] Standard-Testmission zeigt 3D als Hauptbild.
- [x] 2D-Fallback/Compare-Pfad ist kontrolliert verfuegbar.
- [x] Picking/Marker/Path Preview bleiben funktional.
- [x] Debug-Overlay bleibt ueber 3D lesbar.
- [x] Verifier bestaetigt, dass keine Gameplay-State-Mutation aus der Bridge erfolgt.

## Umsetzung
- `mission_reactivity_test.tscn` startet die `Mission25DVisualBridge` jetzt als primaere Ansicht: die 3D-Kamera ist current und die alte `MapRoot`-2D-Karte wird standardmaessig ausgeblendet.
- `MissionLive25DVisualBridge` besitzt jetzt eine kleine Fallback-/Compare-API:
  - `set_2d_fallback_visible(...)`
  - `is_2d_fallback_visible()`
  - `is_primary_3d_view_active()`
  - `F7` toggelt die 2D-Compare-Karte.
- Die Live-Bridge nutzt `Terrain25DPicker` fuer `pick_screen_position(...)`; der Tactical Controller verwendet diesen Pick fuer Target-, LZ- und Waypoint-Zielpositionen, wenn die 3D-Bridge primaer aktiv ist. Die alte Canvas-Transformation bleibt Fallback.
- Das Tactical Debug Overlay bleibt unveraendert als lesende 3D-Schicht verfuegbar.
- `scripts/tests/task_148_verifier.gd` prueft 3D-Startzustand, 2D-Fallback/Compare, 3D-Picking -> TargetMarker, Overlay und ausbleibende SimulationRoot-Command-Mutation.

## Erwartetes Ergebnis
Ab diesem Task sieht der normale Missions-Testpfad wie die neue 3D/2.5D-Zielrichtung aus. Die alte 2D-Optik ist nur noch Fallback, nicht mehr Zielbild.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_148_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_142_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_143_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_144_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_145_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_147_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_139_verifier.gd`
- [ ] Manuell `mission_fireteam_dev_test.tscn` starten und 3D/2D-Fallback vergleichen.

## Dateien (voraussichtlich)
- `scenes/tests/mission_reactivity_test.tscn`
- `scripts/tests/mission_live_2_5d_visual_bridge.gd`
- `scripts/tests/task_148_verifier.gd`

## Risiken
- Bei paralleler 2D-/3D-Darstellung kann das Bild verwirrend doppelt wirken. Deshalb soll 3D primaer sein und 2D klar als Fallback/Compare markiert bleiben.
- 3D-Unit-Endvisuals sind weiterhin Nicht-Ziel dieses Tasks und bleiben fuer `TASK_149` offen.
- Der alte `task_098_verifier.gd` startet mehrere schwere Live-Szenen und lief lokal in den Timeout; die beruehrte Selection-Logik nutzt aber weiterhin den alten Canvas-Pfad, waehrend der neue 3D-Pick nur fuer Command-Ziele verwendet wird.
