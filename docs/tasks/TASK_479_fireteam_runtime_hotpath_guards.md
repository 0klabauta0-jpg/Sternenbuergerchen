# TASK_479 - Fireteam Runtime Hotpath Guards

## Ziel / Problem

Die externen Review-Vorschlaege zu Drop-Phase, O(n^2)-Scans und "Gefuehlsgabe" sollen in den bestehenden Fireteam-Runtime-Pfad uebernommen werden, ohne eine zweite Unit-KI oder eine zweite Navigation-Wahrheit einzufuehren.

Im aktuellen Fireteam-Drill laufen Combat-, Contact-, Overwatch- und Diagnosepfade ueber `MissionCombatLoopDriver`, `SimulationRoot`, `UnitRegistry` und die bestehenden Resolver. Dieser Pfad soll klarer zwischen registrierten Runtime-Units und wirklich kampffaehigen Units unterscheiden.

## Sinnhaftigkeit / Ursache

- Nicht registrierte Drop-/Staging-Units duerfen nicht in Combat-/Contact-Hotpaths mitlaufen.
- Registrierte, aber nicht kampffaehige Units wie `down`, `bleedout` oder `respawning` sollen nicht als Combat-Kandidaten in Contact-/Fire-Schleifen auftauchen.
- Wiederholte Unit-Listenaufloesung im selben Combat-Tick erzeugt unnoetige Arbeit und erschwert Diagnose.
- C/N/A, Skills und Doctrine bleiben Daten-/Command-Gewichte im bestehenden System. Es wird keine neue per-Unit-State-Machine eingefuehrt.

## Umfang

- Zentrale, ticklokale Unit-Caches im `MissionCombatLoopDriver`.
- Explizite Combat-Kandidatenlisten fuer Friendlies und Enemies.
- Contact-/Fire-/Overwatch-Hotpaths nutzen kampffaehige Kandidaten statt rohe registrierte Unit-Listen.
- Audit-Snapshot meldet Filterpolitik, Cache-Zaehler und grobe Pair-/LOS-Messwerte.
- Presence-Audit meldet auch inaktive Friendly-IDs, damit Drop-/Staging-Filter sichtbar werden.

## Nicht-Ziele

- Kein Umstieg auf Godot `NavigationServer`, `NavigationAgent2D` oder per-Unit-`Area2D`.
- Kein neues `TacticalUnit`-Basisskript.
- Keine neue Doctrine-/Gefuehlsgabe-KI neben `FireteamMovementController`, `CombatLoop` und Command-Daten.
- Keine finale Spatial-Bucket-Implementierung fuer Zielauswahl. Dieser Task macht den Hotpath messbar und filtert die Kandidaten stabil.

## Relevante Contracts / Dokumente

- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_behavior_modes_contract.md`

## Akzeptanzkriterien

- Der Combat-Loop nutzt pro Tick einen gemeinsamen Unit-Cache statt mehrfach unabhaengige Path-/Registry-Aufloesungen fuer dieselben Listen.
- Nicht registrierte Friendly-Slots erscheinen im Presence-Audit als inaktiv und nicht als aktive Combat-Friendlies.
- Down-/Respawn-Units bleiben fuer Bleedout/Respawn-Logik erreichbar, tauchen aber nicht als Fire-/Contact-Kandidaten auf.
- `get_combat_hotpath_audit_snapshot()` zeigt aktive Runtime-Counts, kampffaehige Counts, potenzielle Pair-Anzahl und letzte Contact-Scan-Zaehler.
- Tests belegen Filter, Diagnose und Doku-Status.

## Betroffene Dateien

- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_479_fireteam_runtime_hotpath_guards.gd`
- `docs/tasks/TASK_479_fireteam_runtime_hotpath_guards.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_479_fireteam_runtime_hotpath_guards.gd`
- relevante Combat-/Fireteam-Regressionen aus TASK_470, TASK_473, TASK_477 und TASK_478
- `git diff --check`

## Risiken / offene Punkte

- Der Task reduziert unnoetige Kandidaten und macht Kosten sichtbar, ersetzt aber noch keine raeumliche Spatial-Bucket-Zielsuche.
- Wenn spaeter sehr viele Units aktiv sind, sollte auf dieser Diagnose ein eigener Bucket-/Budget-Task aufsetzen.
