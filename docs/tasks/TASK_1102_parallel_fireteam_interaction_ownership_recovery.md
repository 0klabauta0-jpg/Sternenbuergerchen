# TASK_1102 - Parallel Fireteam Interaction Ownership and Recovery

## Ziel / Problem
Zwei Spieler sollen mit getrennten Fireteams gleichzeitig unterschiedliche Missionsinteraktionen bearbeiten koennen. Ein zweites Fireteam darf eine bereits laufende Interaction nicht still uebernehmen oder deren Hold-Fortschritt ersetzen. Disconnect und Rejoin muessen die Fireteam-basierte Ownership erhalten.

## Ursache / Sinnhaftigkeit
Der Host speichert Pending-Interactions derzeit nach `interaction_id`. Ein spaeter akzeptierter Command kann denselben Eintrag mit einem anderen `fireteam_id` ueberschreiben, obwohl der erste Hold bereits laeuft. Die bestehende Multiplayer-Command-Pruefung kennt Team und Fireteam, aber noch nicht die dynamische Interaction-Reservierung.

## Designentscheidung
- Empfohlen und umgesetzt wird ein read-only Preflight-Validator am autoritativen `SimulationRoot`: Der Runtime-Besitzer der Interaction prueft vor Queue/Accept, ob ein Command die bestehende Fireteam-Reservierung verletzt.
- Nicht gewaehlt: Konflikte erst nach `network_command_accepted` ignorieren. Das wuerde dem Client faelschlich `HOST OK` melden und den Command bereits enqueuen.
- Nicht gewaehlt: Interaction-Ownership als zweite Dictionary-Wahrheit im `SimulationRoot`. Die Pending-Interaction bleibt allein beim `MissionCombatLoopDriver`; der Root bleibt Commit-Grenze und ruft nur den Validator auf.

## Umfang
- Genau ein optionaler Network-Command-Preflight-Validator im `SimulationRoot`.
- Interaction-Validator im autoritativen Mission-Driver.
- Exklusive Ownership pro laufender `interaction_id` und `fireteam_id`.
- Derselbe Fireteam darf einen Command erneut senden; ein anderes Fireteam erhaelt einen expliziten Reject.
- Derselbe Fireteam darf bei einem Continue nur Peer/Unit aktualisieren; Ziel, Radius, Dauer und Gate-Metadaten bleiben aus dem ersten host-akzeptierten Pending-Eintrag stabil.
- Unterschiedliche Interactions duerfen parallel fortschreiten und gemeinsam repliziert werden.
- Reconnect mit neuer Peer-ID darf dieselbe Fireteam-Ownership fortsetzen.

## Nicht-Ziele
- Keine Host-Migration.
- Keine globale Lock-/Reservation-Architektur fuer alle Command-Typen.
- Keine UI-Neugestaltung.
- Keine Aenderung der sequentiellen Station-Route-Gates.

## Relevante Contracts
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_1101_connected_interaction_reconnect_state_recovery.md`
- `scripts/mission/mission_interaction_multiplayer_command.gd`

## Akzeptanzkriterien
- Zwei Fireteams koennen zwei unterschiedliche Interactions gleichzeitig halten.
- Ein fremdes Fireteam kann eine laufende Interaction weder uebernehmen noch deren Timer zuruecksetzen.
- Der Reject lautet `interaction_reserved_by_other_fireteam` und erreicht den anfragenden Client.
- Der gleiche Fireteam darf nach Peer-ID-Rebind die eigene Interaction weiter bedienen.
- Ein Same-Fireteam-Resend kann Ziel, Radius oder Dauer der laufenden Interaction nicht umschreiben.
- Pending-State, `network_command_accepted`, Client-Ergebnis und Command-Queue erhalten bei Same-Fireteam-Continue dasselbe kanonische Payload.
- Host- und Client-Snapshot enthalten beide parallelen States mit korrektem `fireteam_id`.
- Keine UI-/Client-Commands oder Effects entstehen aus Snapshot-Recovery.
- Der Preflight hat ohne registrierten Validator keinerlei Verhaltensaenderung fuer bestehende Commands.

## Betroffene Dateien
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/task_1102_parallel_fireteam_interaction_ownership_recovery.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- TASK_1102-Verifier mit zwei Fireteams, Parallelfortschritt, Konflikt-Reject und Rebind.
- TASK_1101 Reconnect-Regression.
- TASK_1093 Full-Route-Regression.
- TASK_1083 Zwei-Instanz-Authority-Regression.
- `git diff --check`.

## Risiken / offene Punkte
- Der aktuelle Runtime-Owner ist noch historisch im Testpfad `MissionCombatLoopDriver`; der Preflight-Vertrag darf dessen spaetere Extraktion nicht blockieren.
- Eine abgeschlossene Interaction bleibt abgeschlossen, ist aber nicht mehr pending. Wiederholte Commands muessen in einem spaeteren Szenario-Policy-Task entschieden werden; TASK_1102 behandelt nur laufende Ownership.
