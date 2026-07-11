# TASK_1125 - Connected First Contact Local Team and Contact Cluster Readability

## Ziel / Problem
Nach der World3D-Isolation ist der echte BLUE-/GOLD-Erstkontakt frei von fremden Renderresten. Die lokale Fireteam-Gruppe, der Kontaktmarker und ihre Labels liegen aber eng am oberen Kartenrand. Das aktuelle Framing beruecksichtigt nur einen Fireteam-Anker und den Kontakt, nicht alle lokalen Mitglieder.

## Sinnhaftigkeit / Ursache
Der Spieler fuehrt ein Fireteam und muss dessen gesamte sichtbare Aufstellung im Bezug zum Kontakt lesen. Wenn nur der Leader die Kameragrenzen bestimmt, koennen Wingmen trotz korrekter Formation am Rand liegen. Eine Aenderung der Gameplay-Positionen waere falsch; die Kamera soll die vorhandene lokale Wahrheit vollstaendig lesen.

## Umfang
- Connected-First-Contact-Framing sammelt alle sichtbaren Mitglieder der lokal ausgewaehlten Fireteams.
- Nur Kontakte dieser Fireteams erweitern den Punktesatz.
- Der bestehende einmalige, read-only Frame bleibt erhalten.
- Produktverifier misst Punktzahl, lokale Screen-Bounds und sicheren Viewport-Rand fuer BLUE und GOLD.
- Finale BLUE-/GOLD-Captures werden visuell geprueft.

## Nicht-Ziele
- Keine Aenderung an Unit-, Formation-, Combat- oder Contact-Positionen.
- Kein Verstecken anderer freundlicher Fireteams.
- Kein Kamera-Nachfuehren pro Frame.
- Kein neues RPC, Snapshotfeld, Command oder Effect.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1124_connected_contact_world_root_compositing_residue_isolation.md`
- `docs/tasks/TASK_1122_connected_mission_world_camera_exposure_contact_cluster_readability.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Der Frame-Punktesatz enthaelt jedes lokale Fireteam-Mitglied und mindestens einen lokalen Kontakt.
- BLUE und GOLD behalten nach dem Frame einen sicheren Bildschirmrand fuer alle lokalen Mitglieder und Kontakte.
- Das Framing bleibt one-shot und read-only.
- Gegner-, Formation-, Combat- und Multiplayer-State bleiben unveraendert.
- TASK_1119, TASK_1122, TASK_1123, TASK_1124, TASK_1104 und TASK_222 bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1119_connected_first_contact_three_peer_product_visual_playtest.gd`
- `scripts/tests/task_1125_connected_first_contact_local_team_contact_cluster_readability.gd`
- Status-, Roadmap- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1125 RED/GREEN.
- TASK_1119 headless und Real Window fuer BLUE/GOLD.
- TASK_1122, TASK_1123, TASK_1124, TASK_1104 und TASK_222.
- `git diff --check`.

## Risiken / offene Punkte
Mehr Framing-Punkte koennen die Kamera geringfuegig herauszoomen. Die Bounds bleiben deshalb eng begrenzt; eine allgemeine Kameraautomatik oder per-frame Nachfuehrung ist nicht Teil dieses Tasks.

## Ergebnis
- Das Connected-First-Contact-Framing verwendet jetzt alle Mitglieder der lokal ausgewaehlten Fireteams plus deren Kontakte statt nur Leader plus Kontakt.
- Der Produktfixture positioniert auch das fuenfte BLUE-Mitglied; zuvor blieb es an einer alten Szenenposition und zog Kamera sowie Weltbeleg auseinander.
- BLUE und GOLD halten den kompletten lokalen Entscheidungssatz in der HUD-freien taktischen Flaeche zwischen Seiten- und Bottom-Panels.
- Beide echten Full-HD-Perspektiven bleiben bei Camera-Size 24 und zeigen denselben engen Kartenmassstab.

## Verifikation
- TASK_1125: 10/10.
- TASK_1119: 29/29 headless, 35/35 BLUE Real Window, 35/35 GOLD Real Window.
- TASK_1122: 11/11; TASK_1123: 9/9; TASK_1124: 11/11; TASK_1104: 31/31; TASK_222: 82/82.
- Sichtpruefung: kein lokales Mitglied unter dem HUD; naechster Befund ist die Marker-/Label-Ueberlagerung innerhalb des gemeinsamen Kontaktclusters.
