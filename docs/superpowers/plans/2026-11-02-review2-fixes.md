# Review 2 Fixes - Implementation Plan

**Goal:** Sieben weitere Befunde beheben und den echten Roster unveraendert lassen.
**Spec:** `docs/tasks/REVIEW2_2026_11_02_performance_architecture_fixes.md`
**Architecture:** Bestehende Runtime-Autoritaet erhalten; abgeleitete Caches und
raeumliche Indizes nutzen, UI-Sichtbarkeit von Simulationsfortschritt entkoppeln.
**Tech Stack:** Godot 4.6.2, GDScript, Python/PowerShell fuer isolierte Pruefung.

## Globale Regeln
- Jeder Godot-Lauf nur durch den verifizierten Isolation-Runner, auch RED/Import.
- Eigener Appname in separater Projektdatei vor Prozessstart; Runtime-Pfadguard.
- Roster-Integritaet vor/nach jedem Prozess pruefen; keine automatische Reparatur.
- Erst P1 implementieren, pruefen, reviewen und committen; dann P2 parallel nach
  disjunkten Dateieigentuemern. Keine Main-Integration in diesem Auftrag.
- Jeder Fix RED -> minimal GREEN -> betroffene Gates; keine parallelen Timings.

## Schritte
- [x] Isolation-Runner/Guard anlegen; Live-Canary prueft eigene user://-Ablage und
  unveraenderten Originalroster. Source-Projektkonfiguration bleibt bytegleich.
- [x] P1 `meta_layer_flow.gd`: echter normaler Missionsstart plus Homebase-/FOB-
  Navigation; aktive Ticks/Bewegung/Respawn weiter, Preview und versteckte UI sicher.
  Test `review2_20261102_p1_hidden_mission_verifier.gd` zuerst rot, dann gruen.
- [x] P1 unabhaengig reviewen und separat committen.
- [x] Terrain-Hoehe und Editor-Picking: gemeinsame Renderdatei in einem Worker;
  zwei eigenstaendige Tests `review2_20261102_p2_height_lookup_verifier.gd` und
  `review2_20261102_p2_editor_picking_verifier.gd`, Mapwechsel/Edits und Eingabewege.
- [x] Spacing und Kontaktzustand/-relays: Runtime-Worker mit drei Tests
  `review2_20261102_p2_spacing_verifier.gd`, `review2_20261102_p2_contact_observers_verifier.gd`,
  `review2_20261102_p2_contact_relays_verifier.gd`; reale Resolver-/Driver-Pfade.
- [x] Reassembly in SimulationRoot: Root; Test
  `review2_20261102_p2_chunk_jitter_verifier.gd`; real komprimierte 64-Unit-
  Snapshots, vier Ticks Versatz, Duplikate, Stale-Guard und begrenzter Speicher.
- [x] Je Slice relevante bestehende Gates; neue und alte Auswahl abschliessend
  sequentiell mit isolierten Nutzerdaten ausfuehren. Roster-Integritaet dokumentieren.
- [x] Unabhaengige Gesamt-Review und wichtige Befunde beheben.
- [x] Status/Task/Contracts/Evidence finalisieren; gezielte Commits und Task-Push.

## Schnittstellen / Konflikte
Terrain-Worker besitzt `terrain_map_3d_view.gd` und `map_editor.gd` gemeinsam.
Runtime-Worker besitzt `contact_tracker.gd` und `local_avoidance_resolver.gd`.
Root besitzt `simulation_root.gd`; falls Spacing dort einen Debug-Schalter braucht,
wartet Root mit Reassembly-Edits auf die koordinierte Uebergabe.
P1-Worker besitzt nur Meta-Lifecycle und zugehoerigen Test.

## Fortschritt
- P1: RED 44/16, GREEN 60/0; unabhaengig APPROVED. Bestand: 40/40 + 19/19 +
  116/116. TASK_348 14/17 auf P1 und unveraenderter HEAD-Baseline identisch rot.
- Alle Runtime-Pruefungen ueber den Isolationsrunner, Rosterzustand unveraendert.
- Alle sieben neuen Regressionen 202/202; effektiv 55 unterschiedliche Gates
  mit 1650 numerischen Assertions strikt gruen. Zwei Harnessprobleme im ersten
  Gesamtlauf dokumentiert und gezielt erneut geprueft; keine Testabschwaechung.
- Terrain-/Runtime-/Gesamt-Review und Harness-Nachreview APPROVED. Detaillierte
  Quellhashes, Einzelreports, Operationen und historische Fehler im Ergebnisindex.
