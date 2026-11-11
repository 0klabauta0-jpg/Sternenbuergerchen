# Hex-Terrainkomposition und explizite Rampen

## Ziel und Ursache
Die aktuellen A/B/C-Kandidaten zeigen lange gleichmaessige Hoehenbaender und
zu wenige lesbare Grossformen. Der Nutzer wuenscht mehr Hoehenebenen,
Steilklippen, Details und zusammenhaengende Struktur nach den vorhandenen
A/B/C-Referenzen; keine isolierten Einsernadeln.

## Umfang und Nicht-Ziele
Deterministischer Offline-Compiler fuer drei separate 512x256-Kandidaten.
A: verzweigte Trockentaeler und asymmetrische Tafelberge. B: gestaffelte
Felsruecken, breite Handelsachse und Umfahrung. C: Missionsterrassen,
Felsspalten, erhaltene Bruecken und H6/H8-Hintergrundmassen.
Explizite Vollhex-Rampen mit ebenen Zwischenpodesten. Missionsidentitaeten,
Padanker, Ressourcen, Container und persistente Objektfootprints erhalten.
Die bestehenden Depotverschiebungen B+66q/C+91q bleiben bestehen.
Keine Live-JSON-, Runtime-, View-, Kampagnen-, Save- oder Gefechtsaenderungen
in diesem Teilauftrag. Keine grossen Tests oder Benchmarks.

## Basis und Vertraege
Bewusste Fortsetzung auf task/native-glut-maps-20261110. Authoringquelle bleibt
639a49d657086c9e436de89979fa04cc5d69ba39. Pflichtdokumente gelesen, dazu
graphics_reference_revision_contract.md, explicit_hex_ramps_contract.md,
hex_grid_v1_contract.md, terrain_truth_visual_audit_contract.md und
MAP_WORLD_REBUILD_2026_11_10.md. Originalauftrag und 512x256-Bildquellen im
Glut-Paket vom 10.11.2026 wurden tatsaechlich geoeffnet.

## Akzeptanz
- Genau 131072 eindeutige Hexfelder pro Karte, H0 bis maximal H8.
- terrain_height_rules=explicit_hex_ramps_v1, alle Plateaus ramp_direction=-1.
- Rampen direction0..5, untere HoeheH, obereH+1; beide Anschlussfelder
  auf gleicher Endpunkthoehe. Nach aktueller Nutzerkorrektur bilden benachbarte
  Rampen breite Baender: seitliche Rampenkanten teilen H+0.5, normale
  Plateauklippen erhalten keine automatische Freigabe.
- Keine isolierten objektlosen H1-Pins; breite zusammenhaengende Gipfelflaechen.
- Enge Datenpruefung von Missionsankern, Footprints, Bruecken und verbundenen
  Haupt-/Nebenrouten. Keine Behauptung nativer Spiel-/Performanceabnahme.
- Herkunft/SHA256, Datenansichten und empfohlene native Kameraanker dokumentiert.

## Betroffene Dateien
scripts/tools/build_native_glut_ground.py; dieser Task;
art/hex_terrain_composition_20261111/;
output/native_glut_maps/explicit_ramps_candidate/.

## Lokale Pruefung
Kompilierung, deterministischer Wiederholungshash und begrenzte Python-
Datenpruefung. Referenzen und erzeugte Datenbilder visuell ansehen. Native
Godot-Aufnahmen erfolgen ausschliesslich koordiniert durch den Root-Agenten.

## Risiken und offene Punkte
KI-Referenzen besitzen keine metrische Kameramatrix. Datenansichten zeigen
Komposition und Hoehen, keine native Material-/Lichtabnahme. Feldreservierung,
Gefechte, grosse Matrizen, Save-/Multiplayer-/Performanceabnahme bleiben spaeter.

## Umsetzung
Asymmetrische, ueberlappende Tafelberge mit breiten H6/H8-Kronen und direkten
mehrstufigen Steilwaenden statt regelmaessiger Einzelstufen. Vorgegebene
Missionsanker bleiben die festen Ortskerne; neue Tal- und Umfahrungsschleifen
verbinden die regionale Landschaft. Jeder normale Aufstieg ist fuenf Hexfelder
breit, mit fuenf flachen Feldern zwischen zwei Anstiegen. Je Karte ein
gewundener Aufstieg mit 60-Grad-Richtungswechseln auf Podesten sowie eine
zusammenhaengende Eckrampe mit direkt benachbarten Richtungen2/1.
Je Karte maximal72 neue vorhandene Glut-Felsprops; keine neue Assetklasse.

Ergebnis, deterministische Hashes, Referenzen und native Kameraempfehlungen:
art/hex_terrain_composition_20261111/README.md und manifest.json.
Eigene Dateien uncommittiert; keine Livekarten, Runtime- oder View-Dateien
veraendert. Root koordiniert native Sichtkontrolle und weitere Integration.
