# Cutlass — Refinement 03, Nutzerentwurf mit vier Triebwerken

Dieser separate Kandidat setzt die neue Nutzeranordnung um und weicht bewusst von den ursprünglichen Illustrationen ab: schmalere Frontflügel, in Breite und Höhe kleinere Hecktriebwerke und zwei neue Fronttriebwerke mit halbem Durchmesser der verkleinerten Hecktriebwerke. Refinement 02 bleibt unverändert erhalten.

Finale editierbare Quelle: `source/final/cutlass_01.blend`, bytegleich mit `source/iteration01/cutlass_01.blend`. Export relativ zum Repository: `Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/cutlass_01.glb`. Die Quelle enthält 174 benannte Mesh-Teile in `LOW` mit editierbaren Modifikatoren. Der GLB enthält ein Mesh, acht Materialien und fünf Texturbilder. 22.496 Dreiecke, Maße 12,0783 × 16,0000 × 5,7466 m; gesamte XY-Bounding-Box zentriert, Boden Z=0, Blender -Y vorwärts beziehungsweise glTF/Godot +Z vorwärts.

| Geometrisches Maß | Refinement 02 | Refinement 03 |
|---|---:|---:|
| Horizontale Frontflügelspannweite | 11,618 m | 8,224 m (−29,2 %) |
| Spannweite der Front-Endplatten | 11,931 m | 8,537 m (−28,4 %) |
| Einzelner Heckpod: maximale Breite | 2,707 m | 2,355 m (−13,0 %) |
| Heckdüse: äußerer Durchmesser | 2,332 m | 2,029 m (−13,0 %) |
| Neue Frontdüse: äußerer Durchmesser | — | 1,014 m (50,0 % der Heckdüse) |
| Neuer Frontpod: maximale Breite | — | 1,177 m (50,0 % des Heckpods) |
| Ganze vordere Gruppe einschließlich Pods | — | 10,443 m |
| Gesamte hintere Podgruppe | 12,430 m | 12,078 m |

Die vorderen Motorachsen liegen bei X=±4,633 m, die hinteren bei X=±4,862 m. Damit sind die Frontachsen je 0,229 m nach innen versetzt. Die Hecktriebwerke reichen beidseitig noch 0,818 m über die äußerste Vordergruppe hinaus. Die neuen Pods sind längs auf 43 % der Heckpodlänge verkürzt und über eigene Sättel mit Flügeln/Endplatten verbunden. Alle neuen Komponenten tragen `VH_Cutlass_Forepod_` im Namen.

Cockpit, Nase und bemannter Turm sind geometrisch exakt aus Refinement 02 erhalten: Ein Hashvergleich der ausgewerteten Vertexpositionen, Polygone und Materialzuordnungen bestätigt Gleichheit. Die verdeckten Sitzpersonen-/Freiraumproxies bleiben enthalten und bestehen erneut die Eckpunktprüfung; sie sind keine ausgearbeitete Inneneinrichtung oder Ergonomie-Zertifizierung. Alle Maße und Prüfdetails: `review/final/evaluated_proportions.json`.

`review/final/independent_qa.json` besteht mit **0 Fehlern und 0 Warnungen**. Source-Asset-QA, Kontaktgraph, endliche Geometrie, Achsen, Länge, Ground-Pivot, Materialien/Texturkanäle, UVs und frischer GLB-Reimport wurden geprüft. Positionsabweichung 0 m; direkte GLB-Normalenabweichung maximal 0,000101675, frischer Reimport 0,001117273 bei unveränderter Grenze 0,002. Alle sieben eigenen Front-/Heck-/Seiten-/Drauf-/Spielabstands-/Baugruppen-/Wireframe-Ansichten wurden geöffnet. Unabhängige direkte Vergleiche liegen im gemeinsamen Ordner `refinement_03/review/cutlass/`.

Die gegenüberliegende kleine Frontgondel wird aus der vorderen Dreiviertelansicht teilweise durch ihre innere Endplatte verdeckt; Heck- und Draufsicht zeigen die Anordnung eindeutig. Keine weitere Detailausweitung. Kein Godot-Import, keine Laufzeitintegration und keine Nutzerabnahme.

Herkunft: eigener vorhandener Generator und eigene deterministische Farbtexturen weiterentwickelt; keine externen 3D-Meshes übernommen. Die gepackten Nutzerreferenzen 08/09 bleiben stilistische Herkunft, sind für diese neue Viertriebwerksanordnung keine Behauptung originalgetreuer Rekonstruktion. Keine neue Lizenz für zugrunde liegende Schiffs-IP behauptet; Datei-/Referenzhashes werden im gemeinsamen Manifest gebunden.

Reproduktion, Blender 5.2.3 und Python mit Pillow/NumPy:

```powershell
$repo = 'C:/Users/bjoer/.codex/worktrees/grafikreferenzen-20261101/SternenBuergerchen'
$shipArt = "$repo/art/frontier_illustrated_20261101/ships/pass05_astra_ultra/refinement_03/cutlass"
$shipQa = "$repo/art/frontier_illustrated_20261101/ships/pass05_astra_ultra/qa_tools"
$shipGlb = "$repo/Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/cutlass_01.glb"
$blender = 'C:/Users/bjoer/AppData/Local/Programs/Blender Foundation/Blender 5.2/blender.exe'
python "$shipArt/build/make_paint.py"
& $blender -b --factory-startup --python-exit-code 1 -P "$shipArt/build/build_cutlass.py" -- --iteration 1
New-Item -ItemType Directory -Force -Path "$shipArt/source/final","$shipArt/review/final" | Out-Null
Copy-Item -LiteralPath "$shipArt/source/iteration01/cutlass_01.blend" -Destination "$shipArt/source/final/cutlass_01.blend"
Copy-Item -LiteralPath "$shipArt/build/build_cutlass.py" -Destination "$shipArt/source/final/generator_snapshot.py"
Copy-Item -LiteralPath "$shipArt/source/iteration01/proportion_metrics.json" -Destination "$shipArt/source/final/proportion_metrics.json"
& $blender -b --factory-startup --python-exit-code 1 -P "$shipArt/build/measure_proportions.py" -- --iteration 1
Copy-Item -LiteralPath "$shipArt/review/iteration01/evaluated_proportions.json" -Destination "$shipArt/review/final/evaluated_proportions.json"
& $blender -b --factory-startup --python-exit-code 1 -P "$shipArt/build/review_cutlass.py" -- --final
& $blender -b --factory-startup --python-exit-code 1 -P "$shipQa/verify_ship.py" -- --blend "$shipArt/source/final/cutlass_01.blend" --glb $shipGlb --out "$shipArt/review/final/independent_qa.json" --collection LOW --length 16
```

Aktiver Einstieg ist `build/build_cutlass.py`; `source/final/generator_snapshot.py` ist nur die Archivkopie. Der Builder konsolidiert den Teil-GLB mit `qa_tools/consolidate_glb.py` ohne Normalen-Neukodierung.

- Blend SHA-256: `9ad68207a8ee30dc307df4b53a7735e422335363031b3e1343f5731b58fdc9cd`
- GLB SHA-256: `21484195affa66a1bc503f34b20ae561312057e46e077250e8a772b6881e6daf`
