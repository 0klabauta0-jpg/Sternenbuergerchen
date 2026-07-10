# TASK_1058 - Embarked Fireteam Selected HUD Truth

## Ziel / Problem

Ein im Dropship befindliches, aber im Command-Kontext noch ausgewaehltes Fireteam darf im Selected-Fireteam-Bereich keine Boden-Mitgliederkarten zeigen. Stattdessen muss dort eindeutig stehen, dass das Team im Dropship ist.

## Ursache / Sinnhaftigkeit

Der Renderer erkennt den Embarked-State bereits, ueberspringt danach aber die vorhandene Ground-Unit-Filterung. Dadurch erscheinen disabled Member-Cards anstelle der vorgesehenen Dropship-Hinweiszeile. Die linke Mini-Card-Liste behandelt dieselben Units bereits korrekt als nicht bodenaktiv.

## Umfang

- Den Selected-Fireteam-Renderer und dessen Runtime-Signatur auf dieselbe Ground-Unit-Regel wie die Mini-Cards ausrichten.
- Bestehenden TASK_503-Verifier als Regression nutzen.

## Nicht-Ziele

- Keine Aenderung von Deployment-, Combat- oder Selection-Wahrheit.
- Keine Entfernung des Fireteams aus dem Command-Kontext.
- Kein neuer UI-Panelbaum.

## Relevante Contracts

- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/tasks/TASK_503_mission_dropship_fireteam_hud_truth.md` falls vorhanden

## Akzeptanzkriterien

- Embarked Fireteams fehlen in der linken Boden-Mini-Card-Liste.
- Der Selected-Fireteam-Bereich zeigt genau den Dropship-Hinweis und keine Member-Cards.
- Nach Deboarding erscheinen dieselben Member wieder als Boden-Cards.
- `task_503_mission_dropship_fireteam_hud_truth.gd` ist gruen.

## Ergebnis

- TASK_503 ist 10/10 gruen: Die linke Mini-Card-Liste blendet eingebarktes FT1 aus, #17 zeigt den Dropship-Hinweis ohne Member-Cards und stellt die Member-Cards nach Deployment wieder her.
- Die Runtime-Signatur nutzt dieselbe Ground-Unit-Auswahl wie der Renderer. Der vorhandene HUD-Hotpath-Guard bleibt damit konsistent, ohne einen separaten Refresh-Zustand einzufuehren.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_503_mission_dropship_fireteam_hud_truth.gd`
- diese Task-Datei

## Lokale Pruefung

- `godot_console.exe --headless --path . --script res://scripts/tests/task_503_mission_dropship_fireteam_hud_truth.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_396_mission_dropship_lz_drop_hotfix.gd`
- `git diff --check`

## Risiken / offene Punkte

Die Fireteam-Auswahl bleibt waehrend des Inbounds bewusst bestehen, damit der Spieler den Kontext behaelt. Nur die Darstellung der nicht bodenaktiven Mitglieder wird verborgen.
