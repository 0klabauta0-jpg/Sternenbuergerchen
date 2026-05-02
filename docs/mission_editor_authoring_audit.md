# Mission Editor Authoring Audit

## Anlass
Nach der Umstellung der Live-Mission auf die primaere 3D-/2.5D-Ansicht sind die taktischen Systeme wieder technisch testbar, aber das schnelle manuelle Bauen von Missionssituationen ist noch zu schwach. Fuer echte Playtests braucht das Projekt wieder einen Editor-Pfad, der taktische Szenarien reproduzierbar authoren und in die Live-Mission laden kann.

Wichtige Produktentscheidung: Die LZ wird nicht vom Editor gesetzt. Die LZ ist immer eine Spielerentscheidung im Missionsflow.

## Bestehender Editor-Stand
- `scenes/editor/map_editor.tscn` mit `scripts/editor/map_editor.gd` ist ein interner Map-Editor fuer Terrain.
- Terrain wird ueber `TerrainMapData` aus JSON geladen und gespeichert.
- Der Editor kann Tile-Typen, Walkability, LOS, Cover, Hoehen, Oberflaechen, Object-Layer und Kartengroesse bearbeiten.
- `mission_slot_count` ist bereits Teil der Karten-JSON.
- Marker werden ueber `TerrainMapData` und den gemeinsamen Marker-Katalog gespeichert.
- Die festen Missionsmarker `spawn_alpha`, `spawn_bravo` und `objective_point` sind im Editor platzierbar.
- Patrol-Pfade sind authorbar und werden in `patrol_paths` gespeichert.
- `MissionTestSetup` laedt die Karten-JSON, registriert Terrain in `TerrainRegistry`, rendert die Map und wendet Markerpositionen auf die feste Missionsszene an.
- `EnemyWaveController` kann Patrol-Pfade pro Unit erhalten und Wellen starten.

## Was fuer taktisches Testen fehlt
- Kein eigener Missionsszenario-Vertrag, der Map, Objective, Gegner, Wellen, Patrols und Testparameter zusammenfasst.
- Gegner-Units sind noch stark an feste Szenen-Nodes und Namen gebunden.
- Wellenparameter liegen als Scene-Exports im `EnemyWaveController`, nicht als authorbares Szenario.
- Patrol-Pfade existieren, sind aber an Spawn-/Unit-IDs gekoppelt und nicht Teil einer sichtbaren Szenario-Uebersicht.
- Objective-Parameter wie Capture-Radius, Win Condition und Zeitlimit sind nicht komfortabel pro Szenario authorbar.
- Meta-Missionen werden in `MetaLayerFlow.HOMEBASE_MISSION_CATALOG` hardcodiert, statt aus authorbaren Szenario-Dateien zu kommen.
- Es gibt keine kleine Preset-Bibliothek fuer schnelle Tests wie Attack Area, Defend Area, Patrol Contact oder Dropship Insertion.
- Es gibt keinen Editor-Button oder Test-Harness, der ein authorbares Szenario direkt in die Live-Mission laedt.

## Bewusst nicht im Editor
- LZ-Position.
- Dropship-Call als vorab gespeicherte Pflichtposition.
- Spieler-Area-Orders und Wegpunkte als Karteninhalt.
- Laufender Combat-State, Contact-State oder SimulationRoot-Queues.
- Meta-Roster-Entscheidungen, Loadout-Entscheidungen oder echte Kampagnen-Saves.

## Empfohlener Schnitt
Der Terrain-Editor bleibt fuer Karten- und Markerdaten verantwortlich. Darauf wird ein kleiner Missions-Authoring-Layer gesetzt:

- Map-Datei: Terrain, Object-Layer, authorbare Map-Marker, Patrol-Pfade.
- Mission-Szenario: referenziert eine Map-Datei und beschreibt Objective, Gegner, Wellen, Patrol-Zuordnung, Test-Parameter und Meta-Katalogdaten.
- Live-Mission: laedt Szenario + Map, setzt aber keine Spieler-LZ aus dem Szenario.
- Tactical UI: Spieler setzt LZ, ruft Dropship, plant Area Orders und fuehrt GO aus.

## Gute Reihenfolge
1. Tactical Test Presets erstellen, damit taktische Systeme sofort reproduzierbar testbar werden.
2. Datenvertrag fuer Mission-Szenarien festlegen.
3. Editor-MVP auf dem bestehenden Map-Editor aufbauen.
4. Editor-to-Live-Mission-Validation mit 3D-Bridge, Area Orders, Contacts, Patrols und Dropship-Flow pruefen.

## Risiken
- Wenn alles in `TerrainMapData` landet, wird die Map-Datei zur versteckten Gameplay-Wahrheit.
- Wenn das Szenario die LZ speichert, widerspricht es dem Spielerflow.
- Wenn der Editor direkt Live-Nodes mutiert, entsteht UI-Gameplay-Kopplung.
- Wenn zuerst ein grosser Editor gebaut wird, fehlen schnelle Presets fuer konkrete Taktiktests.

## Naechster Task-Schnitt
- `TASK_155 - Tactical Mission Test Presets`
- `TASK_156 - Mission Scenario Data Contract`
- `TASK_157 - Tactical Mission Editor MVP`
- `TASK_158 - Editor-to-Live Mission Validation`

## Update nach TASK_157
- Der bestehende Map-Editor besitzt jetzt ein schlankes Mission-Scenario-Panel fuer Load/Save, Objective-Regeln, Enemy-Groups, Wave-Parameter, Spawn-Marker/-Positionen und Patrol-Bindings.
- `MissionTestSetup` kann eine `scenario_file_path` laden und die Scenario-Daten in die Live-Testmission uebernehmen.
- Die LZ bleibt weiterhin ausserhalb des Authoring-Vertrags und wird nicht gespeichert.
- Offen bleibt eine breitere Editor-to-Live-Validation mit mehreren Szenariovarianten (`TASK_158`).

## Update nach TASK_158
- `data/mission_scenarios/editor_validation_smoke.json` dient als kleiner Editor-to-Live-Smoke ohne gespeicherte LZ.
- `scripts/tests/task_158_verifier.gd` validiert Editor-Load/Save, Live-Missionsstart, Scenario-Objective, Enemy-Waves, Patrol-Bindings, Spieler-LZ, Dropship-Deploy, Attack Area, Contact Overlay, Objective-Fortschritt und sichtbare Live-Visuals.
- `docs/manual_checks/editor_to_live_mission_checklist.md` beschreibt den manuellen Editor-to-Live-Durchlauf.
- Der aktuelle getrackte Stand besitzt inzwischen die TASK_159-2.5D-Primary-View; die automatisierte Pruefung deckt Editor-to-Live-Datenfluss und die 2.5D-Visual-Bridge fuer LZ, Dropship, Attack Area, Contacts und Unit-Proxies ab.

## Update nach TASK_159 Follow-up
- Die 2.5D-Primary-View ist jetzt der gepruefte Editor- und Live-Pfad fuer Terrain, LZ, Dropship, Attack Area und Contacts.
- Der Missionsstart hing, weil `TerrainMapData.load_from_file()` den Tile-Katalog pro Tile neu geladen hat. Der Loader nutzt den Katalog jetzt einmal pro Map; TASK_159 fiel dadurch lokal von ueber 100 Sekunden auf rund 5 Sekunden.
- Die sichtbaren Asset-Fehler kamen aus dem falschen Primaerpfad: Kenney-GLBs ersetzten kurzzeitig die authored Isometric-PNGs. Dabei gingen Wall-/Corner-Richtungen, Texturen, Farben und Sprite-Groessen verloren.
- `TerrainMap3DView` rendert Boden, Waende, automatische Cliff-/Slope-Kanten, Rampen, Felsen und Katalog-Objekte jetzt wieder als `Sprite3D`-Texturkarten aus den vorhandenen Isometric-PNGs. Die GLB-Modelle bleiben nur Fallback fuer nicht aufloesbare Texturen.
- Units und Dropship sind in der 2.5D-View keine Capsule-/Box-Platzhalter mehr und werden auch nicht mehr auf generische GLBs gezwungen; sie spiegeln die vorhandenen Unit-`Visual`-/Weapon-Sprites und die TacticalController-Dropship-Textur.
- Die alte 2D-Karte bleibt Daten-/Fallback-Pfad, wird im 2.5D-Live-Pfad aber nicht mehr unsichtbar parallel gerendert.

## Update nach TASK_160
- Die 2.5D-Primary-View zeigt jetzt nicht nur Asset-Parity, sondern einen kompakten taktischen Spielstatus: LZ, Dropship, Move-/Defend-/Take-Wegpunkte, Attack-/Defend-Areas, Contacts, Objective-Capture-Fortschritt und Missionsergebnis.
- `MissionCombatLoopDriver` liefert dafuer einen read-only Playability-Snapshot; Gameplay-Wahrheit bleibt bei Simulation/Combat-Loop und wird nicht in die UI verschoben.
- Alte frei schwebende 2D-Readability-Labels fuer Combat, Wave und Objective werden im 2.5D-Pfad unterdrueckt, damit Zoom und Kamera nicht wieder nur Text ueber der Karte bewegen.
- `scripts/tests/task_160_tactical_playability_verifier.gd` spielt den Mini-Loop LZ -> Dropship -> Deploy -> Move/Defend/Take -> Area Orders -> Contact -> Objective Capture -> Victory durch.
- Offen bleibt echte optische Feinarbeit am Kampffeedback im laufenden Godot-Fenster; der neue Test sichert Datenfluss und Sichtbarkeit, ersetzt aber keinen manuellen Lesbarkeits-Pass.
