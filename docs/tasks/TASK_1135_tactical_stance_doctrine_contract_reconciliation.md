# TASK_1135 - Tactical Stance Doctrine Contract Reconciliation

## Ziel / Problem
TASK_421 und TASK_425 erwarten noch die urspruenglichen Move-Sonderwerte fuer Speed und Sicht. Seit TASK_451 gilt laut `fireteam_behavior_modes_contract.md` jedoch ein globales C/N/A-Grundprofil, das TASK_429 bereits fuer Move, Defend, Take und Engage prueft. Der Runtime-Code enthaelt parallel beide Zahlensaetze und ueberschreibt die alten Parameter spaeter still.

## Ursache / Sinnhaftigkeit
Die spaetere Workbench-Entscheidung wurde funktional importiert, aber historische Tests, Tasktexte und tote Balancekonstanten wurden nicht vollstaendig migriert. Dadurch sieht der Code aus, als koenne man Move-, Defend-, Take- oder Engage-Speed getrennt balancieren, obwohl zur Laufzeit immer das gemeinsame Profil gewinnt.

## Entscheidung
- TASK_451/TASK_429 und `fireteam_behavior_modes_contract.md` sind der aktuelle Vertrag.
- Speed, Sicht, Deckungsprioritaet, Aim-Bereitschaft, Kontakt-Initiative und Team-Zielhilfe kommen fuer C/N/A aus genau einem globalen Grundprofil.
- Commands bleiben durch Posture, Weapon-Posture, Zielpolitik, Formation und Sequenz unterscheidbar.
- TASK_421/TASK_425 bleiben als historische Funktionsvertraege fuer Move-Posture, Fog-of-War, Live-Revision und UI-Weitergabe erhalten, verwenden aber die aktuelle Profilbalance.

## Umfang
- Altverifier auf die aktuelle globale C/N/A-Balance aktualisieren.
- Historische Tasktexte als durch TASK_451/TASK_1135 superseded kennzeichnen.
- Wirkungslose befehlsspezifische Speed-/Sicht-/Attack-Balancekonstanten und Builder-Parameter entfernen.
- Zentralen Profilpfad sowie command-spezifische Postures absichern.

## Nicht-Ziele
- Keine neue Balance und keine Aenderung der aktuellen Runtimewerte.
- Keine Aenderung an Formation, Pathfinding, Combat, Fog-of-War oder Command-Revisionen.
- Keine UI-, RPC-, Snapshot- oder Multiplayer-Autoritaetsaenderung.

## Relevante Contracts / Dokumente
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/tasks/TASK_421_move_stance_posture_speed_sight.md`
- `docs/tasks/TASK_425_live_move_stance_update.md`
- `docs/tasks/TASK_429_fireteam_behavior_modes_runtime.md`
- `docs/tasks/TASK_451_fireteam_workbench_runtime_import.md`

## Akzeptanzkriterien
- TASK_421 und TASK_425 sind mit dem aktuellen globalen Profil gruen.
- TASK_429 bleibt 100/100 gruen.
- Move, Defend, Take und Engage lesen C/N/A-Speed und -Sicht aus derselben Quelle.
- Command-spezifische Movement-/Weapon-Postures bleiben erhalten.
- Der MovementController enthaelt keine wirkungslosen alten command-spezifischen Speed-/Sicht-/Attack-Konstanten mehr.
- Live-Stance-Updates behalten Command-Revision und stale-token Schutz.

## Betroffene Dateien
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/task_421_move_stance_posture_speed_sight.gd`
- `scripts/tests/task_425_live_move_stance_update.gd`
- `scripts/tests/task_1135_tactical_stance_doctrine_contract_reconciliation.gd`
- TASK_421-/TASK_425-Dokumente sowie Status, Roadmap und HTML-Bericht

## Lokale Pruefung
- TASK_1135 RED/GREEN
- TASK_421, TASK_425 und TASK_429
- Movement-/Pathfinding-/Combat-Regressionen
- TASK_109, TASK_503, TASK_773 und TASK_222
- `git diff --check`

## Risiken / offene Punkte
Die aktuellen globalen Werte sind weiterhin Workbench-Startwerte und keine finale Balance. Eine spaetere Aenderung muss am globalen Profil und seinem Contract erfolgen, nicht durch neue versteckte Command-Ausnahmen.
