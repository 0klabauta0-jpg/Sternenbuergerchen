# TASK_1111 - Connected Dropship Command Authority and Ownership

## Status: IMPLEMENTIERT

## Ziel / Problem
LZ, Approach, Drop und Return muessen in verbundenen Missionen als hostautoritative Commands laufen. Ein Client darf weder seinen lokalen Dropship-State direkt mutieren noch ein Craft bedienen, dessen Fireteam ihm nicht zugewiesen ist.

## Sinnhaftigkeit / Ursache
TASK_1110 repliziert den Transportstate korrekt. Die aktuellen Mission-Callbacks mutieren LZ, Approach, Drop-Sequenz und Return jedoch weiterhin direkt im lokalen `MissionTacticalSandboxController`. Der vorhandene `dropship_command`-Contract kennt nur einen Teil der Aktionen, verlangt keine Craft-ID und verarbeitet akzeptierte Commands in `SimulationRoot` nicht.

## Umfang
- Dropship-Commands fuer `set_lz`, `set_dropship_approach`, `call_dropship` und `return_dropship` vollstaendig definieren.
- Craft-ID, Team und Fireteam als Pflichtbesitz pruefen.
- Peer-Fireteam-Zuweisung und Craft-Payload-Zuordnung auf dem Host validieren.
- Akzeptierte Commands erst im autoritativen Physiktick committen.
- Mission-Controller wendet nur committed Commands an.
- Verbundene UI-Callbacks senden zum Host und mutieren vor Snapshot/Commit keinen lokalen Transportstate.
- Menschliches Pending-/Accepted-/Blocked-Feedback anzeigen.

## Nicht-Ziele
- Keine neue Dropship-Simulation.
- Keine Replikation lokaler Auswahl.
- Kein Umbau des Snapshot-Chunktransports.
- Keine Aenderung an Flugkurven oder Deboard-Zeiten.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1110_connected_multi_dropship_fireteam_selection_perspective.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `scripts/multiplayer/multiplayer_command_contract.gd`

## Akzeptanzkriterien
- BLUE-Peer darf BLUE-Craft bedienen und GOLD-Craft nicht.
- Spectator kann keinen Dropship-Command senden.
- Unbekannte Craft-ID und fehlende Fireteam-ID werden abgewiesen.
- LZ, Approach, Drop und Return werden erst nach Host-Commit mutiert.
- Client-Request erzeugt keine lokale Drop-Sequenz.
- Host-Snapshot repliziert das Ergebnis an alle Clients.
- Bestehende Singleplayer- und Zwei-Dropship-Abläufe bleiben gruen.

## Betroffene Dateien
- `scripts/multiplayer/multiplayer_command_contract.gd`
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1111_connected_dropship_command_authority_ownership.gd`
- Status-, Roadmap- und HTML-Arbeitsreport-Dokumentation

## Lokale Pruefung
- TASK_1111 Verifier
- TASK_281 Multiplayer Command Contract
- TASK_1110 Mehrschiff-Snapshot
- TASK_396 Zwei-Dropship-Deboarding
- TASK_399 Dropship-Hotpath
- TASK_1104 Drei-Peer-Produktlauf
- `git diff --check`

## Risiken / offene Punkte
Der Mission-Controller besitzt den historischen Dropship-Runtime-State. `SimulationRoot` soll Commands validieren und committen, aber keinen zweiten Transportstate aufbauen. Die Craft-/Fireteam-Zuordnung muss aus dem bereits publizierten autoritativen Dropship-Kontext gelesen werden.

## Ergebnis
- Der Dropship-Command-Contract verlangt Craft, Fireteam und Team und prueft Peer-Zuweisung gegen die autoritativen Dropship-Karten.
- LZ, Approach, Drop und Return werden in `SimulationRoot` gequeued und erst im Physiktick ueber `dropship_command_committed` ausgefuehrt.
- Verbundene UI-Callbacks senden Requests und mutieren vor Host-Commit keinen Transportstate.
- Ein echter ENet-Rundweg bestaetigt Client-Request, Host-Commit, Snapshot-Konvergenz und Fremd-Craft-Reject.
- Spectator, fehlende IDs und unbekannte Approach-Winkel werden explizit abgewiesen.
- Vector3-LZ wird korrekt als X/Z auf die taktische Ebene abgebildet.

## Verifikation
- TASK_1111: 30/30
- TASK_281: 33/33
- TASK_1110: 20/20
- TASK_396: 17/17
- TASK_399: 9/9
- TASK_1104: 31/31
