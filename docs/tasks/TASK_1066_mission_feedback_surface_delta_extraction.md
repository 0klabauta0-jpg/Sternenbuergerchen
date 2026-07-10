# TASK_1066 - Mission Feedback Surface Delta Extraction

## Ziel / Problem

Der taktische Event-Log-Panel hat bereits einen Render-Signature-Guard. Sein
oeffentlicher Feedback-Eingang kopiert und normalisiert aber bei jedem
Controller-Refresh erneut alle Event-Entries, auch wenn Auswahl, Eintraege und
Darstellungsstil identisch sind. Das ist vermeidbare UI-Arbeit im wiederkehrenden
Missionsfeedback-Pfad.

## Ursache / Sinnhaftigkeit

`TacticalEventLogPanel.set_feedback_snapshot()` baut immer ein neues
`PackedStringArray` und ruft immer `set_event_entries()` auf. Erst tiefer im
Panel erkennt `_refresh_display()` die gleiche Render-Signatur. Ein frueher,
read-only Feedback-Signature-Guard spart die Datenkopie, ohne Event-Log,
Command-Feedback, Combat oder Simulation zu mutieren.

## Umfang

- Einen fruehen Panel-Guard fuer identische Feedback-Snapshots einfuehren.
- Diagnosezaehler fuer Feedback-Apply/Skip im bestehenden Panel-Snapshot
  sichtbar machen.
- Echte neue Event-Entries weiter sichtbar anwenden.
- Einen gezielten Verifier und die bestehenden Event-Log-/Mehr-Fireteam-
  Regressionen ausfuehren.

## Nicht-Ziele

- Keine Aenderung an EventRouter, Combat, ContactTracker, Command-Queue oder
  `SimulationRoot`.
- Kein Cache fuer Gameplay-Wahrheit und kein Umbau des kompletten
  Command-Feedback-Snapshots.
- Kein Neudesign des Event-Log-Panels.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1043_mission_hud_hotpath_event_log_guard.md`
- `docs/tasks/TASK_1065_mission_runtime_review_performance_pass.md`

## Akzeptanzkriterien

- Identische Feedback-Snapshots erhoehen einen Skip-Zaehler und behalten die
  gerenderten Event-Entries.
- Ein neuer Event-Eintrag wendet den Panel-Snapshot erneut an und erscheint
  sichtbar im Event-Log.
- Der Panel-Snapshot bleibt eine read-only Diagnose ohne Gameplay-Wahrheit.
- TASK_1043, TASK_1061, TASK_1062 und TASK_503 bleiben gruen.

## Betroffene Dateien

- `scripts/ui/tactical_event_log_panel.gd`
- `scripts/tests/task_1066_mission_feedback_surface_delta_extraction.gd`
- diese Task-Datei sowie Status, Roadmap und der aktuelle HTML-Bericht.

## Lokale Pruefung

- Neuer TASK-1066-Verifier.
- TASK_1043 Mission HUD Hotpath Event Log Guard.
- TASK_1061 Multi-Fireteam Mission Runtime Budget.
- TASK_1062 Fireteam Card Delta Rendering.
- TASK_503 Mission Dropship Fireteam HUD Truth.
- `git diff --check`.

## Risiken / offene Punkte

Die Signatur muss jede fuer das Panel sichtbare Auswahl-, Event- und
Style-Aenderung abbilden. Der Controller baut den schmalen Live-Snapshot in
diesem Task weiter; seine breiteren Command-/Sekundaerlabel-Refreshes bleiben
separate Folgearbeit.
