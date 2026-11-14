# Ergebnis der Modellaufbereitung

## Polygonzahlen
Gemessen an den in Blender geladenen Quellmeshes und den erneut importierten
GLB-Dateien, nicht nur an angeforderten Decimate-Zielwerten.

| Modell | Quelldreiecke | Exportdreiecke | Reduktion |
|---|---:|---:|---:|
| Prospector | 403.931 | 19.932 | 95,1 % |
| Vulture | 999.904 | 17.970 | 98,2 % |
| Caterpillar | 243.269 | 32.826 | 86,5 % |
| Gladius | 417.693 | 14.000 | 96,6 % |
| Hornet (vorhandene F7C-Quelle) | 287.335 | 15.840 | 94,5 % |

## Geometrie / Darstellung
Alle fuenf finalen Geometrieberichte melden `pass: true`, keine Fehler.
Die vier statischen Modelle wurden einschliesslich ihrer neuen UVs geprueft.
Caterpillar verwendet einfarbige Materialien ohne Texturen; ihre Geometrie-QA
lief ausdruecklich ohne UV-Pruefung. UV-/Textur-Authoring fuer die Caterpillar
ist dadurch nicht abgenommen.

Verbleibende akzeptierte Warnungen betreffen versteckte, entgegengesetzte
Kontaktflaechen: Prospector 7 Paare, Vulture 6, Hornet 38; Caterpillar insgesamt
6 Paare an Liftbefestigung und geschlossenen Klappen. Sie sind keine gleichseitigen
Z-Fighting-Flaechen. Wegen des geringen Anteils und zum Erhalt geschlossener
Geometrie bzw. beweglicher Bauteilgrenzen bleiben sie erhalten. Gladius ohne
Warnung. Kein gesamter Szene-/FPS-Performanceanspruch aus Polygonzahlen.

Silhouette aus Original und Kandidat verglichen; alle fuenf bleiben zuordenbar.
Die Aufbereitung entfernt kleine Leitungs-/Paneeldetails und nutzt sichtbar
facettierte Flaechen. Prospector und Hornet wirken im Rumpfzentrum weiterhin
detailreich/unruhig. Dies ist ein technisch gepruefter Reduktionskandidat,
keine behauptete gestalterische Nutzerfreigabe oder finale Originaltexturierung.
Die Materialfarben wurden neu gesetzt; Gladius oliv, Vulture gelb, die anderen
mit hellen Rumpf-/dunklen Struktur- beziehungsweise roten Klappenflaechen.

## Caterpillar-Mechanik
14 Meshbauteile, davon 10 beweglich: acht seitliche Frachtklappen,
eine Bugklappe, ein neues Liftdeck. Klappen um 90 Grad, Liftweg 0,30 in der
normierten 8m-Arbeitsfassung. GLB-Clip `Scene` oeffnet/senkt und schliesst/hebt
innerhalb von drei Sekunden. `Hull` und Liftfuehrungen bleiben fest.
Die Bild- und Transformpruefung betrifft diesen exportierten Demonstrationsclip.

Die Originalquelle hatte keine benannten Mechanikbauteile. Klappen stammen
aus der Quellhaut; Liftdeck und Fuehrung sind neu konstruiert. Keine Behauptung
eines originalgetreuen RSI-Lifts. Laufwege, Frachtauflage, Kollisionen und
Mitnahme von Personen/Fracht muessen beim spaeteren Gameplay-Einbau entstehen.
Der Schiffanker folgt dem statischen Rumpf; die neue seitliche Liftplattform
darf die Gesamtbounds asymmetrisch erweitern.

## Technische Nachweise
Unveraenderte Quellen per SHA-256, nichtleere Exporte, Blender-GLB-Roundtrip,
erneutes Oeffnen editierbarer Blender-Dateien und separater Godot-4.6.2-Import.
Die unabhaengigen Engineberichte, Datei-Hashes und nativen Aufnahmen liegen
in `godot_probe/final/`. Die genaue Abschlusszahl steht in dessen README.
Die Wireframebilder verwenden duenne Kanten ohne Miter-Spitzen; der erste
Review-Helper hatte nur im Diagnoseoverlay ueberlange Spitzen erzeugt.

## Lieferung / Grenze
`SternenBuergerchen_5_Schiffmodelle_2026-11-14.zip` enthaelt genau fuenf
editierbare Blender-Dateien und fuenf GLB-Dateien, passende Bilder und Messdaten.
`delivery_manifest.json` nennt Groesse und SHA-256 aller verpackten Dateien.
Rohmodelle, verworfene Zwischenstaende und Blender-Backups sind nicht Teil
dieses ZIPs. Keine Integration in Main oder in den November-Spielstand.
