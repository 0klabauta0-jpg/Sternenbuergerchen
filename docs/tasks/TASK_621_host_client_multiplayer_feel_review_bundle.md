# TASK_621 - Host Client Multiplayer Feel Review Bundle

## Problem
TASK_620 belegt den sichtbaren Host-/Client-Badge im Zwei-Fenster-Capture. Fuer den naechsten echten Multiplayer-Feel-Test fehlen aber noch ein gebuendelter Review-Stand und eine klare Checkliste: Welche Evidence liegt vor, welche Authority-/Sync-Smokes stuetzen den Stand, welche manuellen Punkte muss ein Mensch im Zwei-Fenster-Lauf noch pruefen?

## Ursache
Die bisherigen Tasks bauen den Host/Client-Pfad bewusst in kleinen Schritten auf: Smoke, Capture, Fensterlayout, Crop, HUD-Badge und Re-Capture. Diese Evidence liegt verteilt in Manifesten, Verifiern, HTML-Berichten und Task-Dateien. Ohne Bundle ist der naechste Test leicht wieder ein Screenshot-Moment statt ein nachvollziehbarer Playtest.

## Umfang
- Read-only Review-Bundle `tmp/host_client_multiplayer_feel_review.json` als lokales Manifest.
- Bundle verweist auf den echten TASK_620-Real-Run-Manifestpfad, Host-/Client-Crops und erwartete Badge-Texte.
- Bundle listet vorhandene Authority-/Sync-/Feel-Smokes als Evidence-Tests.
- Bundle definiert die manuellen Zwei-Fenster-Checks fuer Sichtbarkeit, Peer-2-Bravo-Command, Peer-2-Alpha-Reject, Snapshot-Sync, F6-Lesbarkeit, Performance und Notizen.
- Rolling HTML-Bericht und Ist-Stand-/Handbuch-Bericht zeigen TASK_621 als aktuellen Arbeitsanker.

## Nicht-Ziele
- Kein neuer Netcode.
- Kein neuer Command-Pfad.
- Kein automatischer GUI-/Fensterlauf.
- Keine OCR oder Pixelbewertung.
- Keine Runtime-, Peer-, Command-, Objective-, Cargo-, Combat-, Movement- oder UI-Wahrheit im Bundle.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_620_host_client_badge_recapture_review.md`
- `docs/tasks/TASK_610_host_client_two_window_playtest_notes.md`
- `docs/tasks/TASK_607_two_instance_host_client_runtime_smoke.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- Verifier erzeugt oder aktualisiert `tmp/host_client_multiplayer_feel_review.json`.
- Bundle nutzt Schema `sternenbuergerchen.host_client_multiplayer_feel_review.v1`.
- Bundle bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.
- Bei vorhandenem TASK_620-Manifest uebernimmt das Bundle `badge_recapture_gate = review_ready`, Host-/Client-Crop-Pfade und die erwarteten Badge-Texte `HOST P1 ALPHA` / `CLIENT P2 BRAVO`.
- Bundle nennt die vorhandenen Evidence-Tests fuer TASK_604, TASK_607, TASK_610 und TASK_620.
- Bundle haelt den manuellen Review offen und empfiehlt als naechsten Schritt `TASK_622 - Host Client Command Authority Live Interaction Review`.
- Reports und Contract dokumentieren, dass TASK_621 nur Playtest-/Review-Evidence buendelt.

## Betroffene Dateien
- `docs/tasks/TASK_621_host_client_multiplayer_feel_review_bundle.md`
- `scripts/tests/task_621_host_client_multiplayer_feel_review_bundle.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_621_host_client_multiplayer_feel_review_bundle.gd`
- Regression: `godot_console.exe --headless --path . --script scripts/tests/task_620_host_client_badge_recapture_review.gd`
- Regression: `godot_console.exe --headless --path . --script scripts/tests/task_619_host_client_role_peer_badge_hud.gd`
- Optionaler tiefer Smoke: `godot_console.exe --headless --path . --script scripts/tests/task_604_core_loop_host_client_feel_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das Bundle ist kein erledigter menschlicher Playtest. Es macht den naechsten Test nur strukturiert und reproduzierbar.
- Der echte Live-Interaction-Review muss danach belegen, ob Peer-2-Bravo-Befehle, Alpha-Reject, Snapshot-Sync, UI-Lesbarkeit und Performance im sichtbaren Zwei-Fenster-Lauf wirklich gut genug sind.
