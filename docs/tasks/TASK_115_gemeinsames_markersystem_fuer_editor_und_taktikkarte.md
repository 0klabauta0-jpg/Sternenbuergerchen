# TASK_115 - Gemeinsames Markersystem fuer Editor und Taktikkarte

## Ziel
Map-Marker sollen nicht mehr nur aus ein paar festen IDs bestehen. Stattdessen gibt es einen kleinen gemeinsamen Marker-Typkatalog, ueber den der Editor authorbare Map-/Systemmarker pflegt und die Taktikkarte einen freigegebenen Teil als spielerseitige Befehlsmarker direkt auf der Karte setzen kann.

## Status: IMPLEMENTIERT

## Pflicht vor Beginn
- Lies [docs/PROJECT_BRIEF.md](docs/PROJECT_BRIEF.md)
- Lies [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Lies [docs/CODEX_RULES.md](docs/CODEX_RULES.md)
- Lies [docs/IMPLEMENTATION_STATUS.md](docs/IMPLEMENTATION_STATUS.md)
- Lies [docs/tasks/TASK_078_meta_navigation_map_ansicht.md](docs/tasks/TASK_078_meta_navigation_map_ansicht.md)
- Lies [docs/tasks/TASK_082_gemeinsamer_terrain_renderer_editor_und_mission.md](docs/tasks/TASK_082_gemeinsamer_terrain_renderer_editor_und_mission.md)
- Lies [docs/tasks/TASK_099_wegpunktplanung_und_order_visualisierung.md](docs/tasks/TASK_099_wegpunktplanung_und_order_visualisierung.md)
- Pruefe den Git-Status

## Kontext
- `TASK_082` fuehrte einen kleinen Marker-Datenvertrag nur fuer feste Missionsmarker ein.
- Der verbliebene Restpunkt daraus war: starre feste IDs, keine Marker-Typ-Liste und keine direkte Markerbearbeitung auf der Karte.
- Fuer diesen Folge-Task gilt die Produktentscheidung vom 2026-04-23:
  - Marker-Typen kommen aus einer Liste, nicht aus frei erfundenen Typnamen.
  - Jeder Marker hat mindestens Name, Farbe und ein kleines Symbol.
  - Marker rasten auf Kartenfelder ein.
  - Marker duerfen sich in V1 nicht ueberlappen.
  - Doppelklick benennt um, Drag verschiebt, `Entf` loescht.
  - Die bisherigen festen Missionsmarker sollen ueber dasselbe System gepflegt werden.
  - Spielerseitige Befehlsmarker duerfen in der Mission gesetzt werden.
  - Gegner- und Systemmarker bleiben editor-only.
- Die Architekturgrenze bleibt dabei bestehen: UI ist nicht die Wahrheit. Kartenmarker in `TerrainMapData` und spielerseitige Missionsmarker im Tactical-State duerfen denselben Typkatalog und Renderer teilen, aber nicht zu einer zweiten versteckten Datenwahrheit in UI-Skripten zusammenfallen.

## Aufgabe

### 1. Kleinen gemeinsamen Marker-Typkatalog einfuehren
- Fuehre einen zentralen V1-Katalog fuer Marker-Typen ein statt einzelner Hardcode-IDs.
- Der Katalog trennt mindestens zwischen:
  - authorbaren Map-/Systemmarkern fuer den Editor
  - spielerseitigen Befehlsmarkern fuer die Taktikkarte
- Jeder Typ beschreibt mindestens:
  - `marker_type_id`
  - Standardname oder Label
  - Standardfarbe
  - kleines Symbol/Icon
  - erlaubten Platzierungskontext (`editor_only`, `mission_player`)
- Fuer die Mission sollen mindestens die bestehenden Befehlsfamilien `move`, `defend`, `engage`, `flank` und `take` als Marker-Typen aus derselben Liste abbildbar sein.
- Fuer den Editor muessen mindestens die bisherigen festen Marker `spawn_alpha`, `spawn_bravo` und `objective_point` ueber denselben Katalog abbildbar bleiben. Die alten `flank_anchor_left`-/`flank_anchor_right`-Marker wurden spaeter als veraltet entfernt.

### 2. Markervertrag vereinheitlichen, ohne die Wahrheiten zu vermischen
- Authorbare Kartenmarker bleiben Teil von `TerrainMapData` und werden weiter mit der Map gespeichert.
- Spielerseitige Missionsmarker werden nicht in die Karten-JSON zurueckgeschrieben, sondern bleiben missionslokaler Tactical-/Planning-State.
- Beide Pfade nutzen denselben kleinen Markervertrag fuer Typ, Name, Farbe, Symbol und Tile-Position, damit Renderer und Listen-UI nicht doppelt wachsen.
- Bestehende feste Marker-Lookups sollen uebergangsweise weiter semantisch aufloesbar bleiben, damit Mission, Meta-Map und bestehende Testpfade nicht brechen.

### 3. Editor: Liste und direkte Kartenbearbeitung
- Der Map-Editor bekommt eine Marker-Liste fuer die aktuell vorhandenen Marker.
- Neue Marker werden aus der festen Typ-Liste angelegt, nicht als freier Texttyp.
- Platzierung erfolgt direkt auf der Karte und rastet auf Tiles ein.
- Marker koennen per Drag verschoben werden.
- `Entf` loescht den aktuell gewaehlten Marker.
- Doppelklick auf einen Marker oder seinen Listeneintrag erlaubt das Umbenennen.
- Farbe und Symbol muessen pro Marker sichtbar und bearbeitbar sein.
- Wenn ein Feld bereits einen Marker traegt, wird ein weiterer Marker auf demselben Feld in V1 blockiert statt gestapelt.

### 4. Taktikkarte: freigegebene Spieler-Marker direkt platzieren
- Die Taktikkarte darf nur Marker-Typen platzieren, die im Katalog explizit fuer `mission_player` freigegeben sind.
- Gegner-, Spawn-, Objective- und andere Systemmarker bleiben in der Mission read-only und koennen dort nicht vom Spieler erzeugt oder verschoben werden.
- Platzierung, Drag und Loeschen fuer spielerseitige Befehlsmarker laufen direkt ueber die Karte, nicht nur ueber Listen-UI.
- Die Darstellung soll dieselbe Symbol-/Farb-Logik wie im Editor nutzen, damit Marker in Editor, Mission und read-only Meta-Ansichten gleich lesbar bleiben.

### 5. Bestehende feste Marker in dasselbe System ueberfuehren
- Die bisherigen festen Map-Marker duerfen nicht als zweiter Sonderfall parallel weiterleben.
- Der Editor pflegt auch `spawn_alpha`, `spawn_bravo` und `objective_point` ueber die neue Marker-Liste und dieselbe Karteninteraktion; die alten Flank-Anchors sind nicht mehr Teil des aktuellen Editor-Vertrags.
- Mission und Meta-Map duerfen diese Marker weiter lesen, aber nicht ueber eine separate Altdatenstruktur.

## Nicht-Ziele
- kein frei textbarer Marker-Typ-Editor fuer beliebige neue Typfamilien
- keine ueberlappenden Marker-Stapel auf demselben Feld
- keine persistente Kampagnen- oder Savegame-Speicherung spielerseitiger Missionsmarker
- keine automatische Gegner-KI, die selbst Marker erzeugt
- kein zweiter Gameplay-Wahrheitspfad in UI-Skripten

## Akzeptanzkriterien
- Bestehende feste Missionsmarker werden ueber denselben Markervertrag und dieselbe Editor-UI gepflegt wie neue Marker-Typen.
- Der Editor bietet eine Marker-Liste sowie direkte Karteninteraktion zum Platzieren, Verschieben, Umbenennen und Loeschen.
- Marker rasten auf Tiles ein und koennen sich in V1 nicht ueberlappen.
- Der Marker-Typ kommt immer aus einer festen Liste und traegt mindestens Name, Farbe und kleines Symbol.
- In der Mission koennen Spieler nur freigegebene Befehlsmarker direkt auf der Karte setzen; Gegner- und Systemmarker bleiben dort read-only.
- Map-Datei und missionslokaler Tactical-State teilen Renderer und Typkatalog, bleiben aber getrennte Datenwahrheiten.

## Umsetzung
- `scripts/terrain/terrain_marker_catalog.gd` fuehrt jetzt einen kleinen gemeinsamen Typkatalog fuer Editor- und Mission-Marker, inklusive Standardname, Farbe, Symbol, Kontext und Single-/Multi-Instance-Regel.
- `scripts/terrain/terrain_map_data.gd` speichert Kartenmarker nicht mehr nur als nackte Positionen, sondern als normale Marker-Eintraege mit Typ, Name, Farbe, Symbol und Position. Alte JSON-Dateien mit reinem `x`/`y`-Markerformat bleiben dabei weiter lesbar.
- `scripts/editor/map_editor.gd` ersetzt die alten festen Marker-Zeilen durch eine echte Marker-Liste mit Add/Remove, Typwechsel, Namensbearbeitung, Farbwahl und sichtbarem Overlay direkt auf der Karte. Platzierung und Drag rasten auf Tile-Mitten ein; doppelte Belegung eines Felds wird blockiert.
- Die festen Marker `spawn_alpha`, `spawn_bravo` und `objective_point` laufen im Editor jetzt ueber dieselbe Marker-Basis wie neue Typen wie `rally_point`, `danger_zone`, `loot_cache` und `recon_note`.
- `scripts/tests/mission_tactical_sandbox_controller.gd` erzeugt Taktikmarker nur noch aus dem gemeinsamen `mission_player`-Typkatalog, baut das Kontextmenue daraus auf und rastet neue oder verschobene Wegpunkte auf Tile-Mitten ein.
- `scripts/tactical/visuals/fireteam_order_visualizer.gd` nutzt fuer Spieler-Befehlsmarker jetzt dieselbe Symbolfamilie aus dem Marker-Katalog statt einer separaten reinen Sondertabelle.
- `scripts/tests/task_115_verifier.gd` deckt den neuen Marker-Roundtrip, den Editor-Workflow und die taktische Tile-Snap-/Katalog-Integration headless ab.
