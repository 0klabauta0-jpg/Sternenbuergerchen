# Native Karten des Glut-Systems

Auftrag: `C:/Users/bjoer/.codex/visualizations/2026/11/10/01a1c61f-714c-7b51-829d-277d83d7d62b/integration_handoff_20261110/INTEGRATIONSAUFTRAG.md`.
Basis: Main `639a49d657086c9e436de89979fa04cc5d69ba39`, enthält den Kampagnenumbau e4b407fe0 und die neueren Editor-/UI-Integrationen. Arbeitszweig `task/native-glut-maps-20261110`.

## Ziel und Umfang

A/B/C als dauerhaft gespeicherte 512 × 256 Hexkarten mit eigenen Geländeprofilen, erhaltenen Ortsidentitäten und überprüften Wegen. Sternkarte mit 256 × 256 Hexfeldern und drei Monden über dem bestehenden Reiseowner. Heimatbasis, Trainingskarten und Raumkampfregeln sind außerhalb des Umfangs.

## Verträge und Abnahme

Hex Grid V1, Terrain Truth Visual Audit, Graphics Reference Revision, Map Builder Tooling, Persistent Location Runtime und Orbit Quantum Travel. Betroffen sind die drei Orts-JSONs, der begrenzte Authoringpfad, Terrainprojektion, Sternsystemdefinition und die Reise-/Kartenansicht. Abnahme über gespeicherte Zellanzahl, Kanten/Picking, SaveAs, reguläre Ausflüge und Skirmish, native Bildvergleiche sowie Lastmessungen bei normaler Spielzeit.

## Risiken

Die Bildreferenzen liefern Komposition, keine metrische Vorlage. Die Downloadpakete haben lokal unbelegte Lizenz und Herkunft. Alte Basischeckpoints und Ortsressourcen benötigen nachgewiesene Kompatibilität. Erste A-Stufe hält aktive Ortsanker unverändert, um Lade-, Pfad- und Renderkosten isoliert zu messen.


## Umsetzung und Datenkompatibilität

- Gemeinsamer Compiler `scripts/tools/build_native_glut_ground.py A B C`.
  Der Ursprung sind die drei Git-Objekte der dokumentierten Basis.
  Die Ausgabe speichert pro Karte 131.072 unterschiedliche Axialzellen.
  Physische Kontur `Spalte = q + floor(r/2)` von −170 bis 341 und
  `r` von −108 bis 147. Weltprojektion und Hexeinheit bleiben beim V1-Vertrag.
- A verbindet eine breite Schlucht mit dem Lande- und Satellitenbecken.
  Objekt-Footprints und alte Interaktions-/Ressourcenkoordinaten bleiben
  erhalten. A/B/C entfernen die alten H1-Streumuster und isolierte
  H1-Erhebungen ohne Objekt. B erhält getrennte
  Bergrücken, einen Feldlandeplatz und das um +66 q versetzte Lager. Auf C
  liegt der um +91 q versetzte Chip-Außenposten auf H4. Zwei Brückendecks
  nutzen je die einzige begehbare Fläche ihrer gespeicherten Zellen.
- H0–H8 werden gespeichert, ausgewählt und im Editor bearbeitet. Die drei
  regionalen Karten verwenden 0,75 visuelle Einheiten pro Stufe. Die
  vorhandene Spanne des Höhenvorteils für Trefferwahrscheinlichkeit bleibt
  auf zwei Stufen begrenzt. Zwischen zwei begehbaren Geländefeldern ist
  genau eine Stufe in beide Richtungen begehbar. Rampen schließen mit
  gemeinsamen Eck- und Kantenpunkten an. Infanteriedarstellung, Auswahl,
  Raster und Nebel verwenden dieselbe Rampenfläche. Brücken werden auf
  gleicher Höhe betreten. Klippen und Blocker werden aus den Tile-Fakten
  gelesen. Der Fernüberblick ist bei ausgeschaltetem FoW verfügbar.
- Speicherkompatibilität folgt der legalen Basischeckpoint-Grenze.
  Checkpoints tragen keine laufenden Oberflächenakteure oder Orbitpositionen.
  Die Rückkehr zu alten Dateien erfolgt über unveränderte Standort-,
  Container-, Auftrags- und Marker-IDs. Ressourcenmengen und Entdeckung
  bleiben beim bestehenden Owner. Alte exportierte Editor-Karten lassen
  sich mit ihrem eigenen Raster weiter laden.
- Sternsystem V2 verwendet vier Himmelskörper plus Sonne und vier Zielorbits.
  `moon_orbit` bleibt Heimorbit, `planet_orbit` bleibt für C und den Notruf
  erhalten. `glut_1a_orbit` und `glut_1b_orbit` binden A und B.
  Der Reiseowner hält die gültige Hex-Nachbarkette und veröffentlicht eine
  normierte Projektion an die bestehenden Verbraucher. Die native Ansicht
  nutzt dieselbe Geometrie für Raster, Ringe, Oberflächenmarkierungen und
  Schiffsprojektion. Die bestehenden taktischen Begegnungsregeln bleiben
  am Raumgefecht.
- Grafiknachweise und Messprotokolle liegen lokal unter
  `output/native_glut_maps/`. Der Art-Quellenbeleg steht in
  `Assets/curated/glut_regional/SOURCES.md`.

## Nachsteuerung im Playtest

- Die Cutlass behält beim Aufsetzen die Richtung der Anflugachse. Die
  regionale Reisehöhe hat ein gemeinsames Datum und blendet in den
  Landeanflug ein. Strategische Fluglinie und Schiff folgen einer
  durchgehenden Kurve. Glut 1 ist im Überblick 19 Hexeinheiten breit,
  die Monde je 4,5. Die Eintrittszelle des Planetenorbits liegt auf
  dem erweiterten Gürtel, die Orbit-ID bleibt erhalten.
- Ortskarten werden während der Anfluganzeige eingelesen. Der
  taktische Blick startet am Landeanker. Für noch nicht gerenderte
  Teile des sichtbaren Ausschnitts wird keine Kartenklickauswahl
  angeboten. Die visuelle Nachladung beeinflusst die Simulation
  bereits gelandeter Trupps außerhalb der Kamera nicht. Bis zu 64
  fertige Nachbarausschnitte bleiben für Rückschwenks verfügbar.
- Links ist FT1 kompakter. Porträt und Profildaten stehen in der
  gemeinsamen Charakterkarte nebeneinander, mit größerer 3D-Figur.
  Die leichte Startrüstung trägt einen Missionsdatenträger. Ein
  optionaler Rucksack bietet nach Kauf und Anlegen zwölf zusätzliche
  Plätze. Bestehende Bestände und Rucksäcke bleiben zugänglich.
  Der QA-Bericht bündelt die Belege.
