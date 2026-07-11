# TASK_1103 - Parallel Interaction Ownership Feedback Readability

## Ziel / Problem
Die in TASK_1102 abgesicherte Fireteam-Ownership soll im bestehenden Mission-HUD sofort lesbar sein. Der Spieler muss erkennen, welches Fireteam eine Interaction bearbeitet und warum ein zweites Fireteam blockiert wurde.

## Ursache / Sinnhaftigkeit
Der replizierte Interaction-State enthaelt bereits `fireteam_id`, die Network-Progress-Zeile verwirft den Besitzer jedoch. Bei mehreren parallelen States zeigt sie nur einen Eintrag. Der neue Reject `interaction_reserved_by_other_fireteam` faellt derzeit auf eine technische Grossbuchstaben-Uebersetzung zurueck.

## Umfang
- Bestehende `LAST`-Command-Feedback-Zeile wiederverwenden.
- Einzelnen laufenden State mit kompaktem Fireteam-Token anzeigen.
- Bis zu zwei parallele laufende States als kurze Besitzeruebersicht anzeigen.
- Reservierungs-Reject als `ANDERES FIRETEAM AKTIV` uebersetzen.
- Network-Accept/Reject um das anfragende Fireteam ergaenzen.
- Fingerprint um Besitzer und parallele States erweitern, damit echte Ownership-/Progress-Aenderungen sichtbar werden.

## Nicht-Ziele
- Kein neues HUD-Panel.
- Keine Aenderung der autoritativen Ownership.
- Keine Anzeige technischer Interaction-IDs oder Peer-IDs.
- Keine beliebig lange Liste aller Interactions.

## Akzeptanzkriterien
- `COM 42% BLUE` ist fuer einen einzelnen laufenden Computer-State lesbar.
- Zwei States erscheinen kompakt wie `COM 42% BLUE | CARGO 58% GOLD`.
- Die kombinierte Zeile bleibt hoechstens 72 Zeichen lang.
- Ein fremder Zugriff zeigt `COM GOLD BLOCKIERT | ANDERES FIRETEAM AKTIV`.
- Technische Reason- und Interaction-IDs bleiben verborgen.
- Eine Ownership-Aenderung aktualisiert die Zeile auch bei gleichem Prozentwert.
- Ein sichtbarer Token-Wechsel des zweiten Parallel-States aktualisiert die Zeile auch bei identischem Owner und Fortschritt.
- Identische Snapshots bleiben dedupliziert; kein HUD-Komplett-Rebuild.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1103_parallel_interaction_ownership_feedback_readability.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- TASK_1103-Verifier.
- TASK_1095 Feedback-Regression.
- TASK_1096 Progress-Regression.
- TASK_1098 HUD-Performance-Regression.
- TASK_1102 Ownership-Regression.
- `git diff --check`.

## Risiken / offene Punkte
- Mehr als zwei parallele States werden bewusst nicht vollstaendig in eine einzige Statuszeile gepresst; spaetere Detailansichten koennen bei echtem Bedarf folgen.
- Der finale FullHD-Sichtcheck bleibt fuer Abstaende und Farbwirkung sinnvoll.
