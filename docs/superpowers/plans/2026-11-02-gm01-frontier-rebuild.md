# GM01 Frontier Rebuild Implementation Plan

> **For agentic workers:** Use separated shared-layout, authored-data and integration corridors; Root owns sequential engine verification.

**Goal:** Tatsächliche Standardmission mit dem vorhandenen neuen Außenposten-Grafikensemble neu bauen.
**Architecture:** Gespeicherte Tilefakten bleiben autoritativ. Optionales versioniertes Layout-ID verbindet konkreten kalten Authoringbuilder und reine Runtimevisuals, ohne neue Simulationswahrheit.
**Tech Stack:** Godot4.6.2, gespeicherte Hex-GM01, vorhandene Frontier-GLBs/Shader/Builder.
**Spec:** `docs/tasks/TASK_GM01_FRONTIER_REBUILD_20261102.md`.

## Constraints
- R4/Cutlass/UI erhalten; eigener Branch, kein Main-Checkout.
- Reale Landung/Entladung ohne Zeit-/Actorpatch; finale Userdaten isolieren.
- Renderer liest; Map/Registry/Simulation besitzen begehbare/LOS-/Höhenfakten.

### 1. Inhalt und gemeinsame Definition
- [x] Standarddispatch, Graph-/Markeranker und aktuelle Grafikbausteine unabhängig auditieren.
- [x] Konkreten Build-once-Layoutbuilder mit echten Footprints/Material-/Assetquellen bereitstellen; keine Previewactors/Pads als versteckte Wahrheit.
- [x] Neue gespeicherte GM01 deterministisch autorieren, Graphen/Anker/Spawnflächen prüfen.

### 2. Reguläre Integration
- [x] Optionales Layout-ID in MapData laden/speichern; bestehende Karten kompatibel.
- [x] Passiven Scene-/Ground-/Objectowner im normalen Renderer anschließen, H0-Kappen und echte dezente Hexkanten für die organische Grafik sauber behandeln.
- [x] Tatsächliche normale Mission ohne CLI-/Previewdispatch nachweisen.

### 3. Prüfung und Übergabe
- [x] Einmal importieren; betroffene Daten-/A*-/HPA-/LOS-/Roundtrip-/Objectivechecks ausführen.
- [x] Echte normale Cutlass/LZ/Entladung/GO-Route und native Vorher-/Nachherbilder, unabhängige Gegenprüfung.
- [x] Gründe/Quellen/Hashes/Status samt begrenztem Workbenchreport dokumentieren, Taskbranch committen/pushen.

## Final bestätigte Hexbasis
Auf weiteren ausdrücklichen Nutzerwunsch echte Hexfelder stattSquare8.48×48 versetzte Reihen werden als Axialkoordinaten q=Spalte-floor(Reihe/2),r=Reihe gespeichert(2304Zellen,ca48×41m). BestehendeOriginalgeometrie/Wearanker bleibenunverschoben; Rasterung nutztHexpolygon/Rect-Intersektion, Deckung6Nachbarn. Bounds,Kamera,Minimap und Save/Load unterstützennegativeq. Die Karte zeigt dezent echteHexkanten. Standard-known_terrain bekommtkeinen temporären schwarzenFoW-Kasten; unbekanntesTerrain imBlackoutmodus bleibt geschützt.
