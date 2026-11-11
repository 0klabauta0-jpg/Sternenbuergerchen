# R06 — Rüstungsproportionen und Hauptformen näher an die 2D-Vorlagen

## Ziel / Problem / Ursache
Der Nutzer findet die bestätigten 2D-Tafeln weiterhin deutlich schöner als
R05. Proportionen, Panzerungsabdeckung, Knieform/-sitz und seitliches Umgreifen
weichen sichtbar ab. R05 verbreitert nicht ausreichend die Brusthälften,
lässt den Rumpf schmal und viele Seiten offen; Knie wirken als geneigte
aufgesetzte Schilder statt angepasster Kappen. Zusätzliche pauschale Wölbung
löst die Hauptformabweichung nicht. Mehr gezielte Formknicke, Dreiecke und
Vertices sind ausdrücklich erwünscht; weniger Kleinteile, bessere Silhouette.

## Basis / Quellen / Verträge
Isolierter bestehender Taskbranch task/native-glut-maps-20261110 auf85fd00afc.
Originale Kenney-Quellen bleiben erhalten. Der Nutzer hat nachfolgend
eine eigene abgeleitete Körperform ausdrücklich erlaubt; vorhandenes Rig
und Animationen möglichst weiterverwenden.
- art/armor_orc_morozov_20261111/{light,medium,heavy}_turnaround_ai_r04.png
- art/armor_kenney_r05_20261111/armor_r05_editable.blend und Builder
- scripts/terrain/personnel_armor_visual.gd und produktive R05-GLBs
- docs/dev/graphics_reference_revision_contract.md
- docs/dev/personnel_inventory_contract.md
- docs/dev/html_report_workbench_contract.md
- docs/tasks/ARMOR_ORC_MOROZOV_2026_11_11.md
- docs/qa/armor_kenney_r05_20261111/README.md

## Umfang / Nicht-Ziele
Eigene neue R06-Modellrevision mit überprüfbaren Hauptformen. Breitere,
geknickte Brustflächen, sinnvoll gegliederter Rumpf/Rücken, körperfolgende
seitliche Abdeckung und zentrierte Kniekappen. Schwere Rüstung an der schönen
geschwungenen Gesamtform der Vorlage orientieren; einzelne Platten müssen
nicht überall bombiert sein. Zunächst Relationen zur Vorlage prüfen, dann
ungeeignete Schalen neu bauen. Keine reine Bevel- oder Detailvermehrung.
Geschlossene klare Visiere und feste Wangen-/Kinnschalen leicht/mittel aus
der neueren Nutzerkorrektur beibehalten. Nicht durch Luftabstände oder
übermäßige Dicke aufblasen. Eigene Körperform siehe Präzisierung unten;
keine Gameplay-/Inventaränderung,
keine Fahrzeuge, Mainintegration oder EXE. Kein neues Lebenserhaltungssystem.

## Akzeptanz
- Tatsächliche Vorlage/R05/R06 bei gleicher Figurenhöhe nebeneinander öffnen.
- Proportionsabweichungen konkret nennen: Brust zu Kopf/Schulterbreite,
  Rumpfabdeckung, Kniezentrum/Kappenprofil, Seiten- und Rückenabdeckung.
- Neue Geometrie unterstützt lesbare Hauptknicke und körperfolgende Schalen;
  Materialfarben oder zusätzliche Minisegmente ersetzen die Formarbeit nicht.
- Kneecaps sitzen auf beiden vorhandenen Rigs vor dem Knie und greifen
  seitlich zurück; Stand und echte Walkphasen prüfen.
- Ganze Bauchplatten behalten passende Spine-/Hips-Bindung; keine Knicke
  innerhalb starrer Platten. Füße/Toes und Helmanschlüsse bleiben korrekt.
- Reversible Ausrüstungsprojektion, Mesh/Skin-Caching und höchstens fünf
  Materialflächen beibehalten; Dreieckzahl messen, keine starre alte Obergrenze.
- Quellen, R05 und R06 getrennt erhalten; technische Prüfung ist keine
  ästhetische Nutzerfreigabe.

## Betroffene Dateien / Prüfung
Neue art/armor_kenney_r06_20261111 und entsprechende curated-GLBs,
Projektor, gezielter Rüstungsverifier, Vergleichs-Workbench, QA/Status.
Blender Geometrie-/UV-/Normalenprüfung und Material-/Wire-Bilder öffnen.
Frischer Godotimport; beide Rigs, Front/Seite/Quarter/Rücken/Oben,
Walk/Fire/Kopfdrehung, echter Inventar-/Basisweg mit privater APPDATA.
Aktualisierte Workbench lokal breit/schmal mit Notizen/JSON-Roundtrip prüfen.
Native Formbilder entscheiden über die Revision, nicht bloß bestandene Checks.

## Risiken / offene Punkte
KI-Tafeln sind keine maßhaltigen, völlig konsistenten Orthoprojektionen.
Kenney-Stil und vorhandenes Animationsrig begrenzen exakte Deckung;
die Körperform selbst ist nun Teil des freigegebenen Umfangs.
Mehr Formgeometrie darf keine unnötigen Drawcalls oder per-frame Rebuilds
verursachen. Sitz-/Transportextreme und breite Framerate bleiben getrennt.

## Arbeitsteilung
Der bereits ausdrücklich gewünschte kreative Astra-Ultra-Agent erstellt
R06-Kandidaten, Quellen und private Probes; Root überprüft Vergleich und
übernimmt erst danach in den produktiven Projektor. R05 bleibt Vergleich.

## Ausdrückliche Erweiterung: Figur statt sackförmigem Grundkörper
Der Nutzer benennt den nativen Körper als „Sack“ und wünscht ausdrücklich,
die Figur selbst näher an die schöne Schulter-/Körperform der 2D-Vorlage
zu bringen. Das ersetzt die frühere Vorgabe, den Body unverändert zu lassen.
Eigene R06-Bodyvariante aus dem tatsächlichen Kenney-Original modellieren:
etwas breitere Schultern/Brust, erkennbarer Brustkorb, schmalere Taille und
zusammenhängende anatomische Silhouette. Stil von Kopf/Händen/Füßen erhalten;
kein Aufblasen des gesamten Modells. Originalasset, Rig und Animationen
möglichst unverändert weiterverwenden und Quelle/Abweichung dokumentieren.
Basis- und Einsatzfigur müssen konsistent dieselbe neue Körperform erhalten;
Rüstungen an diesen Körper anpassen. Ohne Rüstung ist die Formänderung
ebenfalls im nativen Vorher/Nachher zu zeigen. Stand/echte Walk-/Fire-Posen
und Equip-/Unequip-Wechsel auf beiden Rigpfaden prüfen. Eigene editierbare
Blenderquelle und Exporte getrennt von unveränderter Originalquelle ablegen.

## Ergebnis R06
Eigene editierbare Body-/Armorsource,31GLBs und erforderliches Runtimeprofil
produktiv in isolierter Branchprojektion übernommen. Grundkörper formt
Schultern/Brust/Taille;285 Vertices geändert, Originaltopologie und bestehende
Rigs/Animationen erhalten. Produktive Posen/Wechsel156/0 headless+nativ,
Body-Korrespondenz154/0, echter Equip-/Basisweg16/0. Workbench134/0.
Quellen/Belege/Restabweichungen: docs/qa/armor_kenney_r06_20261111/README.md.
Keine ästhetische Nutzerfreigabe oder Main-/EXE-Aktualisierung behauptet.
