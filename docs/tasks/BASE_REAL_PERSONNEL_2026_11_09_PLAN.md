# Echte Basispersonen und begehbare Originalraeume Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Die beiden echten Kampagnenpersonen auf der Basis bedienen und die Originalraeume durch echte Tueren nutzen koennen.

**Architecture:** SimulationRoot-gebundene Runtime besitzt Basisaktionen; UI liest Snapshots und sendet bestehende Commands. Navigation bleibt TerrainRegistry/MapData, Geometriechecks pruefen unabhaengig die Originalmeshes.

**Tech Stack:** Godot 4.6.2, GDScript, JSON-Karten, headless Verifier.

**Spec:** BASE_REAL_PERSONNEL_2026_11_09_DESIGN.md plus explizite Nutzerbestaetigung: beide NPCs duerfen am Boden teilnehmen, aktuell zugewiesene echte Person vor Rueckflug am Pilotenplatz, auch ein anderer NPC darf uebernehmen.

## Global Constraints

- Genau zwei echte Kampagnen-Rosterpersonen, keine dritte Commanderfigur.
- Originalmoebel/-modelle und grosse sichtbare Basis erhalten.
- Keine sichtbaren Fenster/Fokuswechsel; private Testprofile, niedrige Prioritaet.
- Isolierter task/base-personnel-world-20261109, fremde Orbit-WIP nicht anfassen, kein Push.
- Keine neue Heilungs-/Muedigkeitsbalance. Schlaf ist Bettbelegung/Ruhe/Wecken.

## Review Focus

- Identische IDs nach Board/Unboard/Mission/Continue; kein Doppelbesitz.
- Echter Pilot am Boden sperrt Rueckflug bis zum Wiedereinsteigen.
- Versteckte Basisansicht darf angeforderte Bewegung nicht still stoppen.
- Originalmesh-Tueren und Moebelabstaende statt bloss gruener Kartenfelder.
- Alte Saves und Skirmish bleiben verwendbar.

### Task 1: Originalraeume navigierbar machen

- [x] Unabhaengige Geometriepruefung mit Koerperabstand, echte Eingangsrouten und Bett-/Terminal-Arbeitspunkte spezifizieren.
- [x] Statische feinere Basis-Laufdaten/-Navigation implementieren, physische Groesse beibehalten; keine per-frame Meshsuche.
- [x] Geometrie-/Simulationsweg-Verifier und Kostenmessung ausfuehren.
- [x] Originalmodelle/Terminals an passenden Raumarbeitsplaetzen erhalten, Review.

### Task 2: Beide echten NPCs im Einsatz

- [x] Vorhandene Pilot-/Deployment-Owner untersuchen und regressionsfaehigen Szenariotest schreiben.
- [x] Pilot nach Landung aus-/wieder einsteigen lassen, Rueckflug guardet tatsaechliche Pilotanwesenheit.
- [x] Identitaeten, Rollen, Payload, Einzelpersonen-/Truppbindung und bisherigen Kampagnenloop pruefen; Review.

### Task 3: Autoritative Basisaktionen und Weltbedienung

- [x] SimulationRoot-gebundene Basisruntime mit Roster-IDs, Position, Bewegungsabsicht, Bettbelegung/Wecken und Snapshots anbinden.
- [x] Aktionsbruecke fuer bestehendes Ausruesten, Boarding/Unboarding und Details anbinden; neue Basisaktionen ueber denselben Ownerpfad.
- [x] Kampagnenbasis durch echte Personenprojektionen ersetzen; Auswahl, kleine Aktionsleiste und entfernte Terminal-Ankunft anbinden.
- [x] Sichere Checkpointfelder migrieren/persistieren und Wechsel zwischen Ansichten pruefen; Review.

### Task 4: Integration und lokaler Testbuild

- [ ] Breiter Branchreview, Befunde beheben, gezielte Kampagnen-/Skirmish-/Basischecks.
- [ ] Task/Contracts/Status und begrenzte QA-Belege aktualisieren, eigene Dateien committen.
- [ ] Autorisierte lokale Mainintegration in isoliertem Worktree, ohne fremde Orbit-WIP.
- [ ] Aktuelle Main-EXE exportieren und headless Paket-/Startpruefung, kein Push.

## Schnittstellen / Dateibesitz

Task1 besitzt Karten, neue Basis-Navigations-/Geometriehelfer und zugehoerige Tests; kleine View-Aenderungen nur abstimmen. Task2 besitzt Missions-/Airtransportpfade und Pilotentests. Task3 besitzt ExplorableHomebase, Presenter, neue Basisruntime und Saveintegration. Gemeinsame SimulationRoot/MetaLayerFlow-Aenderungen vorab abstimmen; keine konkurrierenden Komplettumbauten.
