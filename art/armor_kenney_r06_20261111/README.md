# R06 — Kenney-Körper und referenznahe Rüstungsschalen

Integrationskandidat vom 11.11.2026, gebaut mit Blender 5.1.1 und nativ in
Godot 4.6.2 geprüft. Keine ästhetische Nutzerabnahme, kein Release-/FPS-PASS.
Aufbau auf R05 / Taskbranch `task/native-glut-maps-20261110`; Originalmodell
und R05 bleiben unverändert. Produktion, Inventar und Spielwerte sind nicht
Teil dieses Artpakets. Die Root-Integration und deren tatsächlicher Equip-Test
folgen getrennt.

## Quellen und verbindliche Formziele

- `../armor_orc_morozov_20261111/light_turnaround_ai_r04.png`: kurze breite
  Brustfünfecke, wenig Abdeckung, kleine vollständige Kniekappen.
- `../armor_orc_morozov_20261111/medium_turnaround_ai_r04.png`: breite
  polygonale Brusthälften, horizontaler Hauptknick, gegliederter Rücken und
  Taille, seitlich umgreifende Arme/Beine.
- `../armor_orc_morozov_20261111/heavy_turnaround_ai_r04.png`: zusammenhängende
  Ausrüstung, geschwungene Brust-Taille-Silhouette, Kragen und Schichtung.
- Körperursprung: `Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb`.
  SHA256 `00c378d03bd508d67c6e04d5e257827eaca053d48b072072255ad217e63f325c`.
- `origin_r05.blend` und `origin_r05_builder.py` sind erhaltene Ausgangskopien.

Die 2D-Tafeln sind kreative Mehransichten, keine maßhaltigen Orthoprojektionen.
Neuere ausdrückliche Nutzerkorrekturen haben Vorrang: Light/Medium besitzen
geschlossene klare Visiere, feste Wangen/Kinnschalen und Halsabschluss. Der
Body darf breitere Schultern/Brust und eine klarere Taille erhalten. Diese
Korrekturen wurden übernommen; Kopf, Hände, Füße, Rest-Rig und Animationen
bleiben erhalten. Es wurden keine neuen KI-Bilder als Modellnachweis benutzt.

## Tatsächliche Formänderungen

R05 hatte lange schmale Brustsäulen, kleine isolierte Rückenplatten und
Frontschilder an Armen/Beinen. R06 baut diese Hauptschalen neu. Light/Medium
haben zwei ruhige, geometrisch koplanare Frontfelder je Brusthälfte sowie
abgeschrägte seitliche Rückläufe. Die maximale Querausdehnung der Brustschalen
einschließlich Seitenrücklauf wächst gegenüber den R05-Quellparametern um
ca. 34 % bei Light und 27 % bei Medium; das ist keine pauschale Body-Skalierung.
Die mittlere Rückenhauptplatte wächst von 0,571 auf 1,020 normierte Breite.
Abdomenlamellen verjüngen sich zur Taille. Die Rückenabschlüsse wurden anhand
echter Körperquerschnitte geneigt und körpernäher geführt.

Medium/Heavy besitzen geschlossene facettierte Manschetten mit Innenwand und
Ringrändern an Unterarmen, Oberschenkeln und Schienbeinen. Heavy erhält eine
umlaufende, gegliederte Weste mit Taille statt größerem Frontblock. Dunkelgraue
Schalen heben sich unter normaler Spielbeleuchtung vom schwarzen Unteranzug ab.
Die Kniekappen haben eine breite flache Front, schräge obere/untere Facetten
und durchgehende Seitenrückläufe. Ihr Fit benutzt Dreieckquerschnitte direkt
am Kniegelenk statt die AABB des gesamten Schienbeins. Komplette starre
Bauchplatten folgen Chest/Spine/Hips nach Komponentenzentrum.

Der echte Body wurde in `body_r06_editable.blend` verändert: 285 von 1029
Vertices, 1604 Dreiecke unverändert. Das Profil verbreitert gezielt den oberen
Thorax und verjüngt die Taille mit seitlich auslaufender Maske. Maximale
Vertexverschiebung: 0,0448386 ursprüngliche Rig-Einheiten. Die Wirkung bleibt
beim Ablegen der Rüstung sichtbar. Der Helm wurde nicht verkleinert.

## Editierbare Quellen und Runtime-Übergabe

- `armor_r06_editable.blend`: 30 fertig triangulierte Wearable-Quellobjekte,
  UVs, Materialien und separate verborgene ursprüngliche Körperreferenz.
- `build_armor_r06.py` + `primary_shells.py`: reproduzierbarer parametrischer
  Blender-Aufbau. Bewusste Hauptflächen/Schalen sind in `primary_shells.py`.
- `body_r06_editable.blend` + `build_body_r06.py`: echte abgeleitete Figur mit
  unverändertem ursprünglichen Rig/Animationsbestand.
- `body_shape_profile.json`, `body_vertices.json`, `body_manifest.json`:
  Profil, unabhängige Blender-Vertexkorrespondenz und Herkunft.
- `runtime_candidate.gd`: eingefrorener privater Godot-Projektor.
  `update_r06_fit.py`, `body_projection.gdinc`, `knee_section.gdinc` erzeugen ihn
  aus dem eingefrorenen R05-Projektor. `anatomical_fit.gdinc` ist ein generierter
  Diagnoseauszug, keine zusätzliche manuell zu pflegende Wahrheit.
- Exporte: `output/native_glut_maps/armor_r06_parts/` enthält **30 Wearable-GLBs**,
  dazu **body_r06_derived.glb** und **body_shape_profile.json**.

Für die produktive Integration die Wearables und das Profil in einen eigenen
curated-R06-Pfad kopieren. `PATH` im Projektor ersetzen; Wearable-Lader auf
importierte `PackedScene` umstellen. Das Profil wird über `PATH` gelesen und
**muss außerhalb des durch .gdignore verborgenen Artordners liegen**.
`body_r06_derived.glb` ist der tatsächliche Blender-Export zum Nachvollziehen;
die Runtime ersetzt damit keine vorhandene komplette Figurenhierarchie.
Sie wendet dasselbe Profil einmalig auf die unveränderten bestehenden
Basis-/Einsatzmeshes an und cached eine neue immutable Meshvariante.

Die Basis und der Einsatz haben unterschiedliche Bind-Koordinatenursprünge.
Der Projektor richtet den kanonischen Profilursprung anhand der vollständigen
ursprünglichen Körperhülle aus; ohne diesen Schritt wäre der Einsatzbody
asymmetrisch. Unabhängiger Vergleich mit den tatsächlichen Blender-Vertices:
maximal 1,908e-6 Schulterbreiten Abweichung Basis / 2,703e-6 Einsatz.
Originalmesh bleibt unter `r06_source_body_mesh`, neue Variante unter
`r06_body_variant_mesh`; die Head-Cover-/Unequip-Restoration verwendet die neue
Variante. Keine kumulative Verformung, kein per-frame Rebuild. Ungültige Profile
und fehlende erforderliche Bones setzen keine falsche Body-Revisionsmarkierung.

## Metriken und Prüfung

| Outfit | Segmente | Dreiecke | Exportvertices | Materialflächen |
|---|---:|---:|---:|---:|
| Light | 15 | 5052 | 10931 | 5 |
| Medium | 15 | 6124 | 13723 | 5 |
| Heavy | 20 | 7216 | 16782 | 5 |

Die Outfitwerte sind auf beiden Rigs identisch. Jedes Rüstungsvertex besitzt
genau ein positives Knochengewicht; Bodygewichte bleiben unverändert. Die
Wearable-Bibliothek besitzt insgesamt 13140 Dreiecke vor bilateraler Nutzung.
Der Body kommt mit 1604 Dreiecken / einer Materialfläche hinzu.

- Blender-Asset-QA: **30/30** Wearables; keine degenerierten/losen/duplizierten
  Vertices, offenen oder nichtmanifold Kanten, falschen Normalen oder
  erkannten Z-Fighting-Flächen. UVs gültig, keine erkannten Überlappungen.
- Akzeptierte Wearable-Warnungen: zentrierte Anbaupivots statt Bodenpivot;
  je ein vollständig verdeckter innerer Träger in Light-/Heavy-Torso.
- Body-QA: PASS, keine neuen degenerierten Flächen/Normalenfehler oder
  ungewichteten Vertices. 215 lagegleiche Vertices und 432 Randkanten gehören
  zur übernommenen gesplitteten Quelltopologie; keine Zusammenführung, damit
  UVs/Materialgrenzen/Gewichte erhalten bleiben. Sie sind keine neue geschlossene
  Manifold-Körpermodellierung. Siehe zusätzlichen Herkunftsvergleich.
- `body_source_audit.json`: unmittelbarer Blender-Vergleich Original gegen
  abgeleitete Quelle bestanden; 45 Bones, beide ursprünglichen Actions,
  Gewichte, Vertexgruppen, rohe Dreiecksindizes und UV-Loops identisch.
  Original und Ableitung haben exakt dieselben 215 lagegleichen Vertices,
  432 Randkanten und 12 Inseln. Ein beim Audit gefundener automatischer
  Winding-Wechsel offener Quellinseln im Zwischenexport wurde korrigiert:
  der finale Body-Builder erhält die ursprüngliche Flächenorientierung und
  transformiert Customnormals über die Verformungs-Jacobi-Matrix.
  Das änderte weder Runtimeprofil noch Wearables oder native Ergebnisse.
- Private Rüstungsverifier: **132/0 headless und 132/0 nativ**, beide Rigs,
  vier Klassen, Mesh/Skin-Sharing, klares Visier, starre Bauchkomponenten,
  Heavy→Medium-Gesichtsrestoration, Suit-Restoration, tatsächlicher `walk`.
- Private Bodyprüfung: **154/0**, Blenderkorrespondenz, Originalimmutabilität,
  Positionen/UV/Indizes/Gewichte, Bones, Persistenz über Equipmentwechsel und
  Fehlergrenzen für ungültiges Profil/fehlende Bones.
- Native Bilder: 1920×1080, echtes `idle`, identische Kamera/Beleuchtung zum
  bisherigen Vergleich. Front/Quarter/Seite/Hinten/Oben geöffnet. Echte
  Walk-Phasen 0,15 / 0,42 / 0,70 auf beiden Rigs erfasst; mindestens die ersten
  beiden und zuvor die dritte geöffnet. Fire und Kopfdrehung ±25° geöffnet.
- Material-/Wire-Kontaktbögen mit vier Blickrichtungen für die neu aufgebauten
  Hauptteile sowie echte Body-Material-/Wire-Ansichten liegen hier; erneute
  Sichtprüfung nach letzter Geometrieänderung ist erfolgt.
  Die Body-Kontaktbögen zeigen denselben finalen Vertexstand vor der reinen
  Export-Orientierungs-/Normalenkorrektur; keine erneute Renderabnahme dieses
  Referenzexports. Die aktuelle native Figur nutzt unveränderte Quellindizes.

Die privaten Verifier und Runner sind unter `validation/` eingefroren. Die
aktuellen ausführbaren Probes und Logs liegen in `output/native_glut_maps/`.
`handoff_manifest.json` bindet Quelldateien, Exporte, finale Bilder und Logs
über SHA256. `manifest.json` stammt aus dem Blender-Build.

## Qualitätsurteil und Grenzen

R06 liegt bei Brustbreite, ruhigen Hauptflächen, Seitenabdeckung, Kniekappen
und Körper-Taille-Verhältnis deutlich näher an den bestätigten Tafeln als R05.
Es ist ein prüfbarer Integrationskandidat, kein behaupteter 1:1-Nachbau und keine
ästhetische Nutzerfreigabe. Die Schulterkappen und Halsanschlüsse bleiben
stärker segmentiert als die malerischen Referenzen; die echte Idle-Pose hat
gebeugtere Beine. Die Helme/Beleuchtung wirken kantiger als das weiche 2D-Bild.
Die Körper-/Rüstungskombination wurde in den genannten Posen geprüft; extreme
Sitz-/Transportposen und breite Framerate-/Releaseprüfung bleiben offen.

## Reproduktion

Aus dem isolierten Worktree mit Blender **5.1.1**, ohne die Nutzer-Liveszene:

```powershell
& 'C:/Program Files/Blender Foundation/Blender 5.1/blender.exe' --background --factory-startup --python-exit-code 1 --python art/armor_kenney_r06_20261111/build_body_r06.py
& 'C:/Program Files/Blender Foundation/Blender 5.1/blender.exe' --background --factory-startup --python-exit-code 1 --python art/armor_kenney_r06_20261111/build_armor_r06.py
python art/armor_kenney_r06_20261111/update_r06_fit.py
```

Die Builder verwenden die vorhandenen lokalen Blender-Asset-QA-Skripte unter
`~/.codex/skills/blender-asset-qa/scripts`. Native Godot-Proben ausschließlich
mit privater APPDATA und dem Python-Runner; dessen subprocess-Rückgabe/Logs
belegen den Prozessabschluss, nicht ein vorzeitig zurückkehrender GUI-Aufruf.
