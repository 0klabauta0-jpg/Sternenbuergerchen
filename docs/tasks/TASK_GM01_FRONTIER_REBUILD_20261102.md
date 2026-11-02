# GM01 mit Frontier-Grafik und echter Hexfläche neu bauen

## Status und Ziel
Implementiert und lokal verifiziert. Der Nutzer wünscht die regelmäßig gezeigte Standardmap mit den neuen Grafiken, anschließend mehr Platz und ausdrücklich echte Hexfelder mit dezentem Raster. Auch das kleinere dunkle Quadrat und sein schwarzes Aufblitzen sollen erklärt und korrigiert werden.

## Ursache und Sinn
Die alte reguläre GM01 nutzte nur das Frontier-Farbprofil über alter Stationskomposition. Das neue Außenpostenensemble existierte bisher als eigener Grafikpreview. Seine Geometrie musste mit gespeicherten Gameplayfakten verbunden werden. Das dunkle Quadrat stammte aus der Sichtmaske über einem größeren Boden; der temporäre Blackout wurde auch bei bekanntem Terrain eingeblendet.

## Basis und Umfang
Eigener Branch `task/gm01-frontier-rebuild-20261102`, bewusst auf noch nicht integriertem UI R4 `49220b59e` mit dessen Main-Grafikbasis `7f594530f`. Kein Maincheckout oder Release.

- Dieselbe reguläre Map-/Szenarioreferenz; Karte jetzt `GM01 Frontier Hex 48x48` mit2304echtenAxialzellen in48×48versetztenReihen. Ursprüngliche Modell-/Shaderanker unverändert, zusätzliche Versorgungshalle und Felszüge mit zwei breiten Zufahrten.
- Optionales versioniertes `authored_visual_layout_id`. Gemeinsamer konkreter Layoutbuilder liefert Geometrie/Hüllen; Offlineautorierung schreibt817Solidzellen und440begehbare Deckungsnachbarn. Runtimevisuals lesen nur. Keine Previewbürger oder statischen Schiffe; echte Cutlass bleibt im normalen Pfad.
- Polygonkontakt statt Square-Rasterung,6Nachbarn, negativeq gültig. Kamera/Panning/Picking/Minimap/Bounds und Roundtrip folgen tatsächlichen Tilepositionen. Geprüfter Rampentripel(6,24)H0→(7,24)H1/slope→(8,24)H1.
- Bekanntes Terrain ohne schwarzen Aufbaukasten; unbekanntes Terrain weiter geschützt, Maskenhöhe aus tatsächlichen Visuals. Standardmäßig sichtbare dezente Hexkanten.
- Feste Komposition im Editor gegen freies Bemalen/Löschen/Verschieben geschützt. Ansicht und unveränderter Save/SaveAs bleiben möglich; interner Hüllentyp kein Palettenasset.
- Nach Messung notwendige enge Performancekorrekturen: identische lokale Cover-Scores wiederverwenden; Radiusprüfung vor Walkability-/Covergettern; statisches Briefing bei identischen Inhalts-SHAs weiterverwenden. Dynamische Auswahl, Readiness, Loadout und Transportdaten bleiben aktuell. Keine Timeränderung. Veraltete UI-Prädikate auf bereits bestehende R4-Texte/Detailbedienung korrigiert.

## Nicht-Ziele
Keine neue Navigationsarchitektur, Waffen-/Gegner-/Transportregeln, Innenräume oder freie Multi-Cell-Platzierungsbearbeitung. Keine Actor-, HP-, Positions- oder Timerpatches für den physischen Nachweis. Kein Mainmerge, Export oder Release; keine vollständige Kampagnen-, Balance-, Mehrspieler- oder Langzeitabnahme.

## Relevante Dokumente
`docs/ARCHITECTURE.md`, `docs/dev/gm01_frontier_map_contract.md`, `terrain_truth_visual_audit_contract.md`, `hex_grid_v1_contract.md`, `graphics_reference_revision_contract.md`, Höhen-/Naturverträge und `html_report_workbench_contract.md`.

## Akzeptanz und lokale Prüfung
- [x] Regulärer Menü→Heimatbasis→Grid-Sweep-Dispatch lädt die neue gespeicherte Karte; kein CLI-/Previewfallback.
- [x]2304Hexzellen, unveränderte Szenariobytes mit8Gegnern/Taktiken/Zielradius96/Zeitlimit1200; legale tatsächliche Spawnabstände und breite A*/HPA-Verbindungen.
- [x] Gespeicherte Hüllen, Höhen und Deckung passen zur konkreten Geometrie; Renderer mutiert keine Fakten. Wiederverwendung und Aufräumen der Stage, Legacy-/Unknown-ID-Verhalten und Save/Load geprüft.
- [x] Kamera, negative Koordinaten, Minimap, echter Hexraster und Mehrframe-Sichtmasken geprüft; Unknownschutz erhalten.
- [x] Cachefälle gegen Legacyergebnisse/Reihenfolge geprüft; Sourceänderungen gleicher Größe und Zeit invalidieren Briefing korrekt. Loadoutcallbacks, Readiness, Boarding, Handoff und tatsächlicher Startbutton funktionieren.
- [x]24gezielte Engine-Gates/881Assertions;102Checks in zwei normalen zeitgesteuerten nativen Cutlass-/LZ-/Entlade-/GO-Läufen bei1920×1080 und1280×720. Finale ausgewählte Prozesse Exit0 ohne Script-/Leakfehler; eigene Userdatenverzeichnisse und bytegenaue Projektkonfigurationswiederherstellung.
- [x] Native Bilder angesehen; lokaler HTML-Report mit Erklärungen und JSON-Feedback. Node-DOM-/Exportprüfung separat von Browserlayout und Gameplay geführt.

## Betroffene Dateien
Map und Terrainkatalog; konkrete Frontier-Layout-/Authoringhelper; TerrainMapData/Registry/3DView; Editor- und Briefing-/Minimap-/Metaflowpfade; enges Combat-Scorememo und gated Profiler; gezielte neue und aktualisierte Verifier. Vollständige Quellenpins und akzeptierte Artefakte in `docs/qa/gm01_frontier_20261102/`.

## Risiken und offene Punkte
Es verbleiben UI-/Transport-Zeitspitzen; eine insgesamt flüssige Performance ist nicht abgenommen. Der32-Paar-CPU-Vergleich(20,8→2,4ms pro8Radiusabfragen) ist kein Gesamt-FPS-Nachweis. Raster-/Höhenklassen sind keine genaue Meshnavigation. Ein Bild des Osthofs beweist keinen tatsächlichen Truppmarsch dorthin. Verworfene Vorläufe, früh fehlende Profilisolation und ein abgelehnter Profilierlauf mit Exitwarnung sind imQA-README offen abgegrenzt.

## Nachweise
`docs/qa/gm01_frontier_20261102/VERIFIKATION.json`, `SOURCE_SNAPSHOT.json`, `STALE_GATES.md`, `README.md` und `docs/reports/STERNENBUERGERCHEN_GM01_FRONTIER_2026-11-02.html`.
