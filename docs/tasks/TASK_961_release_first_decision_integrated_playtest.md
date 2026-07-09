# TASK_961 - Release First Decision Integrated Playtest

## Ziel / Problem
TASK_960 beschreibt den ersten Release-Decision-Spine als spielbaren Slice. Es fehlt der integrierte Playtest-Rahmen, der den Release-Pfad wirklich als Manifest/Evidence-Paket bewertet: Prozess, Deep-Link, Fensterinhalt, Homebase-bis-Mission, Dropship/LZ/Drop, erste Preview, `GO`, Post-GO-Feedback, Performance und Multiplayer-Grenze.

## Sinnhaftigkeit / Ursache
Ein Contract-Slice reicht nicht, um das Spielgefuehl zu belegen. Der naechste Schritt muss den echten Playtest sichtbar machen, ohne dabei selbst Gameplay-State zu erzeugen oder Erfolg zu faken.

## Umfang
- Read-only Analyzer `ReleaseFirstDecisionIntegratedPlaytest`.
- Capture-/Manifest-Tool `capture_release_first_decision_integrated_playtest.ps1`.
- Manifestfelder fuer Release-Prozess, `--release-singleplayer-lz-drop-preview`, Window-/Desktop-Screenshotpfade, beobachtete Release-Stages, Performance, HUD-Read-only-Grenze und Multiplayer-Snapshot-Grenze.
- Routing zu `TASK_962 - Release First Decision Playtest Findings`.

## Nicht-Ziele
- Kein automatisches Bestehen des Playtests.
- Kein Shortcut-Update.
- Kein neuer Gameplay-, Mission-, Movement-, Combat- oder Multiplayer-State.
- Kein Export-Umbau.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_960_first_decision_release_playable_slice.md`
- `docs/tasks/TASK_959_first_decision_playability_smoke.md`

## Akzeptanzkriterien
- Fehlender oder nicht spielbarer TASK_960-Slice blockiert.
- Fehlendes Manifest bleibt `needs_integrated_playtest_run`.
- Vollstaendiges Manifest setzt `integrated_playtest_passed`.
- Regressionspunkte erzeugen konkrete Issues und routen zu TASK_962-Findings.
- Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_integrated_playtest.gd`
- `scripts/tools/capture_release_first_decision_integrated_playtest.ps1`
- `scripts/tests/task_961_release_first_decision_integrated_playtest.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_961_release_first_decision_integrated_playtest.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_960_first_decision_release_playable_slice.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_959_first_decision_playability_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_961 legt den integrierten Playtest-Rahmen und ein Manifest-Tool an, fuehrt aber keinen echten menschlichen Playtest automatisch als bestanden. TASK_962 soll den echten Befund schneiden oder belegte Reibungen priorisieren.
