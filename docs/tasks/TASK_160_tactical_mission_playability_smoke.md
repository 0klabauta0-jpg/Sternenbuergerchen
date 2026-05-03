# TASK_160 - Tactical Mission Playability Smoke

## Ziel
Die 2.5D-Live-Mission soll nicht nur korrekt rendern, sondern einen kompakten taktischen Spielablauf sichtbar und regressionssicher abbilden: LZ setzen, Dropship einsetzen, Fireteam deployen, Move/Defend/Take sowie Area Orders sehen, Contacts anzeigen, Objective capturen und Missionsergebnis ausgeben.

## Status: IMPLEMENTIERT

## Voraussetzung
- `TASK_158 - Editor-to-Live Mission Validation`
- `TASK_159 - 2.5D Editor and Mission Primary View`
- `TASK_121` bis `TASK_124` fuer Area Orders und Feedback
- `TASK_040` und `TASK_041` fuer Objective-Capture und Siegbedingung

## Umfang
1. 2.5D-Playability-Feedback:
   - Objective-Capture-Zone, Capture-Fortschritt und Missionsergebnis werden in `TerrainMap3DView` gespiegelt.
   - Unit-Proxies zeigen kurze taktische State-Badges wie `MOVE`, `DEFEND`, `TAKE`, `ENGAGE`, `CONTACT` oder Vital-States.
   - Move-/Defend-/Take-Wegpunkte und Area Orders werden im 2.5D-Snapshot zaehlbar.
2. Legacy-Overlay-Cleanup im 2.5D-Pfad:
   - Frei schwebende 2D-Debug-/Readability-Labels fuer Combat, Wave und Objective werden unterdrueckt, wenn die 2.5D-Primary-View aktiv ist.
   - Tactical UI bleibt weiterhin die Bedienoberflaeche; die 3D-View ist nur Darstellung und Picking.
3. Regression:
   - Neuer `task_160_tactical_playability_verifier.gd` prueft den kompletten Mini-Loop.
   - Der Dropship-Bugfix-Verifier akzeptiert den 2.5D-Primary-Dropship-Marker statt den alten `DropshipPlanMarker` als Pflichtpfad.

## Nicht-Ziele
- Kein Multiplayer-Feature-Start.
- Keine neue Combat-Architektur.
- Keine Entfernung der bestehenden `Node2D`-Runtime-Anker.
- Kein Balancing der Kampfwerte.

## Architekturregeln
- Gameplay-Wahrheit bleibt in `SimulationRoot`, `MissionCombatLoopDriver`, TacticalController und den Registries.
- `TerrainMap3DView` liest Snapshots und spiegelt sie visuell; sie mutiert keinen Gameplay-State.
- UI-Labels und 3D-Overlays duerfen nicht zur zweiten Missionslogik werden.

## Akzeptanzkriterien
- [x] LZ -> Dropship -> Deploy ist im 2.5D-Pfad sichtbar.
- [x] Move, Defend und Take-Wegpunkte sind in der 2.5D-View sichtbar.
- [x] Attack/Defend Area Orders sind in der 2.5D-View sichtbar.
- [x] Contacts werden in der 2.5D-View gespiegelt.
- [x] Objective-Capture-Fortschritt und Mission Victory sind in der 2.5D-View sichtbar.
- [x] Alte frei schwebende 2D-Combat-/Wave-/Objective-Labels bleiben im 2.5D-Pfad verborgen.
- [x] Bestehende Editor-to-Live- und Dropship-Smokes bleiben gruen.

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_159_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_158_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_124_verifier.gd`

## Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_160_tactical_playability_verifier.gd`
- `scripts/tests/bugfix_dropship_mission_flow_verifier.gd`

## Ergebnis
- Der 2.5D-Primary-Pfad zeigt jetzt Objective-Status, Capture-Fortschritt, Missionsergebnis und kompakte Unit-State-Badges.
- Die alten frei schwebenden 2D-Readability-Labels werden im 2.5D-Pfad unterdrueckt, damit die Karte nicht mehr von Debugtext ueberdeckt wird.
- Der neue Verifier spielt einen kompakten Live-Loop durch und sichert, dass die sichtbaren taktischen Elemente nicht wieder nur im 2D-Fallback haengen.

## Risiken
- Die Headless-Pruefung beweist Struktur und Datenfluss, ersetzt aber weiterhin keinen manuellen Godot-Run fuer Lesbarkeit, Sprite-Sortierung und Kameragefuehl.
- Die Unit-State-Badges sind bewusst knapp; falls sie optisch zu viel werden, sollte ein Folge-Task sie feinjustieren statt Gameplay-Logik zu veraendern.
