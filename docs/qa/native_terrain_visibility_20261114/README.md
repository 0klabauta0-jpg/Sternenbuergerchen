# Terrainvorbereitung und Kampf-/FoW-Sicht — 14.11.2026

## Ergebnis und Entscheidung

Basis ist der zu Taskbeginn frisch geholte Main
`a982a0b5d2265678bc796a5da77fe7a0e13e397c`. Umsetzung auf
`task/native-terrain-visibility-20261114` im eigenen Worktree.

Die gerichtete Terrain-Kantenerzeugung lohnt sich als C++-Batch: komplette
GM01-Vorbereitung rund 80,5 % weniger CPU-Zeit. Ein kleiner, zustandsloser
C++-Kern fuer Hexlinien spart im kurzen gecachten Sichtlesepfad rund 9,4 %.
Beide sind standardmaessig aktiv, wenn die Klassen der vorhandenen GDExtension
verfuegbar und die Eingaben unterstuetzt sind. Die bisherigen GDScriptpfade
bleiben erhalten. Kein neuer C#-Runtimebedarf.

FoW profitiert nur begrenzt von den kuerzeren Linienberechnungen. Eine ganze
FoW- oder Kampfimplementierung wurde deshalb nicht portiert. Der volle FoW-Job
hat nur einen rund 2 % niedrigeren beobachteten Median; das ist keine belastbare
Aussage ueber einen allgemeinen FoW- oder FPS-Gewinn.

## Messwerte

Godot `4.6.2.stable.official.71f334935`, Windows x64, Ryzen 7 7800X3D,
headless CPU. Alle Angaben in Millisekunden. Median und p95 beziehen sich jeweils
auf 40 Samples pro Variante; p95 ist der naechste Rang ohne Interpolation.

| Gemessener Pfad | Median GDScript | Median C++ | Veraenderung | p95 vorher / nachher |
|---|---:|---:|---:|---:|
| GM01 `prepare`, adapterkalt | 388,853 | 75,834 | -80,5 % | 446,841 / 92,999 |
| GM01 nach Sperrrevision | 398,529 | 76,704 | -80,8 % | 446,587 / 87,748 |
| GM01 nach Wiedereroeffnung | 392,5795 | 77,2115 | -80,3 % | 462,117 / 93,160 |
| GM01 unveraendert wiederverwenden | 0,032 | 0,036 | kein Gewinn | 0,044 / 0,049 |
| Rampenfixture, adapterkalt | 10,741 | 2,185 | -79,7 % | 13,270 / 2,674 |
| Kurze gecachte Sichtabfragen, 4–8 Hexfelder | 2,620 | 2,3725 | -9,4 % | 2,952 / 2,626 |
| Breite/lange gecachte Sichtabfragen | 4,9045 | 3,887 | -20,7 % | 5,809 / 4,391 |
| Vollstaendiger FoW-Job | 132,438 | 129,7915 | -2,0 % | 150,844 / 139,194 |
| Dirty-FoW-Job | 36,2995 | 33,705 | -7,1 % | 44,219 / 35,779 |

Die isolierte Hexlinien-Diagnose sinkt von 1,1035 auf 0,197 ms. Dieser Wert
enthaelt nicht den kompletten Sicht- oder FoW-Pfad und ist keine Spielbeschleunigung.
Rohwerte, Mittelwerte, Maxima und Quellbezug: [comparison.json](comparison.json).

## Messgrenzen und Referenz

- Terrain: echte GM01-Importerdaten mit 9.408 Zellen und zusaetzlich eine
  explizite Rampenfixture. Zwei frische Prozesse mit je 20 gepaarten Samples.
  Jede Probe erzeugt neue Adapter; Backend-Reihenfolge wechselt. Keine verworfenen
  Terrain-Warmups: kalt bedeutet neuer Adapter innerhalb eines laufenden Prozesses.
- Gemessen wird der komplette `NativeNavigation.prepare`-Aufruf inklusive
  Extraktion, Kanten, nativer Uebergabe und echtem `load_terrain`. Identische
  Capture-Proxies rufen in beiden Varianten den echten Kernel auf; sie erlauben
  danach einen bytegenauen Vergleich der geordneten gepackten Snapshots.
  Mapimport, Registryaufbau und nachtraegliches Hashen liegen ausserhalb der Zeit.
- Die eingefrorene `_load_terrain`-Referenz entspricht Main exakt bis auf drei
  Phasentimer. Der Summarizer prueft das gegen `git show` der Basis. Der umgebende
  Adapter und die Navigation-DLL sind in beiden Varianten identisch. Dies isoliert
  die Terrainoptimierung und ist kein Vergleich kompletter alter/neuer Programme.
- Fuer Sicht wird der bestehende GDScriptlinienpfad per Instanzschalter gewaehlt.
  Terrainabfragen, Cache, Reichweite und FoW-Owner bleiben gleich. Gemessene Zeiten
  enthalten Sprachgrenze, Ergebnisuebergabe und erste lazy Kernelinstanziierung.
  Drei Warmups, danach abwechselnde Backend-Reihenfolge.
- Breite Sicht/FoW: zwei frische Prozesse mit je 20 Samples je Backend. 64
  geordnete GM01-Paare, vier Leser, 64 echte LOS-Pruefungen/192 Cachetreffer.
  Die breite Sichtfixture nutzt beliebige laengere Paare, 360 Grad und unbegrenzte
  Reichweitenzulassung; sie ist kein typischer Nahkampf.
- Separater Nahbereich: 40 gepaarte Samples in einem Prozess, 64 verschiedene
  begehbare Paare ueber 4–8 Hexfelder entlang sechs Achsen, Reichweite 8,
  Blickkegel 120 Grad zum jeweiligen Ziel. Alle 64 Paare sind unverdeckt und
  die Endpunkte haben in dieser Auswahl keine halben Rampenhoehen. Native war
  in 37/40 Paarmessungen schneller. Keine Blocker-/Rampen-Performanceaussage;
  diese Regeln sind separat funktional geprueft.
- FoW: vier Beobachter, Reichweite 8, Arbeitsslices mit 256 Zellen. Die Zeit ist
  die CPU-Summe aus Anforderung und allen Slices eines vollstaendigen bzw.
  anschliessenden Dirty-Jobs, keine einzelne Framezeit. Sichtmengen stimmen
  exakt ueberein. Dirty-Budgets und atomare Veroeffentlichung sind unveraendert.
- Die Messungen sind beschreibende lokale CPU-Vergleiche. Kein GPUprofil,
  keine Fullgame-FPS, keine Speicherbenchmark-, WAN-, Export- oder Playtestfreigabe.

## Umsetzung und Regelgleichheit

`native_terrain_builder.{h,cpp}` erzeugt gerichtete Kanten aus gepackten Feldern
der kanonischen TerrainRegistry. Nachbarreihenfolge, Kosten, Rampenanschluesse
einschliesslich H+0,5, regionale Grade/Bruecken und Square-Diagonalen bleiben gleich.
Eigene Reader oder abgeleitete Registries benutzen die bisherige GDScript-
Kantenschleife. Jede Revision baut weiterhin den vollstaendigen Snapshot neu auf.

`native_visibility.{h,cpp}` liefert ausschliesslich die geordnete Hexzelllinie.
Der bestehende LOS-Code liest weiterhin aktuelle Terrainwerte/Overrides und
entscheidet ueber Hoehen, ersten Blocker und Zielzellregel. Kein persistenter
Terrainzustand in C++, keine neue Spielautoritaet, keine Callbacks je C++-Iteration.
Squarewaende, Cache-Keys, Tickgrenzen, FoW-Slices und Gameplaybesitzer bleiben gleich.

Native fehlt, alte DLL ohne neue Klasse/Methode, deaktivierter Schalter,
ungeeigneter Reader oder ungueltige Eingabe: bisheriger GDScriptpfad.
Vertraege: [Navigation](../../dev/native_navigation_runtime_contract.md),
[Sicht](../../dev/native_visibility_runtime_contract.md).

## Lokale Verifikation

12 akzeptierte, nichtleere Gates, jeweils Exit 0, Erfolgmarker und keine
Engine-/Parser-/Leakfehler. [accepted_checks.json](accepted_checks.json)
verweist auf die unveraenderten Einzelreports und ihre gehashten Quellen.

| Gate | Ergebnis |
|---|---|
| Native Sichtdifferential | 3.387/0; 3.036 native Aufrufe |
| Terrain-/Kantendifferential | 1.468/0; 51.721 verglichene Kanten |
| Frontier Hexsicht | 76/0 |
| FoW LOS und FoW Single Slice | beide PASS |
| Bestehender Hex-/Cache-Performancetest | 27/0 |
| Navigation Main | 668/0; 245 Slicevergleiche, vier Runtimepaare |
| Ladevorbereitung | 24/0 |
| Bestehender 16v12-Kampf-/Cachetest | 12/0; 600 Ticks pro Cachevariante |
| Sicht ohne DLL | 3.335/0; null native Aufrufe |
| Navigation ohne DLL | 654/0 |
| Ladevorbereitung ohne DLL | 23/0 |

Die Differentialtests decken auch halbe Hoehen, alle sechs Rampenrichtungen,
Blocker/Zielzellen, Squarewaende, direkte Tileaenderungen ohne Revision,
benutzerdefinierte Reader, Grenzkoordinaten und Native-Ablehnung ab. Der
16v12-Test ist ein bestehendes benachbartes Cache-Regressionsgate; er wird nicht
als vollstaendiger Native-an/aus-Schlachtvergleich oder Performancewert ausgegeben.

Unabhaengiger Source- und Evidenzreview: anfangs gefundene Risiken bei abgeleiteten
Registries und fehlender Buildermethode durch kanonisches Script-Gate und
Methodenpruefung behoben. Abschliessend keine gravierenden offenen Semantikbefunde.
Alle Quellen der fuenf finalen Messserien und der akzeptierten Gates stimmen
einschliesslich DLL mit dem dokumentierten Stand ueberein.

## Beleginventar und verworfene Laeufe

- `baseline_combat`, `baseline_terrain`, `baseline_visibility`: vor Produktumbau
  auf Main gemessene Ausgangslaeufe. Historische Quellen, nicht als finale Serie
  gegen inzwischen geaenderte Testquellen umetikettiert.
- `terrain_after_a/b`, `visibility_final_a/b`, `visibility_near_a`: finale Daten
  fuer `comparison.json`. Jeder Ordner enthaelt Manifest, Rohresultat,
  Import-/Lauflogs und Exit-/Zeitmetadaten.
- `visibility_after_a`: fruehe Messung vor kanonischer Endpunkthoehenableitung
  im Benchmark; nicht in finaler Zusammenfassung enthalten.
- `visibility_verify_a`, `terrain_verify_a`: fruehe erfolgreiche Verifier;
  die spaeteren Gates sind massgeblich.
- `native_suite` + `native_checks`: acht akzeptierte Checks; der Kampftest wurde
  wegen fehlender echter LimboAI-Abhaengigkeit im Minimalprojekt verworfen.
- `combat_suite` + `combat_checks`: LimboAI vorhanden, aber zwei fehlende
  dynamisch geladene Impact-Audiodateien. Trotz 12/0 Assertions wegen Enginefehlern
  verworfen. Keine Fehlermeldung unterdrueckt und keine Spielquelle umgeschrieben.
- `combat_suite_final` + `combat_checks_final`: echte LimboAI-DLLs und beide
  Audiodateien ueber Runneroptionen kopiert/importiert; 12/0 ohne Fehler akzeptiert.
- `fallback_suite` + `fallback_checks`: frisches Projekt ohne Native-DLL;
  drei akzeptierte Gates mit unveraenderten Produktquellen.
- `build_first.log`, `build_manifest.json`: erfolgreicher Release-DLL-Build,
  gepinnte Bindings/Buildparameter und SHA256 der geprueften Eingaben/Binaerdatei.
  Kein Anspruch auf maschinenuebergreifend bitidentischen Build.

## Reproduktion

`native/navigation/build.ps1` baut die Erweiterung mit den bereits gepinnten
Bindings. Der bestehende Isolationsrunner kopiert Originalquellen und erfasst
SHA256; `--with-limboai` und wiederholtes `--copy-resource` ergaenzen echte
Laufzeitabhaengigkeiten fuer den Kampftest. `--without-native` erstellt den
Fallbacklauf. Genaue Engineaufrufe stehen in den `*_process.json` und Gate-Reports.
Die finalen Manifeste behalten die originalen Bytehashes und enthalten zusaetzlich
LF-normalisierte Hashes fuer Textquellen. Diese wurden nach bestaetigter
Bytegleichheit ergaenzt, damit Git-Zeilenendennormalisierung beim frischen
Checkout keine falsche Quellabweichung meldet; Binaerdateien bleiben bytegenau.

Beispiel fuer eine frische Terrainserie (neuen Ausgabeordner verwenden):

```powershell
python scripts/tests/run_native_navigation_prototype.py --script native_terrain_preparation_benchmark.gd --script-arg=--samples=20 --output-dir tmp/new_terrain_evidence --success-marker NATIVE_TERRAIN_PREPARATION
```

Endauswertung ohne neue Enginemessung:

```powershell
python scripts/tests/summarize_native_terrain_visibility.py --terrain docs/qa/native_terrain_visibility_20261114/terrain_after_a --terrain docs/qa/native_terrain_visibility_20261114/terrain_after_b --visibility docs/qa/native_terrain_visibility_20261114/visibility_final_a --visibility docs/qa/native_terrain_visibility_20261114/visibility_final_b --near docs/qa/native_terrain_visibility_20261114/visibility_near_a --output tmp/native_terrain_visibility_comparison.json
```

## Offener Umfang

Nur Godot 4.6.2/Windows x64 lokal geprueft. Andere Plattformen benoetigen eigene
Builds und Verifikation. Kein vollstaendiger Spielstart, visueller Playthrough,
EXE-Export oder Mainmerge Teil dieses Tasks. Der separate Hauptcheckout mit
fremdem WIP wurde nicht bearbeitet. Task:
[NATIVE_TERRAIN_VISIBILITY_2026_11_14.md](../../tasks/NATIVE_TERRAIN_VISIBILITY_2026_11_14.md).
