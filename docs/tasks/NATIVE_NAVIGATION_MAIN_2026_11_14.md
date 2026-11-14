# Native Navigation nach Main — 14.11.2026

## Ziel / Ursache
Nutzerauftrag: geprueften C++-Navigationspfad nach Main integrieren, vorhandene
Aenderungen im Hauptcheckout erhalten, danach Navigation erneut pruefen und
Main auf GitHub aktualisieren. Main `03cdccc51` ist neuer als die bisherige
Prototypbasis und hat explizite Rampen, Blocker sowie inkrementelle Hex-Suche.
Eine unveraenderte Uebernahme wuerde dort falsche Kosten liefern und den normalen
Hex-Movepfad nicht beschleunigen.

## Umfang / Nicht-Ziele
Isolierter Integrationsbranch `task/native-navigation-main-20261114` von Main.
Gezielte Uebernahme von `7a7cf80e3`, `fa3a2a7a5`, `2d3e74763`; keine Uebernahme
sonstiger alter Taskhistorie. Anpassung an Main-Rampen/Blocker und nativer
inkrementeller RegionalHexSearch unter den bestehenden Owner-/Budgetregeln.
Terrainvorbereitung im aktuellen Ladeabschluss. Keine fremden WIP-Aenderungen,
kein Grafikumbau, kein EXE-/Downloadpaket oder allgemeiner FPS-Nachweis.

## Vertraege / Dateien
`docs/ARCHITECTURE.md`, `docs/dev/native_navigation_runtime_contract.md`,
`docs/dev/productive_hex_rollout_contract.md`, Hex-Movement-/Ground-Contracts,
`docs/qa/native_navigation_runtime_20261114/README.md`.
`native/navigation/`, NativeAdapter, SimulationRoot, HexMovementCommandRuntime,
Missionladeabschluss, gezielte Verifier, QA- und Statusdokumentation.

## Akzeptanz / Pruefung
- Bestehende Main-Hex-/Rampen-/Blocker-/Belegungs- und Autoritaetsregeln bleiben.
- Native und GDScript liefern gleiche Wege, Kosten, Status und inkrementelle
  Abschluesse bei gleichem Expansionsbudget; Revisionen/Optionswechsel bleiben sicher.
- Normale Move-Commands und Ladevorbereitung im integrierten Stand geprueft;
  DLL-freier Fallback und relevante Main-Nachbarn erneut ausfuehren.
- Main-Quellen/DLL und frische Rohdaten dokumentieren, Zeiten getrennt ausweisen.
- Hauptcheckout unveraendert: sechs WIP-Dateien bytegesichert/gehasht; Branch,
  Index, Status sowie Inventar/Dateistatistik aller untracked Dateien vergleichen.
- Erst nach bestandenen Checks Main ohne Force aktualisieren und nach GitHub pushen.

## Risiken / offene Punkte
Inkrementelle Suche darf Querykontext anderer Jobs nicht ueberschreiben. Neue
Main-Regeln muessen tatsaechlich in der nativen Suche ankommen. Breite visuelle,
Multiplayer-/Save-Continue-Gesamtfreigabe ist kein Ergebnis dieser Integration.
WIP-Sicherung lokal: `C:/Users/bjoer/.codex/tmp/native-navigation-main-wip-20261114/`.

## Abschluss / Ergebnisse
Native RegionalHexSearch, Main-Rampen/Blocker und parallele Suchjobs implementiert;
Mission-/Basis- und abgeschlossene Checkpointladepfade bereiten Terrain vor.
18 nichtleere Gates, 245 native Slicevergleiche und 32 Benchmark-Commandpaare
bestanden. Keine Aenderung der 24/96-Expansionsbudgets oder Ground-Autoritaet.
GM01 je vollstaendigem Command: CPU der Such-Ticks 121,071 -> 7,3885 ms,
alle Bewegungsticks 167,431 -> 53,4115 ms Median. Laden plus acht Commands
1432–1469 -> 823–862 ms; einmalige native Terrainvorbereitung 371–404 ms.

WIP-Guard bestaetigt sechs geaenderte Dateien bytegleich und 102105 untracked
Dateien mit unveraendertem Inventar/Stat. Main-Integration ueber separaten
Worktree; keine neue EXE. Rejected Fixturelaeufe, zwei offene sporadische
Editorimportabstuerze sowie die erfolgreiche frische Endpruefung dokumentiert:
`docs/qa/native_navigation_main_20261114/README.md`.
