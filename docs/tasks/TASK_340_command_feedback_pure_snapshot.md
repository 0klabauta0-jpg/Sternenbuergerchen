# TASK_340 - Command Feedback Pure Snapshot

## Ziel
Der Command-Feedback-Snapshot soll nicht aus bereits gerenderten UI-Labels zurueckgelesen werden. UI-Text und Snapshot muessen aus demselben read-only Controller-/Model-Kontext entstehen.

## Status: GEPLANT

## Voraussetzung
- TASK_286 - UI Feedback Truth Regression Review
- TASK_331 - Mission Tactical Controller Adapter Split First Slice
- TASK_335 - Tactical Feedback Truth Command Clarity Pass

## Kontext
Die Review hat im Command-Feedback-Pfad Label-Readbacks gefunden. Dadurch kann ein Snapshot stale oder nur zufaellig korrekt sein, wenn die UI bereits aktualisiert wurde. Das verwischt die Grenze "UI ist nicht die Wahrheit", obwohl der Snapshot eigentlich Diagnose und Feedback aus Gameplay-/Controller-Zustand abbilden soll.

## Umfang
1. Pfad-Audit:
   - `MissionTacticalSandboxController._build_command_feedback_snapshot_context()` verfolgen.
   - Alle Felder identifizieren, die aktuell aus Label-Texten gelesen werden.
2. Pure Snapshot-Quelle:
   - Einen kleinen read-only Payload oder Helper bauen, der Selection-, Command-, Dropship- und Disabled-Reason-Texte aus bestehendem Zustand berechnet.
   - UI-Labels und `MissionCommandFeedbackSnapshotAdapter` aus diesem Payload fuettern.
3. Architektur-Gate:
   - Snapshot-Erzeugung darf keine UI-Controls als Wahrheit lesen.
   - Adapter bleibt defensiv und dupliziert Payloads weiter.
4. Regression:
   - Command-Clarity-Felder, Disabled-Reasons und Drop-/LZ-Feedback bleiben stabil.

## Nicht-Ziele
- Keine neuen Commander-Befehle.
- Kein neues Label-Wording, ausser vorhandene Duplikate werden zentralisiert.
- Kein Gameplay-Commit aus Snapshot- oder UI-Code.
- Kein grosser Mission-Controller-Umbau.

## Akzeptanzkriterien
- [ ] Command-Feedback-Snapshot liest keine gerenderten Label-Texte zurueck.
- [ ] UI und Snapshot zeigen fuer denselben State dieselben berechneten Command-/Status-Texte.
- [ ] Bestehende Reason-Codes aus TASK_335 bleiben erhalten.
- [ ] Der UI-Feedback-Regressionstest deckt den reinen Snapshot-Pfad ab.

## Erwartete Dateien
- `scripts/mission/mission_tactical_sandbox_controller.gd`
- `scripts/mission/mission_command_feedback_snapshot_adapter.gd`
- optional `scripts/tests/task_340_command_feedback_pure_snapshot.gd`
- `docs/tasks/TASK_340_command_feedback_pure_snapshot.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_340_command_feedback_pure_snapshot.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_335_tactical_feedback_truth_command_clarity_pass.gd`
- [ ] `git diff --check`

## Risiken
- Bestehende Label-Texte koennen an mehreren Stellen implizit als Vertrag genutzt werden. Der Task sollte Texte zentralisieren, aber keine sichtbare UX-Sprache nebenbei neu designen.

## Naechster Schritt
Nach dem Snapshot-Cleanup kann Command-Feedback einfacher fuer Multiplayer-/Replay-Diagnose genutzt werden, weil es nicht mehr vom Renderzeitpunkt abhaengt.
