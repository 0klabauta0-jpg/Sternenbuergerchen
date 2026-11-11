# R07 — Schulterlinie und Kopfproportion

Integrationskandidat vom 11.11.2026, Blender **5.1.1**, Godot **4.6.2**.
Keine ästhetische Nutzerabnahme und kein Release-/FPS-PASS. Aufbau auf R06
im isolierten Branch `task/native-glut-maps-20261110`. Originalmodell, R05
und R06 bleiben erhalten. Dieses Paket verändert keine Spielwerte.

## Ziel und Referenzen

Die Nutzerkorrektur verlangt breitere Schultern oder einen kleineren Kopf
im Verhältnis zu den bestätigten 2D-Tafeln. Sie erlaubt ausdrücklich eine
Änderung der Kopfproportion. Maßgebend sind die drei Dateien
`../armor_orc_morozov_20261111/{light,medium,heavy}_turnaround_ai_r04.png`
und `docs/tasks/ARMOR_PROPORTIONS_R07_2026_11_11.md`.
Die später verlangten geschlossenen klaren Light-/Medium-Visiere sowie
feste Wangen-/Kinnschalen bleiben erhalten. Keine neue 2D-Generierung.

Die Bilder sind kreative Mehransichten, keine maßhaltigen Orthoprojektionen.
`proportion_landmarks.json` hält die Front-Landmarks und Messmethode fest.
Gemessen wird die äußere Schulterkappe gegen die gesamte Helmbreite,
einschließlich seitlicher Helmteile. Die Körperhaltung bleibt echtes Idle.
Native Schulterfarben werden in begrenzten Bildbändern isoliert; dunkle
Oberarme und orange Uniformabzeichen zählen nicht als Schulterkappe.
2D-Endpunkte besitzen ungefähr ±3 Pixel Ableseunsicherheit. Quotienten
sind unabhängig vom Bildmaßstab; zusätzlich sind beide Breiten auf die
sichtbare Figurenhöhe normiert. Frühere grobe R06-Bandwerte sind separat
archiviert und werden nicht mit der verfeinerten Messung vermischt.

| Schulterkappenbreite / Helmbreite | Ziel | R06 | R07 |
| --- | ---: | ---: | ---: |
| Leicht | 0,898 | 0,820 | 0,896 |
| Mittel | 1,195 | 0,899 | 1,187 |
| Schwer | 1,459 | 0,960 | 1,430 |

## Tatsächliche Modelländerungen

Der ursprüngliche Kenney-Körper wurde in Blender abgeleitet: oberer Thorax
und Deltoidkontur sind gezielt breiter, die R06-Taille bleibt erhalten.
Der Kopf wird um 5 % in Breite/Tiefe und 8 % in Höhe verkleinert, mit einem
weichen geometrischen Übergang am Hals. Die Kopfrotation und Knochenachsen
bleiben unverändert. Die Körperänderung betrifft 460 von 1029 Vertices;
1604 Dreiecke, UVs, Gewichte, 45 Quellknochen und zwei Quellanimationen
bleiben identisch. Maximale Verschiebung: 0,0677321 ursprüngliche Rig-Einheiten.
Hände, Finger, Füße und Zehen bleiben geometrisch unverändert.

Medium-/Heavy-Schultern besitzen neue achtseitige Dachquerschnitte mit
abgeschrägten Ecken und zwei beziehungsweise drei abgesetzten Stufen.
Die Dächer neigen sich nach außen über den Deltoid und folgen dem Armknochen.
Sie verbreitern die Schulterlinie, ohne den bisherigen runden Querschnitt
zu flachen Scheiben aufzuziehen. Light behält die kleinere segmentierte Kappe.
Brust-, Rücken-, Knie- und Gliedmaßenschalen stammen aus R06 und werden
auf den neuen Body gefittet. Eigene Helme folgen den neuen Head-Bounds.

## Quellen und Integration

- Original: `Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb`,
  SHA256 `00c378d03bd508d67c6e04d5e257827eaca053d48b072072255ad217e63f325c`.
- `origin_r06_armor.blend`, `origin_r06_body.blend`, `origin_r06_runtime.gd`:
  eingefrorene Ausgangskopien.
- `build_armor_r07.py` und `primary_shells.py` erzeugen
  `armor_r07_editable.blend` und 30 Wearable-GLBs.
- `build_body_r07.py` erzeugt `body_r07_editable.blend`, den tatsächlichen
  Body-Referenzexport, Profil, Vertexkorrespondenz und Body-QA.
- `update_r07_fit.py` assembliert den privaten Projektor aus R06 und
  `body_projection.gdinc`. `runtime_candidate.gd` ist die eingefrorene Kopie.
- Übergabe: `output/native_glut_maps/armor_r07_parts/` enthält 30 Wearables,
  **body_r07_derived.glb** und **body_shape_profile.json**. Der private Helfer
  liegt unter `output/native_glut_maps/personnel_armor_visual_r07.gd`.

Root kopiert Wearables und Profil in einen eigenen curated-R07-Pfad,
ersetzt `PATH` und lädt importierte `PackedScene` statt privatem GLTFDocument.
Das Profil muss außerhalb des durch `.gdignore` verborgenen Artordners liegen.
Der abgeleitete Body-GLB ist eine nachprüfbare Blenderquelle, keine neue
Laufzeit-Figurenhierarchie. Runtime wendet dasselbe Profil einmalig auf die
unveränderten Meshquellen beider bestehender Rigs an. Body- und Armor-Meshes
werden gecacht; die Körperform bleibt auch bei `suit` bestehen.

Wichtig bei bereits R06-behandelten Einsatzproxies: Der Ursprung wird aus
`armor_source_body_mesh`, dann `r07_source_body_mesh`, dann
`r06_source_body_mesh` gelesen, bevor `armor_original_body_mesh` infrage kommt.
R07 projiziert somit nicht erneut auf eine schon verbreiterte R06-Geometrie.
`armor_original_body_mesh` erhält anschließend die R07-Körpervariante für
Heavy-Head-Cover und die Wiederherstellung beim Rüstungswechsel.

Der bestehende `HelmetVisual_*` des normalen Spaceanzugs wird ebenfalls
passend zum Kopf transformiert. `armor_source_transform` speichert seinen
Ursprung; jeder Fit entsteht daraus, nicht aus einem vorherigen Fit.
Die tatsächliche BoneAttachment-Hierarchie wird berücksichtigt. Originale
Helmdatei, Rig, Inventar und Equip-Wahrheit bleiben unverändert.

## Prüfnachweise

| Outfit | Dreiecke | Segmente | Materialflächen |
| --- | ---: | ---: | ---: |
| Leicht | 5052 | 15 | 5 |
| Mittel | 5932 | 15 | 5 |
| Schwer | 6964 | 20 | 5 |

Je Outfit ein gecachtes skinnendes ArrayMesh; je Armorvertex genau ein
positives Knochengewicht. Basis-Skin 45, Einsatz-Skin 58 Binds.

- Wearable-Geometrie-/UV-/Normalen-QA: **30/30**, keine Fehler.
- `armor_r07_rig_test.gd`: **132/0 headless und 132/0 nativ**; tatsächliche
  Proxies, alle Klassen, Caches, Materialflächen, Head-Cover/Restore,
  exakter `walk`-Clip, Fire und Headturn.
- `armor_r07_body_test.gd`: **165/0 headless**; beide Rigs stimmen mit den
  unabhängigen Blender-Vertices überein. Maximaler Positionsfehler
  0,000002703 Schulterbreiten. Hände/Füße: exakt null Verschiebung.
  Ursprungsquelle, Body-Persistenz, wiederholte Equip-Wechsel und die
  nichtkumulative Skalierung des echten Spacehelms sind geprüft.
- `body_source_audit.json`: ursprüngliche und abgeleitete Index-/UV-Arrays,
  Gewichte, Vertexgruppen, Knochen und Animationen identisch. Keine
  umgekehrte Quellfläche; Normalen über Transformations-Jacobian angepasst.
- Material-/Wire-Mehransichten der aktuellen Quellen geöffnet, einschließlich
  der neuen Schultern und des aktuellen Körpers.
- Echte native Front/Quarter/Side/Rear/Top bei gleicher Kamera/Beleuchtung
  wie R06; Bodyvergleich R06/R07 beider Rigs; Walk-Füße bei Phasen
  0,15 / 0,42 / 0,70. Phasen 0,15 und 0,42 visuell geöffnet.
- Suit/Light/Medium/Heavy-Kopfdrehungen bei −25° / +25° vollständig sichtbar
  gerendert und geöffnet: keine neue offensichtliche Trennung der
  Kinn-/Halsanschlüsse; klare Visierfronten bleiben erkennbar.

Akzeptierte Warnungen: Wearable-Pivots liegen am Anbaupunkt statt am Boden;
je ein eingeschlossener interner Träger in Light-/Heavy-Torso. Der Originalbody
besitzt bereits 215 lagegleiche UV-/Teilgrenzen-Vertices, 432 offene Randkanten
und 12 Inseln. R07 besitzt exakt denselben Befund; keine losen Vertices,
degenerierten Flächen oder inkonsistenten Normalenkanten hinzugefügt.

## Reproduktion und Grenzen

Die archivierten privaten Runner/Probes liegen unter `validation/`; ihre
`res://output/...`-Pfade bezeichnen den ursprünglichen Ausführungsort. Die
Godot-Aufrufe liefen mit privatem APPDATA und Python subprocess.run samt
Exitcode/Timeout. Blender lief ausschließlich in eigenen Background-Szenen.

1. `python output/native_glut_maps/build_armor_r07_background.py art/armor_kenney_r07_20261111/build_armor_r07.py`
2. Derselbe Runner mit `build_body_r07.py`; danach `python art/armor_kenney_r07_20261111/update_r07_fit.py`.
3. `python output/native_glut_maps/run_armor_r07.py armor_r07_rig_test.gd --headless`
4. Derselbe Test ohne `--headless`, außerdem Body-Test und Bildprobes.

Qualitätsurteil: Die Schulter-/Kopfrelation und der echte Body liegen deutlich
näher an den bestätigten Tafeln. Der Kopf bleibt bewusst stiltypisch groß.
Helm und Schulterübergänge sind kantiger als die gemalte Darstellung;
die tatsächliche Idle-Pose hat stärker gebeugte Beine. Die Messwerte sind
eine überprüfbare Proportionshilfe, keine vollständige ästhetische Abnahme.
Extreme Sitz-/Transportposen, breite Performance und die endgültige produktive
Equip-Integration sind nicht Teil dieses begrenzten Kandidaten-PASS.

`handoff_manifest.json` enthält die endgültigen SHA256-Werte für Quellen,
Exporte, Helfer, Profil, Bilder und Logs. Keine Modell-/Fitänderung nach
Freigabe des GPU-Fensters an Root.
