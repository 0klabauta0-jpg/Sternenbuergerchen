# Performance-/Architekturzyklen, 2026-11-03

## Ziel / Ursache
Nutzerauftrag: auf aktuellem Main erneut Performance/Architektur pruefen und
anschliessend selbststaendig drei Review-/Fix-/Retest-Runden durchfuehren.
Nach jeder Runde den veraenderten Stand erneut auf konkrete Probleme pruefen.

## Basis / Umfang / Nicht-Ziele
Basis ist der per Fetch bestaetigte Main `8eaeadd27e92d68539550058a4795c3ba626dcdc`.
Eigener Branch `task/performance-architecture-cycles-20261103` vom aktuellen Main,
wie fuer den Review explizit beauftragt. Nur bestaetigte Performance-/Architektur-
und daraus folgende Verhaltensfehler beheben, keine pauschalen Refactors oder
neuen Features. Keine automatische Main-Integration, keine Release-Abnahme.

## Dokumente / Contracts
`AGENTS.md`, `PROJECT_BRIEF.md`, `ARCHITECTURE.md`, `CODEX_RULES.md`,
`IMPLEMENTATION_STATUS.md`, `TASK_ROADMAP.md`; owning Contracts der bestaetigten
Befunde unter `docs/dev/`, bisherige Review2-Regressionen und deren Evidenz.

## Akzeptanz / Vorgehen
- Drei aufeinanderfolgende Runden mit Review, konkretem Repro, minimalem Fix,
  passenden Regressionen und unabhaengiger Nachpruefung.
- Neue Fehler zuerst durch erwartbar fehlschlagenden Verhaltenstest nachweisen;
  Performance mit Operationen messen, keine FPS-Aussagen aus Headless-Fixtures.
- Alle Godot-Laeufe ausschliesslich durch `scripts/tests/run_review2_isolated.py`
  mit frischen eindeutigen Nutzerdaten, erstem Pfadguard und Canary; keine
  parallel laufenden Engineprozesse oder Benchmarks.
- Neuer unveraenderlicher Roster-Ausgangsvergleich fuer diesen Auftrag; Bytes,
  Laenge und Schreibzeit vor/nach jedem Test gleich. Keine automatische
  Profilwiederherstellung, keine privaten Rosterbytes im Repository.
- Relevante alte Gates und die gemeinsame Review2-Auswahl nach den Fixes pruefen.
  Bekannte Baselinefehler explizit erhalten/dokumentieren, Tests nicht abschwaechen.
- Runde getrennt committen, Status/Ergebnisindex aktualisieren und Task-Branch
  pushen. Bestehende fremde/ungetrackte Dateien bleiben unberuehrt.

## Betroffene Dateien / lokale Pruefung
Erst nach Bestaetigung je Befund unten ergaenzen. Neue Regressionen unter
`scripts/tests/review_cycles_20261103_*`, Evidenz und neue Roster-Metadaten unter
`output/review_cycles_20261103/`. Produktive Ownership bleibt bei SimulationRoot,
Runtime/Contracts und Registries; UI/Visuals bleiben Leseschichten.

## Risiken / offene Punkte
Unvollstaendige Review-Abdeckung ist keine Bugfreiheit. Headless-Tests ersetzen
keine native FPS-/GPU-/Release-Abnahme. Der vorhandene TASK_348-Baselinefehler
bleibt bis zu einem passenden bestaetigten Fix separat sichtbar.

## Rundenstatus
- [ ] Runde 1: Review, bestaetigte Befunde, Fixes und Regressionen.
- [ ] Runde 2: erneuter Review des neuen Stands, Fixes und Regressionen.
- [ ] Runde 3: erneuter Review, Fixes und gemeinsame Abschlusspruefung.
- [ ] Unabhaengiger Abschlussreview, gezielte Commits und Task-Push.
