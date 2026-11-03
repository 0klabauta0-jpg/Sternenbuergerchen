# Drei weitere Performance-/Architekturrunden, 2026-11-03

## Ziel / Problem
Drei weitere Review-, Fix- und Nachreview-Runden auf dem aktuellen Main
`21bacf0f2f3268cf058f1c5e52381fce4e4b1792`; bestaetigte aktuelle Probleme
gezielt beheben und den gemeinsam geprueften Stand nach Main pushen.

## Sinnhaftigkeit / Ursache
Weitere reale Hotpath- und Ownership-Fehler suchen. Alte Befunde zuerst gegen
den aktuellen Code pruefen; keine Anzahl von Fehlern erzwingen.

## Umfang und Nicht-Ziele
Kleine integrierbare Fixes, Regressionen, unabhängige Nachreviews, gemeinsame
Abschlusspruefung und Main-Integration. Keine neuen Features, Renderqualitaets-
Absenkung, pauschalen Refactors, Assets, Exporte oder Release-Abnahme.
Vorhandene ungetrackte Arbeiten bleiben unangetastet.

## Relevante Dokumente / Contracts
- AGENTS.md; docs/PROJECT_BRIEF.md; docs/ARCHITECTURE.md; docs/CODEX_RULES.md
- docs/IMPLEMENTATION_STATUS.md; docs/TASK_ROADMAP.md
- docs/tasks/REVIEW_CYCLES_2026_11_03_performance_architecture.md
- docs/dev/runtime_script_layout_contract.md
- Weitere owning Contracts werden pro bestaetigtem Befund ergaenzt.

## Akzeptanzkriterien
- [ ] Drei Review-/Fix-/Nachreview-Runden abgeschlossen.
- [ ] Neue Regressionen vor jedem Produktfix korrekt RED, danach GREEN.
- [ ] Performanceaussagen durch gleiche Workloads/Operationen belegt.
- [ ] Alle Godot-Laeufe ausschliesslich sequenziell ueber
  scripts/tests/run_review2_isolated.py mit frischen Nutzerdaten und Pfadguard.
- [ ] Originalroster SHA256, Laenge und Schreibzeit vor/nach jedem Lauf gleich.
- [ ] Abschlussmatrix und unabhaengiges Gesamt-Nachreview bestanden.
- [ ] Nur Taskdateien committed, Main konfliktfrei integriert und Push verifiziert.

## Betroffene Dateien
Diese Taskdatei; Befund-spezifische Produkt-/Regressiondateien folgen nach Review.
Evidence unter output/review_cycles_4_6_20261103/.

## Lokale Pruefung
Neuer unabhaengiger Roster-Baseline/Sicherheitsabzug ausserhalb des Repositorys;
bewaehrter unveraenderter Isolationsrunner mit synchronem Userdata-Guard.
Gezielte RED/GREEN-Gates, angrenzende Regressionen, gemeinsame Abschlussmatrix.
Kein direkter Godot-Start im echten Profil. Keine automatische Wiederherstellung.

## Risiken / offene Punkte
Headless-Operationsmessungen sind keine native FPS-/GPU-Abnahme.
Keine unbestaetigten Review-Ideen implementieren. Native Langzeitperformance
und bereits bekannte Altfehler bleiben getrennt ausgewiesen.

## Runden / Befunde / Ergebnisse
Review gestartet; noch keine neuen Befunde bestaetigt.
