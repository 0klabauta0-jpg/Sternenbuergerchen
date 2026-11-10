# Playteststand nach Main uebernehmen

## Ziel / Problem
Nutzerauftrag vom10.11.2026: den fertig geprueften Playtestplan einschliesslich
NPC-Ruhe aus task/playtest-rest-resources-20261110 nach Main uebernehmen.

## Ursache und Sinn
Main auf GitHub ist046b6d91a, exakt die Ausgangsbasis des Tasks. Der gepruefte
Taskstand401c4a049 ist ein direkter Nachfolger; Fast-forward bewahrt alle Commits.
Der urspruengliche Checkout wird parallel benutzt und hat fremden WIP.

## Umfang / Nicht-Ziele
Main-Fast-forward, gezielte Integrationspruefung und normaler GitHub-Push.
Original-WIP bleibt unveraendert. Keine neue EXE/PCK und keine Integration der
unfertigen Karten-/Gebaeudemigration des anderen Chats.

## Dokumente / Contracts
AGENTS, PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES; Playtesttask vom10.11.;
base_automatic_rest_contract, persistent_location_runtime_contract und
location_resource_interaction_contract. Vorige Abnahme:
docs/qa/playtest_20261110_acceptance/README.md.

## Akzeptanz
Main enthaelt401c4a049 mit allen vorherigen Taskcommits. Kein fremder WIP wird
mitgenommen; keine Konflikte. Gezielte17-Quellsuite und Basisruhe einschliesslich
Save/Continue/Boarding sowie echter Zwei-Ausflug-Rueckweg auf Main erfolgreich.
GitHub-Main und lokaler Mainref weisen auf denselben Commit.

## Betroffene Dateien
Produktquellen unveraendert401c4a049; nur Integrationsstatus in IMPLEMENTATION_STATUS,
TASK_ROADMAP und diesem Task, plus Integrationsbeleg unter docs/qa/.

## Lokale Pruefung
Godot4.6.2 mit isoliertem APPDATA, Headless17-Quellsuite, automatic_rest_verifier
und extraction_loop. Vorherige native Abnahme175/0, Folgeausflug62/0,
Mehrort-Wiederbesuch61/0 wird nicht als frisch wiederholter Exporttest ausgegeben.

## Risiken / offene Punkte
Stilfreigabe, Mehrschiff-Weltcheckpoint, Sekundaerwaffe-Ablegen-Minor und breite
Performance-/Releaseabnahme bleiben getrennt. Checkout des anderen Chats bleibt
auf seinem Taskbranch; nur dessen nicht ausgecheckter Mainref darf aktualisiert werden.
