# TASK 472: Fireteam Contact Performance, Bubble Cleanup und Kartenlesbarkeit

## Ziel / Problem

Im Fireteam-Drill bricht die Performance bei Kontakt/Feuer stark ein. Gleichzeitig bleiben alte Leader-Sprechblasen sichtbar, der sichtbare Text erklaert Pinned/Engage/Flanking nicht ausreichend und die einzelnen Unit-Karten in Panel #17 schneiden Statusinformationen ab.

## Sinnhaftigkeit / Ursache

Der aktuelle Playtest-Pfad erzeugt bei Kontakt sehr viele dynamische Visual-Updates. Alte HUD-Bubble-Nodes werden im 3D-Order-Refresh nicht konsequent entfernt. Zusaetzlich laeuft Flank-/Vulnerability-Logik sichtbar in den Kontaktzustand hinein, obwohl Flank fuer die aktuelle Baseline bewusst noch nicht Teil der aktiven Befehle sein soll.

## Umfang

- Sichtbare Leader-Bubble auf genau eine aktive Bubble begrenzen.
- Kontakt-/Fire-Visuals billiger takten und Anzahl gleichzeitiger Feuer-VFX begrenzen.
- Flank-Vulnerability fuer die aktuelle Drill-Baseline deaktivieren, damit keine automatische Flanking-Ansage den Engage/Defend-Test ueberlagert.
- Unit-Karten in #17 gleich breit lassen, aber nach unten mehr Raum fuer gewrappte Statuszeilen geben.
- Muzzle-Flash klein, gelb und lesbar halten.

## Nicht-Ziele

- Kein neues Flank-Verhalten.
- Keine finale Treffer-/Tod-Balance.
- Keine grosse UI-Neugestaltung ausser den betroffenen Statuskarten.
- Keine Map-/Scenario-Neuerstellung.

## Relevante Contracts / Dokumente

- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien

- Wiederholte dynamische Order-Refreshes hinterlassen nur eine HUD-Leader-Bubble.
- Fire-VFX zeigt maximal wenige gleichzeitige, kurze gelbe Muzzle-Hinweise statt grosser Flaechen.
- Die Combat-Loop meldet in der Baseline keine aktive Flank-Vulnerability und keine automatische Flanking-Bubble.
- #17-Unit-Karten bleiben in der Breite stabil und koennen mehrere kurze Statuszeilen anzeigen.
- Bestehende Fireteam-Regressionstests bleiben gruen oder dokumentieren nur bekannte, nicht betroffene Restthemen.

## Betroffene Dateien

- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_472_fireteam_contact_perf_bubble_card_readability.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- Godot-Script-Test fuer Bubble-Cleanup, Flank-Deaktivierung und Card-Wrapping.
- Bestehende Fireteam-Tests fuer Muzzle/Manual/Contact nachziehen.
- `git diff --check`.

## Risiken / offene Punkte

- Flank-Vulnerability muss spaeter bewusst wieder als eigener, expliziter Behavior-Pass aktiviert werden.
- Die Performance-Aenderung reduziert Visual-Dichte; bei spaeterer Trefferbalance koennen feinere VFX wieder noetig werden.
