# Tripo-Tanker: gepruefter Modellkandidat

Die Nutzerquelle `C:/dev/SternenBuergerchen/Assets/Trip/tanker.blend` ist erhalten.
Sie war nur 1.001 m lang. Alle 82 Einzelteile, UVs und 82 eingebetteten Bilder waren
vorhanden. Die Skalierung auf 102 m erfolgt gleichfoermig; die breitere Tripo-Form
wird nicht auf die schmaleren frueheren Starfarer-Proportionen verzerrt.

## Dateien fuer die weitere Arbeit
- `editable/tanker_102m_clean_segmented.blend`: 82 separat editierbare Bauteile,
  Originalmaterialien, bereinigte Geometrie, sinnvoll eingerichtete Anfangsansicht.
- `editable/tanker_102m_atlas_segmented.blend`: dieselben 82 Teile mit gemeinsamem Atlas.
- `exports/tanker_102m.glb`: ein statisches Mesh und ein Material, in Metern.
- `exports/tanker_game.glb`: derselbe Export mit eingebautem bisherigen Spielmassstab.
  Im aktuellen Spiel bei Faktor1.0 verwenden; nicht erneut mit dem Meterfaktor skalieren.
- `exports/tanker_102m_clean_segmented.glb`: 82-Material-Vergleichsbasis.
- `source/tanker_tripo_original.blend`: bytegleiche unveraenderte Quellsicherung.
Die unbereinigte skalierte Fassung bleibt separat als `tanker_102m_segmented.*` erhalten.

## Ergebnis und Massstab
- Laenge102.000 m, Breite68.655 m, Hoehe28.882 m; 15097 Dreiecke, 7719 Vertices.
- Quelle15102Tris: genau zwei lose Kleinstinseln mit4+1Tris entfernt.
- Vier falsch gerichtete Flaechen lokal korrigiert. Sechs Kanten an nicht
  orientierbaren Naehten topologisch getrennt; verbleibende Eckpunkte und UVs erhalten.
- Blender: Z oben, Nase-Y. GLB/Godot: Y oben, Nase+Z. Horizontal zentriert, Boden0.
- Spielmassstab3.52/37.5=0.0938666667 Einheiten/m; Godot(B,H,L)=
  6.444448,2.711016,9.574400. Cutlass/Entermesser aus Main: Laenge3.52.
  Der Tanker ist dadurch2.72mal so lang.
- 82 Texturen in einen2048x4096-PNG-Atlas gepackt, ohne Originaltexel zu verkleinern:
  frischer PNG-Readback0Byteabweichung. Laufzeit82Materialien/Oberflaechen auf1 reduziert.
  Das verringert Materialwechsel; ein allgemeiner FPS-Gewinn ist damit nicht vermessen.

## Pruefung und akzeptierte Warnungen
Blender-Game-QA0Fehler. Drei bzw. sechs deckungsgleiche Nahtvertices in part1/74
bleiben absichtlich getrennt, um die nicht orientierbare Verbindung zu beseitigen.
Drei bereits vorhandene verdeckte Back-to-Back-Flaechenpaare bleiben erhalten:
part0/1,54/69,64/69. Sie kosten wenige Dreiecke und verursachen keine gleichgerichteten
Z-Fighting-Flaechen; eine groessere Form-/UV-Operation ist dafuer nicht sinnvoll.
Exakter Readback belegt gleiche verbleibende Positionen, UVs, Materialslots,
Smooth-Flags und gepackte Bilddaten. Der statische Mesh-Join bewirkt hoechstens
0.0000054m Float-Rundung; alle15097Dreiecke eindeutig zugeordnet.

Native Blender-Mehransichten in `qa/review_random.png` und `qa/review_wire.png`.
Der Wireframe-Helfer verwendet duenne Linien ohne Even-Offset, damit sehr schmale
Dreiecke keine kuenstlichen QA-Dornen erzeugen. Die Modellgeometrie wird nicht geaendert.

Frischer Godot4.6.2-Import: alle3GLBs ohne fehlende Texturen/UVs/Materialslots,
Bounds/Pivot/Tris geprueft. Native Vorher/Nachher-Bilder und Vergleich mit Cutlass
unter `../../qa/tanker_tripo_20261121/`. Identische Kameras und Beleuchtung;
95Prozent der sichtbaren Schiffspixel maximal1/255 Farbkanalabweichung, keine
sichtbaren flaechigen Atlasfehler. Das ist ein separates Pruefprojekt, keine Spielintegration.
Die weiche Tripo-Grundform und gemalten Oberflaechen bleiben sichtbar; die Nutzerabnahme
der Gestaltung steht aus. Tanks, Cockpit und die beiden Motoren bleiben klar lesbar.

## Offene Gameplay-Arbeit
Noch kein rufbarer Nottankdienst, Preis/Kauf, Sprittransfer, Betankungsanimation oder
Collision-Setup. Diese Systeme sind durch das Modell nicht automatisch vorhanden.
Main, alter Schiffworktree, Originaldatei, aktive Blender-Sitzung und Bridge unveraendert.

## Nachweise und Wiederholung
`metrics.json`: erster Skalierungsdurchlauf, einschliesslich historischer Quellfehler.
`qa/runtime_stats.json`, `qa/geometry_clean.json`, `qa/geometry_atlas_segmented.json`,
`qa/geometry_diagnosis_readback.json`, `qa/atlas.json`, `qa/join_geometry.json`: Endstand.
`deliverable_manifest.json`: finale Hashes und Quellenzuordnung.
Tools laufen nur in einer separaten Blender5.2-Backgroundinstanz mit `--disable-autoexec`.
Reihenfolge: prepare_tanker.py --stage prepare, clean_tanker.py,
prepare_tanker.py --stage finish, review_tanker.py, frame_editable.py.
Die Tools verwenden die lokalen Blender-Asset-QA-Helfer aus den Codex-Skills.
