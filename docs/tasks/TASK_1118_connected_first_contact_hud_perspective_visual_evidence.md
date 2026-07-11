# TASK_1118 - Connected First Contact HUD Perspective and Visual Evidence

## Ziel / Problem
Nach TASK_1117 ist der erste verbundene Feuerkontakt funktional konsistent. BLUE und GOLD muessen im HUD aber jeweils ihren eigenen relevanten Kontakt, ihr ROE, das Ergebnis des Feuerwechsels und den naechsten Spielergriff lesen, statt das global letzte Ereignis eines anderen Fireteams zu uebernehmen.

## Sinnhaftigkeit / Ursache
Der Client-Combat-Driver haelt mehrere autoritative Contact- und Fire-Event-Eintraege. Die bisherige read-only Diagnose waehlt global den letzten Fire-Event. Bei parallelen Fireteams kann GOLD dadurch BLUEs Schuss als aktuellen eigenen Zustand lesen. Das ist funktional ungefaehrlich, aber spielerisch widerspruechlich.

## Umfang
- Contact-/Fire-Diagnostics nach ausgewaehltem Fireteam filtern.
- Autoritative Fire-Events mit Angreifer- und Ziel-Fireteam-ID versehen.
- Eine kompakte HUD-Zeile mit Fireteam, Contact, ROE, Outcome und `NEXT` erzeugen.
- BLUE- und GOLD-Perspektive aus demselben Snapshot headless pruefen.
- Im Real-Window-Lauf je ein Full-HD-PNG fuer BLUE und GOLD schreiben.

## Nicht-Ziele
- Keine neue Zielwahl, kein Combat- oder ROE-Rewrite.
- Keine automatischen Folgecommands aus `NEXT`.
- Kein neuer Netzwerk-RPC und kein neues Snapshotformat.
- Kein Umbau aller Mission-HUD-Panels.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1117_connected_post_deboard_first_contact_combat_handoff.md`
- `docs/ARCHITECTURE.md`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`

## Akzeptanzkriterien
- BLUE liest BLUEs Event-ID und GOLD liest GOLDs Event-ID aus demselben Snapshot.
- Die sichtbare Primaerzeile beginnt mit der aktiven Fireteam-ID.
- Die Zeile enthaelt `CONTACT FIRE`, ROE, HIT/MISS und `NEXT`.
- Auswahlwechsel erzeugt keine Commands, Effects oder Combat-Wahrheit.
- BLUE-/GOLD-PNGs sind 1920x1080 und enthalten nicht dieselbe Perspektivsignatur.
- Bestehender TASK_1117-Drei-Peer-Lauf und Performance-Gate bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1118_connected_first_contact_hud_perspective_visual_evidence.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- TASK_1118 headless und Real-Window.
- TASK_1117 Drei-Peer-Regression.
- TASK_466/TASK_467 Combat-/ROE-Regression.
- TASK_222 Performance-Gate.
- `git diff --check`.

## Risiken / offene Punkte
Die PNGs belegen die echte HUD-Geometrie und Perspektivumschaltung, ersetzen aber keinen manuellen Drei-Fenster-Usability-Test mit zwei Menschen. Der Task speichert nur visuelle Evidence und keine Gameplay-Wahrheit.
