# C++-Navigation im normalen Spielpfad — 14.11.2026

## Ziel / Ursache
Expliziter Nutzerauftrag: optimierten C++-Pfad in normale Spielnavigation
integrieren und Terraindaten beim Laden vorbereiten. Der optimierte Prototyp
liefert gleiche Ergebnisse und schnelle Folgeanfragen; der Erstaufbau soll vor
dem ersten Bewegungsbefehl im Ladepfad stattfinden.

## Basis / Umfang
Branch `task/native-navigation-runtime-20261114`, bewusst auf dem noch nicht
integrierten optimierten Prototyp `fa3a2a7a5` (Playtestbasis `9e2e972a1`).
SimulationRoot waehlt standardmaessig Native fuer HPA/A*, behaelt seine Budget-,
Status-, Fallback- und Autoritaetsregeln. Der Missionladepfad bereitet nach der
Terrainregistrierung und den initialen Szenario-/Tuer-Overrides, vor der
Ladefreigabe und dem ersten Gameplaytick Graph und Native-Snapshot vor.
Optionswechsel verwenden den vorbereiteten Snapshot; Terrainrevisionen und
Kartenwechsel invalidieren korrekt. Nicht verfuegbare/unterstuetzte Nativepfade
verwenden explizit die vorhandene GDScript-Implementierung.

## Nicht-Ziele
Keine neue Kostenformel, kein Mainmerge/EXE-Export, keine aendernden Grafik- oder
UI-Arbeiten, keine Hintergrundthread-Architektur oder generelle FPS-Freigabe.
Fremde Working-Tree-Aenderungen im Hauptcheckout bleiben erhalten. Regulaere
Mission- und Simulationnavigation ist das Ziel; Editorhilfen bleiben separat.
Die Heimatbasis bereitet ihren eigenen nativen Godot-AStar2D-Feinrastergraph
bereits beim Laden vor und uebergibt fertige Weltpfade. Dort wird kein zusaetzlicher
ungenutzter HPA-Graph aufgebaut.

## Vertraege / betroffene Dateien
`docs/ARCHITECTURE.md`, `docs/dev/hex_grid_v1_contract.md`,
`docs/dev/runtime_script_layout_contract.md`,
`docs/dev/native_navigation_runtime_contract.md`,
`docs/qa/native_navigation_dynamic_costs_20261114/README.md`.
`scripts/core/simulation_root.gd`, bestehender produktiver Legacy-Ladepfad
`scripts/tests/mission_test_setup.gd`, Native-Adapter unter `scripts/terrain/`,
gezielte Verifier und neue QA-/Contract-/Statusdokumentation. Die bestehende
Mission-Setup-Datei bleibt gemaess Layoutvertrag Legacy-Bridge; keine Verschiebung.

## Akzeptanz / lokale Pruefung
1. Normale Move-Anfrage ueber SimulationRoot nutzt standardmaessig Native; kein
   Opt-in fuer den Spieler. Vollstaendiger Pfad/Status gegen GDScript geprueft.
2. Ladeabschluss erstellt Graph/Terrain vor Gameplayfreigabe; erste Anfrage
   nach Ladevorbereitung baut keinen Snapshot neu. Vorbereitung separat messen.
3. Wechselnde Optionen, neue Registry, Terrain-/Graphrevision, null/fehlende
   Registry und fehlende Extension liefern keine veralteten Daten.
4. Bestehende Budget-, Unreachable-, Zielersatz- und Bewegungstests bleiben gruen;
   DLL-freier Prozess beweist GDScript-Fallback und weiterhin funktionierende Moves.
5. Native-Paritaet, relevante Runtime-Nachbarn, Headless-Import/Fehler-/Leakchecks,
   Rohwerte und Quell-/DLL-Hashes; `git diff --check`. Engines seriell ausfuehren.

## Risiken / offene Punkte
Mission-Setup kann nach Registrierung weitere Runtime-Overrides setzen; Prewarm
muss hinter den initialen Terrainmutationen liegen. Andere Szenen muessen ihren
Ladeabschluss ebenfalls an den Owner anbinden. Terrain-Revisionsaufbau bleibt
synchron; nur Erstaufbau wird gezielt in die Ladephase verschoben. Windows x64
ist die vorhandene native Plattform; andere Plattformen nutzen GDScript.

## Abschluss / lokale Evidenz
Produktiver Owner und Missionladeabschluss sind angebunden. Der bisherige
Prototypname bleibt als Kompatibilitaetswrapper erhalten. 8 native und 2
DLL-freie Gates bestehen mit insgesamt 1953 Assertions ohne Fehler/Leaks;
32 gepaarte echte Bewegungsticks stimmen exakt ueberein. Die erste Anfrage
nach Ladeabschluss baut Terrain/HPA nicht erneut auf, auch ein spaeter initialer
Szenariooverride ist bereits vorbereitet. Options-/Terrain-/Kartenwechsel und
deaktiviertes/fehlendes Native sind abgedeckt.

GM01-Tickmedian einschliesslich Bewertung und Bewegung: 171,9645 -> 6,9825 ms
(24,63x). Native Ladevorbereitung einschliesslich HPA-Graph rund 0,594 s;
davon rund 0,309 s zusaetzliche native Vorbereitung. Laden plus acht Ticks:
1846–1915 ms GDScript gegen 657–658 ms Native. Alle Quell-/DLL-Hashes sind
geprueft; Build unveraendert zum optimierten Prototyp. Messgrenzen, exakte
Reproduktionsbefehle und Rohdaten:
`docs/qa/native_navigation_runtime_20261114/README.md`.

Kein visueller Gesamtplaytest, keine Multiplayer-/Save-Continue-Gesamtfreigabe.
Der Task bleibt auf dem oben genannten Folgebranch; kein Mainmerge/EXE-Export.
