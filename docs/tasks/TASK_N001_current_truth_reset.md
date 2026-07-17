# TASK_N001 — Reset der aktuellen Wahrheit

## Ziel / Problem

Eine kurze, menschenlesbare Quelle für den aktuellen Produktstand und ein maschinenlesbares Evidenzmanifest schaffen, ohne die historischen Ledger zu löschen, die bestehende Verifier verwenden.

## Ursache / Nutzen

Das Projekt besitzt umfangreiche historische Dokumentation, doch weder Tasknummer noch datierter Report drücken sichere gegenwärtige Reife aus. Der Evidenzvertrag trennt für Spieler, Reviewer und Folgetasks implementiertes Verhalten, frische Nachweise, Caveats und Vision.

## Umfang

- `docs/DOCS_INDEX.md`, `docs/CURRENT_GAME_STATE.md`, `docs/PRODUCT_MILESTONES.md`, `docs/qa/CURRENT_EVIDENCE.md`, `docs/visual/WORLD_ART_DIRECTION.md`, `docs/reports/README.md` sowie `data/project_evidence_manifest.json` nach Schema v1 anlegen.
- Projektbrief, Regeln und Architektur um Commander-Fantasie, vollständige Schleife, V1-Grenzen, Frontier-Low-Poly-Pfeiler, Current-Truth-Vorrang und Anti-Monolith-Leitplanken ergänzen.
- Kompatibilitätsbanner in `docs/IMPLEMENTATION_STATUS.md` und `docs/TASK_ROADMAP.md` additiv einfügen.
- Datierte Reports und Handbücher mit `supersedes`-Metadaten als Snapshots indexieren, ohne die TASK-1181-HTML zu verändern.
- TASK_1180 ausschließlich als hashgesicherten Kandidaten außerhalb des aktiven Checkouts mit versioniertem Recovery-Manifest führen; nicht als Evidence-Record.

## Nicht-Ziele

- Keinen frischen TASK-1179-Objective-/Debrief-Lauf behaupten.
- TASK_1180 nicht integrieren, kein Runtime-Verhalten ändern und keine Legacy-Dokumentation bereinigen.
- Keine Szenen, Karten, UI- oder Gameplay-Wahrheit ändern.

## Relevante Contracts / Dokumente

- `docs/DOCS_INDEX.md`, `docs/CURRENT_GAME_STATE.md`, `docs/PRODUCT_MILESTONES.md`, `docs/qa/CURRENT_EVIDENCE.md`
- `docs/history/TASK_HISTORY_SUMMARY.md` und `docs/history/recovery/TASK_1180_recovery_manifest.json`
- `docs/PROJECT_BRIEF.md`, `docs/ARCHITECTURE.md`, `docs/CODEX_RULES.md`, `AGENTS.md`
- `docs/IMPLEMENTATION_STATUS.md` und `docs/TASK_ROADMAP.md` als Kompatibilitätsledger

## Akzeptanzkriterien

- Genau ein Dokument deklariert den kanonischen aktuellen Spielstand, genau ein Meilenstein ist mit `now` markiert.
- Das Manifest enthält `delivery_state`, `product_maturity`, `scope`, `evidence[]` und `candidates[]`; jeder Evidence-Record hat `id`, `commit`, `run_at`, `type`, `result`, `artifact`, `caveat` und `owning_paths`.
- Jeder Evidence-Commit ist ein 7- bis 40-stelliger Hex-SHA, jedes repo-relative Evidence-Artefakt existiert.
- TASK_1180 steht nur in `candidates[]`, verweist auf den exakten Recovery-Pfad unter `docs/tasks/`, den SHA-256 `D290C5115B3BE6044C2CFCD3086DBFDCF92EE55294FE7B0DED21EDDCB25119E6` und ein versioniertes Recovery-Manifest.
- Aktuelle Claims nennen TASK_1179 als historische 18/18-Evidenz mit Frische-Caveat und TASK_1180 als nicht integrierten hashgesicherten Kandidaten.
- `scripts/tests/project_current_truth_contract.gd` akzeptiert `--project-root <absoluter-pfad>`, läuft aus einem externen Verzeichnis ohne Projekt-Autoloads und prüft RED vor sowie GREEN nach der Hierarchie/Provenance-Implementierung.
- Der Verifier erzwingt diese Maximalbudgets: `DOCS_INDEX.md` 120, `CURRENT_GAME_STATE.md` 220, `PRODUCT_MILESTONES.md` 180, `CURRENT_EVIDENCE.md` 220 und `WORLD_ART_DIRECTION.md` 180 Zeilen.

## Betroffene Bereiche

Dokumentationsindizes, Evidenz- und Recovery-Manifest, Projektleitlinien, Status-/Roadmap-Banner und ein fokussierter Dokumentationsverifier. Keine Gameplay-Szene, kein Runtime-Script, keine Karte und keine historische Task-Datei.

## Lokale Prüfung

Den Dokumentationscontract aus einem externen Verzeichnis mit absolutem `--project-root` erst rot und dann grün ausführen; JSON, Evidence-Provenance und Kandidaten prüfen; Budgets sowie canonical-/now-Einzigkeit prüfen; TASK-1181-Hash und `git diff --check` prüfen.

## Risiken / offene Punkte

Kompatibilitätsledger werden von Legacy-Tools verwendet und bleiben daher additiv. Evidenzsprache darf weder einen wiederhergestellten Kandidaten noch einen historischen grünen Lauf zu einer aktuellen Release-Behauptung machen. Ein reproduzierbarer Checkout bleibt Aufgabe von TASK_N002.

## Abhängigkeit / Exit-Gate

Dieser erste aktive Task liefert Index, Manifest, Einzigkeits- und Kompatibilitätsvertrag. TASK_N002 darf erst starten, wenn diese Elemente inklusive isoliert laufendem Verifier committed sind.
