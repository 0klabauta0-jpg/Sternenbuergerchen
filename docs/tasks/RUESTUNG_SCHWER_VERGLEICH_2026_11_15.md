# Ruestungen leicht / mittel / schwer: Ist-Zustand gegen Referenzbogen (15.11.2026)

Reiner Lese- und Messauftrag. Es wurde kein Spielcode, kein Modell und keine Datendatei veraendert.
Bilder: `docs/qa/ruestung_vergleich_20261115/` (`vergleich_light.jpg`, `vergleich_medium.jpg`, `vergleich_heavy.jpg`:
oben Referenzbogen, unten vier Renders vorne/hinten/Seite/oben; `silhouette_*.jpg`: Referenz | Spiel | Differenz, rot = nur Referenz,
blau = nur Spiel, mit 10-%-Hoehenraster; `extra_heavy_mit_waffe.jpg`: schwere Ruestung mit Gewehr wie im Spiel).

## 1. Woher die Ruestungs-Optik kommt

Kette: `data/npc_unit_visual_mapping.json` (Archetyp `friendly_space_suit_white`, Scale 0.22, Rotation 270 Grad) ->
`TerrainMap3DView._create_unit_proxy` (terrain_map_3d_view.gd:13841) laedt den Koerper, haengt Animation, Sockel, Helm und Blaster an und ruft zuletzt
`scripts/terrain/personnel_armor_visual.gd::apply_to_model(root, unit.get_armor_id())`. Dasselbe Skript wird auch von
`scripts/meta/explorable_homebase.gd`, `scripts/terrain/polisa_station_visual.gd` (Vitrinen) und `scripts/ui/components/personnel_body_preview.gd` benutzt.

- Koerper (fuer alle Ruestungen gleich): Kenney "Animated Characters" `Assets/used/npc/animated_characters/models/characterMedium.fbx`,
  Skin `skins/astroMaleA.png`, Animationen `idle/walk/shoot.fbx` im selben Ordner. Das Skript verformt den Koerper zur Laufzeit mit
  `Assets/curated/personnel/armor_kenney_r07_20261111/body_shape_profile.json` (Breite/Tiefe/Kopf/Deltoid-Skalierung je Hoehe) und tauscht das Material
  gegen einen Unterzug-Shader (Stoff wird fast schwarz: Albedo ca. 0.05/0.06/0.075; Anzug "suit" bleibt hell). Bei "heavy" wird der Kopf des Koerpermeshes entfernt (1316 statt 1604 Dreiecke).
- Ruestungsteile: 33 GLB-Teile in `Assets/curated/personnel/armor_kenney_r07_20261111/` (`torso_*`, `pelvis_*`, `helmet_*`, `pauldron_*`, `forearm_*`, `thigh_*`, `knee_*`, `shin_*`, `boot_*`;
  nur schwer: `collar`, `upper_arm_heavy`, `hand_guard_heavy`). Jedes Teil wird zur Laufzeit auf Masse aus den Knochen (Schulterbreite `width`, Torso-Hoehe, Koerper-Huellen) skaliert
  (`_add_spec`/`_fit_anatomical_specs`, Faktor `bulk` 0.93 / 1.22 / 1.50), starr an EINEN Knochen gebunden (Gewicht 1.0, keine Verformung) und zu einem einzigen Mesh
  `ArmorVisual_Outfit` (Kind des Skeleton3D) zusammengebacken, je Material eine Surface. Materialien stecken in den GLBs: `M_Armor_Ceramic` (Sand, 0.38/0.32/0.255),
  `Graphite` (0.049/0.057/0.071), `Titanium` (0.13/0.15/0.18), `Amber` (Orange), `Visor` bzw. `ClearVisor`. Keine Texturen, nur Flaechenfarben; Revision-String `kenney_authored_r07_undersuit_v2`.
- Der GLB-Metadatenvermerk lautet "R07 model candidate, not aesthetic acceptance"; Export "Khronos glTF Blender I/O v5.1.19".
- Editierbare Quelle: NEIN. Weder .blend noch Generator-Skript fuer die Ruestungsteile im Repo (Suche nach Materialnamen, Teilenamen, `armor_kenney`, `*.blend`, art/, tools/, docs: nichts; git-Historie hat nur den Sammel-Commit 03cdccc5).
  Vorhanden sind nur die exportierten GLBs plus der Zusammenbau-Code. `body_r07_derived.glb` (+png) im selben Ordner wird von keinem Skript referenziert. Die Referenzbogen liegen in `Assets/curated/ui/polisa_armor/*_turnaround.png`.
  Die GLBs lassen sich per bpy importieren und neu exportieren, das waere aber Rekonstruktion, keine Quelle.

## 2. Render-Bedingungen

Echter Proxy aus `_create_unit_proxy` (test_unit.gd mit `armor_id`), ortho Kamera, Hintergrund 0.8 grau, gleichmaessiges Umgebungslicht plus schwaches Richtungslicht, kein Schatten.
Idle-Animation bei 0.2 s (wie `grafikpass_r1_capture.gd`), Gewehr und Teambasis-Scheibe ausgeblendet (Hauptsheets); der Bogen zeigt eine gerade A-Pose, das Spiel eine leicht geduckte Idle-Haltung
mit gebeugten Knien und nach vorn gehaltenen Armen. Die Ruhepose des Rigs ist eine T-Pose und eignet sich nicht zum Vergleich. Alle Messwerte sind Verhaeltnisse aus Silhouetten (Maske gegen Hintergrund), ca. +-1 % Messfehler;
Helm-/Beinlaengen sind Augenmass an den 10-%-Rastern (+-2 %). Die Draufsicht des Bogens ist perspektivisch aufgeblasen und daher nur grob vergleichbar.

## 3. Differenzen

### Gemessene Verhaeltnisse (Referenz -> Spiel)

| Mass | leicht | mittel | schwer |
|---|---|---|---|
| Breite/Hoehe (vorne) | 0.456 -> 0.373 | 0.460 -> 0.387 | 0.473 -> 0.464 |
| Schulterbreite/Hoehe | 0.320 -> 0.318 | 0.367 -> 0.373 | 0.454 -> 0.464 |
| Helmbreite/Hoehe | 0.321 -> 0.311 | 0.318 -> 0.318 | 0.311 -> 0.324 |
| Helm/Schulter | 1.00 -> 0.98 | 0.87 -> 0.85 | 0.69 -> 0.70 |
| Spannweite Arme/Haende (Zone 46-72 %) | 0.456 -> 0.373 | 0.460 -> 0.387 | 0.473 -> 0.396 |
| Beinbreite (Zone 76-97 %) | 0.253 -> 0.267 | 0.270 -> 0.265 | 0.287 -> 0.269 |
| Kopfhoehe (Helm), Augenmass | ca. 29 % -> 29 % | ca. 31 % -> 30 % | ca. 26 % -> 28 % |
| Kopf Tiefe/Hoehe (Seite) | 0.324 -> 0.313 | 0.321 -> 0.313 | 0.319 -> 0.349 |
| Rumpftiefe bei 45 % Hoehe | 0.149 -> 0.151 | 0.244 -> 0.169 | 0.268 -> 0.196 |
| Rumpf Breite/Tiefe bei 45 % | 2.12 -> 2.08 | 1.33 -> 1.85 | 1.44 -> 1.98 |
| Beintiefe (Seite, 80-97 %) | 0.154 -> 0.218 | 0.166 -> 0.213 | 0.197 -> 0.216 |
| Beinanteil an Gesamthoehe, Augenmass | ca. 37 % -> 35 % | ca. 34 % -> 33 % | ca. 33 % -> 32 % |

Kopf:Gesamthoehe (Helm) schwer: etwa 1:3.8 Referenz gegen 1:3.6 Spiel. Die Gesamt-Silhouette von vorn passt bei "schwer" also gut; Leicht/Mittel sind wegen anliegender Arme schmaler.
Draufsicht (Breite/Hoehe, Tiefe/Hoehe), nur grob: schwer 0.505/0.586 -> 0.463/0.350.

### Farbe (Anteil der Figurenpixel, Mittelwert der Klasse)

| | dunkel (Luma<75) | Sand | Grau/Rest | Orange |
|---|---|---|---|---|
| leicht Ref | 42 % (67,65,67) | 33 % (181,159,142) | 25 % (87,83,85) | 0.5 % |
| leicht Spiel | 54 % (20,22,25) | 34 % (167,145,128) | 12 % (80,86,94) | 0.4 % |
| mittel Ref | 23 % (60,56,56) | 54 % (180,156,137) | 22 % | 0.6 % |
| mittel Spiel | 22 % (27,29,30) | 65 % (153,139,125) | 12 % | 0.3 % |
| schwer Ref | 35 % (54,54,59) | 15 % (168,154,142) | 50 % (101,100,103) | 0.3 % |
| schwer Spiel | 19 % (52,57,64) | 20 % (147,136,123) | 61 % (87,93,101) | 0.2 % |

### Schwer, nach Beitrag zum "klobig"-Eindruck sortiert

1. Helm: `helmet_heavy` (556 Dreiecke) ist ein tiefer, kantiger Kasten (Tiefe/Hoehe 0.349 gegen 0.319, +9 %; Helmunterkante bei ca. 28 % statt 26 %). Der Bogen zeigt eine glatte, gewoelbte Kuppel mit breitem Visor,
   darunter eine Kinn-/Maskenpartie mit Luftschlitzen und seitliche Scheiben. Im Spiel: Visor nur ein flaches schwarzes Band, keine Maske, Seitenscheibe nur flach aufgesetzt; Helmrueckseite ist ein glatter Block. Optisch der groesste Einzelposten.
2. Rumpf ist ein flacher Block: Tiefe auf Brusthoehe 0.196 gegen 0.268 (-27 %), Breite/Tiefe 1.98 gegen 1.44. Der Bogen hat eine vorstehende Brustplatte in dunklem Rahmen, gurtartige Schulterpartie, Guertel mit zwei grossen Taschenbloecken,
   dreiteiligen Ruecken-Octagon-Plattenstapel mit Traegern; im Spiel sind Brust-/Beckenplatten eine einzige blaugraue Flaeche, Guertel nur als schmaler Streifen, Taschen fehlen, Rueckenplatten sind flach.
3. Farbe/Kontrast: Dunkel-Anteil 19 % statt 35 %, dafuer 61 % blaugraues Mittelgrau (87,93,101) statt neutralem Grau (101,100,103). Die Referenz lebt vom Kontrast dunkelgrauer Basis gegen Sand und Orange; im Spiel verschmelzen
   Graphite/Titanium zu einer blassen Blaugraufarbe (Titanium-Material 0.13/0.15/0.18 plus Lichtanteil), Sand etwas zu dunkel/gelblich-grau (147,136,123 gegen 168,154,142). Haende und Unterzug sind fast schwarz (Referenz: hellgraue Handschuhe).
4. Arme: Spannweite 0.396 gegen 0.473 (-16 %), Arme liegen am Koerper (Idle-Pose, Gewehrhaltung). Referenz: dicke, in drei Stufen gegliederte Oberarme, grosse sandfarbene Unterarmschalen mit orangem Streifen, grosse hellgraue Faeuste.
   Im Spiel: Unterarmschale ok, Oberarm ohne erkennbare Gliederung, Hand nur kleine schwarze Box (`hand_guard_heavy`).
5. Schulterplatten: Referenz drei gestapelte, nach aussen kippende Platten ("Dach"-Form). Im Spiel `pauldron_heavy` um -50 Grad gekippt, wirkt wie flach abstehende Fluegel; Breite stimmt (0.464 gegen 0.454).
6. Beine/Knie: Beine 6 % schmaler (0.269 gegen 0.287), Knieplatten klein; Referenz grosse achteckige Knieplatten mit Schlitzen, sandfarbene Oberschenkelschalen, dunkle Schienbeinschalen mit orangem Streifen, kantige zweifarbige Stiefel. Im Spiel horizontale Zierstreifen am Knie statt der Platte; Beintiefe 0.216 gegen 0.197.
7. Haltung: Idle hat gebeugte Knie und vorgebeugten Oberkoerper (Gesamthoehe ca. 2 % kleiner als T-Pose); der Bogen zeigt aufrechte Haltung. Kein Modellfehler, aber im Seitenbild deutlich.
8. Kragen: vorhanden (`collar`, 428 Dreiecke), Form passt grob; Orange-Markierungen kleiner. Gering.

### Leicht (Reihenfolge)
1. Unterzug fast schwarz (20,22,25) statt dunkelgrau (67,65,67); Haende schwarz statt hellgrau. 2. Arme liegen an, Spannweite 0.373 gegen 0.456 (-18 %) (Bogen: A-Pose).
3. Helm: Referenz offener Helm mit Kinnspange und Ohrpods; Spiel kugelig-kantig mit Klarsicht-Visor, Rueckseite blaugrau statt anthrazit. 4. Guertel mit Schnalle fehlt, Brust-/Bauchplatten kleiner/zahlreicher im Bogen. 5. Knieplatten (Sechseck) kleiner; Stiefel ok (Sand-Kappe). Proportionen (Schulter, Helm, Rumpftiefe) stimmen innerhalb 3 %.

### Mittel (Reihenfolge)
1. Rumpftiefe 0.169 gegen 0.244 (-31 %): Brustpanzer flach statt modelliert, Bauchplatten zu flach. 2. Zwischenraeume schwarz (27,29,30) statt dunkelgrau (60,56,56), Haende schwarz. 3. Sandanteil 65 % gegen 54 %, Sand zu grau.
4. Arme anliegend (-16 % Spannweite). 5. Helm wie bei leicht. Schulter-/Helmproportionen stimmen.

### Polygon- und Materialzahlen (sichtbar im Proxy)
| | Koerper | Ruestung `ArmorVisual_Outfit` | Gewehr | Materialien Ruestung |
|---|---|---|---|---|
| leicht | 1604 | 5052 | 470 | 5 (Amber, Ceramic, ClearVisor, Graphite, Titanium) |
| mittel | 1604 | 5932 | 470 | 5 (wie leicht) |
| schwer | 1316 | 6964 | 470 | 5 (Amber, Ceramic, Graphite, Titanium, Visor) |

Einzelteile schwer (Dreiecke): torso 1192, helmet 556, collar 428, thigh 432 (je Seite), boot 350, forearm 340, shin 296, hand_guard 276, upper_arm 240, pelvis 224, pauldron 200, knee 148.
Plus Koerper-Material (Shader) und Unterzug-ShaderMaterial. Alle Teile werden doppelt/mehrfach (links/rechts) instanziiert.

## 4. Wege zur Behebung (nicht umgesetzt)

(a) Bestehendes anpassen. Zwei Hebel ohne neue Modelle: Zahlen im Skript (`bulk` 1.50, Torso-Tiefe `*1.16`, Pauldron-Kippwinkel, Knie-/Arm-Faktoren, Handschuh-/Unterzugfarbe im Shader, `body_shape_profile.json`)
und die Teile selbst (GLB per bpy/Blender importieren, umformen, unter gleichem Namen exportieren; Materialfaktoren der M_Armor_*-Materialien neu setzen). Aufwand klein bis mittel; Risiko niedrig-mittel.
Grenzen: Teile sind starr an einen Knochen gebunden und werden auf Specs gestreckt, Torso-/Beckenmasse folgen dem Kenney-Koerper; Helm, Maske und Brustplattenrelief lassen sich nur ueber neue Geometrie loesen. Ohne Quelle bleibt es Rekonstruktion.
Betroffen: gleicher Code bedient leicht/mittel/schwer, nur per `armor_id`-Zweig trennbar; `REVISION` hochzaehlen, sonst greift der Cache. Brechen kann: Optik in Homebase, Polisa-Vitrinen, Charakter-Vorschau (alle nutzen dieselbe Funktion).

(b) Neubau als Python-/Blender-Skript im Stil `art/windbruch_kit_20261114/build_kit.py` (462 Zeilen, abgeschraegte Boxen, Flaechenfarben, bpy installiert). Schwer: 12 Teile (Helm mit Maske/Visor/Ohrscheiben, Kragen, gestufte Schulter, Brustplatte mit Rahmen, Rueckenplatten, Guertel mit Taschen, Oberarm-/Unterarmstufen, Faust, Oberschenkel/Knie/Schienbein, Stiefel),
gleiche Dateinamen im selben Ordner oder neuer Ordner plus geaenderter `PATH`, Materialnamen Ceramic/Graphite/Titanium/Amber/Visor beibehalten (Buckets laufen ueber `resource_name`), Front -Y (glTF +Z). Hat endlich eine editierbare Quelle (`art/.../build_armor.py`).
Aufwand mittel bis hoch (heavy allein grob 1-2 Tage, alle drei mehr); Risiko niedrig fuer Rig/Animation, da die Teile weiter starr an die Kenney-Knochen gehen und nur ihre Form wechselt. Beachten: Teile werden auf Spec-Masse gestreckt (`bounds` wird fuer Torso/Pelvis/Unterarm/Oberschenkel/Schienbein/Knie auf Einheitswuerfel gesetzt),
also in Einheitsboxen bauen; Tiefe haengt von `_fit_anatomical_specs` ab (Torso-Tiefe aus Koerperhuelle) und bleibt dort der Flaschenhals, wenn die Brust vorstehen soll.

(c) Sonstiges. (1) Nur Daten: `body_shape_profile.json` aendern (Koerper pro Hoehe breiter/tiefer, Kopfgroesse): billig, wirkt aber auf alle Ruestungen und das Anzug-Aussehen. (2) Neue Idle-/Pose-Animation fuer aufrechte Haltung: Animationen kommen aus Kenney-FBX, Aenderung braucht Bearbeitung der Clips,
beruehrt Kampf-/Schusspose-Tests (task_403, task_431). (3) Kompletten Charakter neu (eigenes Mesh + Rig mit Kenney-Knochennamen): Zielbild am besten getroffen, aber hoechster Aufwand und Risiko (Skinning, Animationen, Sockel, Helm-/Blaster-Anbau, Vorschau).
Das Repo kennt sonst keinen Ruestungs-Generator, `body_r07_derived.glb` ist ungenutzt.

### Was jeweils bricht (Fundstellen per grep in scripts/ und tests/)
- Einziger Test, der Ruestungs-Interna festnagelt: `scripts/tests/personnel_undersuit_switch_verifier.gd` (Knoten `ArmorVisual_*`, Meta `worn_armor_id`, Shader-Parameter `visible_suit`, Operator-GLB). Keine Tests, die GLB-Teilepfade oder Ruestungs-Bounds festschreiben gefunden.
- Weitere Verbraucher: `explorable_homebase.gd` (Meta `worn_armor_id`), `polisa_station_visual.gd` (Vitrinen), `personnel_body_preview.gd` (Vorschau), `grafikpass_r1_capture.gd`, `review_completion_personnel_capture.gd`.
- Animation/Skelett: bei (a)/(b) unveraendert, da Ruestung nur Kind von `Skeleton3D` mit Knochenbindung ist; bei (c)(2)/(3) betroffen (`UnitVisualAnimationPlayer`, task_172/173/403/431/review7).
- Anbaupunkte: `HeadSocket`, `RightHandSocket`, `LeftHandSocket`, `BackSocket`, `MuzzleSocket` haengen am Koerper-Skelett, nicht an der Ruestung; Verfaelschung nur bei neuer Hand-/Helmgeometrie (Gewehr greift am Handsocket, Helm-Fit `armor_head_fit`). Tests: task_172/173/175/190.
- Portraits: 2D-Atlanten (`art/portraits_20261105`), Gesichts-Skin-Tausch in `personnel_visual_identity.gd`; nicht von Ruestungsformen abhaengig, nur die 3D-Vorschau.

Am wenigsten riskant erscheint (a) plus Teilaustausch nach (b) nur fuer `helmet_heavy`/`torso_heavy`/`pauldron_heavy`: gleiche Dateinamen, gleiche Materialnamen, Rig und Tests bleiben unberuehrt, jede Teilerneuerung ist einzeln mit diesen Renders pruefbar.

## 5. Nicht bestimmbar / Einschraenkungen
- Entstehungsweg der GLBs (Blender-Datei, Skript, externes Werkzeug) laesst sich aus dem Repo nicht belegen.
- Hand- und Stiefelgroesse nur nach Augenmass (Haende im Spiel kleiner und schwarz; Stiefel in etwa gleich gross), nicht gemessen.
- Kopf-/Beinanteile Augenmass +-2 %; Draufsicht-Verhaeltnisse unzuverlaessig (Perspektive im Bogen).
- Render mit llvmpipe/OpenGL3 und eigener Beleuchtung; die In-Game-Kamera, Tonemapping und Licht koennen Farben leicht anders zeigen.
