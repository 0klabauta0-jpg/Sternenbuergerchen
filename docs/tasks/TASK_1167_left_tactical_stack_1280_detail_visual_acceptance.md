# TASK_1167 - Left Tactical Stack 1280 Detail Visual Acceptance

## Ziel / Problem
TASK_1166 hat den frisch exportierten 1280x720-Host-/Client-FirstContact-Stand belegt. Jetzt muss der linke taktische Stack aus Fireteam-Mini-Cards und Ereignislog als echter Spielerblick bewertet werden.

## Sinnhaftigkeit / Ursache
Die letzten Tasks haben technische Lesbarkeit und Release-Provenance gehaertet. Fuer das Spielgefuehl reicht ein gruener Snapshot allein nicht: Host- und Client-Fenster muessen zeigen, ob Auswahl, Kontaktstatus, Eventlog und Memberkarten im echten Bild schnell genug erfassbar sind.

## Umfang
- Read-only Visual-Acceptance-Snapshot fuer den TASK_1166-Recapture.
- Host- und Client-Fensterbilder als getrennte Belege verwenden.
- Akzeptanzstatus, positive Befunde und konkrete Restreibung dokumentieren.
- Naechsten sinnvollen Task aus dem Befund ableiten.

## Nicht-Ziele
- Kein neues Layout in diesem Task.
- Keine neuen Commands, Effects, Fire-/Damage-Events oder Movement-Logik.
- Keine Multiplayer-Wahrheit im UI.
- Keine Bildanalyse als Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1166_left_tactical_stack_1280_detail_recapture.md`
- `docs/tasks/TASK_1165_left_tactical_stack_1280_detail_polish.md`

## Akzeptanzkriterien
- Snapshot `get_left_tactical_stack_1280_detail_visual_acceptance_snapshot()` existiert.
- Snapshot meldet Schema `sternenbuergerchen.left_tactical_stack_1280_detail_visual_acceptance.v1`.
- TASK_1166-Recapture ist bereit und die Host-/Client-Fensterbilder sind getrennt, vorhanden und nicht leer.
- Visual Acceptance ist fuer den naechsten Spielbarkeits-Slice freigegeben.
- Positive Befunde nennen Fireteam-Karten, Primaerfokus, Ereignislog und Memberkarten.
- Restreibung bleibt als Follow-up erhalten: linker Stack ist noch randnah/eng und kann luftiger verankert werden.
- Snapshot erzeugt keine Commands, Effects oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1167_left_tactical_stack_1280_detail_visual_acceptance.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- TASK_1167
- TASK_1166
- TASK_1165
- TASK_1109
- TASK_1110
- `git diff --check`

## Risiken / offene Punkte
Der Snapshot ist eine dokumentierte visuelle Abnahme anhand konkreter Fensterbilder, keine automatische Pixelbewertung. Der naechste Polish sollte die linke Stack-Flaeche luftiger und stabiler ankern, wenn wir vor dem naechsten Spielbarkeits-Slice noch sichtbar nacharbeiten wollen.
