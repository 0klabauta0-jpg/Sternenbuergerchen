# TASK_605 - Host Client F6 Visual Review Pass

## Ziel / Problem
TASK_604 beweist den Host/Client-Core-Loop als kombinierten read-only Snapshot. Offen bleibt der sichtbare F6-Blick: Teamchip, Mission-Control-`ACT`-Zeile, Objective/Cargo/ROE und Selected-Fireteam-Kontext muessen im Bild zusammen pruefbar werden.

Ziel ist ein lokaler Evidence-Pass mit PNG und Manifest fuer den Host/Client-F6-Zustand. Headless erzeugt ein markiertes Evidence-Board; ein Fensterlauf darf einen echten Viewport-Readback speichern.

## Sinnhaftigkeit / Ursache
Multiplayer-Lesbarkeit scheitert oft nicht am Datenpfad, sondern an sichtbarer Dichte, Ueberlappung und widerspruechlichen Panels. Ein reproduzierbarer Screenshot-/Evidence-Ort macht diese Reibung reviewbar, ohne sofort UI umzubauen oder neue Runtime-Wahrheit zu erzeugen.

## Umfang
- Neuer Verifier `task_605_host_client_f6_visual_review_pass.gd`.
- Er baut den Frontier-Probe-Host/Client-Kontext mit Host Peer 1, Peer 2, Objective/Cargo, SUP-ROE und Kontakt auf.
- Er prueft `get_core_loop_host_client_feel_snapshot()`.
- Er schreibt `tmp/host_client_f6_visual_review.png` und `tmp/host_client_f6_visual_review.json`.
- Der laufende HTML-Bericht bekommt TASK_605-Artefaktfelder, manuelle Review-Checks und TASK_606 als Anschluss.

## Nicht-Ziele
- Kein echtes Zwei-Prozess-/LAN-Setup.
- Kein automatisches UI-Polish aus einem Headless-Board.
- Kein neues Networking-System.
- Keine neue Gameplay-Wahrheit im HUD oder Report.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_604_core_loop_host_client_feel_smoke.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- PNG und Manifest werden unter `tmp/` erzeugt.
- Manifest enthaelt `task_id = TASK_605`, `capture_type = host_client_f6_visual_review`, `read_only = true`, `ui_sets_gameplay_truth = false`.
- Manifest nennt TASK_604-Gate, Teamchip-Kontext, ACT-/OBJ-/CARGO-/ROE-Sichtbarkeit und Selected-Fireteam-Sichtbarkeit.
- Headless darf ein Evidence-Board erzeugen und markiert `generated_evidence_board = true`.
- Fensterlauf darf `viewport_readback_available = true` setzen.
- Der Bericht exportiert PNG-/Manifestpfad, Review-Status und naechste Prioritaet.

## Betroffene Dateien
- `scripts/tests/task_605_host_client_f6_visual_review_pass.gd`
- `docs/tasks/TASK_605_host_client_f6_visual_review_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `scripts/tests/task_596_homebase_progression_player_review_notes.gd`
- `scripts/tests/task_598_homebase_progression_evidence_polish_findings.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_605_host_client_f6_visual_review_pass.gd`
- Regression: `task_604_core_loop_host_client_feel_smoke.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- Regression: `task_598_homebase_progression_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Headless-Evidence ersetzt keinen finalen menschlichen Spielgefuehlentscheid.
- Falls das echte Fensterbild Ueberlappungen oder kryptische Texte zeigt, sollte TASK_606 die konkreten Visual-Polish-Findings anwenden.
- Das Manifest ist Berichtsfutter und Diagnose, keine Runtime-Autoritaet.
