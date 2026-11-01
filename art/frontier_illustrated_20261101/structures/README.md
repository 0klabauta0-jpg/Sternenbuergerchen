# Frontier-Strukturen: Pass 02, visueller Kandidat

Ueberarbeitete statische Modellfamilie fuer `03_aussenposten_stilstudie.png` sowie die neu gelieferten Nutzerbilder `references/current/01_rostgrenze_cutaway.png` und `02_freihafen_distribution_center.png` unter `docs/reports/assets/grafik-2026-11-01/`. Alle drei Vorlagen wurden geoeffnet. Quellen, Exporte, Roh-QA, frischer GLB-Rueckimport und 12 geoeffnete Blender-Pruefbilder liegen getrennt vor. Dieser Stand ist ein Modellkandidat; die gestalterische Nutzerabnahme und der frische native Godot-Vergleich gehoeren zum uebergeordneten Pass-02-Task.

## Modelle und Schnittstelle

| Modell | X/Y/Z in Blender, Meter | Dreiecke Export | Meshes / Materialien |
|---|---|---:|---|
| habitat_01 | 6.68 / 6.745 / 4.35 | 13184 | 1 / 8 |
| workshop_01 | 7.04 / 5.718 / 4.2225 | 9992 | 1 / 9 |
| service_unit_01 | 4.85 / 3.20 / 2.71 | 6760 | 1 / 7 |

Ursprung ist jeweils Bounds-Mitte in X/Y und Boden Z=0. Front ist Blender **-Y**, nach glTF in Godot **+Z**. Godot-Abmessungen werden damit X / Hoehe / Tiefe. Die Heimatstruktur bleibt zentriert; die Habitat-Bounds schliessen die Fronttreppe ein.

Habitat und Versorgung behalten ihre bisherigen Bounds exakt. Die Werkstatttiefe waechst durch das hintere orange Band um 0.028m; der Bounds-Mittelpunkt wird weiter automatisch zentriert. Breite und Hoehe bleiben gleich. Der GLB-Rueckimport bestaetigt alle Bounds und den Bodenpivot innerhalb 0.0001m.

- Habitat: hellere cremegraue Schale mit drei neutralen Dachfeldern, petrolfarbenen Dachschultern und umlaufendem orangefarbenem Band. Die abgeschraegte Luftschleuse hat klarere orange Akzente. Tuer, Fenster, Luefter, Treppe und Handlaeufe behalten die bisherige Konstruktion.
- Werkstatt: gleiches helles Dach-/Schalenkit und orange Wand-/Portalbaender. Die vorhandene zusammenhaengende Werkbankgruppe mit Schrank und Schraubstock steht 1.45m weiter vorn und wird nicht mehr vom Dach verdeckt. Ein getragenes dreistufiges Regal mit fuenf grossen Kisten steht rechts innerhalb des vorhandenen Grundrisses. Hebeportal, Laufwagen, Seil und Haken bleiben statisch.
- Versorgung: hellere Tank-/Pumpenschalen, orange Tankmitte, neutraler Pumpendeckel und zwei sichtbar verbundene Frontkupplungen. Saettel, Haltebaender, Ventil und Vor-/Ruecklauf behalten ihre Verbindungen.

Die GLBs unter `Assets/curated/frontier_illustrated_20261101/structures/` enthalten nur 1 Meshnode mit den benoetigten Materialsurfaces, keine Kamera/Lichter, Kollision, Navigation, Animation oder Skins. Alle Teile bleiben in der `.blend` einzeln benannt und editierbar. Die Palette besteht aus konstanten matten Principled-Materialien; es werden keine Texturen verwendet.

## Reproduktion und Evidenz

Blender 5.2.3 LTS:

```powershell
& 'C:/Users/bjoer/AppData/Local/Programs/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python-exit-code 1 --python 'art/frontier_illustrated_20261101/structures/generator/build_structures.py' -- --preview
& 'C:/Users/bjoer/AppData/Local/Programs/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python-exit-code 1 --python 'art/frontier_illustrated_20261101/structures/generator/verify_structure_exports.py'
python 'art/frontier_illustrated_20261101/structures/generator/finalize_structure_manifest.py'
```

`review_structure_sources.py` aktualisiert nur Ansichten aus den Quellen, ohne Quellen/Exporte zu aendern. `manifest.json` dokumentiert Abmessungen, exakte Counts, Datei-/Referenz-/Bildhashes und Pruefumfang. `qa/*_qa_raw.json` sind direkte Ausgaben des unveraenderten Skill-Pruefers. Der aktuelle Generator-/Exportlauf steht in `qa/pass02_build_r02.log`; `qa/pass02_glb_roundtrip.json` und `qa/pass02_roundtrip.log` belegen den frischen Blender-Rueckimport. Fruehere Build-Logs sind historische Zwischenstaende.

Alle zwoelf Vorder-/Rueck-/Teilfarben-/Wire-Ansichten wurden geoeffnet. Handlaeufe, Stufen, Waende, Dachplatten, Werkbankfuesse, Regal/Kisten und Rohre zeigen nachvollziehbare Auflagen/Verbindungen. Nach dem ersten Pass-02-Bild wurde das neue Regal nach vorn gerueckt, weil es zunaechst von der Seitenwand verdeckt wurde. Sichtbarkeit im normalen Gameplay-Abstand prueft der native Godot-Preview des uebergeordneten Tasks. Die Blender-Bilder verwenden Workbench, kein enginegleiches Licht; die Zufallsfarben sind reine QA, nicht die exportierte Palette.

## QA-Ergebnis

Alle drei Modelle bestehen den vollstaendigen neuen Geometriecheck mit `profile=game`, `eps=0.0003`, `tol=0.006`: keine inversen Inseln, inkonsistente Normalen, degenerierten Flaechen, Null-Laengen-Kanten, nichtmanifold/offenen Kanten, Z-Fighting- oder Floating-Fehler. Der Paar-/Kontaktcheck wurde bei diesen Counts nicht uebersprungen. Der Generator verweigert Export bei neuen QA-Fehlern.

UV-spezifische Pruefungen sind ausdruecklich ausgeschlossen, weil diese Familie ausschliesslich konstante untexturierte Materialien nutzt. Eine spaetere Texturroute braucht eine passende UV-Revision.

Akzeptierte Warnungen sind erhalten und nicht als Fehlerfreiheit versteckt:

- Habitat: 19 Warnungen zu verdeckten gegenlaeufigen Montage-/Kontaktflaechen der einzeln editierbaren Zarge, Fensterrahmen, Paneele und der Band-/Servicepanel-Auflage. Diese sind geschlossene Bauteile, keine vollstaendig vereinigte wasserdichte Boolean-Huelle. Es gibt keine sichtbare coplanare Ueberlagerung. Eine weitere Heuristik nennt zwei eingeschlossene Tuergriffe; beide Ocker-Griffstangen sind in der geoeffneten Vorderansicht sichtbar. Die Einschliessungsheuristik wird hier durch die verschachtelte Zarge getaeuscht.
- Werkstatt: 15 entsprechende Warnungen zu verdeckten Montage-/Kontaktflaechen von Sockel/Portal, Schrankschalen, Stossfaenger-Akzentplatten, aufliegenden Kisten/Regalboeden und Bodenmarkierungen. Die neuen Kisten stehen auf den Regalboeden; die Kontaktkappen werden als getrennt editierbare geschlossene Teile behalten.
- Versorgung: keine Warnungen.

Der GLB-Rueckimport besteht denselben Geometriecheck und liefert identische Dreieckzahlen. Er meldet zusaetzlich 12984 / 9939 / 6439 doppelte Vertexpositionen: glTF trennt hier Flaechen-Normalen und Materialgrenzen. Es gibt keine losen Vertices; ein blindes Verschweissen wuerde die beabsichtigten harten Kanten veraendern. Die importierten Kontaktflaechenwarnungen beziehen sich auf dieselben bewusst getrennten Bauteile. Diese Warnungen sind mit Begruendung im Manifest erhalten.

Der Pass behaelt geschlossene Daechermodelle. Ein vollstaendiges Cutaway-Raumensemble ist noch nicht umgesetzt; Bettenzahlen und andere Referenzbeschriftungen sind keine Gameplay-Regeln. Die Assets belegen keine globale Migration aller Bestandsmodelle, keine Navigation in Gebaeuden, keine begehbaren Innenraeume und keine vollstaendige Spiel-/Release-Abnahme. Placement, frischer Godot-Import, native Gesamtansicht und Spielabstand werden im uebergeordneten Grafikdurchgang geprueft.
