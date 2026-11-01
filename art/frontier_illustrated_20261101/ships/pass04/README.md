# Pass04: neue Cutlass- und Buccaneer-Kandidaten

Die beiden statischen Schiffe wurden nach den vier zugewiesenen Bildvorlagen neu modelliert. Der Generator konstruiert alle exportierten Vertices selbst; weder die hochpolygonalen Drake-OBJs und deren fehlerhafte Materialstudien noch generische Kenney-Schiffe wurden importiert. Schiffsentwurf und Namen orientieren sich an Drake/Star Citizen; dieses Paket behauptet keine Herkunft als offizielles Spielmesh und keine Kenney-Lizenz fuer diese neuen Geometrien.

| Asset | Quelle B x L x H, m | Vertices | Dreiecke | Editierbare Teile | GLB |
|---|---:|---:|---:|---:|---|
| cutlass_01 | 12.361 x 16.000 x 4.940 | 2234 | 4184 | 75 | 1 Mesh, 7 Materialien |
| buccaneer_01 | 12.065 x 11.000 x 4.016 | 2004 | 3800 | 62 | 1 Mesh, 7 Materialien |

16 m beziehungsweise 11 m Gesamtlange sind bewusst stilisierte Normierungen, keine kanonischen Star-Citizen-Masse. Blender -Y ist vorne, nach glTF-Export Godot +Z. Der Pivot liegt im XY-Zentrum der gesamten Boundingbox auf Bodenhoehe Z0. Die geschlossenen, abgestuetzten Landefuesse sind eigene vereinfachte Standhilfen fuer die statische Praesentation. Bei RuntimeScale 0.22 entstehen Cutlass 2.719 x 3.520 x 1.087 m und Buccaneer 2.654 x 2.420 x 0.883 m. Keine Collision-, Navigation-, Licht-, Animations- oder Gameplayknoten sind enthalten.

Cutlass behaelt Transportkoerper, abgesenkte Kanzel, vordere Fluegel/Endplatten, getrennte Hecktriebwerke, mittige geschlossene Rampe und Doppelturm. Buccaneer behaelt den schmalen spitzen Rumpf zwischen zwei grossen Pods, dunkle vordere Einlaesse, kleinere hintere Duessen mit sechs breiten Segmenten, kurze Aussenfluegel und Rueckenkanone. Vorder- und Rueckansicht zeigen jeweils dasselbe konsistente Modell. Die Palette besteht aus breiten matten Elfenbein-, Petrol- und dunklen Feldern mit wenigen Ockerakzenten. Warme Duessenvertiefungen sind nicht emissiv.

`manifest.json` enthaelt aktuelle Quell-/Export-/Referenzhashes, Materialbelegung, Masse, Grenzen und alle Bildpfade. Editierbare Quellen liegen in `source/`, Exporte unter `Assets/curated/frontier_illustrated_20261101/ships_pass04/`. Die Vorlagen sind `08_cutlass_vorne_wimmel.png`, `09_cutlass_hinten_wimmel.png`, `13_buccaneer_vorne_wimmel_vereinfacht.png` und `11_buccaneer_hinten_wimmel.png` unter `docs/reports/assets/grafik-2026-11-01/`.

Die vollstaendige Source-QA meldet fuer beide Modelle null Fehler und null Warnungen; keine teuren Geometriepruefungen wurden ausgelassen. UV-Pruefung ist fuer die untexturierten Farbmaterialien deaktiviert. Frischer GLB-Import in eine leere Blender-Szene erhaelt alle Dreiecke, Materialzuordnungen und Positionen (maximaler beidseitiger Vertex-Abstand 0 m). Die Rohberichte des Imports behalten die durch glTF-Attributnaehte getrennten Vertices als Warnungen bei: 4152 bei Cutlass, 3520 bei Buccaneer; keine losen Vertices oder Meshfehler. Die Quellen selbst enthalten diese Duplikatwarnung nicht.

18 tatsaechlich geoeffnete Bilder dokumentieren Quelle und Roundtrip: Front, Heck, oben, Spielabstand, Teilfarben und echtes Drahtgitter sowie frische GLB-Ansichten. Workbench mit hellblauem Hintergrund ist begrenzte Modellpruefung; der native Godot-Import und dessen Captures gehoeren zur separaten Integration. Spielabstand ist bei angenommenem Scale 0.22 und orthografischer Kamerahoehe 12 m reproduzierbar. Die Modelle sind sauberer und kantiger als die gemalten Vorlagen; kleine Leitungen, Schrammen und die meisten dritten Detailebenen wurden bewusst weggelassen. Nutzerfreigabe und allgemeine Laufzeit-/Releaseabnahme werden nicht behauptet.

Reproduktion aus dem Repository-Root mit Blender 5.2.3 (Neubau ersetzt die eingefrorenen Kandidaten; vor erneutem Import mit der Integration koordinieren):

```powershell
$shipBlender = 'C:/Users/bjoer/AppData/Local/Programs/Blender Foundation/Blender 5.2/blender.exe'
& $shipBlender --background --factory-startup --python art/frontier_illustrated_20261101/ships/pass04/generator/build_ships.py
& $shipBlender --background --factory-startup --python art/frontier_illustrated_20261101/ships/pass04/generator/review_ships.py
& $shipBlender --background --factory-startup --python art/frontier_illustrated_20261101/ships/pass04/generator/verify_roundtrip.py
python art/frontier_illustrated_20261101/ships/pass04/generator/finalize_manifest.py
```

Aktuelle Belege: `qa/build_r02.log` (Cutlass), `qa/build_r03.log` (Buccaneer), `qa/roundtrip_r01.log`, `qa/roundtrip.json` und die erhaltenen `*_raw.json`. Generatoren benoetigen den lokalen Blender-Asset-QA-Skill, dessen Importpfad im Skript explizit hinterlegt ist.
