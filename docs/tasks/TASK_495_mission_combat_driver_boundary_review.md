# TASK_495 - Mission Combat Driver Boundary Review

## Status: IMPLEMENTIERT

## Ziel / Problem
Der aktuelle `MissionCombatLoopDriver` ist wieder zu einem grossen Missions-Orchestrator mit vielen Verantwortlichkeiten angewachsen. Er umfasst Combat-Tick, Zielwahl, Gegnerverhalten, Objective-Auswertung, Respawn-Koordination, RPC-/Remote-Events und sichtbare UI-Hilfsnodes.

Ziel dieses Tasks ist kein Grossrefactor, sondern ein aktueller Grenzschnitt: Welche Verantwortung bleibt kurzfristig im Driver, welche muss in produktive Resolver/Controller oder Contracts wandern, und welche Befunde sind bereits veraltet.

## Sinnhaftigkeit / Ursache
Die frueheren Tasks `TASK_118` und `TASK_162` haben produktive Resolver und Contracts eingefuehrt, aber der Driver ist durch weitere Mission-, Gegner-, UI- und Multiplayer-Slices erneut verdichtet worden. Ohne neuen Grenzschnitt wird jeder weitere Missionsfeature-Task wahrscheinlicher im Driver landen.

## Umfang
- Aktuellen Verantwortungsumfang von `scripts/tests/mission_combat_loop_driver.gd` dokumentieren.
- Bereits vorhandene Auslagerungen wie `CombatFireDecisionResolver`, `MedicSupportResolver`, `OverwatchController`, `ContactTracker`, `MissionCombatAuthorityContract` und `MissionCombatRemoteEventBridge` gegen den Driver abgleichen.
- Eine kleine Extraktionsreihenfolge fuer Folge-Tasks festlegen:
  - Objective-/Mission-Result-Aufloesung
  - Respawn-/Bleedout-Koordination
  - Enemy-Behavior-Orchestrierung
  - UI-/Debug-Node-Aufbau
  - RPC-/Remote-Event-Ausgabe
- Veraltete Review-Befunde explizit markieren, damit sie nicht erneut umgesetzt werden.

## Nicht-Ziele
- kein kompletter Combat-Rewrite
- keine neue Gegner-KI
- kein Balancing-Pass
- keine Dateiverschiebung des Drivers in diesem Task
- keine Umbenennung von Snapshot-Keys ohne separaten Vertrag

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/tasks/TASK_118_combat_entscheidungen_aus_mission_driver_herausloesen.md`
- `docs/tasks/TASK_162_combat_loop_authority_split.md`
- `docs/dev/combat_loop_authority_contract.md`
- `docs/tasks/TASK_479_fireteam_runtime_hotpath_guards.md`

## Akzeptanzkriterien
- Es gibt einen aktuellen Review-/Task-Nachtrag, der den Driver nach Verantwortlichkeiten und Zielpfaden aufschluesselt.
- Veraltete Befunde wie `roll_override: 0.4` im aktuellen Standardangriffspfad und duplizierter Bleedout-Code sind als erledigt/obsolete markiert.
- Die naechsten Umsetzungsslices sind klein genug, dass sie einzeln getestet und committed werden koennen.
- Keine Gameplay-Wahrheit wird in UI-/Debug-Pfade verschoben.

## Betroffene Dateien
- `scripts/tests/mission_combat_loop_driver.gd`
- `docs/dev/combat_loop_authority_contract.md`
- ggf. neuer Review-/QA-Nachtrag unter `docs/reviews/` oder `docs/qa/`

## Lokale Pruefung
- `rg`/Code-Review gegen aktuelle Driver-Funktionen und vorhandene Resolver.
- Mindestens ein bestehender Combat-Smoke als Nicht-Regressionscheck, falls Code beruehrt wird.
- `git diff --check`

## Risiken / offene Punkte
- Der Driver ist mit vielen Verifiern verdrahtet; grosse Verschiebungen koennen Snapshot- oder Szenenpfade brechen.
- Dieser Task soll bewusst Planung und Schnittklaerung liefern. Umsetzung der einzelnen Extraktionen folgt separat.

## Umsetzung
- `docs/reviews/mission_combat_driver_boundary_review_2026_05_24.md` dokumentiert den aktuellen Verantwortungsumfang, vorhandene Auslagerungen, verifizierte Risiken, veraltete Review-Befunde und die empfohlene Folge-Reihenfolge.
- `docs/dev/combat_loop_authority_contract.md` enthaelt einen TASK_495-Follow-up-Abschnitt, der die erlaubten naechsten Grenzen festhaelt.
- `roll_override: 0.4` und duplizierter Bleedout-Code wurden als obsolete Befunde markiert; Registry-/Elimination-Risiko bleibt fuer `TASK_496`.

## Abschluss-Pruefung
- [x] Driver-Verantwortungen per `rg` und Code-Lektuere gegen aktuelle Funktionen geprueft.
- [x] Ausgelagerte Resolver/Contracts gegen Driver-Aufgaben abgeglichen.
- [x] Keine Gameplay- oder Runtime-Codeaenderung in diesem Task.
- [x] `git diff --check`
