# C++-Navigation auf aktuellem Main — 14.11.2026

## Integrationsumfang

Nutzerauftrag: Navigation nach Main integrieren, Hauptcheckout-WIP erhalten,
erneut pruefen und GitHub aktualisieren. Ausgangsbasis: Main `03cdccc51`.
Gezielt uebernommen: `7a7cf80e3`, `fa3a2a7a5`, `2d3e74763`; lokale Integrations-
commits `919f629e9`, `5e0f83a09`, `ecd397dea`. Keine Uebernahme der sonstigen alten
Taskhistorie. Statuskonflikte behalten den aktuellen Main-Verlauf; Produktkonflikte
erhalten die neuen Main-Regionalregeln und bedingte Fog-of-War-Initialisierung.

Main nutzt mittlerweile HexGround statt des frueher gemessenen HPA-Movepfads.
Deshalb wurde die Integration um native inkrementelle `RegionalHexSearch` mit
eigener Frontier/Kostenkontext pro Job erweitert. Bestehende 24 Expansionen je
Hexjob, 96 je Tick, Reihenfolge, Blocker, Reservierung und Ankunft bleiben gleich.
Rampen verwenden Main-konforme halbe Standhoehen; `blocked_grids` wird vollstaendig
beruecksichtigt. HPA/A* und GDScript-Fallback bleiben erhalten.

Mission- und Basisladeabschluss bereiten Terrain vor; ein HPA-Graph entsteht nur
fuer Legacy-HPA. Erfolgreiche Checkpointfinalisierung bereitet nach wiederhergestellten
Terrainoverrides erneut vor, ausserhalb der atomaren Veroeffentlichung.
Vertrag: `docs/dev/native_navigation_runtime_contract.md`.

## Akzeptierte Verhaltenspruefungen

**18 nichtleere Gates bestanden**, Godot `4.6.2.stable.official.71f334935`,
Windows x64, headless. Erfolg verlangt Exit0, Erfolgsmarker, kein Timeout und
keine Script-/Parser-/Compile-/Enginefehler oder Leakmeldungen im akzeptierten Lauf.
Der Quellen-/Asset-/DLL-Abgleich sowie die genaue Auswahl stehen in
[comparison.json](comparison.json). Ein Marker ohne Assertions wird nicht akzeptiert.

| Gate | Nachweis |
|---|---:|
| Neue Main-Paritaet mit Native: Rampen, Blocker, Jobs, Revision, reale Commands und Checkpoint | 668/0 |
| Dieselbe Main-Pruefung ohne DLL | 654/0 |
| Legacy-Runtime native / ohne DLL | 172/0 und 168/0 |
| Echter GM01-Missionladeabschluss native / ohne DLL | 24/0 und 23/0 |
| A*/HPA-Differentialpruefung | 1381/0 |
| Tuerrevision / Bewegungsfallback / alte Hexbewegung | 72/0, 42/0, 25/0 |
| Korridor/Lane/Cover / Command-Lebenszyklus | 36/0, 10/0 |
| Autoritative Hexbewegung / Bewegungsspeicher | 47/0, 33/0 |
| Dynamische Schiffshindernisse | fuenf Bedingungen wahr, bis Ankunft |
| Basisowner / Boarding | 68/0, 65/0 |
| Echter Root-Checkpoint mit aktiver Bewegung | 10/0 |

Native und GDScript stimmen in **245 einzelnen Suchslices** ueberein. Vier echte
Main-Bewegungspaare je Verifier sowie **32 weitere Benchmarkpaare** stimmen in
Pfad, Kosten, kompletter Tickfolge, Belegung/Bewegung, Position und Ankunft exakt
ueberein. Kein Ergebnis-Cachetreffer ersetzt die Sucharbeit. Der erste Befehl
nach Prewarm und nach erfolgreichem Restore verwendet den vorbereiteten Snapshot.

Akzeptierte Rohdaten:

- `native_c/checks/20261114T123850Z-pid54740/metadata/report.json`: elf ausgewaehlte Gates.
- `neighbors_a/checks/20261114T124351Z-pid54812/metadata/report.json`: drei frische Nachbargates.
- `fallback_b/checks/`: drei DLL-freie Gates, eigener frischer Import.
- `checkpoint/`: zusaetzlicher Root-Restore mit zehn tatsaechlichen Assertions.
- `benchmark_a/`, `benchmark_b/`: zwei frische Prozesse mit je 16 Paaren.

Die minimalen Projekte enthalten unveraenderte Quelldateien und notwendige
Originalressourcen mit SHA256 und isolierten Nutzerdaten. Das ist kein kompletter
Repo-/Grafikimport. Die DLL wurde neu gebaut und nach allen Laeufen erneut als
aktuell bestaetigt: [Buildmanifest](build_manifest.json), [Buildlog](build_verify.log).
SHA256 `48e55a8f9036c5b45f7ba4a12f25c246df869646ac7291ba32dff367da39d702`,
431616 Bytes; MSVC19.51, SCons4.11.1, gepinnte godot-cpp-Bindings, `/fp:strict`.

## Messung auf dem aktuellen Mainpfad

Ryzen 7 7800X3D, gleiche Karten/Optionen, abwechselnde Reihenfolge, acht Commands
pro Karte/Prozess, 16 Paare pro Karte insgesamt. Messfenster ist jeweils der
echte `SimulationRoot._physics_process(0.25)`. Werte sind **CPU-Summen ueber alle
Ticks eines vollstaendigen Bewegungsbefehls**, keine einzelne Framezeit. Fixture-
Aufbau, Laden, Tracevergleich und Ergebnisbewertung ausserhalb des Zeitfensters;
Ladevorbereitung separat und unten mit eingerechnet.

| Karte / Median je vollstaendigem Command | GDScript | C++ | Faktor |
|---|---:|---:|---:|
| GM01: Ticks mit aktiver Suche | 121,071 ms | 7,3885 ms | 16,39x |
| GM01: alle Ticks bis Ankunft | 167,431 ms | 53,4115 ms | 3,13x |
| Rampenfixture: Ticks mit aktiver Suche | 5,4905 ms | 1,175 ms | 4,67x |
| Rampenfixture: alle Ticks bis Ankunft | 9,137 ms | 5,032 ms | 1,82x |

Native Terrainvorbereitung GM01: **403,596 / 371,125 ms**. GDScript benoetigt
hier keinen Vollkartensnapshot (0,020 / 0,024 ms Vorbereitung). **Vorbereitung
plus acht komplette Commands:** GDScript 1432,316 / 1469,017 ms; Native
862,470 / 823,198 ms. Der einmalige Ladepreis wird also nicht unterschlagen;
ein einzelner kalter Command kann mit Native weiterhin insgesamt teurer sein.
Die frueheren HPA-Werte 172→7 ms beschreiben einen anderen Spielpfad und sind
kein direkter Vorher/Nachher-Vergleich zu diesem Mainstand.

Budgets und Ticks bis Ankunft bleiben identisch. Keine Aussage ueber allgemeine
FPS, Render-/GPU-Zeit, menschlichen Gesamtplaytest, WAN oder komplette Kampagne.
Node2D-Testdarsteller, begrenzte Stichprobe. Basisbewegung und Checkpoint werden
als Owner-Nachbarn geprueft; kein frischer kompletter Basis-UI-/Continue-Durchlauf.

## Verworfene Laeufe und offene Importgrenze

`native_a` und `native_b` endeten beim frischen Editorimport mit Windows
`0xc0000005`, nach Beginn des Fontimports. Keine bestandenen Tests daraus.
Identischer neuer DLL-Stand besteht den frischen Import `native_c` samt Runtime-
Tests. Kleine Fontproben mit alter, neuer und ohne DLL bestehen; volle gleiche
Suiteimporte ohne DLL und mit alter DLL bestehen ebenfalls (`font_import_probe/`,
`import_no_dll/`). Ursache bleibt offen; weder Font noch neue DLL sind damit als
Ursache bewiesen. Der Mainbestand dokumentiert bereits einen aehnlichen offenen
Importabsturz in `docs/qa/editor_import_font_20261113/README.md`. Keine Engine-
Einstellung oder Assets auf Verdacht geaendert, keine Zusage sporadischer
Editorimport-Absturzfreiheit.

`fallback_a`: neue Fixture uebergab untypisierte statt `Array[Dictionary]`-
Admissions; alter Ladertest erwartete noch den ungenutzten HPA-Graph. Korrigiert
und frisch wiederholt. `native_c` Task476/Boarding: Test-Doubles fehlten schon
auf Main eingefuehrte Methoden; aktuelle Schnittstellen ergaenzt, keine Assertions
entfernt. Task476 prueft nur ASCII-Dokumentmarker jetzt byteweise, ohne historische
gemischte Dokumentkodierung umzuschreiben. `native_c/mission_restore` liefert
null Assertions und wird trotz Runner-PASS ausdruecklich verworfen; ersetzt durch
`checkpoint/` mit zehn echten Pruefungen. Rohlogs bleiben nachvollziehbar erhalten.

## Erhalt des Hauptcheckouts und Reproduktion

[WIP-Nachweis](wip_preservation.json): alle sechs geaenderten getrackten Dateien
bytegleich, Index/Status/Branch/HEAD unveraendert. Fuer 102105 untracked Dateien
Inventar, Groesse und Nanosekunden-Mtime unveraendert. Kein Stash, Checkout oder
Clean im Hauptcheckout. Dieser bleibt auf `task/playtest-rework-plan-20261114`;
Main wird aus dem separaten Integrationsworktree aktualisiert.

Einzelne frische Pruefungen von der Repo-Wurzel, seriell:

```powershell
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_main_verifier.gd --output-dir tmp/main_repeat/native --success-marker NATIVE_NAVIGATION_MAIN
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_main_verifier.gd --without-native --script-arg=--expect-native=false --output-dir tmp/main_repeat/fallback --success-marker NATIVE_NAVIGATION_MAIN
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_load_verifier.gd --output-dir tmp/main_repeat/load --success-marker NATIVE_NAVIGATION_LOAD
python scripts/tests/run_native_navigation_prototype.py --script native_navigation_main_benchmark.gd --output-dir tmp/main_repeat/benchmark --success-marker NATIVE_NAVIGATION_MAIN_BENCHMARK
python docs/qa/native_navigation_main_20261114/summarize.py
git diff --check
```

Vorhandene Ausgabeordner werden nicht ueberschrieben. Suite-Manifeste und
Runnerberichte enthalten die historischen absoluten Befehle/Ausgabeziele;
bei Wiederholung frische Ziele verwenden. `summarize.py` validiert archivierte
Evidenz/Quellen und erzeugt keine neuen Engine-Messwerte. Nachtraegliche reine
Statusvoranstellung wird explizit separat gehasht, nicht als getesteter Code gewertet.
