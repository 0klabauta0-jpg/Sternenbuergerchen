# TASK_620 - Host Client Badge Re-Capture Review

## Problem
TASK_619 macht Host/Client-Rolle, Peer und Team im Mission-HUD sichtbar. Der erste echte Sichttest nach dem Fix muss aber als reproduzierbares Review-Artefakt dokumentiert werden, sonst bleibt die Aussage "Host und Client sind jetzt unterscheidbar" zu sehr an einem lokalen Chat-/Screenshot-Moment haengen.

## Ursache
Der Capture-Helper schreibt bereits Desktop-Screenshot, Host-Crop, Client-Crop und Manifest. Das Manifest kennt aber noch nicht die erwarteten Badge-Texte aus dem Host-/Client-Launchplan und empfiehlt weiterhin aeltere Follow-ups. Dadurch kann ein spaeterer Reviewer nicht sauber sehen, ob TASK_619 im sichtbaren Re-Capture abgedeckt ist.

## Umfang
- Capture-Manifest um erwartete Host-/Client-Badge-Texte und Badge-Re-Capture-Gates erweitern.
- Laufenden HTML-Bericht und Ist-Stand-/Handbuch-Bericht um TASK_620-/Re-Capture-Felder erweitern.
- Verifier fuer Task, Contract, Report, Capture-Helper und Manifest-Felder anlegen.
- Echter Zwei-Fenster-Capture bleibt explizit und lokal; keine Pflicht fuer Headless-Verifier.

## Nicht-Ziele
- Keine OCR-/Bildanalyse.
- Keine Netcode-Aenderung.
- Keine neue Multiplayer-Lobby-Quelle.
- Keine Runtime-, Peer-, Team-, Command-, Objective-, Cargo-, Combat- oder Movement-Wahrheit im Capture-Manifest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_619_host_client_role_peer_badge_hud.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- Manifest nennt `host_expected_badge_text = HOST P1 ALPHA` und `client_expected_badge_text = CLIENT P2 BRAVO`.
- Manifest markiert den Badge-Re-Capture als eigenen Review-Kontext und bleibt read-only.
- Rolling Report und Handbuch nennen den Re-Capture als erledigten/naechsten Review-Anker.
- Verifier prueft Capture-Helper, Contract, Reports und vorhandenes Manifest, falls es lokal existiert.

## Betroffene Dateien
- `docs/tasks/TASK_620_host_client_badge_recapture_review.md`
- `scripts/tools/capture_host_client_two_window_real_run.ps1`
- `scripts/tests/task_620_host_client_badge_recapture_review.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 10`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_620_host_client_badge_recapture_review.gd`
- Regression: `task_619_host_client_role_peer_badge_hud.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Verifier prueft Manifest-/Vertragsfelder und die Existenz/Schreibbarkeit der Crop-Artefakte, aber keine Pixel-OCR. Die finale Lesbarkeit bleibt weiterhin ein menschlicher Sichtentscheid.
- Der naechste sinnvolle Schritt nach TASK_620 ist ein echter Multiplayer-Feel-Review: Befehle, Authority, Sync, Performance und Bediengefuehl in den zwei sichtbaren Fenstern.
