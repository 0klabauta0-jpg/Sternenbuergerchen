# Cutlass — Refinement 02

Der Kandidat korrigiert die Hauptproportionen nach der erneuten Nutzerkritik: breitere Frontflügel mit weit nach hinten reichenden Schulterwurzeln, eine breitere und am Bug höhere Kanzel sowie ein deutlich größerer bemannter Turm. Die vorherigen Pakete bleiben erhalten. Die Proportionen sind aus den perspektivischen Referenzen 08/09 abgeleitet; sie sind keine kanonischen Schiffmaße.

Finale editierbare Quelle: `source/final/cutlass_01.blend`, identisch mit `source/iteration02/cutlass_01.blend`. 144 benannte Konstruktionsteile in `LOW`, Bevel-/Normalen-/Triangulationsmodifikatoren bleiben editierbar. `REF` enthält die beiden gepackten Bildvorlagen und zwei ausgeblendete, nicht exportierte Größenprüfvolumen.

Export: `Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_02/cutlass_01.glb` relativ zum Repository. Ein Mesh, acht Materialien, fünf eingebettete Texturbilder. 16.224 Dreiecke. Ausgewertete Abmessungen: 12,4302 × 16,0000 × 5,7466 m. Gesamte XY-Bounding-Box zentriert, Boden Z=0, Blender -Y vorwärts; glTF/Godot +Z vorwärts.

Die ausgewerteten Maße stehen vollständig in `review/final/evaluated_proportions.json`:

| Maß | Refinement 01 | Refinement 02 | Änderung |
|---|---:|---:|---:|
| Horizontale Frontflügel: Spannweite | 9,33 m | 11,62 m | +24,6 % |
| Frontflügel: gesamte Ausdehnung längs | 3,19 m | 5,19 m | +62,9 % |
| Äußere Endplatten: Gesamtspannweite | 9,64 m | 11,93 m | +23,8 % |
| Kanzel: maximale Breite | 1,81 m | 2,29 m | +26,4 % |
| Turmkörper: Breite | 1,31 m | 2,08 m | +58,7 % |
| Turmkörper: Länge | 1,26 m | 2,45 m | +94,2 % |
| Turmkörper: Höhe | 0,81 m | 1,54 m | +90,9 % |
| Turm-Drehring: Durchmesser | 1,37 m | 2,06 m | +50,0 % |

Das Verhältnis Frontflügelspanne zu hinterer Haubenspanne steigt von 0,766 auf 0,955. Die Flügel verjüngen sich von rund 0,73 m Konstruktionsdicke innen auf rund 0,31 m außen und besitzen zwei große, an einer gepfeilten Kante zusammentreffende Oberflächen. Die Kanzel hat einen breiteren, steileren Bug und zusammenhängende Seitenfenster einschließlich der oberen schrägen Wangenflächen.

Der Turm enthält als verdeckte Größenreferenz ein 1,46 × 1,46 × 1,35 m großes Freiraumvolumen sowie eine 0,65 × 1,18 × 1,29 m große Sitzpersonen-Hülle. Alle acht Eckpunkte beider Volumen liegen innerhalb der ausgewerteten äußeren Turmform; der kleinste Abstand der Personen-Hülle zur Oberfläche beträgt 0,062 m. Dies ist eine geometrische Plausibilitätsprüfung. Innenraum, Sitz, Zugang, Rig und Bewegungskollisionen sind nicht modelliert oder ergonomisch zertifiziert.

Die finale Prüfung `review/final/independent_qa.json` besteht mit **0 Fehlern und 0 Warnungen**. Sie führt die Blender-Asset-QA aus und prüft einen frischen GLB-Reimport, Dreiecksecken, endliche Positionen, Normalen, UVs, Materialwerte, Texturkanäle, Achsen, Maße und Bauteilverbindungen. Positionsabweichung 0 m; maximale direkte GLB-Normalenabweichung 0,00008317, nach frischem Blender-Reimport 0,00110512 bei unveränderter Toleranz 0,002.

Front-, Heck-, Seiten-, Drauf-, Spielmaßstab-, Zufallsfarben- und Wireframe-Ansichten liegen in `review/final/`. Alle wurden geöffnet und geprüft. Die unabhängigen Vergleiche mit identischen Kameras liegen im gemeinsamen Ordner `refinement_02/review/cutlass/`. Die vereinfachten Triebwerksmechaniken, großen ruhigen Oberflächen und die gemalte Vorlage bleiben stilistische Abweichungen. Kein Godot-Import, keine Laufzeitprüfung und keine Nutzerabnahme.

Die Modellierung und deterministischen Farbtexturen sind aus dem bisherigen eigenen Generator weiterentwickelt. Es wurde kein externes 3D-Modell importiert. Die vom Nutzer bereitgestellten Vorlagen 08/09 dienen als Bildreferenzen; daraus wird keine neue Lizenz für die zugrunde liegende Schiffs-IP abgeleitet. Referenz- und Dateihashes werden im gemeinsamen Manifest dieser Runde gebunden.

Reproduktion mit Blender 5.2.3 und Python mit Pillow/NumPy, aus diesem Repository:

```powershell
$repo = 'C:/Users/bjoer/.codex/worktrees/grafikreferenzen-20261101/SternenBuergerchen'
$shipArt = "$repo/art/frontier_illustrated_20261101/ships/pass05_astra_ultra/refinement_02/cutlass"
$shipQa = "$repo/art/frontier_illustrated_20261101/ships/pass05_astra_ultra/qa_tools"
$shipGlb = "$repo/Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_02/cutlass_01.glb"
$blender = 'C:/Users/bjoer/AppData/Local/Programs/Blender Foundation/Blender 5.2/blender.exe'
python "$shipArt/build/make_paint.py"
& $blender -b --factory-startup --python-exit-code 1 -P "$shipArt/build/build_cutlass.py" -- --iteration 2
New-Item -ItemType Directory -Force -Path "$shipArt/source/final","$shipArt/review/final" | Out-Null
Copy-Item -LiteralPath "$shipArt/source/iteration02/cutlass_01.blend" -Destination "$shipArt/source/final/cutlass_01.blend"
Copy-Item -LiteralPath "$shipArt/build/build_cutlass.py" -Destination "$shipArt/source/final/generator_snapshot.py"
Copy-Item -LiteralPath "$shipArt/source/iteration02/proportion_metrics.json" -Destination "$shipArt/source/final/proportion_metrics.json"
& $blender -b --factory-startup --python-exit-code 1 -P "$shipArt/build/measure_proportions.py" -- --iteration 2
Copy-Item -LiteralPath "$shipArt/review/iteration02/evaluated_proportions.json" -Destination "$shipArt/review/final/evaluated_proportions.json"
& $blender -b --factory-startup --python-exit-code 1 -P "$shipArt/build/review_cutlass.py" -- --final
& $blender -b --factory-startup --python-exit-code 1 -P "$shipQa/verify_ship.py" -- --blend "$shipArt/source/final/cutlass_01.blend" --glb $shipGlb --out "$shipArt/review/final/independent_qa.json" --collection LOW --length 16
```

Der aktive Generator ist `build/build_cutlass.py`; `source/final/generator_snapshot.py` ist eine Archivkopie und wegen relativer Pfade nicht der Einstiegspunkt. Der Builder exportiert zunächst getrennte Quellteile und konsolidiert sie mit `qa_tools/consolidate_glb.py` ohne erneutes Kodieren der Normalen.

Finale SHA-256:

- Blend: `be3c808f384872f0e9a112535a02c3a6cb3e135aa4f06c1fdbe78e96626fc5a6`
- GLB: `d0a1d31e7a0077021a308013fe0c842e5d742058299f393f072b43f82d01bdc0`
