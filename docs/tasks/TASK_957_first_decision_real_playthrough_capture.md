# TASK_957 - First Decision Real Playthrough Capture

## Ziel / Problem
TASK_956 macht die erste Decision-Lesung im Command-Feedback spielernaeher. Es fehlt der reproduzierbare echte Fenster-Capture, der prueft, ob `NEXT`, `WHY`, Choice-Zeilen, Preview-Grenze und `GO`-Bedienbarkeit im laufenden Playthrough sichtbar sind.

## Sinnhaftigkeit / Ursache
Snapshot-Tests beweisen Struktur, aber nicht den echten Blick im Fenster. TASK_957 legt deshalb den read-only Capture-/Review-Rahmen fuer den ersten Decision-Playthrough an und laesst die manuelle Sichtbewertung bewusst offen.

## Umfang
- Read-only Analyzer `FirstDecisionRealPlaythroughCapture`.
- Capture-Tool-Geruest `capture_first_decision_real_playthrough.ps1`.
- Manifestfelder fuer TASK_956-Source, Deep-Link `--release-singleplayer-lz-drop-preview`, Screenshotpfade, Prozess-/Capture-Metadaten und Pflichtchecks.
- Keine automatische manuelle Abnahme.

## Nicht-Ziele
- Kein automatisches Akzeptieren eines Screenshots.
- Kein neuer Command-, Movement-, Fire-, Damage- oder Multiplayer-State.
- Kein neues HUD-Panel.
- Kein Export- oder Shortcut-Umbau.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_956_first_decision_micro_scenario_polish.md`

## Akzeptanzkriterien
- Fehlendes oder falsches Manifest blockiert mit klaren Issues.
- Gutes Manifest wird `review_ready`, aber ohne abgeschlossene manuelle Checks nicht akzeptiert.
- Abgeschlossene manuelle Checks koennen `accepted` setzen.
- Snapshot bleibt `read_only` und `read_only_capture`.
- Capture-Tool setzt `manual_review_done = false`, nutzt den First-Decision-Deep-Link und schreibt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/first_decision_real_playthrough_capture.gd`
- `scripts/tools/capture_first_decision_real_playthrough.ps1`
- `scripts/tests/task_957_first_decision_real_playthrough_capture.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_957_first_decision_real_playthrough_capture.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_956_first_decision_micro_scenario_polish.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_955_decision_overlay_playability_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_957 erzeugt den Belegrahmen, aber noch keinen akzeptierten Sichtbefund. Der naechste Slice `TASK_958 - First Decision Real Playthrough Visual Findings` soll den echten Fensterblick schneiden und entscheiden, ob noch UI-Polish noetig ist.
