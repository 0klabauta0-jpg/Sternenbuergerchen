# TASK_145 - 2.5D Tactical Debug Overlay

## Ziel
In der taktischen Mission koennen Cover, LOS-Hoehen, Floor-Kontext, Walkability, Pathdaten und Air-Layer-Debug sichtbar umgeschaltet werden.

## Status: ERLEDIGT

## Kontext
- TASK_135-141 liefern viele Debug-Snapshots, aber verteilt ueber Verifier und einzelne Systeme.
- TASK_142-144 bringen 2.5D in die echte Missions-Testkette.
- Danach braucht der Playtest ein schnelles Overlay, damit Hoehen-/Deckungs-/Pfadentscheidungen nicht geraten werden muessen.

## Umfang
1. Kleiner Tactical-Debug-Overlay-Controller fuer die Live-Mission.
2. Umschaltbare Ebenen:
   - Height/Floor,
   - Cover/LOS-Blocker-Hoehe,
   - Walkability/Transitions,
   - aktuelle Unit-Paths/Move-Targets,
   - Air-Layer/Altitude/AA-Gate-Debug.
3. Overlay liest bestehende Snapshots/Registry-Daten, erzeugt aber keine Gameplay-Wahrheit.
4. Tastatur- oder UI-Toggles fuer Playtests, konservativ und nicht als finale UX.
5. Verifier prueft, dass die Overlay-Daten aus Registry/SimulationRoot kommen und einzeln toggelbar sind.

## Nicht-Ziele
- Keine finale HUD-Gestaltung.
- Keine Gameplay-Regelaenderungen.
- Keine per-frame Vollscans im Hotpath.
- Keine Editor-Overlay-Ersetzung; Editor-Overlay bleibt separat.

## Akzeptanzkriterien
- [x] Overlay kann in der Live-Mission aktiviert/deaktiviert werden.
- [x] Height/Floor-, Cover/LOS-, Walkability/Transition- und Path-Ebenen sind getrennt toggelbar.
- [x] Air-Layer-Debug zeigt Altitude und letzten AA-Gate-Grund, wenn vorhanden.
- [x] Overlay nutzt Registry-/Simulation-Daten statt eigene Berechnung als Wahrheit.
- [x] Verifier prueft Toggle-Zustaende und Datenquelle.

## Umsetzung
- `Mission25DTacticalDebugOverlay` haengt als `Node3D` unter der Live-`Mission25DVisualBridge` und ist standardmaessig deaktiviert.
- Tastatur-Toggles: `F6` aktiviert/deaktiviert das Overlay, `1` bis `5` schalten Height/Floor, Cover/LOS, Walkability, Path und Air separat.
- Das Overlay liest Terrain-/Cover-/Walkability-Daten aus `TerrainRegistry`, Pathdaten aus `SimulationRoot.command_queue` plus optionalen Preview-Daten und Air-/AA-Debug aus `UnitRegistry`/`SimulationRoot.get_air_layer_debug_snapshot()`.
- `scripts/tests/task_145_verifier.gd` validiert Live-Mission-Integration, einzelne Layer-Toggles und die Datenquellen gegen die 2.5D-Smoke-Map.

## Risiken
- Zu viele Labels koennen das Bild ueberladen; V1 priorisiert Debugbarkeit vor Schoenheit.
- Overlay darf nicht zum neuen UI-Gameplaypfad werden. Es bleibt rein lesend.
