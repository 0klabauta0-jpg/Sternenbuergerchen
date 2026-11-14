# A*/HPA C++ GDExtension prototype — 14.11.2026

## Ziel und Ursache
Expliziter Nutzerauftrag: einen A*/HPA-Prototyp bauen und tatsaechliche Laufzeit sowie identisches Verhalten gegen den bestehenden GDScript-Pfad pruefen. Navigation ist laut begrenzter November-Messung teuer; ein Sprachgewinn ist bisher unbewiesen.

## Basis und Umfang
Eigener Branch `task/native-navigation-prototype-20261114`, bewusst auf dem noch nicht gemeinsam integrierten Reviewstand `9e2e972a1010d10fa5cdc0c08bd588bea5128173`. `integration/core-foundation` hat aeltere Navigationsquellen. Fremde Working-Tree-Aenderungen werden nicht uebernommen.
Opt-in C++-Kern fuer A*, gerichtete lokale Dijkstra-Karten und HPA-Portalsuche. Ein Adapter materialisiert exakte gerichtete Kosten mit bestehenden GDScript-Regeln; Snapshotaufbau und Uebergabe werden mitgemessen. Ein Snapshot pro Adapter, revisions-/identitaets-/optionsgebunden. Ergebnis-Cache wie bestehender HPA-Pfad maximal64 FIFO-Ergebnisse, defensive Rueckgabe. Keine Gameplay-Autoritaet im nativen Kern.

## Nicht-Ziele
Keine automatische Umschaltung der Produktion, kein Mainmerge, kein Spieleexport, keine GPU-/FPS- oder vollstaendige Multiplayerfreigabe. Keine neue Kostenformel oder Behauptung allgemeiner HPA-Optimalitaet.

## Vertraege und Quellen
- docs/ARCHITECTURE.md; docs/dev/hex_grid_v1_contract.md
- docs/tasks/UI_2026_11_02_a5_kartenrand.md
- docs/qa/mission_a5_kartenrand_20261102/README.md
- scripts/terrain/terrain_pathfinder.gd; hpa_pathfinder.gd; hpa_navigation_graph.gd

## Akzeptanz
1. Godot4.6.2 laedt die selbst gebaute Windows-x64-GDExtension.
2. Vollstaendige geordnete Pfade, HPA-Status und Scores entsprechen unveraendertem GDScript fuer Hex/Square, gerichtete Rampen, Blocker, Kostenoptionen, negative Koordinaten, Fehler und Cache-/Revisionsfaelle.
3. Nicht unterstuetzte Eingaben fallen explizit auf GDScript zurueck und werden nicht als native Erfolge gezaehlt.
4. Wiederholte Messungen zeigen kalte Gesamtkosten, warme neue Ziele und echte Ergebnis-Cachetreffer getrennt, inklusive Datenuebergabe. Rohwerte und Umgebung werden aufbewahrt; langsame Faelle bleiben sichtbar.
5. Vergleich und Regressionen seriell in einer isolierten Minimalprojekt-Kopie ohne Spielerprofile/Assetimport.

## Betroffene Dateien und lokale Pruefung
`native/navigation/`, `scripts/terrain/native_navigation_prototype.gd`, gezielte Verifier/Benchmark unter `scripts/tests/`, Task/QA/Status-Dokumentation. Buildskript, Differentialverifier, unveraenderte Hex-/HPA-Nachbarn, wiederholter Benchmark und `git diff --check`.

## Risiken/offen
Snapshotmaterialisierung kann einmalige/kurze Wege verlangsamen. Native double-Berechnung und Engine-float-Heuristik muessen dieselbe Reihenfolge behalten. Cacheinvalidierung ist korrektheitskritisch. Compiler-/Bindings-/DLL-Versionen werden gepinnt. Nur Windows x64 wird hier gebaut und gemessen.

## Abschluss und Entscheidung
Akzeptanz 1–5 im beschriebenen Testumfang erfuellt. Finaler Verifier 921/0,
unveraenderter Hex-/HPA-Nachbar 41/0; fehlende-DLL-Negativtest schlug erwartungsgemaess fehl.
Zwei akzeptierte statische Laeufe liefern 486/486 identische Ergebnisse; zusaetzlich
16/16 bei wechselnden Bewegungsoptionen. Pfad, Status und Scores stimmen exakt.
Die unabhaengige Quellen-/Evidenzpruefung fand keine blockierenden Befunde.

GM01, Median in ms: A* warm 259,568 -> 0,4225; HPA warm 246,893 -> 7,4465.
HPA kalt 477,145 -> 1046,925; wechselnde Optionen 149,7165 -> 978,075.
Der warme Gewinn umfasst C++ und vorab materialisierte Kosten, keinen reinen
Sprachvergleich. Bei wechselnden Kosten dominiert Snapshotaufbau. Entscheidung:
**KEEP_OPT_IN**, keine Produktionsumschaltung. Eine spaetere Umsetzung sollte
Terrain-Snapshot und anfrageabhaengige Kosten trennen und erneut messen.
Diagnosezaehler sind backendabhaengig und gehoeren nicht zur Gameplay-Paritaetszusage.
Windows x64 ist die einzige gebaute Plattform. Keine allgemeine FPS-Aussage.

Details, Rohdaten, Quell-/DLL-Hashes, Buildnachweis und Wiederholungsschritte:
`docs/qa/native_navigation_20261114/README.md`; `native/navigation/README.md`.
