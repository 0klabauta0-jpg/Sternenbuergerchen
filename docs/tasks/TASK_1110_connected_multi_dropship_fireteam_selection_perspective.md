# TASK_1110 - Connected Multi-Dropship Fireteam Selection Perspective

## Status: IMPLEMENTIERT

## Ziel / Problem
In einer verbundenen Host/Client-Mission muss der autoritative Zustand mehrerer Dropships auf allen Peers konvergieren. Die lokale Auswahl eines Craft-/Fireteam-Paares darf dabei nicht vom Snapshot des Hosts ueberschrieben oder an andere Spieler repliziert werden.

## Sinnhaftigkeit / Ursache
TASK_1109 stabilisiert die lokale Mehrschiffanzeige. Der Multiplayer-Snapshot transportiert derzeit jedoch nur einen einzelnen vereinfachten Dropship-Visualzustand. `mission_drop_cards`, Embarked- und Deployed-IDs fehlen im replizierten Display-State und werden vom Mission-HUD nicht aus dem Snapshot uebernommen.

## Umfang
- Mehrere sanitisierte Dropship-Karten im read-only Multiplayer-Display-State uebertragen.
- Autoritative Embarked-/Deployed-IDs mit den Karten replizieren.
- Snapshot im Mission-Tactical-Controller auf Karten- und HUD-Transportstate anwenden.
- Lokales ausgewähltes Craft und Fireteam erhalten, solange beide im neuen State weiterhin gueltig sind.
- Gemischten Zustand pruefen: BLUE deployed, GOLD weiterhin embarked.
- Keine Auswahl-, Drop- oder Simulation-Commands beim Snapshot-Apply erzeugen.

## Nicht-Ziele
- Keine Replikation der lokalen UI-Auswahl.
- Keine neue Transportwahrheit neben Host-Snapshot und bestehenden Mission-Drop-Karten.
- Kein Umbau des Snapshot-Chunktransports.
- Keine Aenderung an Dropship-Bewegung, LZ oder Deboard-Sequenzen.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1109_multi_dropship_fireteam_selection_hud_consistency.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `scripts/multiplayer/multiplayer_snapshot_contract.gd`

## Akzeptanzkriterien
- Host-Snapshot enthaelt zwei sanitisierte Dropship-Karten und autoritative Presence-IDs.
- Client behaelt seine lokale GOLD-Auswahl, obwohl der Host BLUE betrachtet.
- Nach Snapshot-Apply zeigt der Client deployed BLUE als Boden-Fireteam und embarked GOLD weiterhin im Dropship.
- Host- und Client-Transportstate konvergieren, lokale Auswahl muss nicht identisch sein.
- Snapshot-Apply erzeugt keine Commands oder Effects.
- Payload bleibt innerhalb des bestehenden Snapshot-/Chunk-Budgets.

## Betroffene Dateien
- `scripts/multiplayer/multiplayer_snapshot_contract.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1110_connected_multi_dropship_fireteam_selection_perspective.gd`
- Status-, Roadmap- und HTML-Arbeitsreport-Dokumentation

## Lokale Pruefung
- TASK_1110 Verifier
- TASK_1109 Mehrschiff-HUD
- TASK_168 Snapshot Contract
- TASK_396 Multi-Dropship Deboarding
- TASK_399 Dropship Performance
- TASK_1104 Drei-Peer-Produktlauf
- `git diff --check`

## Risiken / offene Punkte
Die Karten duerfen nur ID-, Status- und Positionsdaten enthalten. Texturressourcen, Callables und lokale Selection-Felder gehoeren nicht in den Snapshot. Ein Apply darf eine weiterhin gueltige lokale Auswahl nicht auf den Host-Fokus zuruecksetzen.

## Ergebnis
- Der Host publiziert alle sanitiserten Dropship-Karten sowie autoritative Embarked-/Deployed-IDs im bestehenden Snapshot.
- Der Client merged nur whitelisted Transportfelder in seine lokalen Karten und behaelt Craft-/Fireteam-Fokus, solange die Auswahl gueltig bleibt.
- Texture-Pfade und lokale Selection-Felder werden nicht uebertragen.
- Identische Dropship-Payloads werden vor HUD-/World-Refresh dedupliziert und in read-only Diagnosezaehlern erfasst.
- Snapshot-Apply erzeugt keine Commands oder Effects.

## Verifikation
- TASK_1110: 20/20
- TASK_168: 20/20
- TASK_1109: 18/18
- TASK_396: 17/17
- TASK_399: 9/9
- TASK_1099: 38/38
- TASK_1104: 31/31
- TASK_230: Snapshot-/Air-Layer-Teil gruen; zwei FoW/LZ-Markerchecks scheitern identisch auf dem unveraenderten Basisstand und sind nicht durch TASK_1110 verursacht.
