# TASK_1065 - Mission Runtime Review and Performance Pass

## Ziel / Problem

Der aktuelle Zwei-Fireteam-Missionspfad ist funktional und sein Mini-Card-
Aufbau wurde bereits als Delta getrennt. Der Runtime-Refresh wendet jedoch
weiter Statuszeilen und ihre Zeichnung erneut an, obwohl sich deren
Member-Snapshot nicht geaendert hat. Das erzeugt vermeidbare UI-Arbeit in
einem wiederkehrenden sichtbaren Refresh.

Parallel wird der aktuelle Codepfad auf Architektur-, Korrektheits- und
Performance-Risiken ueberprueft. Der Bericht trennt bestaetigte Befunde von
bewusst geparkten Strukturthemen.

## Ursache / Sinnhaftigkeit

`_apply_fireteam_member_status_row()` baut den aktuellen Member-Snapshot und
ruft immer `set_member_snapshot()` auf. Die Row normalisiert die Daten und
fordert jedes Mal ein Redraw an, auch wenn sich Mitglieder, Vitalwerte,
Movement- und Combat-Status nicht veraendert haben. Das ist eine Leseschicht;
ein lokaler Signatur-Guard darf daher nur ihre Darstellung drosseln und keine
Gameplay-Wahrheit besitzen.

## Umfang

- Read-only Diagnosezaehler fuer Apply/Skip der Fireteam-Member-Statusrow.
- Pro Kartenrow nur bei geaendertem Snapshot `set_member_snapshot()` und
  `queue_redraw()` ausloesen.
- Suppression, Kontakt, Koordination, Auswahl und Karten-Referenz bleiben
  unveraendert live.
- Einen fokussierten Verifier sowie den realen TASK-1061-Zwei-Team-Trace
  ausfuehren.
- Einen interaktiven HTML-Review-/Performancebericht mit Befunden, Messung,
  Entscheidungen, Notizen und lokalem JSON-Export erstellen.

## Nicht-Ziele

- Kein Austausch des historisch gewachsenen Mission-Tactical-Controllers.
- Keine Aenderung an SimulationRoot, Command-Queue, Combat, Pathfinding oder
  Multiplayer-Ownership.
- Kein FPS-Versprechen aus Headless-Zeiten.
- Kein Anfassen des separaten TASK-1064-Entwurfs.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_1061_multi_fireteam_mission_runtime_budget.md`
- `docs/tasks/TASK_1062_fireteam_card_delta_rendering.md`

## Akzeptanzkriterien

- Bei identischem Member-Snapshot steigt der Skip-Zaehler; die Row behaelt
  Instanz und Snapshot.
- Eine reine Suppression-Aenderung aktualisiert weiterhin den sichtbaren
  Balken, ohne die unveraenderte Member-Row erneut zu zeichnen.
- Eine echte Member-Status-Aenderung wendet die Row wieder an.
- Der Diagnose-Snapshot bleibt read-only und besitzt keine Gameplay-Wahrheit.
- TASK_1061, TASK_1062 und die relevanten Dropship-/HUD-Regressionen bleiben
  gruen.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1065_mission_runtime_review_performance_pass.gd`
- `docs/tasks/TASK_1065_mission_runtime_review_performance_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/task_1065_mission_runtime_review_performance_pass.html`

## Lokale Pruefung

- Neuer TASK-1065-Verifier.
- TASK_1062 Fireteam Card Delta Rendering.
- TASK_1061 Multi-Fireteam Mission Runtime Budget.
- TASK_503 Dropship/Fireteam HUD Truth.
- `git diff --check`.

## Risiken / offene Punkte

Die Signatur muss reale Aenderungen der dargestellten Memberdaten erkennen.
Die grosse Controller-Datei bleibt ein Architektur- und Wartbarkeitsrisiko;
dieser Task verbessert nur einen belegten sichtbaren Hotpath und dokumentiert
die weiteren Befunde statt einen ungetesteten Grossumbau zu starten.
