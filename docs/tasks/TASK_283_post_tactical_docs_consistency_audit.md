# TASK_283 - Post Tactical Docs Consistency Audit

## Ziel
Nach der grossen Tactical-Overhaul-Reihe sollen Roadmap, Implementation Status, Task-Dokumente, Dev-Dokumente und Reports auf Widersprueche, veraltete Aussagen, falsche Abhaengigkeiten und Design-Drift geprueft werden.

Dieser Task ist ein Doku-Audit mit Biss: Er soll nicht nur Tippfehler finden, sondern aufdecken, ob die Dokumente inzwischen unterschiedliche Wahrheiten erzaehlen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_269 - Tactical Doctrine Source Review Game Abstraction
- TASK_270 - Commander to Fireteam Leader Delegation Contract
- TASK_271 - Tactical Command Modes ROE Fire Rules
- TASK_272 - Multi Fireteam Coordinated Area Plan
- TASK_273 - Fireteam Leader Skill Tactical Progression
- TASK_274 - Tactical Communication Feedback Layer
- TASK_275 - Command Button Hierarchy Arrangement Overhaul
- TASK_276 - Tactical Breakout and Exception Behavior
- TASK_277 - Dropship Freighter Anti Armor Threat Contract
- TASK_278 - Air Asset Loss Recovery Meta Loop
- TASK_279 - LZ Security Air Asset Tactical Playability Smoke
- TASK_280 - Tactical Profile Editor Scenario Authoring
- TASK_281 - Tactical Command Multiplayer Authority Snapshot
- TASK_282 - Tactical Overhaul Playability Performance Help Gate

## Kontext
Viele neue Tasks erzeugen neue Begriffe: CommanderIntent, FTL ExecutionPlan, TacticalRules, BreakoutState, AirAssetStatus, LZ Security, Planrollen, Kommunikation, Help-Popups, Editorprofile und Multiplayer-Snapshots. Wenn diese Begriffe in Doku und Code unterschiedlich verwendet werden, schleichen sich spaeter Bugs ein.

## Umfang
1. Roadmap-/Status-Audit:
   - Task-Reihenfolge, Phasen, Status, naechste Schritte.
   - Keine doppelten oder widerspruechlichen Tasknummern.
   - Keine alten "naechster Schritt"-Texte, die neue Folgephasen ignorieren.
2. Dev-Dokumente:
   - Tactical-, Command-, Multiplayer-, Help-, AirAsset- und Editor-Vertraege vergleichen.
   - Ein Begriff darf nicht in drei Dokumenten anders bedeuten.
   - Designentscheidung vs. offene Frage klar markieren.
3. Task-Dokumente:
   - Voraussetzungen, Nicht-Ziele, Akzeptanzkriterien und erwartete Dateien konsistent halten.
   - Keine Akzeptanzkriterien, die im Nicht-Ziel widersprochen werden.
   - Keine Tests auf Dateien, die anders benannt sind.
4. Quellen-/Design-Drift:
   - Quellen aus TASK_269 nur als Game-Abstraktion behandeln.
   - Keine reale Doktrin als konkrete Schrittanleitung in Gameplay-Doku.
5. Report:
   - `docs/reviews/post_tactical_docs_consistency_audit.md`.
   - Befunde mit Schweregrad: blocker, important, cleanup.
   - Folge-Patchtasks fuer echte Korrekturen.

## Nicht-Ziele
- Kein Code-Fix ausser offensichtlichen Doku-Typos.
- Kein Umschreiben der kompletten Roadmap.
- Kein finales Balancing.
- Keine erneute Quellenrecherche, ausser ein Dokument referenziert unklar.

## Akzeptanzkriterien
- [x] Roadmap und Implementation Status widersprechen sich nicht bei TASK_269 bis TASK_282.
- [x] Kernbegriffe sind ueber Dev-Dokumente und Tasks hinweg einheitlich.
- [x] Akzeptanzkriterien, Nicht-Ziele und lokale Pruefungen passen zusammen.
- [x] Quellenbezug bleibt Game-Abstraktion und keine reale Einsatzanleitung.
- [x] Report nennt konkrete Dateien, Zeilen/Abschnitte und empfohlene Korrekturen.
- [x] Ein Verifier prueft Pflichtdokumente, Tasknummern, Linkziele und offensichtliche Statusdrift.

## Erwartete Dateien
- `docs/reviews/post_tactical_docs_consistency_audit.md`
- `scripts/tests/task_283_post_tactical_docs_consistency_audit.gd`
- `docs/tasks/TASK_283_post_tactical_docs_consistency_audit.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_283_post_tactical_docs_consistency_audit.gd`
- [x] `git diff --check`

## Risiken
- Der Audit darf nicht zum Doku-Refactor ohne Ende werden. Befunde priorisieren und Korrekturen in kleine Patchtasks schneiden.
- Zu weiche Formulierungen verstecken echte Widersprueche.

## Naechster Schritt
Nach TASK_283 prueft TASK_284 die Architekturgrenzen und Gameplay-Wahrheit im Code.
