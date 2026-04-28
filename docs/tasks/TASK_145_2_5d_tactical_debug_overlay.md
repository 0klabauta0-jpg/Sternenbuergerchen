# TASK_145 - 2.5D Tactical Debug Overlay

## Ziel
In der taktischen Mission koennen Cover, LOS-Hoehen, Floor-Kontext, Walkability, Pathdaten und Air-Layer-Debug sichtbar umgeschaltet werden.

## Status: GEPLANT

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
- [ ] Overlay kann in der Live-Mission aktiviert/deaktiviert werden.
- [ ] Height/Floor-, Cover/LOS-, Walkability/Transition- und Path-Ebenen sind getrennt toggelbar.
- [ ] Air-Layer-Debug zeigt Altitude und letzten AA-Gate-Grund, wenn vorhanden.
- [ ] Overlay nutzt Registry-/Simulation-Daten statt eigene Berechnung als Wahrheit.
- [ ] Verifier prueft Toggle-Zustaende und Datenquelle.

## Risiken
- Zu viele Labels koennen das Bild ueberladen; V1 priorisiert Debugbarkeit vor Schoenheit.
- Overlay darf nicht zum neuen UI-Gameplaypfad werden. Es bleibt rein lesend.
