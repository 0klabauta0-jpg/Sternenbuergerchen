# Kenney-Ruestungen R05 — Kandidat zur Integration

Stand: 2026-11-11. Blender 5.1.1; Godot 4.6.2. Modellierung und private native Pruefung abgeschlossen, produktive Integration beim Root-Agent. Keine aesthetische Nutzerabnahme behauptet.

## Ziel und verbindliche Referenzen

Die drei bestaetigten `light_turnaround_ai_r04.png`, `medium_turnaround_ai_r04.png` und `heavy_turnaround_ai_r04.png` unter `art/armor_orc_morozov_20261111/` bestimmen die Klassen, Hauptformen und Materialaufteilung. Die Quellen und SHA256 stehen in `manifest.json` und `handoff_manifest.json`.

Spaetere ausdrueckliche Nutzerkorrekturen haben Vorrang vor den aelteren Tafeln:

- Leicht und mittel: feste Wangen-/Kinnschalen, sichtbare klare geschlossene Visierfront, Seitenabdichtung und Halsrand; Gesicht bleibt sichtbar. Kein Fahrradhelm-/Riemenbild.
- Leicht: Spacehelm/ORC-Scout-Richtung, weniger Koerperabdeckung. Mittel: deutlich staerkere Abdeckung, eigener fester Kinnschutz.
- Keine aufgesetzte Schweisserbrille oder vorspringender Hex-Mundblock bei schwer.
- Platten weniger dick und koerpernah; schwere Klasse vor allem durch Abdeckung, Staffelung und Kragen.
- Echte leicht gewoelbte, facettierte Schalen mit zur Koerperkontur zuruecklaufenden Seiten; kein blosses Bevel auf flachen Frontpolygonen.
- Kenney-Koerper, Kopf, Haende, Fuesse und vorhandene Animationen bleiben die Proportionsgrundlage. Keine Fahrzeuge, kein neues Gameplay-/Life-Support-System.

## Editierbare Quelle und Exporte

- `armor_r05_editable.blend`: 30 modellierte Wearable-Teile, unveraenderter importierter Kenney-Referenzkoerper verborgen. Die Originaldatei wird nicht ueberschrieben.
- `build_armor_r05.py`: reproduzierbare Bpy-Geometrie, Materialien, UVs, Export und Geometrie-QA. Startet ausschliesslich eine eigene Background-Szene.
- `anatomical_fit.gdinc`: anatomische Bounds-Anpassung und starre komponentenweise Bauchplattenbindung.
- `runtime_candidate.gd`: eingefrorene vollstaendige Kandidatenkopie des privaten Helpers; produktive Pfad-/Importintegration erfolgt separat.
- `review_armor_r05.py`, `review_shots.json`: echte Blender-Material-/Wire-Mehransichten von elf Schluesselteilen, je Front/Seite/Oben/Dreiviertel.
- GLBs: `output/native_glut_maps/armor_r05_parts/` (30 Dateien, SHA256 in `manifest.json`).
- Privater Runtime-Helper: `output/native_glut_maps/personnel_armor_visual_r05.gd`.
- Vorheriger Stand ohne die letzte Schalenwoelbung: `output/native_glut_maps/armor_r05_snapshot_1222/` mit Quelle, Helper, GLBs und fuenf nativen Ansichten.

Die geometrischen Querprofile besitzen drei bis fuenf Stuetzstellen; die Seiten kehren zur Koerperoberflaeche zurueck. Mittlere Brusthaelften behalten zugleich den horizontalen Knick. Schulterdaecher sind geschlossene gestaffelte Volumina. Stiefel stammen aus der Huellform der unveraenderten Foot-/Toes-Vertices, nicht aus vergroesserten Quadern.

## Passform und Skinning

Das Outfit bleibt ein gecachtes `ArrayMesh` mit passendem vorhandenen Skin. Es wird nur bei einer Aenderung der Ruestung erzeugt. Die Anpassung liest Original-Vertexbounds und Bone-Rests; sie fuehrt keinen Gameplay-State ein.

Schultern sitzen bei 0.10 statt 0.24 der Armstrecke. Unterarm-, Oberschenkel-, Schienbein- und Kniebreiten/-tiefen orientieren sich an gewichteten Original-Koerperbounds. Knie verwenden die Schienbeinachse. Die zuvor zu grosse Frontdistanz der Schienbeine und der zu starke Brust-/Beinvorbau wurden reduziert. Hueft-/Oberschenkelanschluesse laufen der Koerperform folgend zurueck.

Untere Bauchplatten werden als komplette zusammenhaengende Komponenten auf `Spine` bzw. `Hips` gebunden. Die Verbindungsermittlung ueberbrueckt glTF-Splits fuer UVs, Normalen und Materialien. Keine starre Platte wird durch eine Vertex-Hoehenschwelle zwischen zwei Knochen aufgeteilt. In Beugung koennen die unteren Platten sichtbar ueberlappen. Der Vorfuss verwendet dagegen ausdruecklich `Foot`/`Toes`, damit die Schuhhuelle den vorhandenen Zehenanimationen folgt. Jeder Vertex hat genau ein positives Gewicht.

Bei Produktivimport `_assign_torso_components(primitives)` im Ladepfad erhalten. Die private GLTFDocument-Laderoute darf wieder durch importierte `PackedScene`-Assets ersetzt werden. Materialnamen bleiben stabil. Die klare Visierflaeche ist das fuenfte Runtime-Material der leichten/mittleren Klasse; die schwere Klasse nutzt stattdessen das dunkle Visiermaterial.

| Klasse | Segmente | Dreiecke pro Outfit | Materialflaechen | Exportierte Vertices |
| --- | ---: | ---: | ---: | ---: |
| Leicht | 15 | 5.020 | 5 | 10.901 |
| Mittel | 15 | 5.608 | 5 | 12.347 |
| Schwer | 20 | 6.736 | 5 | 15.322 |

`runtime_metrics.json` wurde aus den tatsaechlich erzeugten Godot-Meshes gewonnen. Basis-Skeleton: 45 Bindungen. Konkret erzeugter Einsatzproxy: 58 Skeleton-Bindungen; der importierte Koerperskin hat 45. Body-Skin-Indizes werden korrekt auf Skeleton-Bones abgebildet, nicht gleichgesetzt.

## Abgeschlossene private Pruefung

- Blender `qa.json`: 30/30 PASS. Keine offenen/nonmanifold Kanten, degenerierten Flaechen, inkonsistenten Normalen, losen/duplizierten Vertices oder Z-Fighting-Paare. UVs vorhanden, keine Nullflaechen oder UVs ausserhalb 0..1; groesster gesampelter UV-Overlap 0.18 Prozent.
- Einzige akzeptierte QA-Warnung: Wearable-Pivots sind zentriert, daher liegen die Teile nicht auf z=0. Das sind Anbauteile, keine Bodenprops. Keine weiteren Warnungen.
- Native D3D12 Forward+ und Headless: jeweils `PERSONNEL_ARMOR_VISUAL 124 passed, 0 failed`. Beide Rigpfade, vier Klassen, Cache-/Mesh-/Skin-Sharing, vorhandene Clips, Kopfverdeckung/Wiederherstellung und Equipmentwechsel.
- Exakter Clip `walk` in allen acht Funktionsfaellen; zusaetzlich sechs Figuren in Phasen 0.15, 0.42 und 0.70 visuell geprueft. Fruehere Dateien ohne `walk_only` waren Explorationsaufnahmen und koennen Crouch-Walk enthalten.
- Fire-Aufnahmen nutzen die echte bestehende Einsatz-Waffenanimation. Kopf-/Halsanschluesse zusaetzlich in -25/+25 Grad um die anatomische Hochachse geoeffnet.
- Native Mehransichten verwenden die gleiche 1920x1080-Dreispalten-Kamera und Beleuchtung wie der vorherige Root-Draft. Fixtures werden nur im Formvergleich ausgeblendet; die Funktionsprobe zeigt echte Waffen.
- Alle Prozesse nutzten `output/native_glut_maps/private_armor_profile/astra_r05` als APPDATA. Die Live-Blender-Sitzung und Nutzer-Saves blieben unberuehrt.

Wichtige native Artefakte unter `output/native_glut_maps/`:

- `armor_r05_native.png`, `_quarter.png`, `_side.png`, `_rear.png`, `_top.png`.
- `r05_revision_armor_walk.png`, `_fire.png`, `_head_turn.png`, `_front.png`, `_rear.png`.
- `armor_r05_walk_only_feet_015.png`, `_042.png`, `_070.png`.
- `armor_r05_neck_turn_-25.png`, `armor_r05_neck_turn_25.png`.
- `armor_r05_fit_rest.png`, `_idle.png`, `_walk.png`: Originalkoerper und Ruestung mit Gelenkmarkern, beide Rigs.
- `armor_r05_rig_test.gd_native.log`, `armor_r05_rig_test.gd_headless.log`, `armor_r05_walk_feet.gd_native.log`.

## Grenzen und Qualitaetsurteil

Dieser Stand ist gegenueber R04 und den verworfenen fruehen R05-Staenden deutlich naeher an der gewuenschten Formsprache: klarere Helmkoerper, gewoelbte Brust-/Arm-/Beinschalen, kleinere Frontabstaende, angehobene Schulterkappen und geformte Schuhe. Die geprueften Walk-/Fire-/Headturn-Staende zeigen keinen neuen klaren Sitzfehler. Das ist eine begrenzte technische und gestalterische Kandidatenempfehlung, keine aesthetische Nutzerabnahme.

Restunterschiede zur Bildtafel: Der feste Kenney-Koerper und seine Idle-Pose sind keine deckungsgleiche Rekonstruktion der KI-Zeichnung. Das transparente Visier und die staerkeren Kinnschalen folgen den spaeteren Nutzerkorrekturen. Die native Beleuchtung ist haerter als das gemalte Zielbild; kleine sichtbare Facetten und Ueberlappungen der Bauchlamellen bleiben. Sitz-/Transportextreme, alle denkbaren Kampfclips und eine breite Performance-/FPS-Abnahme wurden nicht geprueft. Die produktive importierte Assetroute samt finalem Equip-/UI-Verhalten prueft Root separat.

Keine produktiven Dateien, Gameplay-Contracts, EXEs oder Main-Integrationen wurden durch diesen Modellierungsagenten geaendert; keine Commits oder Pushes.
