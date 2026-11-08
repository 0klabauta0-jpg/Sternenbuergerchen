# R3: weniger Framehitches, naehere Kamera und klarere Vorbereitung

Stand: 7. November 2026. Basis Main `173a1e3c33b733a78a396a93db9cedf631d84998`.
Taskbranch `task/reference-polish-r3-20261106`. Main-Commit, Remoteabgleich und
frischer Main-Smoke werden nach der Integration getrennt in
`main_receipt.json` quittiert. Dieses Paket beschreibt die davor eingefrorene
gepruefte Variante; historische Ausgaben werden nicht umbeschriftet.

## Ergebnis und Messgrenze

Der gleiche native 90-s-Pfad mit fester Vergleichskamera34 hat jetzt9 statt
75-77 Frames ueber100ms; P99 sinkt von128-135 auf70ms. Die neue normale
Kamera22 erreicht P99=73ms und15 Frames ueber100ms. Beide finalen normalen
Spielrouten bestehen68/68 Checks, ohne Enginefehler, mit echten unveraenderten
Kameras waehrend der Messung, elf Runtime-Units und Simulation nahe60Ticks/s.

Einzelne Spitzen bleiben:164ms mit Vergleichskamera,177ms mit Produktkamera.
Die groesste beobachtete HUD-Aktualisierung kostet noch55.723 bzw.62.874ms.
Das ist keine allgemeine Ruckelfreiheits-, GPU-Budget- oder Releaseabnahme.

## Gleicher Vergleich, getrennte Kamerarolle

Godot4.6.2, echtes Vollbild3440x1440, Vulkan/Forward+, RTX4070TiSUPER,
Ryzen7800X3D, Display240.085Hz, VSync1, Physik60/max8 Schritte, normale1x-
Rate. Alle Displayproben der finalen Profile melden Fokus und Vollbild.
Ordentliche Move/GO-Auftraege alle12Wandsekunden; keine Actor-/Timer-/Fuel-
Patches, erzwungenen Ankuenfte oder Qualitaets-/Workloadreduktionen.
Prozess-, Frame- und Physikzeiten sind unterschiedliche Messgroessen;
verschachtelte Teilzeiten duerfen nicht addiert werden. GPU-Framezeiten
stehen in dieser Instrumentierung nicht zur Verfuegung.

| 90-s-Serie | Kamera | Frames | p50 / p95 / p99 ms | Max ms | >50 / >100 / >250 ms | Sim/Wand |
| --- | ---: | ---: | --- | ---: | --- | ---: |
| Frischer Vorlauf | 34 | 3162 | 21.687 / 77.390 / 135.478 | 281.806 | 445 / 77 / 1 | 0.991585 |
| Vorlauf wiederholt | 34 | 3148 | 20.748 / 78.849 / 128.271 | 210.299 | 524 / 75 / 0 | 0.997771 |
| Erste drei reine Performancefixes | 34 | 3303 | 23.387 / 65.573 / 107.195 | 169.908 | 448 / 42 / 0 | 0.999777 |
| Performancefixes wiederholt | 34 | 3884 | 18.125 / 57.675 / 103.197 | 192.464 | 297 / 44 / 0 | 0.998010 |
| Final, gleiche Vergleichskamera | 34 | 5062 | 14.700 / 42.328 / 70.357 | 163.575 | 128 / 9 / 0 | 1.000339 |
| Final, neue normale Kamera | 22 | 4828 | 15.371 / 43.411 / 72.958 | 177.310 | 157 / 15 / 0 | 0.999616 |

Die letzten beiden Serien enthalten die vollstaendige neue Szene und UI.
Der34er-Lauf stellt22 erst nach der kompletten Messung wieder her; seine
Nachherbilder zeigen somit die Produktkamera. Ein eigener nativer API-Smoke
nach dem Messfenster prueft Zoom/Pan/Rotation, die Wiederholungssperre des
Missionsframings und die Wiederherstellung der Bildkamera. Das ist kein
physischer Tastatur-/Maus-Playtest. Der lesende Kameraaudit meldet waehrend
der Messung keine Kameraaenderung und keine Kameraeingabe.

## Bestaetigte Korrekturen

- Theme-Overrides vergleichen echte vorhandene Werte/Ressourcen. Aktions-
  kacheln erhalten ihren finalen Stil direkt statt eines Zwischenstils.
- Der normale Fog-Scheduler bezahlt nicht nochmals einen zweiten Slice im
  anschliessenden Sync. Expliziter/Force-Pfad und aktuelle Ziel-LOS bleiben.
- Native A5-Controls besitzen ihre finalen Labels, Icons und Stile. Drei
  Legacy-Labelpfade sowie Primary-/GO-Polish setzen diese nicht mehr zurueck;
  Tooltips, Enhancementmetas, Bereitschaft, Gates und Callbacks bleiben.
- Bestehende native Teamkarten behalten ihre finalen Font-/Panel-/Minimawerte.
  Legacy-Initialisierung, versteckte Kompatibilitaetsdaten und Diagnose bleiben.
- Strategic-RAW reicht die bereits gebaute Density weiter. Sein Next-Loop-
  Readout baut die Quelle synchron lokal einmal statt2-4mal; jedes neue RAW
  liest frisch. Alter RAW-Text und alle Rekursionsguard-Kombinationen bleiben.

Es wurde keine zweite Gameplay-Wahrheit eingefuehrt. SimulationRoot,
Runtimekomponenten und Registries behalten Besitz und Commands. Die neue
Dekoration speichert ausschliesslich ihre visuelle Zell-/Transformprojektion.

## Vergleich mit den eigenen 2D-Zielen

Die Originale liegen byte-identisch unter `references/`. Spaetere
Nutzerkorrekturen haben Vorrang: begehbare Basis, kein erzwungener FOB,
Teamparameter links und die wirkliche Ref03-Cutlass statt gemalter Schiffsdaten.

| Bereich | Jetzt sichtbar naeher | Verbleibender Abstand zur Illustration |
| --- | --- | --- |
| Missionskamera | GM01 startet einmal mit22 statt global34; Figuren und lokale Gebaeudemassen sind groesser, der sichtbare Kartenrand draengt sich weniger auf. | Die Illustration ist dichter und staerker inszeniert; die Perspektive und Modelle wurden nicht neu gebaut. Andere Karten/Editor behalten34. |
| Szene | 62 zusaetzliche niedrige Pflanzen-/Gerollobjekte in zwei MultiMesh-Gruppen verbinden bestehende Ensembles. Vollstaendige Pads, Wege, Tueren und echte Zellgrenzen bleiben frei. | Keine neue hochdetaillierte Modellserie und keine erfundenen Hindernisse; grosse freie Sandflaechen bleiben. |
| Missions-UI | Alle neun Aktionen besitzen explizite Symbole; GO behaelt seine zweizeilige Beschriftung. Der linke Teamkopf hat keinen durchlaufenden alten Kartenteiler. | Layout und linke Parameter folgen den spaeteren Bedienwuenschen, nicht jedem gemalten Beispielwert. |
| Homebase | Personal und Trupp links, eigener Ausruestungsfokus, grosse passive Basisszene und breites Flugdeck darunter. 176px-Fokusportrait bei normalen Breiten,224px ultrawide. | Die Basisszene ist ein gekennzeichnetes statisches natives Bild mit echter Schiffsvorschau; sie behauptet keine laufenden Actors oder aktuellen Boardingpositionen. |

Root hat Originale sowie echte Vorher-/Nachher-PNGs direkt geoeffnet. Dies ist
eine technische und gestalterische Kandidatenbewertung, keine vorweggenommene
persoenliche Nutzerabnahme und kein erfundener Prozentwert fuer Referenznaehe.

[Mission vorher, Kamera34](raw/before/06_go_movement.png) ·
[Mission jetzt, Kamera22](raw/final/06_go_movement.png) ·
[Homebase vorher](raw/before/02_homebase.png) ·
[Homebase jetzt](raw/final/02_homebase.png)

## Gates und erhaltene rote Diagnosen

`binding/checks_latest.json` bindet40 unterschiedliche zuletzt gruene Gates.
Die grosse Matrix war zunaechst39/40: das alte Homebase-Gate fand korrekt ein
von176 auf160px geschrumpftes Fokusportrait. Ausschliesslich Bau-/Normalwert
wurden auf176 zurueckgestellt; alle drei betroffenen Homebase-Gates wurden
erneut ausgefuehrt und bestehen72/72,62/62 und203/203. Der39/40-Originalreport
bleibt unveraendert erhalten. Die uebrigen39 bestandenen Gates enthalten
auch die sieben zuvor roten Alt-Gates, Command-Batch, Authority, Maprand,
Editor/Picking, Hex-FoW und den ReadModel-/ActiveOrder-/Hidden-Reveal-Pfad.

Die neuen Komponenten zeigen unter anderem Theme52/52, Fog21/21,
native Labels90/90, Controller43/43, Strategic-Readout55/55 und
Primary-/GO-Stile142/142. Dynamisch wiederholte Guardassertions sinken beim
Next-Loop-GREEN mit der vermiedenen Quellaufrufzahl; alle sieben Faelle und
die RAW-/Guard-/Owner-Orakel bleiben. Parse-/Fixturefehler sind als solche
aufbewahrt und wurden nicht als Produkt-RED ausgegeben.

Welt:45/45 CPU und56/56 native GPU, zwei Winkel und acht PNGs. Die tatsaech-
lichen RenderingServer-MultiMesh-Transforms folgen ihren jeweiligen Zellen,
auch bei gleichzeitig bekannten und unbekannten Slots in derselben AABB.
Der native Bildvergleich behauptet keine Pixelidentifizierung jedes winzigen
Props. Reuse prueft echte Mesh-/Materialidentitaeten und eine selbst gebildete
Signatur; Wrapper-Reuse, manipulierte Signatur und Clusterreihenfolge sind
gesondert korrigiert/geprueft. Neue/ungueltige Plaene bleiben fail closed.

Finale native Homebasefixtures decken3440/1920/1600/1280 und schmale Navigation
ab; native Missionsfixtures3440/1920/1280. Schmalere logische Ansichten laufen
im echten Vollbild mit erhaltener Seitenrelation. Normale echte Owner-/Boarding-
Route und synthetische Presenterfixtures werden nicht gleichgesetzt.

Unabhaengige Reviews: Performance APPROVED scoped, UI/Kamera und Welt ohne
offene zusaetzliche P1/P2. Die spaetere Portraitkorrektur betrifft genau zwei
Groessenwerte und ist durch die frischen betroffenen Gates plus Vollbildbilder
gebunden. Eigene Review-/Testdateien ersetzen keine ausgefuehrte Enginepruefung.

## Schutz und Integration

Frische Byte-/Groessen-/mtime-Pruefung:1101 fremde ungetrackte Dateien,
437 bestehende Roster und der tatsaechliche Spielerroster unveraendert.
2230 finale Code-/Daten-/explizite Grafikinputs sind separat gepinnt.
Alle Enginelaeufe waren seriell, mit frischen privaten Profilen, Canary,
Roster-Guard, Exit0, Erfolgsmarker und ohne Fehler auf den grueneingestuften
Laeufen. Neue QA bleibt vom eingefrorenen alten Paket getrennt.

Main-Fast-forward und normaler Push sind ausdruecklich beauftragt. Ihr Beleg
folgt ausserhalb des eingefrorenen ZIPs; keine neue EXE, kein WAN-Test und
keine allgemeine Multiplayer-/Releaseabnahme gehoeren zu dieser R3-Serie.
