# TASK_953 - Decision Overlay Real Window Recapture

## Ziel / Problem
TASK_952 definiert die Decision-Preview als kompakte safe/risky/suicidal-Badges. Es fehlt der Real-Window-Recapture-Rahmen, der spaeter beweist, ob diese Badge-Politur im echten F6-Fenster lesbar und ruhig wirkt.

## Sinnhaftigkeit / Ursache
Automatische Snapshot-Checks koennen Textlaenge und Datenvertrag pruefen, aber nicht beurteilen, ob Kontrast, Position und visuelle Gewichtung im echten Fenster passen. Dafuer braucht es ein reproduzierbares Manifest mit Screenshot-Pfaden und Pflichtchecks.

## Umfang
- Read-only Analyzer `DecisionOverlayRealWindowRecapture`.
- Capture-Tool-Geruest `capture_decision_overlay_real_window_recapture.ps1`.
- Manifest-Felder fuer TASK_952-Source, Window-/Desktop-Screenshotpfade, Prozess-/Capture-Metadaten und Pflichtchecks.
- Keine automatische manuelle Abnahme.

## Nicht-Ziele
- Kein automatisches Akzeptieren eines Screenshots.
- Kein neues HUD-Panel.
- Kein Command-, Movement-, Fire-, Damage- oder Multiplayer-State.
- Kein neues Export- oder Release-System.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_952_decision_overlay_f6_visual_polish.md`

## Akzeptanzkriterien
- Fehlendes oder falsches Manifest blockiert mit klaren Issues.
- Gutes Manifest wird `review_ready`, aber ohne abgeschlossene manuelle Checks nicht akzeptiert.
- Erledigte manuelle Checks koennen den Snapshot auf `accepted` setzen.
- Snapshot bleibt `read_only` und `read_only_capture`.
- Capture-Tool setzt `manual_review_done = false` und schreibt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/decision_overlay_real_window_recapture.gd`
- `scripts/tools/capture_decision_overlay_real_window_recapture.ps1`
- `scripts/tests/task_953_decision_overlay_real_window_recapture.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_953_decision_overlay_real_window_recapture.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_952_decision_overlay_f6_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_953 schafft den Capture-/Review-Rahmen, erzeugt aber noch keinen belastbaren neuen Screenshot-Beweis. Der naechste Slice `TASK_954 - Decision Overlay Real Window Visual Findings` soll daraus echte Visual Findings schneiden.
