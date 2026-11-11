# Hex-Runtime-Grundlagen — 11.11.2026

## Status

Isolierte Grundlagen implementiert: Ground-State, reine Hexsicht mit separater
Geometrie-LRU im vorhandenen Cache und Erkennungsepisoden. Finale kleine
Checks25/0,38/0,21/0. AP1-Owner-/Versionsgate ergänzt, eigener Check39/0;
zwei unabhängige Reviewbefunde mit RED/GREEN behoben. Keine aktive
Missions-/Basis-/Bewegungsintegration.
Erster AP3-Readeranschluss hinter dem Versionsgate ergänzt: Contact, Schuss,
FoW und Hex-Erkennung; kleine Checks30/0,25/0,39/0. Übrige AP3-Consumer und
Facing bleiben offen. QA hex_sight_consumers_20261111.
Vertrag: `docs/dev/hex_tactical_runtime_contract.md`.
QA: `docs/qa/hex_runtime_foundation_20261111/README.md` und
`docs/qa/hex_ground_owner_20261111/README.md`.

## Ziel / Problem

Die autorisierten unabhängigen Teile des Hex-Arbeitsplans implementieren:
logischer Ground-State mit atomarer Feldzulassung, reine Hexsicht und
episodische Erkennung. Keine zweite Gameplaywahrheit in UI oder Registries.

## Ursache / Sinn

Wiederholte Sicht-/Erkennungsarbeit benötigt stabile logische Eingaben.
Exklusive Feldbelegung muss vor tatsächlicher Bewegung und Reservierung
konsistent sein, auch bei fehlgeschlagener Gruppenplatzierung.

## Arbeitsbasis / Abstimmung

Eigener sparsamer Git-Worktree
`C:/dev/SternenBuergerchen-worktrees/hex-ground-foundation-20261111`,
Branch `task/hex-ground-foundation-20261111`, Basis
`97e00aba14ced147b268113085854ac67dc764c5` aus dem noch nicht integrierten
nativen Kartentask. Keine alten Runtimekopien aus e4b407fe0 übernommen.
Die App-Worktreezuordnung scheiterte zuvor; dieser eigene Git-Worktree ist
davon getrennt und benutzt das gesperrte ownerlose Verzeichnis nicht.

Der koordinierende Chat hat nach geprüftem direktem Nutzerauftrag das
Weiterarbeiten und AP0 auf dem gesicherten Rampencommit freigegeben.
Nachfolgende MapData-Anpassung für regional_terrain_version3 bleibt dort;
sie wird bei späterem Integrationsabgleich erhalten.

## Umfang / Nicht-Ziele

Neue core-Helper und kleine isolierte Contractchecks. Bestehende Runtimepfade
bleiben zunächst unverändert, bis deren konkrete Anbindung separat geprüft
wird. Keine Karten-/Editor-/Stationsänderung, keine große Matrix, native
Gefechtsprobe, Performancefreigabe, Mainintegration oder EXE.

### Nächster abgegrenzter Schritt: AP1-Owner und Version

Auf ausdrücklichen Abstimmungsauftrag folgt die Versionsprüfung in MapData
und der zentrale Besitz in SimulationRoot. `tactical_grid_rules=hex_tactical_v1`
ist nur mit `hex_axial_v1` zulässig. Fehlende Kennung bleibt Legacy;
unbekannte/falsch typisierte Kennungen und Topologiemischungen melden einen
Load-Issue. Ein fehlgeschlagener Konfigurationsversuch verändert keinen
bestehenden gültigen Kontext. Read-Payloads bleiben unabhängige Kopien.
Zulassung/Freigabe erfolgen ausschließlich über den Simulationsowner und
dessen bestehende Autoritätsprüfung. Keine Karte wird jetzt aktiviert.

Zusätzlich betroffene Dateien: `scripts/core/simulation_root.gd`,
`scripts/terrain/terrain_map_data.gd`, neuer kleiner Owner-Verifier und Runner.
Die bereits abgestimmte Regionalversion3 aus5204312c0 wird beim MapData-
Abgleich erhalten. BasePersonnel, Supply, CampaignSave, OrbitUI und Editor
bleiben beim koordinierenden Chat. Kleine Prüfung: Runner-Case `owner`,
echte Quellen und minimale private Projektkopie; keine Szene starten.

### AP3 erster Consumeranschluss

Gemeinsamer Read-Adapter für Contact-/Schussprüfung und Terrain-/Ziel-FoW:
aktivierte Hexkontexte lesen ausschließlich logische Zelle, halbe Standhöhe
und Blickrichtung vom Owner. Fehlende Zulassung bleibt unsichtbar; kein
Rückfall auf Renderpositionen. Legacy behält den bisherigen Pfad. Bestehender
CombatVisibilityCache wird gemeinsam genutzt, FoW-Jobs behalten ihre eingefrorenen
Beobachter und atomare Publikation. Gerichteter Winkel ist konfigurierbar
(Vorschlagsdefault120°), keine neue Waffen-/Skillbalance. Erkennungsepisoden
ersetzen im Hexzweig heruntergezählte Parallelwerte; Legacy bleibt kompatibel.

Dateien: neuer `scripts/core/hex_sight_runtime_adapter.gd`, HexDetectionState,
SimulationRoot-Registry-/Kontextreads, CombatLoopDriver, CombatFireDecisionResolver,
FogOfWarSystem und abgestimmter MissionTestSetup-Sichtadapter. Letztere Datei
ist nach direktem Koordinationsauftrag vom Kartenchat für diesen engen Schritt
freigegeben; Vorbereitungs-/Readiness-/Übergabepfade bleiben bestehen.
Kleine Cases `consumers` und `detection`. Keine große Laufzeit-/Battlematrix.
Sicherungs-/Overwatch-/Flankierungs-/Facingabsichten, Reservierung, Bewegung
und Lifecycle bleiben weitere APs und sperren eine produktive Kartenaktivierung.

## Relevante Dokumente

- `docs/superpowers/plans/2026-11-11-hex-sight-occupancy.md`, AP0–AP3
- `docs/superpowers/specs/2026-11-11-hex-sight-occupancy-design.md`
- `docs/dev/explicit_hex_ramps_contract.md`
- `docs/dev/hex_grid_v1_contract.md`, `docs/dev/contact_report_contract.md`
- `docs/dev/runtime_script_layout_contract.md`

## Akzeptanz

- Nur ein NPC je Zelle, Gruppenaufnahme atomar, unbekannte IDs ohne Zustand.
- Rampenstandhöhe H+0,5 über echte Registry-/Tile-Daten präzise erhalten.
- Read-Snapshots können die internen Indizes nicht verändern.
- Reine Hexsicht verwendet kanonische Hexlinien und tatsächliche Terrainhöhe.
- Erkennungsepisode hat einen stabilen Fälligkeitszeitpunkt; Verlust entfernt
  Fortschritt, wiederholtes Observe im selben Tick zählt nicht zusätzlich.
- Jede Änderung mit engem RED/GREEN belegt; große Tests bleiben zurückgestellt.

## Betroffene Dateien

Neue Dateien unter `scripts/core/hex_*`, `scripts/tests/hex_*`,
`scripts/tests/run_hex_tactical_check.py`; Contract-/QA-Dokumentation.
Eventuelle spätere Integrationsdateien erst im Ledger ausdrücklich benennen.

## Lokale Prüfung

`python scripts/tests/run_hex_tactical_check.py --case ground`
und anschließend ausschließlich die neu implementierten kleinen Cases.
Frische minimale Privatprojekte; echte Terrainquellen bytegleich kopiert,
keine persistenten Spielprofile laden. Keine allgemeine Testsuite jetzt.

## Risiken / offene Punkte

Diese Helper allein ändern noch keine Missionsbewegung oder Bildrate.
Aktuelle Consumer und echte Reservierungs-
ausführung bleiben die nachfolgenden Integrationsschritte des Gesamtplans.
