# R06 — eigener Körper und vorlagennähere Rüstung

11.11.2026. Isolierter task/native-glut-maps-20261110 auf7ef57c931;
keine Mainintegration, keine neue EXE, keine ästhetische Nutzerfreigabe.

## Ziel und sichtbare Änderung

Der Nutzer findet die bestätigten 2D-Tafeln schöner als R05 und benennt
schmale Brustflächen, Knieform/-sitz und unzureichendes seitliches Umgreifen.
Danach erlaubt er ausdrücklich, auch den sackförmigen Grundkörper zu bearbeiten.
R06 leitet eine eigene Figur vom unveränderten Kenney-Original ab: breitere
Schulter-/Brustpartie und klarere Taille. Kopf, Hände, Füße, Gewichte,
Topology/UVs und vorhandenes Rig/Animationen bleiben erhalten.
Die neue Form bleibt beim Ablegen sichtbar und wird nicht kumulativ verformt.

Breite Brusthälften haben zwei ruhigere Hauptflächen mit horizontalem Knick,
seitliche Rückläufe statt kleiner Säulen/Pyramiden. Knie sind vollständige
zentrierte Kappen mit flacherer Vorderprojektion und seitlichem Rücklauf.
Mittlere Bauchlamellen sind abgeschrägt/verjüngt, schwere Weste hat eine
Brust→Taillenform. Mittel/schwer umgreifen Arme/Beine stärker. Geschlossene
klare Visiere mit festen Wangen/Kinn für leicht/mittel bleiben; schwer dunkles
integriertes Visier/Kragen. Keine neue Lebenserhaltungs-/Schutzwertmechanik.

## Quellen und produktive Integration

Eigene editierbare Armor- und Body-Blenderdateien samt Buildern, 2D-Zuordnung,
Material-/Wire-Review und Hashinventar unter art/armor_kenney_r06_20261111.
Vorherige R05/R04 einschließlich verworfener Zwischenstände bleiben erhalten.
30 Wearable-GLBs plus Body-Referenz-GLB und body_shape_profile.json nach
Assets/curated/personnel/armor_kenney_r06_20261111 bytegenau übernommen.
Runtime benutzt das JSON-Profil auf einer gecachten Kopie des echten
Originalmeshes; Body-GLB dient als eigener Blender-/Importreferenzexport.
Produktiv werden Wearables aus importierten PackedScenes geladen. Original-
meshes werden separat erhalten, Heavy-Kopfbedeckung und Equipwechsel sind
reversibel. Kein per-frame Körper-/Outfitbau oder zweiter Gameplayzustand.

## Produktionsprüfung

- Godot4.6.2, frischer Editorimport Exit0 ohne Script-/Importfehler.
- personnel_armor_visual_test: Headless156/0 und nativ156/0. Beide Rigs,
  Suit/Light/Medium/Heavy, bestehende echte Walk-/Fireclips, Rücken/Kopfdrehung,
  Cachewiederverwendung, klares Visier, Spine/Hips und neue Body-Persistenz.
- Eigene Produktionskopie des Bodyvergleichs:154/0. Gegen echte Blender-
  Original-/Ableitungsvertices,285/1029 Vertices geändert auf beiden Rigs;
  maximaler Korrespondenzfehler1,91e-6 bzw2,70e-6 Schulterbreiten.
  Kopfdisplacement0, UV/Farben/Indices/Gewichte/Rigrests/Originalarrays
  unverändert. Fehlerprofile und fehlende Bones werden korrekt abgewiesen.
  Produktionsprobe liest r06_source_body_mesh auch bei bereits projizierten
  echten Einsatzproxies, nicht fälschlich die schon abgeleitete Form.
- Tatsächlicher Inventar-/Basisweg: Headless15/0, nativ16/0. Anlegen/Ablegen,
  endlicher Bestand, Blueprint-Ownerfixture und echte Basisprojektion.
- Root-Dreiklassenvergleich: drei produktiv importierte Modelle, fünf
  unveränderte Kameras/Lichtsettings, Exit0. production_pose_* und
  armor_actual_* zeigen ebenfalls den produktiven Pfad.
- runtime_metrics.json:5052/6124/7216 Dreiecke je leicht/mittel/schwer,
 15/15/20 Segmente, jeweils fünf Materialflächen und genau ein positives
 Knochengewicht pro Vertex. Skins45 Basis/58 konkreter Einsatzproxy.
- Workbench134/0 Browserchecks: alle60 Varianten-/Klassen-/Ansichtspaare,
 gleiche vollständige Figurenhöhe, Dialog/Graustufen, Notizen und validierter
 JSON-Roundtrip, Desktop1600×1000/Mobil390×844. Exportleiste liegt unter den
 Figuren. ?variant=r06 öffnet explizit den neuen Stand, alte Notizen bleiben.
 workbench_roundtrip.json enthält nur automatische Testnotizen/-urteile.

## Delegierte Kandidatenprüfung und akzeptierte Warnungen

Astra Ultra: Blender Armor30/30, private Rigchecks132/0 headless+nativ,
Body154/0. Zusätzliche tatsächliche Walkphasen.15/.42/.70 und beidseitige
Kopfdrehungen geöffnet. Kandidatenbilder sind als candidate_* getrennt.
Body-Quellaudit bestätigt geerbte215 Duplikatpositionen/432 Randkanten/12Inseln
auch im Original; keine neuen UV-/Rig-/Topology-Schäden. Die offenen UV-/Normal-
Splits werden absichtlich nicht zusammengeführt. Wearable-Pivots zentriert,
beim Zusammenbau über Bones platziert. Finale Body-Referenzexportkorrektur
bewahrt rohe Originalindizes und korrekt transformierte Customnormals;
sie verändert Runtimeprofil/Helper/Outfits und native Resultate nicht.

## Grenzen

Kenney-Stil bleibt facettierter als die weiche 2D-Tafel. Schulter-/Halsformen
sind stärker segmentiert; echte Idle-Beine sind gebeugter als die Zeichnung.
Diese Revision ist ein geprüfter Kandidat, keine perfekte1:1-Rekonstruktion.
Sitz-/Transportextreme, alle Kampfclips, breite FPS-/Releaseabnahme bleiben
offen. Späterer gemeinsamer nativer B-Nachlauf wird beim Terrain-Prefilltask
geführt und nicht rückwirkend als isolierter R06-Performancenachweis ausgegeben.
Bekannte zwei Homebase-UID-Fallbacks und Asset-Placer-/ObjectDB-Importwarnungen
bleiben dokumentiert; kein allgemeiner Editor-/Testsuite-PASS.
Alle Laufzeitprüfungen nutzen private APPDATA unter output/native_glut_maps.
