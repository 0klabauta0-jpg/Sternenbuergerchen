# TASK_370 - Fireteam Member Health Status Row

## Ziel
Unter oder innerhalb der Fireteam-Karte soll eine kompakte Member-Zeile zeigen, wie viele Mitglieder fit, downed, wounded, suppressed oder busy sind.

## Status: IMPLEMENTIERT

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
- [x] Vier-Personen-Fireteam zeigt vier stabile Member-Chips.
- [x] Fit/wounded/downed/suppressed werden unterscheidbar dargestellt.
- [x] Leere oder fehlende Memberdaten erzeugen eine neutrale Anzeige.
- [x] Zeile bleibt unter kleinen Panelbreiten lesbar.
- [x] Headless-Test prueft Statuswechsel ohne stale Anzeige.

## Umsetzung
- `scripts/ui/fireteam_member_status_row.gd` stellt eine feste, read-only Chip-Zeile fuer Member-Status dar. Sie unterscheidet `fit`, `wounded`, `down`, `suppressed`, `busy` und `unknown` ohne neue Assets.
- `mission_tactical_sandbox_controller.gd` baut pro Fireteam einen Member-Row-Snapshot aus vorhandenen Unit-Vital-, Health-, Runtime- und Fireteam-Suppression-Daten.
- Die Row wird als unten verankertes Overlay innerhalb der Mission-Fireteam-Mini-Card eingebettet. Dadurch bleibt die Card-Layout-Hoehe aus TASK_368/TASK_369 stabil.
- `get_command_feedback_snapshot()` spiegelt `fireteam_member_status_rows` und `fireteam_member_status_row_count`, damit Tests und spaetere HUD-Slices dieselbe Anzeigequelle nutzen.

## Erwartete Dateien
- `scripts/ui/fireteam_member_status_row.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_370_fireteam_member_health_status_row.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_370_fireteam_member_health_status_row.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_369_fireteam_status_card_enhancement.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_368_ftl_readiness_gauge.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Rollen-/Health-Icons duerfen ohne passenden Asset-Task nicht ad hoc massenhaft importiert werden.
- Die Zeile darf keine Loadout- oder Rollenwahrheit erfinden.
- Die Mission-Testszene ist kein voller Vierer-Fireteam-Integrationsfall; der Vierer-Chip-Vertrag wird deshalb isoliert in der Row-Komponente geprueft.
