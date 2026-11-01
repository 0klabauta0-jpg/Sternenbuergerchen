# Buccaneer Pass04 R02

Zwei eigene Formen-/Look-Iterationen nach der Nutzerkritik an den zu
gleichmaessigen Rohren, der Bleistiftkanzel und den Brettfluegeln. Ausschliesslich
Buccaneer; Pass04 R01, Cutlass und das Pass04-Strukturpaket bleiben unveraendert.
R01-Generator/Quelle/Export werden im Manifest mit ihren alten Hashes geprueft.

| Stand | Dreiecke | Materialien im GLB | Editierbare Teile | Status |
|---|---:|---:|---:|---|
| I01 | 13.604 | 8 | 74 | erhaltener Formenvergleich, Source-QA bestanden |
| I02 | 17.324 | 10 | 76 | aktueller eingefrorener Kandidat, Source-/Fresh-GLB-QA bestanden |

Aktueller Export:
`Assets/curated/frontier_illustrated_20261101/ships_pass04_r02/buccaneer_01.glb`.
Quelle: `source/buccaneer_01.blend`, 8.792 Source-Vertices. Der Export hat ein
Mesh/einen Node, 869.120 Bytes, keine Animation/Skin/Textur/Kamera/Licht.

```text
GLB SHA-256  4b33257d1610b5ccb0a287482f025b262f35bea2bfd12f4f8d78e6cf8a180c62
BLEND SHA-256 1c9c6212a6df82a5c82b7ce65860723c2a7236c2db05f885f010311cca446ea3
```

BBox Blender X/Y/Z: 13,8452 / 11,0000 / 4,5634 m. Die Laenge 11 m ist eine
bewusste stilisierte Normierung, keine kanonische Star-Citizen-Abmessung.
Gesamte BBox in XY zentriert, minZ=0 auf statischen Aufstellfuessen. Blender
vorne -Y / Godot vorne +Z; uebernommener Runtime-Scale 0,22. Keine Collision,
Navigation, Flug-, Waffen- oder Landemechanik.

## Bildvergleich und Formen

Aktuelle Hauptziele erneut gross geoeffnet:

- `docs/reports/assets/grafik-2026-11-01/13_buccaneer_vorne_wimmel_vereinfacht.png`
- `docs/reports/assets/grafik-2026-11-01/11_buccaneer_hinten_wimmel.png`

Hashes stehen im Manifest. Das sind die zugeordneten 2D-Ziele; der Kandidat
ist eine neue eigene Geometrie, keine uebernommene originale SC-/Kenney-Datei
und keine Umfaerbung der alten OBJ-Materialstudie.

I01 fuehrt geformte dunkle Einlasskoerper mit tiefem offenen Hals, teilweise
offene gebogene Cowls, eine kuerzere breitere Kanzel, gepfeilte dicke Fluegel
und eine grosse Dorsalkanone ein. Die Sichtung zeigte noch lange gleiche
Cowlbereiche, ein aufgesetztes Fluegelpaneel und einen verdeckten warmen
Heckring. Der kleine Montageabstand zweier Fluegelanschluesse wurde korrigiert.

I02 gliedert die Cowl axial mit eingeschnuerter schwarzer Halszone und
kuerzeren Schultern. Die Scheiben liegen 5,2 cm hinter echten Rahmenflanken.
Die Fluegel haben nun eine dicke geformte Hauptflaeche; elfenbeinfarbenes
Aussenfeld, ockerfarbene Wurzelzone und dunkler Rand sind Polygonmaterialien
dieser Flaeche. Es gibt keine aufgeklebte helle Brettplatte. Der hintere
Kern endet vor der tiefen warmen Ringzone; sechs dicke Lamellen je Duese
bleiben gut abgesetzt. Wenige breite Gebrauchsfelder, breitere mehrstufige
Fasen und insgesamt acht befestigte Nietenkoepfe ergaenzen die Hauptformen.
Fluegelnieten sind auf die tatsaechlich triangulierte Oberflaeche geraycastet.

Pro Iteration vorne, hinten, Spielabstand, oben, Zufallsfarben und Wireframe
gerendert und geoeffnet. Die Kamerarichtungen bleiben R01-kompatibel:
vorne38/32 Grad, hinten-142/32 Grad, Spiel24/50 Grad; Spiel-Welthoehe12 bei
Scale0,22. Der frische I02-GLB wurde zusaetzlich vorne/hinten/Spielabstand
gerendert und geoeffnet. Workbench zeigt Form/Palette, keine native Godot-
Beleuchtungsabnahme. Die native Integration und deren Bilder besitzt Root.

Ein unabhaengiger Bildblick durch `current_visuals` fand keine groben
sichtbaren offenen Loecher, schwebenden Baugruppen oder Front-/Heckverwechslung.
Verbleibender Zielabstand: Cowls sind noch regelmaessiger/zylindrischer als
die kantiger ineinandergeschobene Illustration. Glas und helle Felder wirken
in Workbench dunkler; feine gemalte Lackspuren fehlen. Kleine Aufstellfuesse
sind originale vereinfachte Stuetzen, keine kanonische SC-Landekonstruktion.
Dies ist keine gestalterische Nutzerabnahme.

## QA und Reproduktion

Blender 5.2.3 LTS, unveraendertes `blender-asset-qa/qa_check.py`, gesamte
Source-Baugruppe mit Profil `game`, keine uebersprungenen teuren Checks.
I01 und I02 final: **0 Fehler / 0 Warnungen**. UV-Pruefung absichtlich aus,
weil die Palette konstant und untexturiert ist.

Frischer I02-GLB-Import aus leerer Blender-Szene ohne Geometriereparatur:
Source-/Importpositionen beidseitig exakt (0 m), Materialdreieckszahlen
identisch; Positionen und Normalen endlich. Maximale Ecknormalenabweichung
0,000012007, unter der geprueften Grenze0,0001. Source-Ecknormalen werden
explizit in den zusammengefuegten GLB uebernommen. Einzige akzeptierte
Roundtripwarnung: 14.088 doppelte Positionen an gewollten Material-/Normalen-
Attributnaehten, keine losen Vertices. Kein Reparaturschritt nach Import.

Fehlgeschlagene Montage-Rohpruefungen bleiben als solche benannt erhalten;
sie sind keine finale Evidence. `manifest.json` prueft die aktuellen
Source-/GLB-/Bild-/Helfer-Hashes und die unveraenderten R01-Originale streng.

Vom Projektroot, erste vier Aufrufe mit Blender:
`--background --factory-startup --python-exit-code 1 --python <skript> -- <iteration>`.

1. `generator/build_buccaneer.py -- 1`, dann `generator/review_buccaneer.py -- 1`
2. `generator/build_buccaneer.py -- 2`, dann `generator/review_buccaneer.py -- 2`
3. Normales Python: `generator/finalize_manifest.py --stage`
4. Blender: `generator/verify_roundtrip.py` ohne Iterationsargument
5. Normales Python: `generator/finalize_manifest.py`

Alle Skriptpfade relativ zu diesem Verzeichnis. Build-/Review-/Roundtrip-
Ausgaben fuer neue Belege in die entsprechenden im Manifest genannten
Logdateien umleiten. `--stage` kopiert ausschliesslich den lokal geprueften
I02-Kandidaten in die neuen R02-Zielpfade. Finale Manifestpruefung kopiert
und veraendert keine Modelle. Kein Godot-Import oder Commit durch diese Tools.
