# Rüstung als zusammenhängender Anzug

## Problem / Ursache

Der Nutzer lehnt die erste Rüstungsfassung ab: flache, grün wirkende Platten
sehen aufgeklebt aus. Seine angehängte Achtansichten-Vorlage ist die verbindliche
Formreferenz der schweren Rüstung. Er tendiert ausdrücklich zu schwer. Ergänzend
wünscht er Star-Citizen-/RSI-/ADP-Referenzen. Die vorherige einfache Form ist kein
abgenommener Endstand.

## Ziel und Umfang

Eine vollständige schwere Rüstung mit körperumschließendem Brust-/Rückenpanzer,
Helm, Schulterkappen, Armschutz, Handschutz, Hüftschutz, Oberschenkeln, Knien,
Schienbeinen und Stiefeln. Flexible dunkle Zwischenräume bleiben sichtbar.
Mittlere Ausrüstung bekommt eine schlankere Ausführung derselben Formfamilie.
Leichte Ausrüstung erhält ebenfalls keine grüne rechteckige Frontplatte.
Eigene Farbentscheidung: warme helle Keramik, Graphit und kleine bernsteinfarbene
Akzente. Kein grüner Überwurf. Vorlage bestimmt Form und Zusammenhalt.

Die Körperproportionen und Animationen der vorhandenen Spielfiguren bleiben der
Anpassungsrahmen. Vorhandene fest eingebaute Gear-Platten dürfen bei der Projektion
nicht doppelt durch die neue Ausrüstung scheinen. Der Unteranzug wird als dunkle
flexible Lage sichtbar; Haut und Gesicht behalten ihre ursprünglichen Farben.

Nutzerkorrektur zu Helmen: Größe am vorhandenen Spacehelm orientieren und die
anderen Helme aus dem Figurenpaket zur Formfindung ansehen. Anschließend ausdrücklich:
Pakethelme nicht direkt übernehmen; sie sollen nur helfen. Die Militär-/Rennhelm-
Varianten bleiben daher Vergleichsreferenzen. Eingebaut wird ein eigener Helm mit
passender Größe, Sitz am Kopf/Kragen und derselben Formsprache wie die neue Rüstung.

Die bestehende Ausrüstungs-/Bestandswahrheit bleibt unverändert. Kein neuer
Schutzwert, keine zusätzliche Slotwahrheit, kein gratis Rucksack. Rückengehäuse
der Rüstung ist kein zusätzliches Frachtinventar.

## Umsetzung

- Neue versionierte Blender-Bibliothek aus geformten, abgeschrägten Volumenkörpern
  mit nachvollziehbarem Quellcode, Zielreferenz und Exporten. Alte Kandidaten erhalten.
- Pro Rüstungsstufe einen kombinierten geskinnten Render-Mesh aus den Teilen an
  die vorhandenen Knochen binden. Ein Gewicht pro starrem Teil; gemeinsame
  Materialflächen statt eines Drawcalls für jedes Stück. Geometrie/Skin pro Rig
  und Klasse cachen, nur bei geänderter Ausrüstung anbauen.
- Hauptquelle ist das vom Nutzer angehängte Bild. RSI/CDS/ADP/ORC sind zusätzliche
  Form-/Konstruktionsreferenzen, keine ungeprüft übernommenen Spielwerte.

## Verträge / betroffene Dateien

graphics_reference_revision_contract.md, personnel_inventory_contract.md,
ARCHITECTURE.md. Neue art/armor_revision_20261111-Quellen und Assets, vorhandener
personnel_armor_visual.gd-Helper, dessen Proxy-Anschluss, gezielte Verifier und QA.
Parallel bearbeitet der Performance-Agent ausschließlich die vereinbarten Messpfade.

## Akzeptanz / lokale Prüfung

1. Schwere Ausrüstung liest als vollständiger Anzug entsprechend der Achtansichten-
   Vorlage, einschließlich Helm und geschützter Gliedmaßen; keine flache grüne Weste.
2. Leicht, mittel, schwer bleiben aus Spielabstand unterscheidbar. Alte Gear-Teile
   werden nicht doppelt angezeigt. Kein Einfluss auf Inventar oder Wirkung.
3. Pro Outfit ein kombinierter geskinnten Mesh mit höchstens fünf Materialflächen;
   keine fortlaufenden Szenensuchen oder Geometrie-Rebuilds bei unveränderter Klasse.
4. Blender-Geometrie-/UV-/Normalenprüfung sowie Material- und Wire-Ansichten.
5. Frischer Godotimport, Front/Seite/Rückseite, Stand, Lauf, Feuerpose und echte
   Inventaransicht. Poseanbindung, Bounds, Orientierung und Wechsel zurück zum Anzug.
6. Kleine gezielte Inventar-/Rüstungsregressionen. Nutzerurteil zur Form bleibt
   getrennt von technischen Prüfungen.

## Risiken / offene Punkte

Rüstung muss an beide vorhandenen Rigachsen und die stilisierten Proportionen
passen. Referenzdetails werden auf lesbare Formen reduziert. Sitz-/Transportposen
und endgültige Stilabnahme bleiben ausdrücklich zu prüfen. Performance-Messfenster
erfolgen ohne parallele Blender-/Godotarbeit.

## Ergebnis

Eigene geformte Rüstung mit eigenem Helm im isolierten Taskbranch eingebaut.
Pakethelme ausdrücklich nur Referenzen; ihre Studienexporte werden nicht geladen.
17 eigene GLBs, editierbare Quelle/Builder/Manifest. Ein gecachter skinnender
Mesh je Outfit mit höchstens fünf Materialflächen. Native Poseprüfung109/0,
tatsächlicher Inventar-/Basisweg16/0. Siehe docs/qa/armor_revision_20261111.
Sitz-/Transportextreme und gestalterische Nutzerabnahme bleiben offen.
