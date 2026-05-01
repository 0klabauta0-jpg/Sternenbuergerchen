# TASK_150 - Legacy 2D Mission Asset Retirement

## Ziel
Die alte 2D-Missionsdarstellung wird aus dem aktiven Standardpfad entfernt oder klar zum Debug-/Fallbackpfad degradiert, nachdem 3D-Karte und 3D-Unit-Visuals stabil sind.

## Status: ERLEDIGT

## Voraussetzung
- `TASK_148 - 3D Primary Mission View`
- `TASK_149 - 3D Unit Visual Replacement`

## Kontext
- Die 2D-Assets waren wichtig fuer Aufbau, Editor und fruehe Missionslesbarkeit.
- Sobald 3D der normale Missionslook ist, darf 2D nicht mehr still parallel als visuelle Wahrheit wirken.
- Trotzdem sollten 2D-Sprites nicht vorschnell geloescht werden, weil Editor, UI-Icons, Tests und Debug-Fallbacks sie noch nutzen koennen.

## Umfang
1. Aktive Missionspfade auditieren:
   - welche 2D-Sprites werden noch im Live-Missionsbild gerendert?
   - welche 2D-Assets sind nur Editor/UI/Icon/Fallback?
2. Standard-Missionsbild bereinigen:
   - alte 2D-Map/Unit-Sprites standardmaessig aus.
   - Fallback bewusst benannt und kontrolliert einschaltbar.
3. Verweise dokumentieren:
   - welche 2D-Assets bleiben fuer Editor/UI.
   - welche koennen spaeter geloescht werden.
4. Verifier:
   - Live-Mission startet ohne aktive 2D-Missionsdarstellung im Standardpfad.
   - Fallback/Debugpfad funktioniert noch.
   - Editor- und UI-Preloads bleiben gueltig.

## Nicht-Ziele
- Kein radikales Loeschen aller 2D-Assets.
- Keine Editor-Umstellung auf 3D.
- Keine neue Asset-Pipeline.
- Keine Gameplay-Aenderungen.

## Architekturregeln
- Entfernen betrifft Darstellung, nicht Simulation.
- 2D-Editor-Assets duerfen erhalten bleiben, solange der Map-Editor 2D ist.
- Kein Brechen bestehender Tests durch unnoetige Asset-Loeschungen.

## Akzeptanzkriterien
- [x] Standard-Live-Mission nutzt keine alte 2D-Karte als sichtbaren Hauptpfad.
- [x] 2D-Unit-Sprites sind im Standard-Live-Bild verborgen oder ersetzt.
- [x] Debug-/Fallbackpfad ist explizit.
- [x] Asset-Audit dokumentiert verbleibende 2D-Nutzung.
- [x] Verifier prueft Standard- und Fallbackzustand.

## Umsetzung
- `MissionLive25DVisualBridge` verwaltet jetzt neben 2D-Map und Unit-Sprites auch explizite Legacy-2D-Missionsoverlays.
- Im primaeren 3D-Modus werden `TargetMarker/TargetVisual`, `LZMarker`, `DropshipPlanMarker`, `FireteamOrderVisualizer` und `ContactMapOverlay` ausgeblendet, waehrend die 3D-Bridge deren Daten weiterhin lesen kann.
- `set_2d_fallback_visible(true)` stellt die alte 2D-Karte, Unit-Sprites und Legacy-Overlays fuer Compare/Debug wieder her.
- `get_legacy_2d_mission_visual_audit()` liefert einen pruefbaren Snapshot zu Map, Units und Overlays.
- Das Asset-Audit liegt unter `docs/legacy_2d_mission_asset_audit.md`.

## Erwartetes Ergebnis
Ab diesem Punkt ist 3D/2.5D faktisch die Missionsdarstellung. 2D bleibt nur dort, wo es noch bewusst gebraucht wird: Editor, UI, Icons, Fallback oder historische Referenz.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_150_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_148_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_149_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_145_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_143_verifier.gd`
- [ ] Manuell Live-Mission und Map-Editor starten.

## Dateien (voraussichtlich)
- `scenes/tests/mission_reactivity_test.tscn`
- `scripts/tests/mission_live_2_5d_visual_bridge.gd`
- `scripts/tests/task_150_verifier.gd`
- `docs/legacy_2d_mission_asset_audit.md`

## Risiken
- Wenn 2D zu frueh entfernt wird, verlieren wir einen guten Debugvergleich. Deshalb ist dieser Task bewusst erst nach 3D-Primary und 3D-Unit-Visuals eingeordnet.
