# Pass05 Geologie

Formenstand nach 2D/Ist-Vergleich und zwei nativen Formenrunden eingefroren.
Details, Reproduktion und verbleibender Zielabstand: [ANALYSIS.md](ANALYSIS.md).
Dateien, SHA-256, Vertragspruefung und vier geoeffnete Bildpaare:
[manifest.json](manifest.json).

- 14 unveraenderte Anker und konservative Navigationshuellen.
- 54 Meshes, 23.112 Vertices / 7.704 Dreiecke; bestehendes 30k-Limit eingehalten.
- 12/12 vorhandene Geologie-Vertragspruefungen bestanden, unveraenderter Test.
- Endliche Normalen/Geometrie, Kappen aufwaerts, Waende auswaerts,
  null degenerierte Dreiecke und null Vertices ausserhalb der Huellen.
- Native Godot4.6.2 Forward+/Vulkan-Probe, vier feste Vorher/Nachher-Paare;
  acht finale Bilder tatsaechlich geoeffnet.

Die isolierten Paare zeigen alte/neue Geometrie jeweils mit derselben beim
Probe-Start geladenen Shader-/Profilroute und gleichem Licht. Sie behaupten
keine Materialgleichheit mit dem historischen Pass04-Gesamtbild. Root aendert
die Pass05-Bodenmaterialroute separat; die erfassten Shader-/Profilhashes
stehen in `qa/native_probe.json`.

Die Referenzen enthalten weiterhin feinere Erosion, mehr mittlere Ablagen
und dichtere Fels-/Bodenkontakte. Die flachen grossen Plateaus und ruhigeren
Rueckwaende bleiben sichtbarer Restabstand. Keine Nutzerabnahme oder
allgemeine Performance-/Release-Abnahme. Keine Schiffs-/Astraaenderung.

Runtimequelle: `scripts/terrain/frontier_art_geology.gd`, identische editierbare
Kopie unter `source/frontier_art_geology_pass05.gd`. SHA-256:

```text
f3441b0c5b4a4e4ca93ac32f2cf0f57000e309ecd5729170be21e260d8e0ec70
```

`source/frontier_art_geology_pass04.gd` bewahrt den Ausgangsstand.
`source/frontier_art_geology_pass05_r01.gd` und `qa/r01/` bewahren die erste,
noch zu prismatische Probe. `qa/native_probe_r01.log` dokumentiert einen
behobenen Probe-Parsefehler und ist keine bestandene Evidence.

Nach neuen bewusst ausgefuehrten QA-/Capturelaeufen aktualisiert
`python qa/refresh_manifest.py --run <check-run-directory>` die Metadaten
mit Hashpruefung. Ohne Argument prueft es den dokumentierten finalen Lauf.
Der Helper schreibt keine Runtime-/Test-/Shader-/Modelldatei.
