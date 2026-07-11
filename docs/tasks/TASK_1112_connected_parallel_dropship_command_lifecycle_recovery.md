# TASK_1112 - Connected Parallel Dropship Command Lifecycle and Recovery

## Status: IMPLEMENTIERT

## Ziel / Problem
Zwei aktive Multiplayer-Peers muessen zwei Dropships gleichzeitig bedienen koennen. Retransmits duerfen keinen Doppelcommit erzeugen, und ein Disconnect darf den autoritativen Craft-State nicht verlieren oder die andere Drop-Planung beschaedigen.

## Sinnhaftigkeit / Ursache
TASK_1111 autorisiert einzelne Dropship-Commands. `SimulationRoot` besitzt jedoch noch keinen Command-ID-Dedupe-Guard. Parallele BLUE-/GOLD-Requests und Assignment-Recovery nach einem Disconnect sind fuer Dropships noch nicht gemeinsam verifiziert.

## Umfang
- Dropship-Commands erhalten stabile Command-IDs.
- `SimulationRoot` dedupliziert bereits akzeptierte Command-IDs vor Queue und Commit.
- Dedupe bleibt bounded und liefert read-only Diagnosewerte.
- Drei echte ENet-Peers setzen BLUE- und GOLD-LZ parallel.
- Alle Peers konvergieren auf beide Craft-Zustaende.
- Doppelrequest committed genau einmal.
- Nach GOLD-Disconnect bleibt der Host-State erhalten.
- Rebind von GOLD auf den verbleibenden Client erlaubt weitere GOLD-Commands, ohne BLUE zu veraendern.

## Nicht-Ziele
- Kein allgemeines Reliable-Command-Protokoll.
- Keine persistente Match-Recovery nach Hostverlust.
- Keine Aenderung an Flugkurven oder Deboard-Zeiten.
- Kein UI-Redesign.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1111_connected_dropship_command_authority_ownership.md`
- `scripts/core/simulation_root.gd`
- `scripts/multiplayer/multiplayer_command_contract.gd`

## Akzeptanzkriterien
- BLUE und GOLD koennen im selben Netzwerkfenster unterschiedliche LZs setzen.
- Host und beide Clients sehen beide LZs nach Snapshot-Konvergenz.
- Identische `command_id` erzeugt einen Commit und einen Dedupe-Hit.
- Der Dedupe-Cache ist begrenzt.
- GOLD-State bleibt nach Peer-Disconnect erhalten.
- Nach Assignment-Rebind darf der verbleibende Client GOLD bedienen.
- BLUE-State bleibt dabei unveraendert.

## Betroffene Dateien
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1112_connected_parallel_dropship_command_lifecycle_recovery.gd`
- Status-, Roadmap- und HTML-Arbeitsreport-Dokumentation

## Lokale Pruefung
- TASK_1112 Verifier
- TASK_1111 Authority/Ownership
- TASK_1110 Snapshot-Perspektive
- TASK_396 Zwei-Dropship-Deboarding
- TASK_399 Dropship-Hotpath
- TASK_1104 Drei-Peer-Produktlauf
- `git diff --check`

## Risiken / offene Punkte
Command-IDs sind Idempotenzschluessel, keine dauerhafte Gameplay-Historie. Der Cache muss klein bleiben und darf keine Payloads oder UI-State speichern.

## Ergebnis
- Zwei echte Clients setzen BLUE- und GOLD-LZ parallel; Host und beide Clients konvergieren auf beide Craft-Zustaende.
- Dropship-Requests erhalten stabile Command-IDs aus Peer, lokaler Sequenz, Craft und Aktion.
- `SimulationRoot` committed eine bereits akzeptierte Dropship-Command-ID nur einmal.
- Der read-only Dedupe-Cache ist auf 2048 IDs begrenzt und evicted alte Eintraege.
- GOLD-State bleibt nach Disconnect erhalten; Assignment-Rebind auf BLUE-Client erlaubt GOLD-Fortsetzung.
- Der Recovery-Command veraendert BLUE nicht.

## Verifikation
- TASK_1112: 13/13
- TASK_1111: 30/30
- TASK_281: 33/33
- TASK_1110: 20/20
- TASK_396: 17/17
- TASK_399: 9/9
- TASK_1104: 31/31
