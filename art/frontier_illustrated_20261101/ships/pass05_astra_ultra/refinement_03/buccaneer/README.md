# Buccaneer – Refinement 03

Die Kanzel wurde auf Wunsch in eine geschlossene untere Rumpfwanne und eine obere Verglasung gegliedert. Statt des vorherigen achtteiligen Querschnitts erzeugt der Builder einen zwölfteiligen Querschnitt mit schmalem Kiel, seitlicher unterer Fase, voller Wannenwand und abgesetztem oberen Rand. Die Fenster laufen erst oberhalb der halben lokalen Kanzelhöhe an. Dies ist eine tatsächliche Formänderung, kein Übermalen der bisherigen Glasfläche.

Die ausgewertete Unterkante der Seitenglasflächen steigt von 18,315 % auf 50,313 % der jeweiligen lokalen Rumpfhöhe. Die Außengröße der Kanzel und die Gesamtmaße bleiben erhalten: 11,7578 × 11 × 4,1198 m. Alle übrigen 87 benannten Teile stimmen in ausgewerteten Vertex-/Dreieckshashes mit Refinement 02 überein, einschließlich der kleineren Triebwerke, Flügel und Kanone. Nachweis: [evaluated_proportions.json](evaluated_proportions.json).

Die Originalansichten auf der offiziellen [RSI-Entwurfsseite](https://robertsspaceindustries.com/en/comm-link/transmission/15350-The-Drake-Buccaneer-Sets-Sail) wurden als zusätzliche Inspiration für Kiel, Schweller und gerahmte Kanzel geprüft. Die streng auf die obere Hälfte begrenzte Verglasung folgt der Nutzerkorrektur; manche Originalscheiben reichen ebenfalls tiefer. [Recherchebelege](../review/ORIGINAL_REFERENCE_NOTES.md). Es wurde keine fremde Modellgeometrie importiert.

Finale editierbare Quelle: [buccaneer_master.blend](buccaneer_master.blend), aus `iterations/i01/`; 88 editierbare Mesh-Teile in `LOW`, 19.672 Dreiecke, gepackte Projekttexturen und Referenzen. Export relativ zur Repository-Wurzel: `Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/buccaneer_01.glb`; ein Mesh, acht Materialien, neun eingebettete Texturbilder. Blender −Y vorwärts/Z oben, GLB/Godot +Z vorwärts/Y oben; Gesamt-XY-BBox zentriert, Boden Z=0.

[audit.json](audit.json): PASS, 0 Fehler und 0 Warnungen. Positionsabweichung 0 m, Normalenabweichung direkt 0,00008211 und nach frischem Reimport 0,00144974 bei unveränderter Grenze 0,002. UVs, Materialien und vollständige Texturpixel bestehen. Exportteile wurden ohne Neuberechnung der Normalen konsolidiert.

Alle zwölf finalen Prüf-Render und drei Vergleichstafeln wurden unabhängig geöffnet, einschließlich des vollständigen [Seitenvergleichs](../review/buccaneer/sheets/Vorher_und_Neu_Seite.png). [Sichtbericht](../review/buccaneer/VISUAL_REVIEW.md). Die Glasfarbe und Mechanik sind weiterhin vereinfacht. Kein nativer Godot-Test, keine Nutzerabnahme oder fertiger Innenraum.

Reproduktion aus der Worktree-Wurzel mit Blender 5.2.3 LTS:

```powershell
$shipArt = 'art/frontier_illustrated_20261101/ships/pass05_astra_ultra/refinement_03/buccaneer'
$shipQa = 'art/frontier_illustrated_20261101/ships/pass05_astra_ultra/qa_tools'
$shipGlb = 'Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/buccaneer_01.glb'
$blender = 'C:/Users/bjoer/AppData/Local/Programs/Blender Foundation/Blender 5.2/blender.exe'
& $blender -b --factory-startup --python-exit-code 1 -t 6 -P "$shipArt/build_buccaneer.py" -- --iteration i01 --views '' --qa
& $blender -b --factory-startup --python-exit-code 1 -t 6 -P "$shipArt/finalize_buccaneer.py"
& $blender -b --factory-startup --python-exit-code 1 -t 6 -P "$shipQa/verify_ship.py" -- --blend "$shipArt/buccaneer_master.blend" --glb $shipGlb --out "$shipArt/audit.json" --length 11
& $blender -b --factory-startup --python-exit-code 1 -t 6 -P "$shipArt/measure_proportions.py"
```

Die tatsächlichen Renderbefehle stehen in `../review/buccaneer/package_binding.json`. Ein Neubuild benötigt neue Audit-/Bildbindungen; die eingefrorenen Quellen dieser Lieferung bleiben erhalten.

SHA-256: Blend `681c810e29a5d92203a5641dec3eff818315b0af4e0dda1bf7f9f6a3a705967d`; GLB `922bd0fa668a90121dd5101541f4b5792d791f801a6dd1e7caa9d98a59b3a6c3`.
