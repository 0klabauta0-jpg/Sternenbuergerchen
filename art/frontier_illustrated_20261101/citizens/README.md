# Citizens: finale Auswahl sind die normalen Kenney-Astronauten

Der Nutzer hat die Eigenbaufiguren und anschliessend auch die umgebauten
Kenney-Ableitungen verworfen. Der finale Satz nutzt deshalb die vollstaendige
unveraenderte `characterMedium`-Geometrie mit ihren urspruenglichen Proportionen,
UVs und Skin-Gewichten aus Kenneys **Animated Characters Bundle 4.0 (CC0)**.
Nur ein einheitlicher Meterfaktor normalisiert die Figur auf 1,78 m und setzt
den tiefsten Punkt auf den Boden. Es gibt keine eigenen Koepfe, Panzerplatten,
Manschetten oder angepassten Koerperproportionen im finalen Export.

## Aktuelle Dateien

- `build_stock_citizens.py`: reproduzierbarer finaler Export, Blender 5.2.3.
- `{operator,pilot,mechanic,medic}_stock.blend`: editierbare finale Ableitungen.
- `qa/stock_manifest.json`: Quellen-/Textur-/Exporthashes, unveraenderte
  Topologie, Originalbewegungsquellen und abgetastete Clip-Pruefung.
- `qa/stock_roundtrip.json`: frischer GLB-Rueckimport aller vier Figuren.
- `qa/*_stock_raw.json`: vollstaendige Roh-Geometriepruefungen je Figur.
- `qa/source_animation_settings.json`: Originalclips bei 30 fps, Frames 0-32.
- `KENNEY_LICENSE.txt`: unveraenderte Lizenz des verwendeten Projektbestands.

Laufzeitdateien liegen ausschliesslich unter
`Assets/curated/frontier_illustrated_20261101/citizens/`:

| Dateiname | Original-Skin |
| --- | --- |
| `operator.glb` | `astroMaleA.png` |
| `pilot.glb` | `astroFemaleB.png` |
| `mechanic.glb` | `astroMaleB.png` |
| `medic.glb` | `astroFemaleA.png` |

Die Namen sind Zuordnungslabels fuer die Vorschau, keine neuen Berufsformen
oder Gameplay-Eigenschaften. Jeder GLB enthaelt 804 Quellenvertices,
1.604 Dreiecke, ein Material mit eingebetteter Originaltextur, einen Skin und
die urspruenglichen `idle`-/`walk`-Bewegungen. Die Clips werden mit den
Original-IK-Constraints abgetastet und auf dieselbe Originalhierarchie gebacken.
Es entsteht kein zweites Rig. Beide Clips bleiben 32/30 Sekunden lang.

## Erhaltene, verworfene Studien

`{role}.blend` und `build_citizens.py` sind die erste verworfene Eigenbau-Runde;
`{role}_kenney.blend` und `build_kenney_citizens.py` sind der ebenfalls verworfene
Umbau mit eigenen Koepfen/Ausruestung. Sie sind keine aktuellen Figurenquellen.
Ihre Exporte liegen unter `rejected_original_studies/`,
`rejected_original_runtime_imports/` und `rejected_kenney_reinterpretation/`.
Rohberichte der ersten Runde bleiben unter `qa_original_study/` erhalten.
Einzelne dort dokumentierte Fehler sind Studienbefunde, keine Nachweise fuer
den finalen stock-Satz. Keine verworfene Figur liegt im kuratierten Laufzeitordner.

## Pruefstand und Grenzen

Finale Quelle und frischer GLB-Rueckimport bestehen die Roh-Geometriepruefung
bei allen vier Figuren ohne Fehler oder Warnungen. Die Rueckimporte messen
1,77999985 m Hoehe und Bodenkontakt innerhalb numerischer Rundung. Die
Bewegungsbakes unterscheiden sich maximal etwa 0,00000203 m von den
abgetasteten Original-Bonepositionen. Originaldateien im Kenney-Bundle und
`Assets/used/npc/animated_characters/` wurden nicht veraendert.

Native Godot-Ansichten und deren Import-/Laufzeitpruefung gehoeren zum
uebergeordneten Engine-Grafikpaket. Diese Quellenarbeit migriert keinen
Bevoelkerungs-, Combat- oder Loadout-Pfad und belegt keine Release-Abnahme.
