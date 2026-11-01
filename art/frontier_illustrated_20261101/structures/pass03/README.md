# Kenney-basierte Cutaway-/Hallenmodelle, Grafikpass 03

Die aktuelle Nutzersteuerung verlangt vorhandene Baukaesten als Vorlage und
als echte geometrische Grundlage. Deshalb ersetzen tatsaechlich importierte
Kenney-Module die entsprechenden Eigenbaugruppen der ersten Pass03-Studie.
Die lesbare Raum-/Hallensilhouette bleibt erhalten. Die vorigen drei Strukturen
und alle Citizens wurden nicht veraendert. Dieser Satz ist ein Modellkandidat,
keine gestalterische Nutzerfreigabe und keine Innenraum-/Wirtschaftsmechanik.

| Modell | BBox XYZ in Blender, Meter | Dreiecke | editierbare Teile |
| --- | --- | ---: | ---: |
| habitat_cutaway_01 | 6,90 × 7,10 × 3,005 | 4.935 | 101 |
| freihafen_hall_01 | 10,50 × 6,95 × 4,20 | 6.251 | 123 |

Jeder GLB hat ein statisches Mesh und acht Materialflaechen. Keine Texturen,
Lichter, Kameras, Animationen, Skins, Collision oder Navigation sind exportiert.
Die Quellen behalten einzeln benannte Teile und Funktionsbereiche. Beide sind
in Metern angelegt, volle BBox XY-zentriert und unten Z=0. Vorne ist Blender
-Y, nach GLB-Konvertierung Godot +Z. Preview-Faktor 0,35; Habitat (8,3;6,2),
Halle (13,2;6,2). Diese Platzierung und die native Darstellung gehoeren zum
uebergeordneten Task.

## Tatsaechlich uebernommene Ausgangsgeometrie

Alle folgenden Dateien liegen bereits unter `Assets/curated/kenney/` und
bleiben unveraendert. Space Station Kit 1.0 und Factory Kit 3.0 stammen von
Kenney und stehen unter CC0; die beiden originalen `License.txt` liegen dort.
Es wird kein altes City-Industrial-Gebaeude als Factory-3.0-Quelle ausgegeben.

| Quelle im jeweiligen `models/` | Geometrische Verwendung |
| --- | --- |
| space_station/wall.glb | Wiederholte echte Wandprofile beider Gebaeude, auch die niedrig skalierten Schnittwaende |
| space_station/wall-window.glb | Fensterwand des Bueroanbaus mit originaler ausgesparter Oeffnung/Rahmen |
| space_station/bed-single.glb | Beide vollstaendigen Bettbasen einschliesslich Kissen und Unterbau |
| space_station/table-display.glb | Aufenthaltstisch mit Anzeige und Bedienform; loses Quellobjekt `ship` bewusst ausgelassen |
| space_station/computer.glb | Stehendes Habitat-Terminal einschliesslich Konsole/Standfuss |
| space_station/computer-wide.glb | Breite Buero-Konsole auf dem getragenen Schreibtisch |
| space_station/container-wide.glb | Zwei Habitat-Lagerbehaelter und ein Hallenbehaelter |
| factory/door.glb | Beide tatsaechlichen Pfosten und der Kopfbereich als Ausgang des grossen offenen Hallenrahmens; Tuerblatt/untere Schwelle abgeschnitten, Schnitte gekappt |
| factory/crane-lift.glb | Getragene Hebeeinheit mit Gehaeuse, Kette und Magnetkopf unter dem Rahmen |
| factory/detail-tank.glb | Horizontaler Tank samt Originalbaendern/Fuessen auf dem Buerodach |

Das sind zehn tatsaechlich verwendete GLBs. Dreizehn wurden vor der Auswahl
inspiziert; `wall-door`, `door-wide-closed` und `crane` sind keine enthaltenen
Quellbauteile. Grosse Quellenansichten und Rohbefunde liegen unter
`qa/kenney_sources/`. `manifest.json` enthaelt `kenney_sources` je Datei mit
Pfad, SHA-256, genauem Pack, Lizenz/Hash, Verwendungen und Aenderungen.
`assets[].kenney_geometry_reuse` belegt zusaetzlich jede einzelne Instanz,
uebernommene Quellobjekte, Geometriezahlen, Zuschnitt und Transformation.
Die gemeinsam benutzten Originalatlanten sind ebenfalls gehasht; sie dienen
nur der Erkennung der urspruenglichen Farbfelder und werden nicht exportiert.

Aenderungen an den Ableitungen: normalisierte/angewandte Rotation und Groesse,
Zielpalette statt Atlas, Weld der Attributnaehte, Bereinigung sehr kleiner
Flaechen und konsistente Orientierung. Quellbedingte nicht-mannigfaltige
Montagekanten werden getrennt, um die sichtbaren Quellschalen zu erhalten.
Am Factory-Rahmen bleiben die echten Pfosten-/Kopfflaechen; der Ausschnitt
wird auf die Hallenbreite angepasst. Importierte Objektanimationen von Tuer
oder Lift werden fuer diese statische Baugruppe entfernt. Der frische
Rueckimport prueft ausdruecklich, dass sie nicht im BLEND weiterwirken.

Eigene Ergaenzungen bleiben klar abgegrenzt: Fundament und vier Bodenbereiche,
Schnittkanten/Kappen, orange Baender, Stufen, Raumteiler, Bettdecken/Kopfteile,
Regale und Kisten, Werkbank mit Werkzeuggruppe, Stuehle, Schreibtisch sowie
die gezielten Dachstreifen. Sie verbinden die echten Module zu den zwei
Referenzensembles und bewahren die geprueften BBoxen.

## Reproduktion und Pruefung

Blender 5.2.3 CLI mit `-b --factory-startup --python-exit-code 1 --python <script>`:

1. `generator/build_cutaways.py` mit `kenney_modules.py`: Ableitungen unter
   `source/`, Exporte unter
   `Assets/curated/frontier_illustrated_20261101/structures_pass03/` und Roh-QA.
2. `generator/review_cutaways.py`: Front/Rueck/Top/Spielabstand, Random/Wire.
3. `generator/verify_roundtrip.py`: frischer leerer Blender-GLB-Import,
   Positions-/Mass-/Materialvergleich, Roh-QA, statischer Animationscheck.
4. Normales Python: `generator/finalize_manifest.py` fuer Hashes/Herkunft/QA.

Finale Evidence: `qa/build_kenney_r08.log`, `qa/review_kenney_r09.log`,
`qa/roundtrip_kenney_r05.log`. Beide Source-Pruefungen bestehen ohne Fehler,
einschliesslich Z-Fighting, Orientierung, Kontakt und degenerierter Geometrie.
13 Habitat- und 11 Hallenwarnungen bleiben vollstaendig erhalten und sind
akzeptiert: verdeckte Stirnflaechen exakt aneinander gesetzter Wandmodule,
Quell-Montagekappen sowie getrennte Montagekanten am Displaytisch/Rahmen.
Diese sind keine sichtbaren losen Teile. Einige uebernommene Schalen sind
offen; eine wasserdichte Druckgeometrie wird nicht behauptet. Die UV-Pruefung
ist fuer konstante untexturierte Materialien bewusst ausgeschlossen.

Der frische GLB-Roundtrip besteht mit exakt gleichen Positionen, BBoxen,
Dreieckzahlen und Materialzuordnungen. Er behaelt weitere Format-Attributnaehte
und die beschriebenen verdeckten Kontakte als rohe Warnungen. Keine Quelle
oder Rohpruefung wurde umgeschrieben, um einen Befund zu verstecken.
Alle 16 finalen Source-/Roundtrip-Bilder wurden geoeffnet; dazu die Module und
der ausgeschnittene Rahmen einzeln. Vorne sind alle vier Habitatgruppen und
die gefuellte Ladehalle sichtbar. Rueckwaende verdecken Ausstattung aus der
Gegenrichtung absichtlich. Im weiten Overview werden Kleinteile nachrangig.
Workbench prueft Form/Montage; Godot-Licht und native Spielansichten prueft
Root. Ein technischer PASS ist keine gestalterische Nutzerabnahme.

Die erste rein prozedurale Pass03-Fassung bleibt lokal und Git-ignoriert unter
`studies/procedural_r01/` mit Quellen, Generator, Roh-QA, Bildern und GLBs.
Sie ist keine aktuelle Modellgrundlage. Fruehere Fehlversuchslogs zeigen die
korrigierten Montage- und Import-Animationsbefunde weiterhin nachvollziehbar.
Seit der erneuten Freeze-Freigabe werden die aktuellen GLBs nicht mehr
veraendert. Keine Runtime-/Reportedits, Godot-Imports oder Commits in diesem
Asset-Subtask.
