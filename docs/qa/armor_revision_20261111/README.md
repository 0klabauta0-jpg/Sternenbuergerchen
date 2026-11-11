# Eigene Rüstung und Helm — Revision02

11.11.2026, isolierter Branch `task/native-glut-maps-20261110` auf46acfaa58.
Die Pakethelme dienen nach bestätigter Nutzerkorrektur ausschließlich als
Form-/Größenreferenz. Keine Militär-/Rennhelmgeometrie wurde als neue Rüstung
eingebaut. Die bisherigen Standardhelme bleiben bei Anzug/leicht erhalten.

Die neue eigene Fassung ersetzt auf diesem Taskbranch die vom Nutzer abgelehnte
flache Rüstung. Körperumschließende Brust-/Rückenteile, segmentierte Gliedmaßen,
Kragen und ein eigener geschlossener Helm. Helle warme Keramik, Graphit und kleine
Amberakzente. Die Größe orientiert sich am vorhandenen Spacehelm. Die Helmform
hat eine gerundete Krone, geschütztes schmales Visier, Kinnpartie und seitliche
Koppler. Keine Aussage einer gestalterischen Nutzerabnahme.

## Quellen und Umsetzung

[Quellenpaket](../../../art/armor_revision_20261111/README.md) mit Nutzerbild,
editierbarer Blenderdatei, eigenem Builder, verworfener Pakethelmstudie,
Geometrie-QA und SHA-256-Manifest.17 eigene GLBs. Keine Referenzstudien-Exporte
im produktiven Assetordner. Alte Versionen und ihre QA bleiben erhalten.

Der vorhandene Helper liest die tatsächliche Rüstung und kombiniert4/15/20
Segmente für leicht/mittel/schwer zu einem geskinnten Mesh mit höchstens fünf
Materialflächen. Ein starres Knochengewicht pro Vertex; bestehende Skelette und
Animationen. Mesh, Skin, Material und Teile werden wiederverwendet. Gleiche Klasse
kehrt ohne Suche/Rebuild zurück. Einmalige Nachfahrensuchen nur beim Anbau.
Originalkopf bleibt unverändert als geteilte Ressource erhalten. Für geschlossene
Helme wird eine gecachte Projektion ohne Kopfpolygone benutzt; Ablegen stellt den
Originalmesh wieder her. Die Anpassung misst immer den Originalkopf, auch nach
vorherigem Verbergen. Legacy-Gear wird ausgeblendet, kein zweiter Helm überlagert
die neue Schale. Ausrüstung wird nach bestehendem Zubehöranbau projiziert.

Inventar, Schutzwerte, Eigentum und Freischaltungen bleiben in ihren bestehenden
Ownern. Keine neuen Gameplaydaten oder Animationen in der Anzeige.

## Prüfungen

- Blender5.1.1:17/17 Teile bestehen Geometrie-/UV-/Normalenprüfung ohne Fehler.
  Insgesamt5802 Dreiecke in der Bibliothek. Outfits1168/4652/5756 Dreiecke.
  Zentrierte tragbare Teile haben absichtlich keinen Bodenpivot; einzige
  akzeptierte Warnung je Teil. Material- und Wire-Vierwinkelbilder geöffnet.
- Frischer Godot4.6.2-Import Exit0. Vorhandene UID-Fallbackwarnungen in
  Editor-Addon-Szenen und ObjectDB-Warnung beim Editorende; keine Scriptfehler.
- Native D3D12 Forward+, RTX4070TiSUPER,1920×1080: Poseprüfung109/0, Exit0,
  ohne Enginefehler. Beide vorhandenen Rigachsen, Anzug/leicht/mittel/schwer,
  echte Proxy-Erzeugung, Stand/Lauf/Feuer/Rückseite/Kopfdrehung25°.
  Ein Mesh, höchstens fünf Flächen, Bindings am vorhandenen Skelett,
  Cache-Sharing zwischen gleichen Rigs, Kopfabdeckung und Wiederherstellung.
- Tatsächliche Kampagnenszene/Inventaroperation16/0, Exit0: Besitz/Blueprint,
  Herstellung, endlicher Bestand, kanonischer Wechsel, tatsächlicher Ablegenbutton,
  Rückgabe, Chipfach ohne Rucksack, Legacy-Restore und echte Basisprojektion.
  Derselbe markierte Domainfixture wie zuvor, kein echter neuer Satellitenausflug;
  Autosave für das Fixture gestoppt. Privates APPDATA unter output/native_glut_maps.
  Zwei vorhandene UID-Fallbackwarnungen der Homebase-Szene, keine Scriptfehler.
  Die Basisaufnahme wartet nun auf das erste Rendern des verschachtelten Viewports.
- Beide Programme zusätzlich headless im privaten Profil:109/0 und15/0,
  jeweils Exit0; der zusätzliche Welt-Rendercheck gehört nur zum nativen Lauf.

[Helmvergleich](armor_helmet_own_comparison_quarter.png),
[Lauf](revision_armor_walk.png), [Feuer](revision_armor_fire.png),
[Rückseite](revision_armor_rear.png), [Kopfdrehung](revision_armor_head_turn.png),
[Ausrüstung](armor_actual_equipment.png), [tatsächliche Basis](armor_actual_base.png).
Alle genannten Bilder wurden geöffnet. Der Helmvergleich zeigt links den
bestehenden Spacehelm, mittig und rechts die eigenen neuen Outfits unter gleicher
Kamera/Beleuchtung. Die Pakethelme sind dort keine neuen Rüstungsmodelle.

## Grenzen

Keine breite Frameratefreigabe aus der geringen Meshzahl ableiten. Sitz-/Transport-
und extreme Schulterposen sind noch offen. Die Formen vereinfachen die deutlich
detailliertere Nutzerreferenz für den bestehenden Figurenstil. Mittlere/schwere
Ausrüstung unterscheidet sich durch Umfang und Abdeckung; die endgültige
visuelle Lesbarkeit und Stilabnahme bleiben beim Nutzer. Kein Main-/EXE-Schritt.
