# TASK_699 - Multiplayer Door Feedback Capture

## Ziel / Problem
Door-Breach ist technisch autorisiert und im HUD lesbar, aber Host- und Client-Sicht lassen sich noch nicht als gemeinsames Evidence-Paket vergleichen. Vor einem echten Zwei-Fenster-Test brauchen wir ein reproduzierbares Capture, das zeigt: Host sieht Accepted/Open, falscher Client sieht Blocked, und beide Anzeigen bleiben read-only.

## Sinnhaftigkeit / Ursache
TASK_697 und TASK_698 haben Authority und UI-Feedback getrennt abgesichert. Multiplayer-faehig wird das erst wirklich, wenn Host-/Client-Feedback nebeneinander pruefbar ist und spaeter mit einem echten Fensterlauf abgeglichen werden kann.

## Umfang
- Neuer read-only Capture-Helper fuer Host-/Client-Door-Feedback.
- Capture vergleicht Host-Readout, Wrong-Team-Readout, State-Mutation-Readout und Open-Producer-Readout.
- Der TacticalController exportiert einen `mission_interaction_multiplayer_door_feedback_capture`-Snapshot.
- Verifier schreibt ein Manifest unter `tmp/`.
- HTML-Arbeitsbericht bekommt einen TASK_699-Block mit Export-Key.

## Nicht-Ziele
- Kein echter Zwei-Fenster-Manual-Test.
- Kein neues Netzwerkprotokoll.
- Kein Simulations- oder Door-State im UI.
- Kein neuer Door-Command-Pfad.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/dev/multiplayer_authority_command_contract.md`
- `docs/tasks/TASK_697_door_interaction_multiplayer_authority_check.md`
- `docs/tasks/TASK_698_door_authority_ui_feedback.md`

## Akzeptanzkriterien
- Host-Readout meldet `accepted` oder `open`, wenn der Own-Team-Command akzeptiert und der Producer offen ist.
- Wrong-Team-Readout meldet `blocked` mit Reject-Grund.
- State-Mutation-Readout meldet `blocked` mit `state_mutation_key`.
- Capture-Gate ist `pass`, wenn alle drei Perspektiven konsistent sind und kein UI-Truth-Flag gesetzt ist.
- Bestehende Door-Authority- und Door-UI-Feedback-Tests bleiben gruen.

## Betroffene Dateien
- `scripts/mission/mission_multiplayer_door_feedback_capture.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_699_multiplayer_door_feedback_capture.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_699_multiplayer_door_feedback_capture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_698_door_authority_ui_feedback.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_697_door_interaction_multiplayer_authority_check.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das Capture ersetzt keinen echten menschlichen Zwei-Fenster-Klicklauf.
- Visuelle Lesbarkeit, Fensterlayout und Bediengefuehl bleiben als manueller Recheck offen.
