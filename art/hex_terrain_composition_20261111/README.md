# Glut: Terrainkomposition vom 11.11.2026

Status: separate gespeicherte Datenkandidaten. Keine Livekartenintegration,
keine native Grafik-, Gefechts-, Save- oder Performanceabnahme dieses Pakets.
Aufbau auf task/native-glut-maps-20261110; Authoringbasis weiterhin
639a49d657086c9e436de89979fa04cc5d69ba39.

## Gestaltungsrichtung
A zeigt verzweigte breite Trockentaeler zwischen asymmetrischen Tafelbergen.
Der zentrale bestehende Ort bleibt als Becken lesbar. Westlicher Randaufstieg,
oestlicher Aussichtspunkt und noerdliche H6-Terrasse geben der Talebene
konkrete erhoehte Ziele. B besitzt diagonal gestaffelte, teils verbundene
Felsruecken; Handelsachse, Suedschleife und obere Umfahrung trennen die
Regionen. C hat eine gewundene H2/H4-Missionsterrasse, erhaltene Spalten und
108 originale Deckfelder, zwei voneinander unabhaengige Missionsquerungen
sowie grosse H6/H8-Hintergrundmassen.

Die Referenzbilder wurden tatsaechlich geoeffnet; Herkunft und SHA256 stehen
in references.json. Die Datenplots A/B/C_composition_data.png zeigen die
tatsaechlichen gespeicherten Hoehen und wurden ebenfalls geoeffnet. Sie sind
ausdruecklich Konturdiagramme, keine Godot-Aufnahmen oder Ersatzkarten.
Gegenueber der Referenz bleiben die Missionsorte enger beieinander, weil ihre
Anker und funktionalen Footprints bewahrt werden. Die dichte kleinteilige
Erosion der KI-Bilder wird nicht durch Tausende Objektinstanzen nachgebaut.

## Rampen und Daten
Alle drei Karten enthalten genau512x256=131072 Hexfelder. Schema:
terrain_height_rules="explicit_hex_ramps_v1", regional_terrain_version=3,
regional_height_step=0.75, Plateaus ramp_direction=-1, Rampen0..5. Die
gespeicherte Rampenhoehe ist das untere EndeH, das obereH+1; benachbarte
Rampenseiten teilen gemaess aktualisiertem VertragH+0.5.

Normale Anstiege haben durchgehende fuenf Hexfelder breite Rampenbaender
und fuenf flache Felder zwischen den Anstiegen. Je Karte ist ein Aufstieg
auf den Podesten um60Grad gewunden. Zusaetzlich zeigt eine zusammenhaengende
Eckrampe direkt benachbarte Rampenrichtungen2/1 bei gleicher unterer Hoehe.
Diese Eckrampe ist eine erreichbare kleine Terrasse mit zusammenhaengender
Krone, keine einzelne H1-Nadel. Bestehende Plateauklippen bleiben gesperrt.
Die ganze hochliegende Hintergrundlandschaft wird dadurch nicht pauschal
begehbar; Rampen sind bewusst gesetzte Durchlaesse.

Missionsmarker, Patrouillen, Gegnerkonfiguration, singleplayer_site,
place_presentation, Projektionsdaten und semantische Objektfootprints sind
gegen die bisherigen Livekarten unveraendert. B+66q/C+91q-Depotverschiebung
und alle108 C-Deckzellen bleiben erhalten. Bestehende dekorative Felsen
bewahren ihre Positionen und folgen der neuen Terrainhoehe. Neu kommen
jeweils72 vorhandene glut_sandstone_04-Props an ausgewaehlten Klippenfuessen
hinzu. Es wird keine neue Modellklasse eingefuehrt.

## Enger Nachweis
manifest.json buendelt den zweiten bytegleichen Compilerlauf, Quellen- und
Kartenhashes, Hoehenverteilung, Rampenanzahl und einzelne Pruefdetails.
Pruefung: Zellmenge/Offsetkontur, Rampenendpunkte, bestehende Objektfakten,
alle Missionsmarker, Ressourcenanschluesse, Rampenein-/ausgaenge,
isolierte objektlose Erhebungen und C-Zielerreichbarkeit bei jeweils
gesperrter anderer Missionsbruecke. Das sind Offline-Datenpruefungen,
keine Behauptung realer Unitbewegung, LOS-, HPA- oder Save-Abnahme.

Reproduzieren:

```text
python scripts/tools/build_native_glut_ground.py A B C
python art/hex_terrain_composition_20261111/plot_composition.py
python art/hex_terrain_composition_20261111/audit_candidate.py --repeat
```

Der Compiler schreibt standardmaessig ausschliesslich nach
output/native_glut_maps/explicit_ramps_candidate. Das dortige JSON ist der
native Kandidat; die art-Dateien dokumentieren seine Herkunft und Geometrie.

## Empfohlene native Kameraanker
Axialkoordinaten(q,r), Kamera-Size im bisherigen Godot-Mass. Belichtung,
Materialroute und Kamerawinkel fuer Vorher/Nachher gleich halten.

| Karte | Motiv | Anker | Size |
|---|---|---|---|
| A | Gewundener oestlicher Aufstieg / Tafelberg | 125,37 | 48 |
| A | Mittleres Rampenband | 122,41 | 18 |
| A | Direkte Rampen-Innen-/Aussenecke | 111,50 | 18 |
| B | Gewundener Lager-Ausblick | 145,22 | 48 |
| B | Band am mittleren Podest | 142,21 | 18 |
| B | Direkte Rampen-Innen-/Aussenecke | 135,38 | 18 |
| C | H4-H8-Aufstieg zum Aussichtspunkt | 155,27 | 44 |
| C | H5/H6-Band | 152,31 | 18 |
| C | Direkte Rampen-Innen-/Aussenecke | 139,48 | 18 |
| C | Hauptaufstieg mit erhaltener Bruecke | 92,46 | 48 |

Die native Sichtkontrolle startet ausschliesslich koordiniert durch den
Root-Agenten. Groessere Tests sind gemaess Nutzeranweisung zurueckgestellt.
