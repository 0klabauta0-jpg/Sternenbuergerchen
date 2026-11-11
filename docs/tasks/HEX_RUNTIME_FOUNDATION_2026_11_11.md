# Hex-Runtime-Grundlagen — 11.11.2026

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
Versionsgate, gemeinsamer Owner, aktuelle Consumer und echte Reservierungs-
ausführung bleiben die nachfolgenden Integrationsschritte des Gesamtplans.
