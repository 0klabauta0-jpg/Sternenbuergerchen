# Pass06 Geologie und echtes Fussrelief

Eingefrorener Formenstand auf dem weiterhin unintegrierten Grafikbranch,
Basis `04e934f60`. [manifest.json](manifest.json) verknuepft Quellen, Referenzen,
Native-Paare, lokale Pruefungen und Roots finale 21/21-Serie.

## Problem und Aenderung

Die erneut geoeffneten Ziele Rostgrenze01 und taktische Karte03 zeigen
mittlere/kleine Erosionsformen und abgestufte Fels-/Bodenkontakte. P05
landscape/geology_detail besassen grosse ruhige Waende auf ebenem Boden.

P06 fuegt echte V-foermige Vertiefungen mit Schultern in ausgewaehlte
Wandabschnitte ein. Maximal fuenf Rinnen pro Koerper, bei schmalen Spitzen
hoechstens zwei; Start-/Endhoehen, Tiefe und seitlicher Verlauf variieren.
Die erste zu gleichmaessig durchgeriffelte Probe wurde vor Freeze reduziert.
24 erhaltene Felskoerper enthalten nachweislich mehr Erosionsgeometrie.

Je Anker gibt es nun einen zusammenhaengenden, gelappten Sediment-/Talusfaecher
mit fuenf geometrischen Hoehenbaendern. Er bindet die Felssockel ein und endet
am Aussenrand 1,5 cm unter dem flachen Boden. Der kleinste Faecher besitzt
20,26 cm echte Hoehenspanne und jeder bedeckt mindestens 72,68 Prozent seiner
gesperrten Huelle. Dies sind keine blossen Pigment-/Normalentexturen.

## Geometrie und Vertragsgrenzen

- 68 Meshes: 54 erhaltene Felskoerper plus 14 Relief-Faecher.
- 42.363 unindizierte Vertices / 14.121 Dreiecke, Budget maximal60k.
- Alle14 Anker und konservativen Navhuellen identisch zuP05; null neue
  Vertices ausserhalb, null degenerierte Dreiecke, endliche Normalen.
- Aufwaertige Felskappen und auswaertige Waende bleiben streng geprueft.
  Getaggtes geneigtes Relief besitzt eigene Normalen-/Winding-/Randpruefungen;
  seine kleinste NormaleY ist0,47185 und besteht die unveraenderte Grenze0,45.
- Keine Collision, Kartenhoehe, Picking-, LOS- oder Navigationsaenderung.
  Die spielbaren Flaechen bleiben eben; Aufbau einmalig, kein Frame-Rebuild.
- Keine Shader-/Profil-, Schiffs-/Astra-, Runtime-Preview- oder Reportaenderung
  durch diesen Teilauftrag. P02/P03-Verifier wurden eng typenbasiert angepasst.

Die zulaessige Reliefhoehe wird bei schmalen Huellen staerker begrenzt.
Fruehere Fehlversuche sind in `qa/check_runs/` erhalten; erst der finale Lauf
`20261101T191801Z-pid126152` besteht14/14 Legacy-Vertrags- und10/10 neue Checks.
Root bestaetigt danach21/21 in seinem finalen Integrationslauf.

## Geoeffnete Bilder und Restabstand

Vier native isolierte Paare bei1600x900, Godot4.6.2 Forward+/Vulkan:
landscape, near_detail, wall_detail und rear_detail. Gleiche Kamera,
Beleuchtung und jeweilige geladene P06-Shaderroute jePaar; Vorher ist die
gesicherte P05-Geometrie, keine historische P05-Materialgleichheitsbehauptung.
Alle acht PNGs wurden geoeffnet. Ein unabhaengiger Agent hat die finalen
near_detail_after/landscape_after nach dem Hoehenlimit-Refresh geoeffnet:
keine groben Loecher, schwebenden Hauptkoerper oder abgeloesten Sockel sichtbar.

Die grossen Plateauflaechen bleiben breit, einige Waende noch ruhig. Rinnen
und Relief sind weiterhin vereinfachte Low-poly-Formen; die Illustrationen
sind staerker erodiert und reicher komponiert. Keine gestalterische
Nutzerabnahme oder allgemeine Performance-/Release-Abnahme.

## Reproduktion und Quellen

Quelle: `scripts/terrain/frontier_art_geology.gd`; identische editierbare Kopie
in `source/frontier_art_geology_pass06.gd`, P05-Quelle daneben erhalten.

```text
e0c68350e32e041956d41a6b383661db76d01be5aa2ee18596bd22380000ae58
```

Vom Projektroot: strenger Runner mit `qa/checks.json` und `--skip-import`;
neuer Verifier `qa/frontier_pass06_geology_verifier.gd`, Erfolgsmarker
`FRONTIER_PASS06_GEOLOGY`. Native Probe ohne Editorimport:

```powershell
godot_console.exe --path . --rendering-method forward_plus --rendering-driver vulkan --script art/frontier_illustrated_20261101/environment/pass06/geology/qa/probe_geology.gd
```

Kein fremder Godot-Prozess wurde angefasst. Keine GPU-Exklusivitaetsbehauptung.
Keine Commits/Pushes durch diesen Teilauftrag; Root sammelt das Paket.
