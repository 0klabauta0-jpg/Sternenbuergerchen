# Native Terrainvorbereitung und Kampf-/FoW-Sicht — 14.11.2026

## Ziel / Problem und Ursache
Nutzerauftrag: Terrainvorbereitung und Kampf-/FoW-Sicht auf aktuellem Main
messen und lohnende C++-Optimierungen auf eigenem Branch umsetzen. Main besitzt
bereits native Navigation; deren Vorbereitung baut Zellen/Kanten noch in
GDScript. Allgemeine Sichtpruefungen bleiben GDScript und besitzen bereits
Caches, Dirty-Jobs und Budgets. Ein Sprachwechsel ist nur bei gemessenem Nutzen
einschliesslich Vorbereitung und Datenuebergabe gerechtfertigt.

## Basis / Umfang / Nicht-Ziele
Nach `git fetch origin main` Basis `a982a0b5d2265678bc796a5da77fe7a0e13e397c`.
Eigener Branch `task/native-terrain-visibility-20261114`, separater Worktree.
Zunaechst reproduzierbare CPU-Baselines; danach begrenzte native Rechenkerne,
Differentialpruefungen und gepaarte Messung. Hauptcheckout und fremdes WIP bleiben
unberuehrt. Kein Mainmerge, EXE-Export, Grafikumbau, neue Spielregel, andere
Sichtreichweite, Kadenz oder Budgets. Keine Gesamt-FPS-/GPU-/WAN-Freigabe.

## Relevante Vertraege / Dokumente
- `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`
- `docs/dev/native_navigation_runtime_contract.md`
- `docs/dev/hex_grid_v1_contract.md`, `docs/dev/productive_hex_rollout_contract.md`
- `docs/qa/native_navigation_main_20261114/README.md`
- `docs/qa/performance_review_20261113/README.md`
- Bestehende LOS-/Hexsicht-/FoW- und Terrain-/Rampenvertraege bei den betroffenen Ownern.

## Akzeptanzkriterien
- Kalte Vorbereitung, unveraenderte Wiederverwendung und Terrainrevision getrennt
  messen; gleiche Last und Ergebnisse, Rohsamples, Engine-/CPU-/Quell-/DLLbezug.
- Kampf-/FoW-Sicht gegen den aktuellen gecachten Mainpfad messen, mit realen
  Registrydaten und vorhandenen Owner-/Jobpfaden. Vorbereitung separat und in
  Gesamtkosten ausweisen. Keine synthetische Kernzeit als FPS ausgeben.
- Exakte Gleichheit fuer Blocker, Sicht, geordnete Wege, Kosten, Rampen auf
  H+0,5, Square-Waende, Zielzellregeln, Revisionen und Ownerwechsel.
- `SimulationRoot`, Registries und FoW behalten Autoritaet; native Daten sind
  abgeleitet. Keine GDScript-Callbacks pro nativer innerer Schleifeniteration.
- Fehlende DLL, deaktiviertes Native und nicht unterstuetzte Eingaben verwenden
  den bisherigen GDScriptpfad; keine falsche Sicht bei Fehlern/alten Snapshots.
- Nachweisbarer Nutzen im betroffenen Gesamtpfad, sonst Kandidat nicht aktivieren.
- Sinnvolle Nachbargates, Engine-/Parser-/Leakpruefung, unabhängiger Source-Review.

## Betroffene Dateien
`scripts/terrain/native_navigation.gd`, `scripts/core/los_system.gd`, neue
`native_terrain_builder.{h,cpp}` / `native_visibility.{h,cpp}` und Registrierung
unter `native/navigation/src/`, Release-DLL, gezielte Verifier/Benchmarks und
Evidenzauswertung unter `scripts/tests/`, Isolationsrunner fuer echte
Kampfabhaengigkeiten, Navigation-/Sichtvertrag und QA-Dokumentation.

## Lokale Pruefung
Root fuehrt Build, Import, Enginepruefungen und Messungen seriell aus. Isolierte
Minimalprojekte nach `run_native_navigation_prototype.py`, originale gehashte
Quellen, eigene Nutzerdaten, frische Ausgabeordner und endliche Timeouts.
Godot 4.6.2 Windows x64; headless CPU, GPUzeit nicht verfuegbar. Verifier muessen
tatsaechliche Assertions, Erfolgmarker, Exit0 und fehler-/leakfreie Logs liefern.

## Risiken / offene Punkte
Native Vorbereitung kann kalte Kosten und Speicher erhoehen. Navigationsexposure-
LOS ist nicht automatisch dieselbe Semantik wie Kampfsicht. Dirty-Invalidierung
und gleichzeitig aktive Suchjobs muessen konsistent bleiben. Plattformumfang
der bestehenden DLL ist Windows x64. Sporadische Editorimportabstuerze sind in
der Main-Evidenz bereits offen; fehlgeschlagene Laeufe getrennt dokumentieren.

## Status
Umgesetzt und lokal geprueft auf eigenem Branch von Main. Zwei begrenzte native
Kerne: gerichtete Terrain-Kantenerzeugung und zustandslose Hexlinienberechnung.
Keine Gameplayregeln oder Owner verlagert; GDScript-Fallbacks einschliesslich
fehlender DLL und benutzerdefinierter Reader erhalten.

Finale gepaarte CPU-Mediane: GM01 adapterkalt 388,853 -> 75,834 ms (-80,5 %),
kurze gecachte Sichtabfragen 2,620 -> 2,3725 ms (-9,4 %). Voller FoW-Job nur
132,438 -> 129,7915 ms; kleiner beschreibender Effekt, keine allgemeine
FoW-/FPS-Freigabe. Unveraenderte Vorbereitung hat keinen Nutzen (32 -> 36 us).

12 akzeptierte Gates, darunter 3.387 Sicht- und 1.468 Terrainassertions,
51.721 verglichene Kanten, 600-Tick-Kampf-/Cache-Nachbargate und drei Gates
ohne Native-DLL. Build, exakte Quellhashes und unabhängiger Review dokumentiert.
Zwei wegen fehlender isolierter Kampfabhaengigkeiten verworfene Laeufe bleiben
sichtbar; erfolgreicher Nachlauf mit echten Ressourcen. Details, Grenzen und
Reproduktion: `docs/qa/native_terrain_visibility_20261114/README.md`.
