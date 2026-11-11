# Regionales GO-Suchbudget für wenige wartende Jobs

11.11.2026. Bestehender isolierter Taskbranch task/native-glut-maps-20261110,
auf7ef57c931 und paralleler anderer WIP. Dieser Teilagent hat nicht committed,
gepusht, Main integriert oder eine EXE gebaut.
Task REGIONAL_GO_BUDGET_REUSE_2026_11_11.md.

## Enger Algorithmus

Die vorhandene Admission-Auswahl bleibt unverändert: Priorität, danach letzter
Bedienungstick, danach Queue-Reihenfolge; höchstens vier Jobs. Anschließend
tragen dieselben Dictionary-Einträge statt true den numerischen Sliceanteil.
Nur deren Werte ändern sich, keine weitere Klasse oder gespeicherte Wahrheit.

| Tatsächlich zugelassene Jobs | Anteil je Job | Gemeinsames Maximum |
| --- | ---: | ---: |
|1|96|96|
|2|48|96|
|3|32|96|
|4 oder mehr wartend, maximal4zugelassen|24|96|

Die tatsächliche Advance-Anforderung ist zusätzlich auf das verbleibende
96er-Tickbudget begrenzt. Früher fertige Jobs geben Restbudget nicht in einer
zweiten Runde weiter. Max-Query-Einstellungen0/2 bleiben maßgeblich;
außerhalb eines Physikticks gilt weiterhin der24er-Slice.
Alle Konsumenten des privaten _regional_navigation_admissions-Dictionarys
wurden geprüft: nur die bestehende has()-Zulassung und nun der numerische
Lesepfad verwenden es. Es gibt keine externen Boolkonsumenten oder Tests,
die boolesche Werte injizieren. Suche/Kosten/Frontierreihenfolge/Kollisionen,
Terrainrevisionen und Move-/Hold-Tokenlogik bleiben unverändert.
Keine Suchobjekte oder Kostenkontexte werden für nicht zugelassene Jobs neu
angelegt; der bestehende frühere Admissionguard bleibt vor Suchaufbau.
Keine zusätzliche produktive Traceinstrumentierung.

## RED/GREEN und Funktionsprüfung

Godot4.6.2.stable.official.71f334935, headless Dummy-Renderer, private APPDATA
unter output/native_glut_maps/regional_go_budget_reuse/profile. Kein Import,
Renderer/GPUjob oder Nutzersave. Die sonstige autorisierte Artarbeit lief
parallel; CPU-Zahlen sind deshalb nur begrenzte Diagnose.

Neuer regional_go_budget_reuse_test.gd: RED37Checks/9Fehler, GREEN37/0.
Echte SimulationRoot-/TerrainRegistry-/TestUnit-Aufrufe, kleine kontrollierte
80×40-Hexgeometrie. Die Registry meldet allein zur Branchwahl512×256; das
ist ausdrücklich keine Messung auf einer vollständigen regionalen Spielkarte.

-1/2/3/4/6Jobfälle prüfen tatsächlich expandierte Zellen, nicht bloß Konfiguration.
- Gemeinsamer96er-Cap und maximal vier erzeugte Suchen pro Tick.
- Sechs lange unerreichbare Jobs behalten Fortschritt über faire Rotation.
- Kein Move vor vollständiger legaler Route; Querycaps0/2 werden eingehalten.
- Ein kontrollierter Umweg durch eine Wandöffnung vergleicht vollständige
  erste Routen und tatsächliche physische Bewegungsaufnahme mit dem24er-Oracle.
- AußerhalbTick unveränderte24Expansionen.

Der24er-Oracle im Test ist ein kleiner Test-Subclass, der allein den neuen
Anteil nach unveränderter Admission-Auswahl auf24setzt. Dieselbe aktuelle
Such-/Bewegungsimplementierung erhält damit die frühere Slicezuteilung.
Zusätzlich ist die unveränderte SimulationRoot-Datei aus7ef57c931 als
simulation_root_fixed24_source.gd für einen separaten späteren nativen
Vorherlauf archiviert; die aktuelle Quelle steht daneben. Beide liegen in
source_snapshots.zip mit SHA-Liste source_snapshots.json, ohne Verdoppelung
der großen Quelltexte im Git-Diff.

| Kontrolliertes Umwegfixture | Erster Move mit24er-Oracle | Gleiche vollständige Route mit neuer Zuteilung |
| --- | ---: | ---: |
|1 Job|Tick96|Tick24|
|2 Jobs|beide Tick96|beide Tick48|

Keine Vorab-Teilroute und keine geänderte Heuristik erzeugt diesen Unterschied.
Mehr vom schon vorhandenen Gesamtbudget wird bei wenigen Jobs ausgeschöpft.

Passende vorhandene Regressionen:
- regional_navigation_runtime_test15/0 (Fairness, Hold, neuer GO, Türrevision).
- regional_navigation_slices_test14/0 (Kostengleichheit, Rampen, Invalidierung).
- task_217_navigation_pathfinding_los_performance_pass51/0.
- task_501_integrated_movement_command_lifecycle_hardening10/0.
- playtest_20261105_empty_token_commit_verifier15/0.
- task_476_fireteam_corridor_lane_cover_navigation36/0.
Keine Script-/Compile-/Enginefehler oder Leakwarnungen in diesen gezielten
Läufen. Kein behaupteter vollständiger Editor-/Release-PASS.

## Sichtbarer CPU-Tradeoff und Grenzen

Die Variante verteilt Arbeit anders, statt zu behaupten, dieselbe Rechnung
verschwinde. Im GREEN-Diagnoselauf lag der maximale gemessene Tick im
Ein-Job-Umweg bei2,489→5,200ms; bei zwei Jobs8,478→10,189ms. Die Summen
waren dort104,627→88,403ms bzw.224,798→200,527ms; weniger Warteticks führen
auch weniger Tick-/Snapshot-Verwaltung aus. Diese Zahlen stehen nur als
Rohdiagnose in green_diagnostic.json; parallele Artarbeit, feste Vorher-dann-
Nachher-Reihenfolge und der kleine Fixture verbieten eine allgemeine CPU-/FPS-
Gewinnbehauptung. Der deterministische Nachweis betrifft Expansionen,
identische Routen und Ticks bis physischer Bewegung.

Einzelne größere Slices können Frames verlängern, obwohl die bisherige
Gesamtgrenze96 und maximal4Jobs unverändert bleiben. Isolierter echter B-
1×-Nachlauf muss erste Bewegung, Frame-/Tickkosten und Kampfablauf gemeinsam
prüfen. Root koordiniert diesen erst nach Astra-/Resourceintegration und
exklusivem CPU/GPU-Fenster. Die bisherigen~2,245s sind Movement-Walllatenz,
kein direkt gemessener einzelner Pfadsuchaufruf. Keine neue Frameratefreigabe.
