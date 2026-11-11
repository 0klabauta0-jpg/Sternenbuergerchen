# R05 — gewölbte körperfolgende Rüstung

11.11.2026. Produktiv im isolierten Branch `task/native-glut-maps-20261110`,
auf dem bisherigen Taskstand `290fa0fb6`; kein Main-/EXE-Schritt.

## Änderung und Ursache

Die verworfenen nativen Entwürfe wirkten wie flache aufgesetzte Tafeln.
R05 verwendet tatsächlich gewölbte Querprofile mit zurücklaufenden Seiten
an Brust, Schultern, Unterarmen und Beinen. Keine Vergrößerung der Körper,
keine Rigänderung. Lokale Körperbounds ersetzen pauschale Schulterbreiten
für Tiefenfits; Schulterkappen rücken zum Schultergelenk. Untere Bauchplatten
folgen als ganze zusammenhängende Schalen Spine/Hips, statt allein Chest.
Leicht und mittel besitzen feste Wangen-/Kinnschalen und klare geschlossene
Visierflächen. Schwer hat ein integriertes dunkles Visier und hohen Kragen.
Das folgt den neuesten Nutzerkorrekturen, auch soweit ältere 2D-Tafeln abweichen.
Die Darstellung beweist keine neue Vakuum-/Lebenserhaltungsmechanik.

Eigene Blender-Quelle, Builder und QA: `art/armor_kenney_r05_20261111/`.
30 GLBs unter `Assets/curated/personnel/armor_kenney_r05_20261111/` stimmen
SHA-256-genau mit dem finalen Blender-Manifest überein. Die produktive Route
lädt importierte PackedScenes; der private Kandidat verwendete GLTFDocument.
Die neue komponentenweise Bauchzuordnung bleibt dabei erhalten.
Gameplay/Inventar bleiben bei ihren bisherigen Ownern. Ein gecachter Mesh
pro Outfit, keine per-frame Geometrieerzeugung.

## Aktuelle Produktionsprüfungen

- Godot4.6.2, frischer Headless-Editorimport: Exit0, keine Script-/Importfehler.
- `personnel_armor_visual_test.gd`: Headless132/0 und nativ132/0.
  Beide vorhandenen Rigs, echte Walk-Animation, Fire, Rückseite, Kopfdrehung,
  Ausrüstungswechsel, unveränderter Originalkörper, Mesh-/Skin-Cache,
  transparente Visiermaterialien und Spine/Hips-Artikulation.
- `campaign_suit_equipment_test.gd`: Headless15/0, nativ16/0.
  Tatsächliche Inventarbuttons, endliche Rüstungsbestände, Blueprint-Fixture,
  Ablegen/Rückgabe und reale Basisprojektion. Kein behaupteter erster
  Kampagneneinsatz als Blueprint-Nachweis.
- Dreiklassenvergleich nach produktivem Import: drei Modelle, fünf Ansichten,
  gleiche Kamera und Beleuchtung wie R04, Exit0.
- `runtime_metrics.json`: leicht15 Segmente/5.020 Dreiecke,
  mittel15/5.608, schwer20/6.736; jeweils fünf Materialflächen und ein
  positives Knochengewicht je Vertex,45 Skin-Binds Basis/58 Einsatzproxy.
- Astra-Kandidat separat: Blender30/30 ohne Geometriefehler, private
  Headless-/Nativeprüfungen jeweils124/0. Material-/Wire-Kontaktbögen liegen
  im Quellordner. Akzeptierte Blenderwarnung: zentrierte Wearable-Pivots;
  diese werden beim Zusammenbau an den vorhandenen Bones positioniert.

`production_pose_*`, `native_*` und `armor_actual_*` zeigen den importierten
Produktionspfad. `candidate_*` enthält ausdrücklich zusätzliche private
Diagnoseaufnahmen des exakt übernommenen Modells: Walkphasen.15/.42/.70,
beidseitige Kopfdrehung und Originalkörper-/Gelenkvergleich. Kandidat und
Produktion werden nicht als derselbe Testlauf ausgegeben.
Die geöffneten Stand-/Lauf-/Kopfdrehungs- und Inventarbilder zeigen keine
neuen klaren Anschlussfehler. Bauchlamellen überlappen bei Kompression.

Alle Spieltests verwenden ausschließlich private APPDATA unter
`output/native_glut_maps/`; keine Änderung an Nutzersaves oder Live-Blender.
Bekannte Altwarnungen: zwei Homebase-UID-Fallbacks; Editorimport mit
Asset-Placer-UID-Fallbacks und ObjectDB-Exitwarnung. Kein pauschaler
Editor-/Release-Gesamt-PASS.

## Bildvergleich und Grenzen

`docs/reports/armor_comparison_20261111.html` vergleicht die bestätigte
2D-Richtung mit R04 und R05, einschließlich synchroner Blickrichtungen,
Graustufen, lokaler Notizen/Entscheidungen und JSON-Export/Import.
Ganze Figuren auf derselben sichtbaren Höhe, keine verdeckende Exportleiste.
Neuere Helm-/Wölbungskorrekturen sind sichtbar als Vorrang vor den Tafeldetails
gekennzeichnet. Browserprüfung104/0: alle45 Varianten-/Klassen-/Ansichtskombinationen
mit gleicher vollständiger Figurenhöhe, Dialog/Graustufen/Notizen,
JSON-Download/-Textfallback, gültiger und abgelehnter Import, Desktop1600×1000
und Mobil390×844 ohne horizontalen Überlauf. workbench_roundtrip.json enthält
ausschließlich automatisierte Testurteile, keine Nutzerentscheidungen.

Der feste Kenney-Körper ist keine deckungsgleiche Rekonstruktion der
KI-Zeichnungen. Native Beleuchtung und Facetten bleiben härter als die
Bildvorlage. Die Nutzerabnahme des neuen nativen Stils ist offen.
Sitz-/Transportextreme, alle Kampfclips und breite FPS-Abnahme bleiben
separate Prüfungen. Fahrzeugmodelle bleiben zurückgestellt.

## Echtes B-Gefecht nach der R05-Übernahme

Ein zusätzlicher nativer versteckter Forward+-Lauf auf B/trade_outpost bei1×,
512×256, aus einer privaten Kopie desselben Post-A-Checkpoints:
37/0, acht tatsächliche Schüsse, keine Framezuordnungsfehler, Exit0.
Rohdaten und Log unter `battle/`; der Fensterhost blieb unsichtbar.
Kartenhash d3ab04a32a142a51ea20d180397b7cd9355dfa55452e2fc224fbd63f360624a7.
Checkpointquelle unverändert SHA256
9bb343088ee9ef04bba6575224ced8e2cc69563454eca4a1e0cf2e7cf4554b53f.
GO-Dispatch26,206ms; erste gemessene Bewegung nach2.244,788ms.
Das sind Ablaufmesswerte und kein isolierter Pfadsuchwert. Dieser einzelne
Funktionslauf belegt keine allgemeine FPS- oder Ruckelfreiheitsabnahme;
regionale Publikation/Kampagnenbeobachtung bleiben bekannte Performancearbeit.
Wiederholung mit dem vorhandenen `combat_frame_accounting_20261111/run_hidden_battle.ps1`,
Script native_glut_battle_profile.gd und privater APPDATA unter
output/native_glut_maps/profiles/r05-final/after-armor.
