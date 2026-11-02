# Performance Architecture Review Fixes - Implementation Plan

**Goal:** Die sieben aktuellen Review-Befunde mit Regressionstests beheben.
**Architecture:** SimulationRoot bleibt autoritaer. Registry-/Index-/UI-Caches
bleiben abgeleitet; vorhandene Dirty-, Contract- und Revisionspfade verwenden.
**Tech Stack:** Godot 4.6.2, GDScript, PowerShell, portable Godot-Check-Manifeste.
**Spec:** `docs/tasks/REVIEW_2026_11_02_performance_architecture_fixes.md`

## Global Constraints
- Keine Arbeit auf main; Review-Basis `7f594530f` auf eigenem Task-Branch.
- Zuerst alle drei P1-Korrekturen, danach die vier P2-Korrekturen.
- Jeden Fehler vor der Korrektur durch eine rote Verhaltensregression belegen.
- Keine neuen Systeme, keine zweite Gameplay-Wahrheit, keine Budgetlockerung.
- Keine parallelen Timing-Benchmarks; strukturelle Operationszaehler bevorzugen.

## Review Focus
- Down/Respawn darf alte tokenisierte Moves nicht wiederbeleben.
- Geoeffnete/geschlossene Tueren: Full-/Dirty-HPA und echter Simulationspfad.
- Index: bestehende Nodes wechseln Identitaet/Team/Fireteam ohne Membershipwechsel.
- Hex: Kostenoptionen/Terrainrevision, legale Pfade, kein unbeschraenkter Cache.
- Vitals: beide Transportreihenfolgen, Duplikate, Partial-Snapshots und Respawn.

## P1 - getrennte Eigentumsbereiche
- [x] Movement: `simulation_root.gd`; Test
  `review_20261102_p1_movement_verifier.gd`: laufender Move -> Damage -> down,
  keine weitere Position/Queue; neue gueltige Bewegung nach Respawn.
- [x] Door-HPA: `hpa_navigation_graph.gd`; Test
  `review_20261102_p1_navigation_verifier.gd`: 17er-Korridor mit Runtime-Tuer,
  Full-/Dirty-Build und SimulationRoot-Endziel nach Oeffnen/Schliessen.
- [x] Mission index: `mission_runtime_index.gd` und vorhandene Unit-/Setup-Signale;
  Test `review_20261102_p1_runtime_index_verifier.gd`: gleiche Nodes, neue IDs/
  Teams/Fireteams, echte Slot-Neubelegung, stabile Scananzahl ohne Aenderung.
- [x] Pro Slice RED protokollieren, minimal korrigieren, GREEN plus betroffene
  bestehende Gates; gemeinsamen P1-Diff pruefen und separat committen.

## P2 - nach P1-Green
- [ ] Hex-HPA: lokale Distanzberechnung pro Eintritt/Komponente buendeln;
  `review_20261102_p2_hex_budget_verifier.gd` prueft 24x20-Suchbudget,
  Pfadlegalitaet, Optionen und Revisionen. Keine globale Optimalitaet versprechen.
- [ ] Fallback: `simulation_root.gd`; Test
  `review_20261102_p2_fallback_verifier.gd` prueft Queueabschluss und
  stabile Queryanzahl nach Ersatzankunft, auch mit Avoidance.
- [ ] Dropship HUD: bestehende Craft-ID-Karten behalten; Test
  `review_20261102_p2_dropship_hud_verifier.gd` prueft stabile Node-IDs,
  geaenderten Progress/Status/Payload/Buttons und keine neuen Tree-Scans.
- [ ] Vital ordering: `simulation_root.gd`, Snapshot-Contract, ggf. TestUnit;
  `review_20261102_p2_vital_order_verifier.gd` prueft stale Reliable nach
  Snapshot sowie stale Snapshot nach Reliable, neuere Heilung/Respawn und
  side-effect-freien Apply. Versionierung im gemeinsamen Contract dokumentieren.
- [ ] Je Slice RED -> minimaler Fix -> GREEN; bestehende Gates pruefen.

## Abschluss
- [ ] Sequentielles Manifest mit allen sieben Regressionen und passenden
  bestehenden Gates ausfuehren, Logs und report.json lesen.
- [ ] Unabhaengige Review des gesamten Branch-Diffs; wichtige Befunde beheben.
- [ ] Task, Implementation-Status und Roadmap mit wirklichen Ergebnissen ergaenzen.
- [ ] Gezielte Commits und Task-Branch pushen; keine Main-Integration.

## Arbeitsnotizen
- P1: 20/20 Movement, 72/72 Navigation, 31/31 Index; zwei unabhaengige
  Reviews ohne wichtige offene Befunde. Zehn betroffene Skripte (292 Assertions)
  strikt geprueft, TASK_692-Testfixture nach erstem Leaksignal freigegeben.
- Root koordiniert Tests/Netzwerk/Dokumentation; abgegrenzte Worker bearbeiten
  Movement, Terrain und Index/HUD ohne gegenseitige Dateiedits.
- Gemeinsamer Dateikonflikt: Root aendert SimulationRoot fuer Vital-Ordering erst,
  nachdem der Movement-Worker alle SimulationRoot-Edits beendet hat.
