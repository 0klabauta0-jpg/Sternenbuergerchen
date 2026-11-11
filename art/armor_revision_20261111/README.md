# Eigene geformte Rüstung, Revision 02

Status: im isolierten Taskbranch eingebaut; technische Prüfung, keine
gestalterische Nutzerabnahme. Die flache Fassung in `armor_20261111` bleibt
als vorheriger, vom Nutzer abgelehnter Stand erhalten.

`user_heavy_reference.png` ist die vom Nutzer angehängte Achtansichten-Vorlage
für schwere Ausrüstung. Sie dient der Formfindung und ist keine Spieltextur.
Die Kenney-Helme aus dem vorhandenen Figurenpaket sind ausschließlich Größen-
und Formreferenzen. Der Nutzer hat ihre direkte Übernahme ausdrücklich
abgelehnt und dies auf Rückfrage bestätigt. `build_pack_helmets.py` bleibt
als verworfene Vergleichsstudie erhalten. Keines seiner Modelle wird geladen.

`build_outfit_parts.py` konstruiert die eigenen 17 Segmente, einschließlich
beider Helme, aus selbst definierten Querschnitten. `armor_outfit_parts.blend`
enthält die editierbare Bibliothek. Die normalisierten, zentrierten Exporte
liegen unter `Assets/curated/personnel/armor_revision_20261111/`.
Warme helle Keramik, Graphit, Titan und kleine bernsteinfarbene Akzente;
kein grüner Überwurf. Flexible Gelenklücken und unterschiedliche Umfänge
unterscheiden die Klassen. Ein Segment kann mehrmals am Rig verwendet werden.

Blender 5.1.1, Export GLB, keine Animationen; QA17/17 ohne Geometriefehler.
Einzige akzeptierte Warnung: zentrierte tragbare Teile liegen nicht selbst
auf einer Bodenebene. Der Rigger setzt sie an tatsächliche Knochen.
Die Bibliothek umfasst insgesamt5802 Dreiecke. Zusammengesetzte Outfits:
leicht1168, mittel4652, schwer5756 Dreiecke, jeweils ein Mesh mit höchstens
fünf gemeinsamen Materialflächen. Dies ist keine gemessene FPS-Aussage.

Wiederholung im Repositorywurzelverzeichnis:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.1/blender.exe' --background --factory-startup --python-exit-code 1 --python art/armor_revision_20261111/build_outfit_parts.py -- C:/Temp/armor-outfit-review
```

Der Builder benötigt die lokale Blender-Asset-QA unter `.codex/skills`.
Exporte erst nach QA und Sichtprüfung übernehmen. Die Vorlage, eigene Quellen,
Exporte und nur betrachtete Paketquellen sind in `manifest.json` getrennt und
mit SHA-256 gebunden. Ergänzende Formreferenzen:

- https://robertsspaceindustries.com/en/comm-link/spectrum-dispatch/19122-Portfolio-Clark-Defense-Systems-CDS
- https://robertsspaceindustries.com/en/comm-link/transmission/13840-Letter-From-The-Chairman-43-Million

Die alten Artikel liefern keine aktuellen Spielwerte. Inventar, Schutzwerte,
Chipfach und Freischaltungen wurden für diese Revision nicht verändert.
QA: `docs/qa/armor_revision_20261111/README.md`.
