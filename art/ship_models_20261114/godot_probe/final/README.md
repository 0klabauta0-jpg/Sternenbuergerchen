# Finale unabhaengige Godot-Pruefung, 14.11.2026

Alle fuenf aktuellen GLBs bestehen die frische direkte GLTFDocument-Pruefung
in einem isolierten Godot-4.6.2-Projekt: **109/109 Headless-Assertions**,
**132/132 native Assertions**, jeweils Exit 0, Erfolgsmarker und keine
Script-/Importfehler oder Leak-Warnungen. Die aktuellen GLB- und
Authoring-Metrics-Hashes wurden anschliessend nochmals mit beiden Reports
verglichen und stimmen ueberein. Es wurde kein Spielprojekt geladen.

| Modell | Dreiecke | Benutzte Materialien | GLB SHA-256 |
|---|---:|---:|---|
| Prospector | 19.932 | 3 | `446acf1f20f827c44d54e440d51416cf32828539f510dde14b7bcb25cb019a2d` |
| Vulture | 17.970 | 2 | `ea8833f294d7ff4790199006da5d6f868b8afd560c055a9b1de2e244f24c461a` |
| Gladius | 14.000 | 3 | `6eac54c9a6a035b9374f893a6b149c352847000963d538b4379f1e2fe4fb4ea7` |
| Hornet | 15.840 | 2 | `f2635c1302e9d7a62759bd6ba0758c0323a8f34555d1a16b8a42f9ccd552198a` |
| Caterpillar | 32.826 | 4 | `fa26699dca15c04edc3c032f6666f8cba7684a659489ccc1d96a82d430356e49` |

Geprueft wurden nichtleere Geometrie, endliche Daten, vollstaendige
Einheitsnormalen, Indexgrenzen, Dreiecks-/Materialzahlen gegen GLB-Accessors
und aktuelle Blender-Metriken, transformierte Bounds und Bodenpivot.

Die Caterpillar besitzt 14 Meshes und einen 3-Sekunden-Clip `Scene` mit zehn
bewegten Bauteilen: acht Seitenklappen mit +/-90 Grad, eine Bugklappe mit
90 Grad und ein separat modelliertes Aufzugdeck mit 0,300000 m Hub nach unten
entlang Godot-Y. Hull und Aufzughalterungen bleiben fest; am Clipende kehren
alle Bauteile in die geschlossene Ausgangspose zurueck. Das prueft die
exportierte Demonstrationsbewegung, keine Gameplay-Funktion oder Kollision.

Der Schiffsanker wird bei dieser beweglichen Baugruppe am statischen `Hull`
geprueft. Das seitliche neu modellierte Aufzugdeck erweitert den Gesamtumriss:
Gesamtbreite 2,982616 m gegen Hull-Breite 2,843451 m; Gesamtmittelpunkt X
0,068692 m, Hull-Mittelpunkt X -0,000890 m. Beide Bounds stehen explizit in
den Reports. Der erste allgemeine Gesamt-Bounds-Zentrierungscheck schlug
deshalb fehl (108/109). Nach dieser begruendeten Korrektur des Pruefvertrags
wurde mit unveraenderten Modellen vollstaendig erneut geprueft. Der Erstlauf
bleibt unter `../runs/headless_20261114T145550_69404/` erhalten.

## Native Ansichten und Sichtpruefung

`native_contact_sheet.png` zeigt elf tatsaechlich in Godot gerenderte Ansichten
der importierten Kandidaten. Alle wurden als Kontaktbogen geoeffnet;
die geoeffnete Caterpillar wurde zusaetzlich in voller Aufloesung betrachtet.
Die Modelle sind vollstaendig im Bild; die geoeffneten Seiten-/Bugklappen
und das abgesenkte ockerfarbene Aufzugdeck sind sichtbar. Es gibt in diesen
Ansichten keine fehlenden oder magentafarbenen Materialflaechen.
Gladius ist ruhig oliv, Vulture gelb und gegabelt; Prospector/Hornet besitzen
weiter deutlich facettierte, kleinteilige helle Rumpfdetails. Das bleibt
ein Modellkandidat ohne kuenstlerische Nutzerabnahme.

Renderer: Compatibility/OpenGL 3.3, NVIDIA RTX 4070 Ti SUPER. Aufloesung
960x720, maximal 30 FPS, identische Studio-Materialroute ohne Materialoverride.
Lichtenergie Key 0,25 / Fill 0,08 / Ambient 0,15; die geringere Beleuchtung
erhaelt die Abstufungen der hellen Prospector-/Hornet-Flaechen. Je Schiff
bleiben Framing und Licht fest, insbesondere zwischen Caterpillar geschlossen
und offen. Alle Laengen sind die stilisierten Authoringmasse des Pakets.

## Unveraenderte Originallaeufe

- Headless-Daten: `../runs/headless_20261114T145851_46720/report.json`
- Strenger Headless-Runner: `../verification/20261114T145851Z-pid44608/metadata/report.json`
- Native Daten/Bilder: `../runs/native_20261114T145853_15996/`
- Native Prozesslogs: `../native_logs/20261114T145852/`

Die Dateien hier sind Kopien dieser finalen Nachweise fuer ein kompaktes
Uebergabepaket. Die urspruenglichen Reports behalten ihre absoluten lokalen
Quell-/Belegpfade als Herkunftsnachweis. `evidence_manifest.json` bindet die
kopierten Dateien, aktuelle Probe und Modellbytes per SHA-256 zusammen.
Keine globale Runtime-/FPS-, Multiplayer-, Gameplay- oder Release-Abnahme.

Nach dem rein dokumentarischen Caterpillar-Metrics-Nachtrag wurden beide
finalen Laeufe erneut vollstaendig ausgefuehrt. Der GLB-Hash blieb unveraendert;
beide neuen Reports referenzieren nun den aktuellen Metrics-Hash
`c4125f2fb2a9b6a66a9415e2a8ebbbca1161da196ca51af4ef965af80af6b40a`.
Die vorherigen Nachweise bleiben in ihren Originallaufordnern erhalten.
