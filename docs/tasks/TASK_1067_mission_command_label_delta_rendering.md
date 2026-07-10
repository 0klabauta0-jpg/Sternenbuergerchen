# TASK_1067 - Mission Command Label Delta Rendering

## Ziel / Problem

Der sichtbare Missionsrefresh schreibt mehrere Command-, Strategie- und
Navigationslabels bei jedem getakteten Lauf erneut, obwohl ihr Text gleich
bleibt. Solche Controls koennen dadurch unnoetige Layout-/Redraw-Arbeit
ausloesen und addieren sich mit mehreren Fireteams und Panels.

## Ursache / Sinnhaftigkeit

Die Labels werden aus vorhandenen read-only Snapshots gebaut und direkt mit
`.text = ...` beschrieben. Das ist korrekte Darstellung, aber ohne Delta-Guard.
Ein gemeinsamer Text-Helper kann gleiche Werte ueberspringen, ohne UI-Wahrheit
zu speichern oder die zugrunde liegenden Snapshot-Berechnungen zu veraendern.

## Umfang

- Einen kleinen Label-Text-Delta-Helper samt read-only Diagnosezaehlern.
- Anwenden auf Command-Feedback, Hotkey, Fireteam-/Strategie-/Phase-Status,
  Nav-Timer, Missionsidentitaet und Team-Chip.
- Echte Textaenderungen bleiben sofort sichtbar.
- Einen fokussierten Verifier und bestehende Mission-Refresh-Regressionen.

## Nicht-Ziele

- Kein Caching oder Mutieren von Command-, Simulation-, Netzwerk- oder
  Mission-State.
- Keine Aenderung an Tooltips, Button-Zustaenden, Layout-Contracts oder
  Tastaturbedienung.
- Kein vollstaendiger Controller-Refactor.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/dev/mission_command_feedback_contract.md`
- TASK_1043, TASK_1065, TASK_1066

## Akzeptanzkriterien

- Ein unveraenderter UI-Refresh erhoeht den Label-Skip-Zaehler.
- Eine geaenderte Command-Rueckmeldung schreibt den sichtbaren Text erneut.
- Diagnose bleibt read-only und besitzt keine Gameplay-Wahrheit.
- TASK_1043, TASK_1061, TASK_1062, TASK_1066 und TASK_503 bleiben gruen.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1067_mission_command_label_delta_rendering.gd`
- diese Task-Datei sowie Status, Roadmap und HTML-Bericht.

## Lokale Pruefung

- Neuer TASK-1067-Verifier.
- TASK_1043, TASK_1061, TASK_1062, TASK_1066, TASK_503.
- `git diff --check`.

## Risiken / offene Punkte

Der Helper darf nur gleichbleibende Textzuweisungen ueberspringen. Tooltips,
Sichtbarkeit und Meta-Daten bleiben absichtlich ausserhalb dieses ersten
Text-Schnitts, damit keine Bedienrueckmeldung unbemerkt ausbleibt.
