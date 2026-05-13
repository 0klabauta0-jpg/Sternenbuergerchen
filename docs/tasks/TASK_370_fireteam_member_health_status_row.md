# TASK_370 - Fireteam Member Health Status Row

## Ziel
Unter oder innerhalb der Fireteam-Karte soll eine kompakte Member-Zeile zeigen, wie viele Mitglieder fit, downed, wounded, suppressed oder busy sind.

## Status: GEPLANT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll als kleiner Lesbarkeitsgewinn, solange er nicht zur Character-Sheet-Kopie wird. Fuer taktische Entscheidungen reicht eine kompakte Statusreihe.

## Problem
Ein Fireteam kann formal noch existieren, obwohl einzelne Mitglieder verletzt, downed oder nicht einsatzbereit sind. Das ist im HUD nicht schnell genug lesbar.

## Ursache
Unit-Vital-State und Rollen existieren in Unit-/Simulation-Snapshots, werden aber in Fireteam-Karten nicht als Member-Zusammenfassung dargestellt.

## Umfang
- Member-Snapshot pro Fireteam aus vorhandenen Unit-Daten lesen.
- Kompakte Icons/Farbchips fuer Status und ggf. Rolle darstellen.
- Keine Portraits in dieser Zeile, ausser vorhandene Mini-Assets sind ohne Layoutkosten nutzbar.
- Member-Zeile in Fireteam-Karte integrieren oder als optionales Sub-Control bereitstellen.
- Doppelklick/Character-Sheet bleibt Aufgabe der Meta-Karten, nicht dieser Missionszeile.

## Akzeptanzkriterien
- [ ] Vier-Personen-Fireteam zeigt vier stabile Member-Chips.
- [ ] Fit/wounded/downed/suppressed werden unterscheidbar dargestellt.
- [ ] Leere oder fehlende Memberdaten erzeugen eine neutrale Anzeige.
- [ ] Zeile bleibt unter kleinen Panelbreiten lesbar.
- [ ] Headless-Test prueft Statuswechsel ohne stale Anzeige.

## Erwartete Dateien
- `scripts/ui/fireteam_member_status_row.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_370_fireteam_member_health_status_row.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_370_fireteam_member_health_status_row.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_369_fireteam_status_card_enhancement.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Rollen-/Health-Icons duerfen ohne passenden Asset-Task nicht ad hoc massenhaft importiert werden.
- Die Zeile darf keine Loadout- oder Rollenwahrheit erfinden.

