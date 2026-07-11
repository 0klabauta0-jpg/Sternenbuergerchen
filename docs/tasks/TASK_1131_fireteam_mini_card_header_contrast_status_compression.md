# TASK_1131 - Fireteam Mini-Card Header Contrast and Status Compression

## Ziel / Problem
Die Mission-Mini-Cards muessen Fireteam-Identitaet und den wichtigsten taktischen Zustand bei Full HD auf einen Blick zeigen. Der Titel konkurriert derzeit mit mehreren Header-Indikatoren; der primaere `EX | CONTACT | HP`-Status wird durch eine abgeschnittene Lead-Zeile verdeckt.

## Ursache
Titel, Kontakt, Moral, Koordination und Stance-Buttons teilen sich dieselbe schmale `HeaderRow`. `MemberLabel` erhaelt Lead und Primaerstatus mit Zeilenumbruch, ist im `mission_mini`-Modus aber auf genau eine sichtbare Zeile begrenzt.

## Umfang
- Mission-Mini-Titel mit explizitem, kontrastreichem Header-Stil.
- Sichtbare Statushierarchie: taktischer Primaerstatus zuerst, kompakte Lead-/Teamidentitaet danach.
- Detailstatus, Position, Bewegung, Suppression und Readiness bleiben im Tooltip beziehungsweise in bestehenden Indikatoren erhalten.
- Stance-Bedienung und vorhandene Statusindikatoren bleiben funktional.

## Nicht-Ziele
- Keine Aenderung an Fireteam-, Combat-, Movement-, Multiplayer- oder Snapshot-Wahrheit.
- Kein Umbau der gesamten Mission-HUD-Struktur.
- Keine neuen per-frame Updates oder SceneTree-Scans.

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK_1130_fireteam_mini_card_identity_typography_polish.md`
- `docs/tasks/TASK_431_fireteam_aim_pose_and_card_ui_hotfix.md`

## Akzeptanzkriterien
- BLUE/GOLD haben einen expliziten kontrastreichen Titelstil mit mindestens 12 px.
- Die erste sichtbare Statuszeile beginnt mit dem taktischen Primaerstatus; seine Spielsprache wird ab TASK_1132 ohne Diagnosekuerzel dargestellt.
- Die zweite sichtbare Zeile enthaelt Lead und Operatorzahl, aber keine Wegpunktzahl und keinen versteckten Zeilenumbruch.
- Der vollstaendige technische Status bleibt im Tooltip abrufbar.
- Bestehende Mini-Card-, Multiplayer- und Performance-Verifier bleiben gruen.

## Betroffene Dateien
- `scripts/meta/fob_fireteam_card.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1131_fireteam_mini_card_header_contrast_status_compression.gd`
- Status-, Roadmap- und HTML-Berichtsdokumente

## Lokale Pruefung
- TASK_1131 Runtime-Verifier
- TASK_1130, TASK_431, TASK_503 und TASK_773
- TASK_222 Performance-Gate
- TASK_1128 Full-HD-Real-Window-Capture

## Risiken / offene Punkte
Die Karte bleibt bewusst kompakt. Seltenere Diagnosewerte duerfen deshalb nur im Tooltip sichtbar sein, muessen dort aber vollstaendig erhalten bleiben.
