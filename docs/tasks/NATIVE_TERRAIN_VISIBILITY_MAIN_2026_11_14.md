# Native Terrain-/Sichtoptimierung in Main integrieren — 14.11.2026

## Ziel / Ursache
Nutzerauftrag: den geprueften Branch `task/native-terrain-visibility-20261114`
in aktuellen Main integrieren, relevante Tests erneut ausfuehren und Main pushen.
Optimierung und Branchbelege liegen vor; die Integration benoetigt frische Gates.

## Basis / Umfang / Nicht-Ziele
Frisch geholter Main `a982a0b5d2265678bc796a5da77fe7a0e13e397c`;
Quellbranch `96098c6685141647480d0d7691dd8d2565dd8b49`. Main ist direkter
Vorgaenger, daher Fast-forward ohne Konfliktloesung moeglich. Separater Worktree
`native-terrain-visibility-main-20261114`, Integrationsbranch
`task/native-terrain-visibility-main-20261114`. Hauptcheckout samt fremdem WIP
bleibt erhalten. Keine weitere Optimierung, Spielregel-, UI- oder Budgetaenderung,
kein EXE-Export, kein kompletter visueller Playthrough.

## Relevante Dokumente
- `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`
- `docs/tasks/NATIVE_TERRAIN_VISIBILITY_2026_11_14.md`
- `docs/dev/native_navigation_runtime_contract.md`
- `docs/dev/native_visibility_runtime_contract.md`
- `docs/qa/native_terrain_visibility_20261114/README.md`

## Akzeptanzkriterien
- Unveraenderte Uebernahme des freigegebenen Produktstands inklusive DLL.
- Frische neun native Gates fuer Sicht, Terrain, FoW, Cache, Kampf, Navigation
  und Laden sowie drei Gates ohne Native-DLL. Exit0, Marker, nichtleere
  Assertions und keine Engine-/Parser-/Leakfehler.
- Kurze Paritaetslaeufe der drei neuen Benchmarks, getrennt von den bisherigen
  40-Sample-Performanceaussagen. Keine erneute allgemeine FPS-Behauptung.
- Quell-/DLLhashes, aktuelle Engine und echte Testabhaengigkeiten dokumentieren.
- Nur geprueften, konfliktfreien Stand ohne Force-Push auf Main veroeffentlichen.
- Hauptcheckout-Branch, Index, sechs geaenderte Dateien und Untrackedinventar
  vor/nach vergleichen; keine fremden Aenderungen uebernehmen.

## Betroffene Dateien
Die Dateien des Quellcommits, diese Task-Datei, `docs/IMPLEMENTATION_STATUS.md`,
Integrationsverweise und frische Evidenz unter
`docs/qa/native_terrain_visibility_main_20261114/`.

## Lokale Pruefung
Godot 4.6.2, Windows x64. Frische isolierte Projekte mit gehashten Originalquellen,
echten LimboAI-/Audioabhaengigkeiten fuer Kampf und separaten Nutzerdaten.
Import/Tests seriell ueber vorhandene Isolations- und Skillrunner; begrenzte
Timeouts und frische Belegordner. Unabhaengiger Read-only-Integrationsreview.

## Risiken / offene Punkte
Ein zwischenzeitlich vorgeschobener Remote-Main darf nicht ueberschrieben werden;
vor Push erneut pruefen. Headless-Gates ersetzen keinen visuellen Spieltest oder
Multiplayernachweis. Weitere Plattformen bleiben ausserhalb der Windowspruefung.

## Status
Fast-forward-Integration lokal geprueft und zur Mainveroeffentlichung freigegeben.
Produkt-/Testcode und DLL entsprechen unveraendert `96098c668`. Neun native,
drei DLL-freie Gates und drei kurze Benchmark-Paritaetslaeufe frisch bestanden,
ohne Engine-/Parser-/Leakfehler. Unabhaengiger Review ohne Integrationsblocker.
Hauptcheckout inklusive Index, sechs geaenderter Dateien und Inventar/Stat von
102.105 untracked Eintraegen unveraendert. Belege und genaue Grenzen:
`docs/qa/native_terrain_visibility_main_20261114/README.md`.
