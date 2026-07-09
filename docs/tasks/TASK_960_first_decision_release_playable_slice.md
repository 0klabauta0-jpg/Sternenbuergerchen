# TASK_960 - First Decision Release Playable Slice

## Ziel / Problem
TASK_959 prueft den ersten Entscheidungsgriff als Playability-Smoke. Es fehlt ein kleiner Release-Slice, der die Route vom Singleplayer-Start bis zum ersten `GO` und sichtbarem Post-GO-Feedback als zusammenhaengenden, spielbaren Ablauf absichert.

## Sinnhaftigkeit / Ursache
Das Spiel fuehlt sich erst dann wie ein kleiner spielbarer Abschnitt an, wenn Homebase, Fireteam, Flightdeck, Dropship, Mission, LZ, Drop, Preview, `GO` und Feedback nicht nur einzeln, sondern als zusammenhaengender Spine lesbar bleiben.

## Umfang
- Read-only Analyzer `FirstDecisionReleasePlayableSlice`.
- Akzeptiert nur bestandenen TASK_959-Smoke.
- Bewertet einen Release-Spine-Trace fuer Homebase, Fireteam, Flightdeck, Dropship-Payload, Mission, LZ, Drop, Deployed-Fireteam, Decision-Preview, NEXT/WHY, Risk, GO-Grenze, GO, Post-GO-Feedback, Command-Queue-Lifecycle, Hotpath, HUD-Read-only und Multiplayer-Snapshot-Grenze.
- Routet bei bestandenem Slice zu `TASK_961 - Release First Decision Integrated Playtest`.

## Nicht-Ziele
- Kein Export-/Build-Umbau.
- Kein neuer Command-Commit aus dem Analyzer.
- Kein HUD- oder Mission-Rewrite.
- Kein neuer Multiplayer-State.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_959_first_decision_playability_smoke.md`
- `docs/tasks/TASK_958_first_decision_real_playthrough_visual_findings.md`

## Akzeptanzkriterien
- Fehlender oder nicht bestandener TASK_959-Smoke blockiert.
- Bestandener Smoke ohne Release-Spine-Trace bleibt `needs_release_slice_trace`.
- Vollstaendiger Spine setzt `release_slice_playable`.
- Regressionspunkte erzeugen konkrete Issues.
- Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/first_decision_release_playable_slice.gd`
- `scripts/tests/task_960_first_decision_release_playable_slice.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_960_first_decision_release_playable_slice.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_959_first_decision_playability_smoke.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_958_first_decision_real_playthrough_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_960 ist ein Contract-/Gate-Slice, kein echter manueller Playtest. Der naechste Schritt sollte den integrierten Release-Pfad wirklich starten/capturen oder belegte Slice-Regressionspunkte eng beheben.
