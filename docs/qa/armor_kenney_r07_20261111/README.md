# R07 — native Produktionsintegration

Separater Kandidat auf task/native-glut-maps-20261110, auf R06(77bd2ccf8)
und GO-Fix5f8a6a3cb. Keine Main-/EXE- oder gestalterische Nutzerabnahme.
Die neue Körperform verbreitert Schultern und verjüngt die Taille; Kopfmaß
95/92/95Prozent um den Halsansatz, Hände/Füße und Rig bleiben unverändert.
30Wearables plus Referenzbody/Profile aus Blender5.1.1 übernommen; Runtime
nutzt den bestehenden Godot-PackedScene-Import, kein privater GLTF-Lader.
Originalmesh bleibt unter armor_source_body_mesh getrennt; Legacy-Spacehelm
nutzt seinen unveränderten Quelltransform. Kein kumulatives Equip-Skalieren.

Schulterkappe/Helmbreite aus nativer Front, Ziel und Messunsicherheit siehe
proportion_landmarks.json: Light0,896(Ziel0,898), Mittel1,187(1,195),
Schwer1,430(1,459). Maße sind Formhilfe, keine ästhetische Abnahme.
Outfits5052/5932/6964Dreiecke, je5Materialflächen. Body1029Verts/1604Tris.

Root-Produktionsprüfungen in Godot4.6.2 mit privaten APPDATA:
- Hauptverifier headless+nativ156/0: echte Rigs, Idle/Walk/Fire/Headturn,
  durchgängiger Body, Klassenwechsel, Face-Restore, Outfitcache.
- Body-/Original-/Spacehelmverifier headless+nativ165/0, maximale Blender-
  Korrespondenzabweichung2,71e-6Schulterbreiten; Hände/Füße0Displacement.
- Tatsächlicher Ausrüstungsweg headless15/0, nativ16/0.
- Native3Klassen×5Ansichten, Kamera/Licht unverändert. Root hat Quarter und
  tatsächliches Equipbild geöffnet. Weitere ±25°-/Walkansichten beim Artpaket.
- Offlinevergleich164Browserchecks/0Fehler,75Klassen-/Ansichtkombinationen,
  Desktop/Mobil, JSON-Export/Import/Notizpersistenz. Exportfixture enthält
  Testnotizen, keine Nutzerentscheidung. R07 ist neuester verfügbarer Kandidat.

Native Armor/Body/Comparison ohne Enginefehler oder Warnungen. Equipment hat
2bekannte Homebase-UID-Pfadfallbackwarnungen. Editorimport exit0 mit bekannten
Asset-Placer-UIDwarnungen und Plugin-Exit-Leakwarnung; dies wird nicht als
fehlerfreier kompletter Editorlauf umgedeutet. Kein breiter FPS-Beweis.
Helm-/Schulterübergänge bleiben kantiger als die gemalten Tafeln; Sitz- und
Transportextreme sind weiterhin offen. B-Gefecht wird getrennt geprüft.
