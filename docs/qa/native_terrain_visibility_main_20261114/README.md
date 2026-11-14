# Mainintegration: Native Terrainvorbereitung und Hexsicht — 14.11.2026

## Integrationsstand

Nutzerauftrag: Branch integrieren, relevante Tests erneut ausfuehren und den
geprueften Stand auf Main pushen. Frisch geholter Main war
`a982a0b5d2265678bc796a5da77fe7a0e13e397c`, Quellbranch
`task/native-terrain-visibility-20261114` bei
`96098c6685141647480d0d7691dd8d2565dd8b49`.

Fast-forward im separaten Integrationsworktree; keine Konflikte und keine
nachtraeglichen Aenderungen an Produktcode, Testcode oder DLL. Die Integration
ergaenzt ausschliesslich diese neuen Belege, Taskstatus und Dokumentationsverweise.
Der gepruefte Commit `96098c668` bleibt direkter Vorfahr des Dokumentationscommits.

## Erneute Pruefung

Godot `4.6.2.stable.official.71f334935`, Windows x64, headless. Zwei frische
isolierte Projekte mit unveraenderten Originalquellen und separaten Nutzerdaten;
Native-Projekt mit den echten LimboAI-DLLs und beiden dynamisch geladenen
Impact-Audiodateien. Jedes Projekt einmal frisch importiert, alle Enginepruefungen
seriell und mit endlichen Timeouts. Keine ausgelassenen oder verworfenen Gates.

| Gate | Frisches Ergebnis |
|---|---|
| Native Sicht | 3.387/0; 3.036 native Aufrufe |
| Terrainvorbereitung | 1.468/0; 51.721 Kanten verglichen |
| Frontier Hexsicht | 76/0 |
| FoW LOS / Single Slice | beide PASS |
| Bestehender Hex-/Cache-Performancetest | 27/0 |
| 16v12-Kampf-/Cache-Regressionsgate | 12/0; 600 Ticks je Cachevariante |
| Navigation Main | 668/0; 245 Slicevergleiche, vier Runtimepaare |
| Ladevorbereitung | 24/0 |
| Sicht ohne Native-DLL | 3.335/0; null native Aufrufe |
| Navigation ohne Native-DLL | 654/0 |
| Laden ohne Native-DLL | 23/0 |
| Kurzer Terrainbenchmark | 24 Paarzeilen, exakte Snapshotparitaet |
| Kurzer Sicht-/FoW-Benchmark | sechs Zeilen, drei Samples je Backend, Paritaet |
| Kurzer Nahsichtbenchmark | sechs Zeilen, drei Samples je Backend, Paritaet |

Insgesamt **12 Regressionsgates plus drei Benchmark-Smokes bestanden**.
Alle mit Exit 0, Erfolgmarker, tatsaechlichen Assertions/Resultaten und ohne
Engine-, Parser- oder Leakfehler. `accepted_checks.json` fasst die geprueften
Einzelreports zusammen:

- [Native-Gates](native_checks/20261114T153127Z-pid70056/metadata/report.json)
- [DLL-freie Gates](fallback_checks/20261114T153259Z-pid34296/metadata/report.json)
- [Benchmark-Smokes](benchmark_smoke_checks/20261114T153314Z-pid63312/metadata/report.json)

## Quell- und Binaerbezug

`integration_sources.json` bestaetigt bytegleiche 15 versionierte Buildinputs
einschliesslich DLL gegen den zuvor geprueften Branch-Build. Sieben lokale,
nicht versionierte `.obj`-Zwischenprodukte aus dessen historischem Buildmanifest
sind ausdruecklich ausgenommen; kein neuer DLL-Build war fuer die unveraenderte
Uebernahme erforderlich. Alle 297 Quellen/Ressourcen des Native-Projekts und
251 des DLL-freien Projekts wurden gegen ihre frischen Kopiermanifeste geprueft.
Die Manifeste enthalten Original- und LF-normalisierte Text-Hashes.

Unabhaengiger Read-only-Review bestaetigte den begrenzten Produktdiff,
Registry-/Ownergrenzen und die Testauswahl. Es gibt keine offenen
Integrationsblocker in diesem geprueften Umfang.

## Hauptcheckout und Git

Im Hauptcheckout blieb `task/playtest-rework-plan-20261114` bei `9b52e0781`.
Branch, HEAD, Indexhash, Inhalte der sechs geaenderten Dateien und das
Pfad-/Groessen-/Mtime-Inventar von 102.105 untracked Eintraegen stimmen vor
und nach den Tests ueberein; siehe `main_checkout_before.json` und
`main_checkout_preservation.json`. Kein Checkout, Stash oder Reset fremden WIPs.

Die Mainveroeffentlichung erfolgt als normaler Fast-forward-Push nach erneuter
Remotepruefung; anschliessend wird auch die lokale Mainreferenz vorgezogen.
Der Integrationsworktree ist
`C:/dev/SternenBuergerchen-worktrees/native-terrain-visibility-main-20261114`.

## Grenzen und Reproduktion

Die drei kurzen Benchmarks pruefen Integration und Paritaet. Sie ersetzen nicht
die bisherigen 40-Sample-Messreihen und begruenden keine neuen Leistungszahlen.
Deren Messwerte und Einschraenkungen bleiben im
[urspruenglichen Messbericht](../native_terrain_visibility_20261114/README.md).
Keine neue Spielregel, FoW-Kadenz, Cachegueltigkeit oder Gameplayautoritaet.
GDScript-Fallbacks sind erhalten und erneut in echten DLL-freien Prozessen geprueft.

Die `*_checks.json`-Manifeste und alle exakten Engineargumente stehen bei den
Einzelreports; die `*_suite`-Ordner enthalten Importlogs und Quellmanifeste.
Mit `run_native_navigation_prototype.py --prepare-only` ein frisches Projekt
mit den dort aufgefuehrten Originalquellen erstellen und die jeweiligen
Manifeste mit `godot-game-verification/scripts/run_checks.py` ausfuehren.

Kein vollstaendiger visueller Spielstart, EXE-Export, GPU/FPS-, Multiplayer-
oder Fremdplattformnachweis. Task:
[NATIVE_TERRAIN_VISIBILITY_MAIN_2026_11_14.md](../../tasks/NATIVE_TERRAIN_VISIBILITY_MAIN_2026_11_14.md).
