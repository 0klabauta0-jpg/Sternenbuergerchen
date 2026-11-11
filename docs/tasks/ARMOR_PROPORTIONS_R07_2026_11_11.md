# R07 — Verhältnis Kopf zu Schultern nach bestätigter Vorlage

## Ziel / Problem / Ursache
Der Nutzer sieht auch in R06 noch zu schmale Schultern bzw. einen zu großen
Kopf gegenüber den schönen 2D-Vorlagen. Er erlaubt ausdrücklich kleinere
Kopfproportionen als Alternative/Ergänzung; die frühere Vorgabe unveränderter
Kopfgröße ist damit aufgehoben. Nicht nur Schulterplatten aufblasen.

## Basis / Quellen / Verträge
Isolierter task/native-glut-maps-20261110 auf7ef57c931 plus bewusst noch nicht
integrierter/committeter R06-Arbeit. R06 ist technisch geprüft, vom Nutzer
weiter zur Überarbeitung bestimmt. Eigene R06-Quellen/Exporte und native
Front/Seite/Quarter erhalten. Bestätigte Light/Medium/Heavy2D-Tafeln unter
art/armor_orc_morozov_20261111. graphics_reference_revision_contract,
ARMOR_REFERENCE_SHAPES_R06_2026_11_11, Architektur-/Inventarverträge gelten.

## Umfang / Nicht-Ziele
Je Klasse sichtbare Helm-/Kopfbreite zur echten Schulteraußenbreite an
Vorlage und R06 messen. Daraus harmonische eigene Body-/Head-Proportionen
und dazu passende Armor-/Helmetfits ableiten. Schultern können breiter,
Kopf kleiner werden, ohne den ganzen Körper aufzublasen. Kopfänderung
bewusst um sinnvollen anatomischen Mittelpunkt, nicht durch Actor-Skalierung.
Kopf/Hände/Füße behalten Kenney-Stil; Hände/Füße unverändert. Vorhandene
Rig-/Animationshierarchie möglichst unverändert. Gesicht, klare dichte
Visier-/Kinn-/Wangenschalen und Halsanschluss halten. Keine Gameplayänderung,
Fahrzeuge, Main oder EXE. Separate R07-Quellen; Original/R05/R06 erhalten.

## Akzeptanz
- Verhältnis Schulter-/Helmaußenbreite je Klasse vor/nach dokumentieren;
  keine scheinbare Verbesserung durch Kamera oder geänderte Präsentationspose.
- Neue Körperform auch ohne Rüstung nativ auf beiden Rigs zeigen.
- Rüstung folgt dem neuen Körper, Helm dem bewusst veränderten Kopf.
  Körper- und Kopfänderungen bleiben über Ablegen und Klassenwechsel stabil,
  keine kumulative Verformung auf einer schon projizierten R06-Figur.
- Unveränderter Ursprung ist jederzeit separat erhalten. Korrespondenz
  zur eigenen tatsächlichen Blenderquelle auf Basis/Einsatz prüfen.
- Kopfdisplacement0 ist KEIN R07-Akzeptanzkriterium mehr; stattdessen korrekte
  neue Proportion, Halsanschluss und Kopfdrehung mit konstantem Originalrig.
- Echte Idle-/Walk-/Fire-/Headturn-Aufnahmen, Front/Quarter/Seite/Rücken/Oben,
  identische Kamera/Licht wie R06, Vergleich zur 2D-Tafel.
- Blender Geometrie-/UV-/Normalen-QA, frischer Godotimport, echter Equipweg,
  Body-/Armorcache und maximal fünf Outfitmaterialflächen.

## Dateien / Prüfung / Risiken
Neue art/armor_kenney_r07_20261111, eigene curated-GLBs/Runtimeprofil,
personnel_armor_visual.gd, Verifier, QA und Vergleichsworkbench.
Root integriert erst nach Astra-Kandidatenprüfung, getrennt von Terrain-
Prefill-/Performancearbeit. Private APPDATA und koordinierte Nativefenster.
Risiken: Halslücke bei Kopfverkleinerung, Kopf/Helm drehen um alten Bonepivot,
R06-Body bereits auf tatsächlichem Einsatzproxy projiziert. Keine 1:1-/
Stilfreigabe oder globale Framerate allein aus bestandenen Checks ableiten.

## Erste Formmessung / Richtung
Front-Landmarken grob±3px: Schulteraußenbreite/Helmaußenbreite
Light Vorlage≈0,90/R06≈0,86, Medium≈1,19/0,90, Heavy≈1,46/0,96.
Bei gleicher Figurenhöhe ist R06-Helmbreite nur etwa0–3% größer als die Tafeln;
Hauptabweichung ist die Schulterlinie. Deshalb moderate Kopfableitung
(etwa−5%Breite/−8%Höhe um Halsansatz) mit breiterer echter Deltoidkontur
und klassengerechten Schulterdächern prüfen; keine willkürliche starke
Kopfverkleinerung. Native Zielrelationen Medium≈1,15–1,20/Heavy≈1,35–1,45
sind Vergleichsziele, keine durch technische Tests erzwungene Stilfreigabe.
