# Frontier-Strukturen: erster nativer Grafikdurchgang

Originale statische Modellfamilie fuer den bestaetigten Aussenposten `03_aussenposten_stilstudie.png` und die Landschaft `01_rostwelt_landschaft.png` unter `docs/reports/assets/grafik-2026-11-01/`. Beide Vorlagen wurden vor Modellierung geoeffnet. Quelle, Export und 9 tatsaechliche Blender-Pruefbilder liegen hier nachvollziehbar getrennt vor.

## Modelle und Schnittstelle

| Modell | X/Y/Z in Blender, Meter | Dreiecke Export | Meshes / Materialien |
|---|---|---:|---|
| habitat_01 | 6.68 / 6.745 / 4.35 | 12320 | 1 / 7 |
| workshop_01 | 7.04 / 5.69 / 4.2225 | 7616 | 1 / 8 |
| service_unit_01 | 4.85 / 3.20 / 2.71 | 5832 | 1 / 6 |

Ursprung ist jeweils Bounds-Mitte in X/Y und Boden Z=0. Front ist Blender **-Y**, nach glTF in Godot **+Z**. Godot-Abmessungen werden damit X / Hoehe / Tiefe. Die Heimatstruktur bleibt zentriert; die Habitat-Bounds schliessen die Fronttreppe ein.

- Habitat: dicke cremefarbene Wandsegmente, grosse eingefasste Fensteroeffnungen, rundum abgeschraegtes Dach mit drei breiten Teal-Segmenten, Dachluefter, gerahmte Luftschleuse mit rund 2.1m Rahmenoeffnung, vier Hoehenstufen inklusive Podest, Handlauf und angeschlossene Rueckseitenversorgung.
- Werkstatt: tatsaechlich offene Front mit dicker Portalzarge, beidseitige Waende und geschlossene Rueckwand, getragenes Dach, Werkbank mit vier Fuessen/Schrank/Vise, abgestuetztes Ocker-Hebeportal mit Laufwagen, Seil und Haken. Keine animierte Mechanik.
- Versorgung: horizontaler geschlossener Tank mit zwei Saetteln und Haltebaendern, mittlerem Teal-Guertel, entlueftetem Deckel, bodenverbundener Pumpeneinheit und angeschlossenen Vor-/Ruecklaufrohren mit Ventil.

Die GLBs unter `Assets/curated/frontier_illustrated_20261101/structures/` enthalten nur 1 Meshnode mit den benoetigten Materialsurfaces, keine Kamera/Lichter, Kollision, Navigation, Animation oder Skins. Alle Teile bleiben in der `.blend` einzeln benannt und editierbar. Die Palette besteht aus konstanten matten Principled-Materialien; es werden keine Texturen verwendet.

## Reproduktion und Evidenz

Blender 5.2.3 LTS:

```powershell
& 'C:/Users/bjoer/AppData/Local/Programs/Blender Foundation/Blender 5.2/blender.exe' --background --factory-startup --python-exit-code 1 --python 'art/frontier_illustrated_20261101/structures/generator/build_structures.py' -- --preview
python 'art/frontier_illustrated_20261101/structures/generator/finalize_structure_manifest.py'
```

`review_structure_sources.py` aktualisiert nur Ansichten aus den finalen Quellen, ohne Quellen/Exporte zu aendern. `manifest.json` dokumentiert Abmessungen, exakte Counts, Datei-/Referenz-/Bildhashes und Pruefumfang. `qa/*_qa_raw.json` sind direkte Ausgaben des unveraenderten Skill-Pruefers; `qa/build_r04.log` ist der finale Generator-/Exportlauf.

Alle neun Vorder-/Rueck-/Wire-Ansichten wurden geoeffnet. Handlaeufe, Stufen, Waende, Dachplatten, Werkbankfuesse und Rohre zeigen nachvollziehbare Auflagen/Verbindungen. Die Huebeportalposition wurde fuer Sichtbarkeit nach vorn gesetzt und die obere Werkstattrueckwand geschlossen. Sichtbarkeit im normalen Gameplay-Abstand prueft der native Godot-Preview des uebergeordneten Tasks.

## QA-Ergebnis

Alle drei Modelle bestehen den vollstaendigen neuen Geometriecheck mit `profile=game`, `eps=0.0003`, `tol=0.006`: keine inversen Inseln, inkonsistente Normalen, degenerierten Flaechen, Null-Laengen-Kanten, nichtmanifold/offenen Kanten, Z-Fighting- oder Floating-Fehler. Der Paar-/Kontaktcheck wurde bei diesen Counts nicht uebersprungen. Der Generator verweigert Export bei neuen QA-Fehlern.

UV-spezifische Pruefungen sind ausdruecklich ausgeschlossen, weil diese Familie ausschliesslich konstante untexturierte Materialien nutzt. Eine spaetere Texturroute braucht eine passende UV-Revision.

Akzeptierte Warnungen sind erhalten und nicht als Fehlerfreiheit versteckt:

- Habitat: 18 Warnungen zu verdeckten gegenlaeufigen Montage-/Kontaktflaechen der einzeln editierbaren Zarge, Fensterrahmen und Paneele. Diese sind geschlossene Bauteile, keine vollstaendig vereinigte wasserdichte Boolean-Huelle. Es gibt keine sichtbare coplanare Ueberlagerung. Eine weitere Heuristik nennt zwei eingeschlossene Tuergriffe; beide Ocker-Griffstangen sind in der geoeffneten Vorderansicht sichtbar. Die Einschliessungsheuristik wird hier durch die verschachtelte Zarge getaeuscht.
- Werkstatt: 8 entsprechende Warnungen zu verdeckten Montage-/Kontaktflaechen von Sockel/Portal, Schrankschalen und Stossfaenger-Akzentplatten.
- Versorgung: keine Warnungen.

Das sind erste, originale native Art-Assets. Sie belegen keine globale Migration aller Bestandsmodelle, keine Navigation in Gebaeuden, keine begehbaren Innenraeume und keine vollstaendige Spiel-/Release-Abnahme. Placement, frischer Godot-Import, native Gesamtansicht und Spielabstand werden im uebergeordneten Grafikdurchgang geprueft.
