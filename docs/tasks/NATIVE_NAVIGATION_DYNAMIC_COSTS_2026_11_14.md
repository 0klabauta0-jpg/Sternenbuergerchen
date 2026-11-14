# Native Navigation: wechselnde Kosten ohne Vollaufbau — 14.11.2026

## Ziel / Ursache
Nutzerfrage: Laesst sich der teure Neuaufbau bei wechselnden Optionen optimieren?
Der erste Prototyp braucht auf GM01 etwa 978 ms pro wechselnder Anfrage, davon
etwa 975 ms fuer die Vorbereitung. Sein Snapshot-Key enthaelt alle Optionen.
Stabile Terrain-/HPA-Daten sollen erhalten bleiben; anfrageabhaengige Kosten
werden in C++ bedarfsgerecht ausgewertet.

## Basis / Umfang / Nicht-Ziele
Branch `task/native-navigation-dynamic-costs-20261114` baut bewusst auf dem noch
nicht integrierten Prototyp `7a7cf80e3` auf. Der vorherige Messstand bleibt in Git
und seinen unveraenderten Rohdaten erhalten. A*, Dijkstra und HPA teilen dieselbe
gerichtete Kostenberechnung; Revisionen und Identitaeten invalidieren abgeleitete
Daten. Optionen starten einen neuen Anfragekontext, keinen Terrain-Neuaufbau.
Keine Produktionsumschaltung, Mainintegration, neue Kostenformel, EXE oder
allgemeine FPS-/Multiplayerfreigabe.

## Vertraege / Dateien
`docs/ARCHITECTURE.md`, `docs/dev/hex_grid_v1_contract.md`,
`docs/tasks/NATIVE_NAVIGATION_PROTOTYPE_2026_11_14.md`,
`docs/qa/native_navigation_20261114/README.md`.
Betroffen: `native/navigation/`, `scripts/terrain/native_navigation_prototype.gd`,
gezielte Verifier/Benchmark unter `scripts/tests/`, neue QA- und Statusdokumente.
Produktive GDScript-Implementierungen bleiben unveraenderte Referenz.

## Akzeptanz / lokale Pruefung
1. Unveraenderte geordnete A*/HPA-Pfade, Status und exakte gerichtete Kosten gegen
   GDScript bei Hex/Square, Rampen, Blockern, Cover, Exposure/LOS, Korridor, Lane,
   Clearance sowie wechselnden Optionen auf demselben Adapter.
2. Optionswechsel wiederverwendet Terrain-/HPA-Snapshot; Revisionen, Registry-
   und Graphwechsel bleiben korrekt. Keine Rueckgabe veralteter Suchkosten.
3. Gemessene Gesamtzeit inklusive Vorbereitung und Uebergabe; kalter Erstaufbau,
   stabile Optionen, Wechsel und Ergebnis-Cache getrennt. Gleiche Fixtures;
   zwei akzeptierte serielle Messlaeufe, Rohwerte und Build-/Quellhashes.
4. Fehlende/ungueltige Native-Daten werden explizit behandelt. Native-Nutzung
   wird geprueft; keine GDS-Fallback-Zeit als native Verbesserung ausgegeben.
5. Native Build, Differentialverifier, Hex-Nachbarregression, `git diff --check`.

## Risiken / offene Punkte
Gleiche Float-Reihenfolge und Godot-Vector2-Rundung sind fuer exakte Pfade wichtig.
Hex-LOS und gerichtete Rueckwaertskosten brauchen gezielte Pruefung. Caches sind
abgeleitete Daten; Registry/Simulation bleiben autoritativ. Nur Windows x64.
Performancegewinn wird erst nach Messung beziffert.

## Ergebnis
Umgesetzt und gezielt geprueft: Terrain/HPA-Snapshots bleiben bei Optionswechseln
erhalten, native Anfragekosten werden bedarfsgerecht mit Generationsstempeln
berechnet. 1381/0 Differentialpruefungen, 41/0 Hex-Nachbarn, alle 550 Messpaare exakt.
GM01 bei denselben wechselnden Optionen: Median 978,075 -> 4,173 ms; gleichzeitig
gemessenes GDScript 137,775 ms. Acht Anfragen inklusive Erstvorbereitung brauchen
309,030/318,455 ms statt 1311,001/1318,092 ms im GDScript-Vergleich.
Einzelner kalter Erstaufruf bleibt langsamer (284,410 vs 131,090 ms; nur 2 Samples).
Unabhaengige Quellenpruefung ohne Blocker. Native Build und Hashpruefung gruen.
Opt-in beibehalten; Folgeintegration muss Erstaufbau/Revisionen und reale
Bewegungsanfragen beruecksichtigen. Keine Produktionsumschaltung.
Details und Grenzen: `docs/qa/native_navigation_dynamic_costs_20261114/README.md`.
