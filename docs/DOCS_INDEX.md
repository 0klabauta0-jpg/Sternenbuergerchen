# Dokumentationsindex

## Geltung und Lesereihenfolge

Für Gegenwartsbehauptungen gilt zuerst [CURRENT_GAME_STATE.md](CURRENT_GAME_STATE.md): Es ist das einzige kanonische Dokument zum aktuellen Spielstand. Frische Belege und ihre Einschränkungen stehen in [CURRENT_EVIDENCE.md](qa/CURRENT_EVIDENCE.md); der nächste verbindliche Produktschritt steht in [PRODUCT_MILESTONES.md](PRODUCT_MILESTONES.md).

Diese drei kurzen Dokumente ersetzen keine Runtime-Wahrheit. Gameplay-State bleibt bei SimulationRoot, Runtime-Komponenten und ihren Contracts; UI, Visuals und Dokumente erklären oder lesen ihn nur.

## Produkt und Arbeit

- [fireteam_command_gateway_contract.md](dev/fireteam_command_gateway_contract.md) â€” gemeinsamer Plan-dann-GO-Pfad fuer Buttons, Hotkeys, RMB und Netzwerk.
- [PROJECT_BRIEF.md](PROJECT_BRIEF.md) — Commander-Fantasie, Core Loop, V1-Grenzen und visueller Pfeiler.
- [ARCHITECTURE.md](ARCHITECTURE.md) — Autorität, Runtime-Grenzen und technische Leitplanken.
- [WORLD_ART_DIRECTION.md](visual/WORLD_ART_DIRECTION.md) — Frontier Low-Poly als visuelle Richtung ohne neue Kartenregeln.
- [TASK_N001_current_truth_reset.md](tasks/TASK_N001_current_truth_reset.md) — Scope und Akzeptanz dieses Resets.
- [docs/tasks/README.md](tasks/README.md) — aktive N-Tasks vor historischen TASK-Nummern.

## Evidenz und Historie

- [CURRENT_EVIDENCE.md](qa/CURRENT_EVIDENCE.md) — lesbare Evidenz mit Frische und Caveats.
- [project_evidence_manifest.json](../data/project_evidence_manifest.json) — maschinenlesbarer Schema-v1-Vertrag.
- [TASK_HISTORY_SUMMARY.md](history/TASK_HISTORY_SUMMARY.md) — unverändertes historisches Ledger; keine Gegenwartsfreigabe.
- [TASK_1180_recovery_manifest.json](history/recovery/TASK_1180_recovery_manifest.json) — hashgesicherter, nicht integrierter Kandidat außerhalb des Checkouts.
- [README.md](reports/README.md) — datierte HTML-Reports und Handbücher als unveränderliche Momentaufnahmen.
- [GDD_STATUS.md](GDD_STATUS.md) — Alt-GDD als Inspiration/Migrationsquelle.
- [IMPLEMENTATION_STATUS.md](IMPLEMENTATION_STATUS.md) und [TASK_ROADMAP.md](TASK_ROADMAP.md) — Kompatibilitätsledger für bestehende Verifier.

## Dokumentgrenzen

Aktuelle Kurzform-Dokumente dürfen nicht zu einem neuen Monolithen wachsen. Der Dokumentationsvertrag setzt deshalb diese Maxima: DOCS_INDEX 120, CURRENT_GAME_STATE 220, PRODUCT_MILESTONES 180, CURRENT_EVIDENCE 220 und WORLD_ART_DIRECTION 180 Zeilen. Details gehören in Contracts, konkrete Tasks, QA-Artefakte oder historische Snapshots.
