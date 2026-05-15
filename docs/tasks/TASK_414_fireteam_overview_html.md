# TASK_414 - Fireteam Overview HTML

## Ziel / Problem

Der aktuelle Fireteam-Stand verteilt sich ueber Meta-Staging, Mission-HUD, taktische Resolver, Runtime-Kommandos und Visual-Snapshots. Fuer die weitere Arbeit am Fireteam braucht es eine kompakte, lokal lesbare HTML-Uebersicht, die zeigt, wo welche Information herkommt und wo sie abgefragt wird.

## Sinn / Ursache

Fireteam ist im aktuellen Projekt kein einzelnes monolithisches Objekt. Homebase/FOB halten Staging- und Payload-Daten, die Mission liest Fireteam-IDs, Unit-Nodes und Snapshots, und `SimulationRoot` bleibt die autoritative Stelle fuer Runtime-Kommandos. Ohne eine Karte dieser Wege steigt das Risiko, UI-State versehentlich als Gameplay-Wahrheit zu behandeln.

## Umfang

- Fireteam-Datenfluss ueber Homebase, FOB, Mission und Runtime dokumentieren.
- Wichtige Abfragepunkte und Funktionen tabellarisch nennen.
- Legacy-FTL-Pfad und aktuellen Mission-Tactical-Pfad unterscheiden.
- Risiken und offene Architektur-Watchpoints sichtbar machen.

## Nicht-Ziele

- Keine Code-Aenderung an Fireteam-Logik.
- Keine neuen Contracts oder Gameplay-Regeln.
- Keine Aussage, dass alle Pfade final architektonisch perfekt sind.
- Kein Commit/Push ohne separate Freigabe.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/dev/commander_fireteam_delegation_contract.md`
- `docs/dev/multi_fireteam_plan_contract.md`
- `docs/dev/fireteam_leader_tactical_progression.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_404_fireteam_movement_posture_bridge.md`

## Akzeptanzkriterien

- [x] HTML-Datei nennt die wichtigsten Fireteam-Informationsquellen.
- [x] HTML-Datei trennt Meta-, Mission-, Taktik- und Runtime-Verantwortung.
- [x] HTML-Datei enthaelt konkrete Code-Orte fuer Abfragen und Mutationen.
- [x] HTML-Datei benennt bekannte offene Punkte/Risiken.

## Betroffene Dateien

- `docs/tasks/TASK_414_fireteam_overview_html.md`
- `docs/reports/fireteam_overview.html`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung

- [x] `Get-Item docs/reports/fireteam_overview.html`
- [x] `Select-String -Path docs/reports/fireteam_overview.html -Pattern "<!doctype html>","Fireteam Ueberblick","Informationsquellen"`
- [x] `git diff --check`

## Risiken / offene Punkte

- Die Uebersicht ist eine Bestandsaufnahme des aktuellen Arbeitsstands und ersetzt keinen Contract.
- Einige Mission-HUD-Abfragen laufen ueber Friendly-Unit-Node-Sammlungen; Runtime-Mutationen laufen dagegen ueber `SimulationRoot` und `UnitRegistry`.
