# Native Navigation: normale Runtime und Ladevorbereitung — 14.11.2026

## Ergebnis und Stand

`SimulationRoot` nutzt den optimierten C++-Adapter standardmaessig fuer HPA,
direktes A* und die Suche nach erreichbaren Ersatzzielen. Der normale
Missionladeabschluss bereitet den HPA-Graph und die nativen Terrain-/Graphdaten
nach den initialen Szenario-/Tuer-Overrides vor. Bereits der erste Move-Command
verwendet diese Daten ohne erneuten Snapshotaufbau. Fehlende DLL oder nicht
unterstuetzte Eingaben verwenden weiterhin GDScript.

Branch `task/native-navigation-runtime-20261114`, bewusst auf dem noch nicht
integrierten optimierten Prototyp `fa3a2a7a576f8115edf902a0da7f87dd2a1219bd`.
Keine Mainintegration, kein EXE-Export. C++-Quellen, Buildrezept und DLL sind
gegenueber diesem Prototyp unveraendert. Der Hauptcheckout mit fremder WIP wurde
nicht bearbeitet. Vertrag: `docs/dev/native_navigation_runtime_contract.md`.

## Akzeptierte Pruefungen

Godot `4.6.2.stable.official.71f334935`, Windows x64, headless. Der Skill-Runner
`godot-game-verification/scripts/run_checks.py` pruefte je Prozess Exitcode,
Erfolgsmarker, Timeout sowie Engine-, Parser-, Compile- und Leakmeldungen.
Die isolierten Projekte enthalten gehashte Originalquellen und explizite
Laderessourcen. Jeder Prozess verwendet isolierte Nutzerdaten.

| Gate | Bestanden / Fehler |
|---|---:|
| SimulationRoot: normale Move-Queue, Abschluss, Optionen, Revisionen, Kartenwechsel, deaktiviertes Native, fehlendes Terrain | 172 / 0 |
| Echter Missionladeabschluss mit GM01 und spaetem Terrainoverride | 24 / 0 |
| Bestehender nativer A*/HPA-Differentialverifier | 1381 / 0 |
| Tuer-/Terrainrevision und Navigationsstatus | 72 / 0 |
| Bewegungs-/Ersatzziel-Fallbacks | 42 / 0 |
| Hex-Bewegung | 25 / 0 |
| Korridor, Lane und Cover (Task 476) | 36 / 0 |
| Command-Lebenszyklus (Task 501) | 10 / 0 |
| SimulationRoot im tatsaechlich DLL-freien Projekt | 168 / 0 |
| Missionladeabschluss im DLL-freien Projekt | 23 / 0 |

**10/10 Gates, insgesamt 1953 bestandene Assertions, keine Fehler/Leaks.**
Zusaetzlich sind alle **32 gepaarten Bewegungsticks** exakt gleich: geordneter
Gridpfad, HPA-Status, Pfadbewertung, Command-Weltpfad und erste Positionsaenderung.
Die nativen Messanfragen treffen keinen Ergebnis-Cache und behalten jeweils
genau einen vorbereiteten Terrain- und Graphsnapshot.

Akzeptierte Runnerberichte:

- [Native: 8/8](native_checks/20261114T120907Z-pid28128/metadata/report.json)
- [DLL-frei: 2/2](fallback_checks/20261114T121045Z-pid58720/metadata/report.json)
- [Quellabgleich und Messzusammenfassung](comparison.json)
- [Tatsaechlicher Loaderlauf](mission_load_native.json)

`native_suite_project_v2/source_manifest.json` beschreibt das akzeptierte native
Suiteprojekt. `native_suite_project/` dokumentiert nur den frueheren
Vorbereitungs-/Importlauf und ist kein zusaetzlicher bestandener Testlauf.

## Gemessene Kosten

Zwei frische Benchmarkprozesse, je acht verschiedene Optionen/Anfragen pro
Karte und Backend; abwechselnde Reihenfolge, 16 Paare pro Karte. Gemessen wird
der vollstaendige `_physics_process(0.1)` nach dem Einreihen eines echten
Move-Commands, einschliesslich Suche, GDScript-Pfadbewertung, Weltpfadkonvertierung,
erster Bewegung und uebriger Tickarbeit. Vorbereitungszeiten stehen separat und
werden unten auch in Gesamtkosten eingerechnet. Paritaetsvergleich ausserhalb
des Zeitfensters. Rohwerte: `benchmark_a/result.json`, `benchmark_b/result.json`.

| Karte | GDScript Tick-Median | Native Tick-Median | Faktor |
|---|---:|---:|---:|
| GM01, 9408 Zellen | 171,9645 ms | 6,9825 ms | 24,63x |
| Hex 24 | 27,0815 ms | 1,9195 ms | 14,11x |

Die Ladevorbereitung auf GM01 kostet nativ **593,755 / 594,770 ms**, davon
**309,833 / 309,123 ms** fuer native Daten; der Rest entfaellt ueberwiegend auf
den HPA-Graph. GDScript bereitet seinen eigenen Graph in **289,740 / 295,184 ms**
vor. Der native Snapshot fuegt damit rund 0,3 Sekunden einmalige Ladearbeit hinzu.
Die erste vorbereitete native Anfrage samt Bewegungstick benoetigt im Benchmark
**5,774 / 5,849 ms**.

| Karte / Lauf | Laden + 8 Ticks GDScript | Laden + 8 Ticks Native |
|---|---:|---:|
| GM01 A | 1846,279 ms | 656,700 ms |
| GM01 B | 1914,939 ms | 658,395 ms |
| Hex 24 A | 241,954 ms | 45,748 ms |
| Hex 24 B | 242,557 ms | 44,245 ms |

Der separate echte Missionloader-Verifier misst 919,739 ms fuer JSON-Laden,
Terrainregistrierung, isoliertes Setup und Vorbereitung. Davon sind 609,769 ms
Prewarm (299,810 ms Graph und 309,958 ms Native). Die erste Suche dauert
5,777 ms und behaelt Buildzaehler 1/1. Der spaete Testoverride steckt bereits
in der vorbereiteten Registryrevision 9411. Diese Einzelmessung ist keine
allgemeine Ladezeitprognose.

## Grenzen

Reale SimulationRoot-/UnitRegistry-Commands, aber einfache Node2D-Testeinheiten;
Spacing/Avoidance sind fuer den gepaarten Vergleich deaktiviert. Der Ladertest
erbt den echten Missionladeabschluss und verwendet den echten GM01-JSON-Lader,
isoliert jedoch Rendering, Roster und Fog-of-War durch Testueberschreibungen.
Kein vollstaendiger visueller Spieldurchlauf, keine allgemeine FPS-Aussage,
keine neue Multiplayer- oder Save/Continue-Freigabe. Kleine Messstichprobe.

Terrain-/Tuer-Aenderungen nach Ladeabschluss invalidieren weiterhin ueber ihre
Revisionen und koennen beim naechsten Suchaufruf synchronen Aufbau ausloesen.
Optionswechsel loesen diesen Aufbau nicht aus. Andere zukuenftige Loader muessen
denselben Owner-Hook nach ihren letzten Terrainmutationen aufrufen.
Die Heimatbasis besitzt bereits einen beim Laden vorbereiteten nativen
Godot-AStar2D-Graph und uebergibt fertige Weltpfade; dieser Pfad bleibt bestehen.

## Reproduktion und Nachweis

Von der Repositorywurzel, die einzelnen Engine-Laeufe seriell ausfuehren:

```powershell
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_runtime_verifier.gd --output-dir docs/qa/native_runtime_repeat/runtime
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_load_verifier.gd --output-dir docs/qa/native_runtime_repeat/load
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_runtime_verifier.gd --without-native --script-arg=--expect-native=false --output-dir docs/qa/native_runtime_repeat/fallback
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_load_verifier.gd --without-native --script-arg=--expect-native=false --output-dir docs/qa/native_runtime_repeat/load_fallback
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_runtime_benchmark.gd --output-dir docs/qa/native_runtime_repeat/benchmark
python scripts/tests/summarize_native_navigation_runtime.py
git diff --check
```

Die letzte Python-Pruefung validiert die archivierte Evidenz und deren
Quell-/Asset-/DLL-Hashes; sie erzeugt keine neuen Engine-Messwerte. Die Suite-
Manifeste `native_checks.json` und `fallback_checks.json` enthalten alle Gates
mit ihren historischen absoluten Ausgabezielen. Fuer erneute Suiteausfuehrung
frische Ausgabeziele einsetzen und ein frisch vorbereitetes Projekt verwenden.
Die Skill-Runnerberichte enthalten die vollstaendigen ausgefuehrten Befehle.

`comparison.json` vergleicht die native Builddateiliste mit
`../native_navigation_dynamic_costs_20261114/build_manifest.json`. Ein nach den
Tests vorangestellter Abschlussstatus in `IMPLEMENTATION_STATUS.md` wird separat
ausgewiesen; alle ausgefuehrten Quellen, Testskripte, Assets und DLLs muessen
bytegleich bleiben. Historische Prototyp-/Optionswechsel-Evidenz bleibt erhalten.
