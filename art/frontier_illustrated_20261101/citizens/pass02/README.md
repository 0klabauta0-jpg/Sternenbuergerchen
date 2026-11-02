# Citizen-Ausruestungskandidaten, Grafikpass 02

Vier eigenstaendige Kandidaten auf dem unveraenderten **Kenney Animated
Characters Bundle 4.0 / characterMedium** (CC0). Koerper, Kopf, Proportionen,
Originaltexturen, UVs, Gewichte und die gebackenen Originalclips `idle`/`walk`
sind dieselben wie im Pass01-stock-Satz. Dessen vier BLENDs und GLBs bleiben
byte-identisch. Der neue Satz ist keine gestalterische Nutzerfreigabe.

Die neue Ausruestung besteht aus wenigen breiten, sanft gefasten Formen:
Brustschutz, Schulterkappen, Knieschutz und Rucksack. Pilot: offenes Headset;
Mechaniker: Werkzeugkassette am Rucksack; Medic: orangefarbene Packmarkierung.
Die Referenzen `02_menschen_stilstudie.png` und die drei aktuellen Rostwelt-
Umgebungsbilder leiten Formgruppen/Palette. Die aktuelle Entscheidung fuer die
Kenney-Grundfigur bestimmt weiterhin Anatomie und freundliche Kopfform.

| Rolle | Originalkoerper | neue Ausruestung | gesamt Dreiecke |
| --- | ---: | ---: | ---: |
| operator | 1.604 | 1.200 | 2.804 |
| pilot | 1.604 | 1.740 | 3.344 |
| mechanic | 1.604 | 1.308 | 2.912 |
| medic | 1.604 | 1.416 | 3.020 |

Editierbare, mit Original-PNG gepackte Quellen liegen unter `source/`.
`generator/build_equipment.py` erzeugt sie reproduzierbar aus den vorhandenen
`../{role}_stock.blend` und exportiert nach
`Assets/curated/frontier_illustrated_20261101/citizens_pass02/{role}.glb`.
Zum Ausfuehren Blender 5.2.3 mit `-b --factory-startup --python-exit-code 1
--python <script>` starten; nach `--` sind optional einzelne Rollennamen moeglich.
Anschliessend `review_equipment.py`, `verify_roundtrip.py` und mit Python
`finalize_manifest.py` ausfuehren. Kein Script startet einen Godot-Import.

Jeder GLB hat zwei skinnte Meshes (`characterMedium`, `Gear_Modular`), einen
gemeinsamen Skin, vier Materialien und eine eingebettete Originaltextur.
Die Quelle behaelt einzeln benannte Ausruestungsteile. Jeder neue Vertex hat
genau ein Gewicht von 1 auf einem vorhandenen Deform-Bone; keine neuen Bones,
kein zweites Rig. Exportkoordinaten: Meter, Resthoehe 1,78 m, Fussboden 0,
Godot +Z vorne. Der bestehende Preview-Faktor bleibt 0,35. Keine Collision,
Navigation, Lichter oder Gameplay-Daten hinzugefuegt.

`manifest.json` enthaelt Quellen-/Export-/Referenzhashes, Originalvergleich,
Objekt/Bone-Zuordnung, Roh-QA-Pfade und die geoeffneten Bilder. Source-QA und
fuenf abgetastete Idle/Walk-Posen pro Rolle bestehen ohne Fehler oder Warnung;
die untexturierte Ausruestung hat bewusst keine UVs. Die Koerper-UVs wurden
separat vollstaendig geprueft.

Der frische Blender-GLB-Roundtrip (`qa/roundtrip.json`) besteht: beide Clips
jeweils 33 Frames, maximale beidseitige Vertex-Positionsabweichung etwa
0,00000149 m. Die Rohberichte bleiben unveraendert erhalten. Warnungen fuer
duplizierte Vertices betreffen erhaltene UV-/Hard-Normal-Attributtrennungen
des GLB-Formats; die zugehoerigen Seam-Grenzen sind dort ebenfalls sichtbar.
Die GLB-Attributanalyse belegt die unterschiedlichen Attribute an denselben
Positionen. Diese Warnungen sind akzeptiert, kein verschwiegenes Mesh-Reparat.
Die editierbaren Quellen sind geschlossen und warnungsfrei.

Geoeffnet: vier Sechs-Posen-Blaetter, vier passende stock-Vorherbilder, alle
Random-/Wireframe-Ansichten und vier frische Roundtrip-Laufbilder. Es wurden
keine abgetrennten Ausruestungsteile, Skin-Spitzen oder sichtbaren Gelenk-
Kollapsen gefunden. Bei der diagnostischen Extrempose ueberlappen starre
Schulterteile bewusst am Schulterbereich. Die Extrempose ist kein Exportclip.
Workbench-Texturbilder belegen Formen und Anschluesse; Licht/Farbe im nativen
Godot-Ausschnitt und Lesbarkeit im Spielabstand prueft der uebergeordnete Task.
Keine Bevoelkerungs-/Loadout-/Combat-Migration und keine Release-Abnahme.
