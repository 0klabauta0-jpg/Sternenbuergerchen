# Satellit Mission 1: KI-Vierseitenreferenz

## Ziel und Sinn
Der Nutzer moechte den Satelliten der ersten Bergungsmission in Tripo neu erstellen.
Ein KI-Blatt zeigt Front, rechts, hinten und links im Wimmelbild-Look mit industrieller
Science-Fiction-Gestaltung. Die bestehenden Missionsmerkmale bleiben erkennbar.

## Umfang und Nicht-Ziele
Ein transparentes 2x2-Referenzblatt, Quelle und Promptprovenienz speichern.
Kein neues 3D-Modell, kein Austausch des Missionsassets und keine Gameplay-Aenderung.

## Vertraege und Referenzen
graphics_reference_revision_contract.md; vier Pflichtdokumente vom Tankerauftrag.
Vorhandenes ab_satellite_wreck.glb und native Nahaufnahme aus absturzstelle_20261114;
satellite_recovery.png als Material-/Stilreferenz. Main-Basis be0b30af9e8d29155be5f6473960a537b1f1d1da.

## Akzeptanz und lokale Pruefung
Vier freigestellte Ansichten, Schuessel, einzelner geknickter Solarfluegel, abgebrochener
Gegenanschluss und Datenmodul erkennbar. Sichtpruefung plus RGBA/Alphapruefung.
Die Bild-KI liefert eine Modellierungsreferenz, keine geometrisch vermessene Zeichnung.

## Betroffene Dateien und Risiken
art/satellite_turnaround_20261121/* und diese Task. Zusaetzliche PNG-Kopie in Downloads.
Projektasset wird nicht ersetzt. KI-Ansichten koennen bei der Rekonstruktion eine
manuelle Abstimmung der Rueck- und Seitenansichten erfordern.

## Abschluss
Nutzerkorrektur am 21.11.: Vier separate PNGs statt eines gemeinsamen Blatts
bereitgestellt. V3-Quadranten verlustfrei extrahiert und transparent gepolstert;
keine neue Bildgestaltung. Pixel-/Alpha-/Datei-/ZIP-Pruefung dokumentiert in
`art/satellite_turnaround_20261121/single_views/manifest.json`.

`satellite_mission01_four_views_v3.png` erzeugt, visuell geprueft und als RGBA-PNG
mit echter Transparenz verifiziert. V3 korrigiert Schuesselrichtung und doppelten
Fluegelstumpf in den Seitenansichten. Lokale Kopie in Downloads, Quellenbilder und
alle Prompts/Hashes im Grafikpaket. Kein neues Modell oder Missionsasset ersetzt.
