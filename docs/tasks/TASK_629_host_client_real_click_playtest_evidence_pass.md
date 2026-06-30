# TASK_629 - Host Client Real Click Playtest Evidence Pass

## Ziel / Problem
Nach TASK_628 ist der HUD-Vertrag wieder gruen, aber der naechste echte Host/Client-Klicklauf haengt noch an mehreren verstreuten Pruefpunkten: Badge, Eventlog-Layout, #17-Inbound-Karten, Fire-Rule-Slots, sichtbarer Reject, Tooltip-Rohgrund, Latenz und Snapshot-Sync.

## Sinnhaftigkeit / Ursache
TASK_626 hat die erwartete Real-Click-Evidence ins Capture-Manifest gelegt. TASK_627 und TASK_628 haben danach echte HUD-Reibung beseitigt. Jetzt braucht der Playtest wieder einen festen Packet-/Gate-Punkt, damit der naechste Zwei-Fenster-Lauf nicht als loser Screenshot endet.

## Umfang
- Ein read-only Playtest-Packet unter `tmp/host_client_real_click_playtest_packet.json`.
- Das Packet fasst aktuelle Vorbedingungen, konkrete Klickfolge, erwartete sichtbare Hinweise und offene manuelle Beobachtungen zusammen.
- Rolling Report und Ist-Stand-/Handbuch-Bericht markieren TASK_629 als aktuellen Arbeitsstand.
- Keine Gameplay-, Authority-, Movement-, Combat- oder UI-Wahrheit wird erzeugt.

## Nicht-Ziele
- Kein automatisches Klicken in Godot-Fenstern.
- Kein OCR-/Pixel-Erkennungssystem.
- Kein neuer Multiplayer-Authority-Pfad.
- Kein neues HUD-Panel und kein Toast-/Bubble-System.
- Kein Mini-Szenario-Content in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_626_host_client_real_click_review_evidence.md`
- `docs/tasks/TASK_627_host_client_fireteam_eventlog_overlap_polish.md`
- `docs/tasks/TASK_628_mission_hud_legacy_contract_refresh.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- Das Playtest-Packet nutzt `schema = sternenbuergerchen.host_client_real_click_playtest_packet.v1`.
- `source_real_run_manifest_path` zeigt auf `tmp/host_client_two_window_real_run_review.json`.
- Vorbedingungen enthalten Role/Peer/Team-Badges, getrennte Host-/Client-Crops, Eventlog-Overlap-Fix, #16 Fire-Rule-Slots und #17 Inbound-Member-Cards.
- Die Klickfolge nennt Peer-2-Alpha-Reject, sichtbaren `BLOCK P2 wrong team`, Tooltip-Rohgrund `peer_team_mismatch`, Input-Latenz, Snapshot-Sync und Fokuswechsel.
- `manual_review_required = true`, `manual_review_done = false`, `read_only = true` und `ui_sets_gameplay_truth = false`.
- Reports und Statusdateien nennen TASK_629, ohne den echten Klicklauf als erledigt zu behaupten.

## Betroffene Dateien
- `scripts/tests/task_629_host_client_real_click_playtest_evidence_pass.gd`
- `docs/tasks/TASK_629_host_client_real_click_playtest_evidence_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/launch_host_client_two_window_review.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1`
- `godot_console.exe --headless --path . --script scripts/tests/task_629_host_client_real_click_playtest_evidence_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_628_mission_hud_legacy_contract_refresh.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_626_host_client_real_click_review_evidence.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das Packet ist immer noch kein erledigter menschlicher Playtest. Es macht nur den naechsten Lauf so konkret, dass daraus belastbare UI-/Latenz-/Sync-Findings entstehen koennen.
- Wenn der sichtbare Blocker im echten Lauf zu leise ist, sollte der naechste Task ein belegter kleiner Feedback-Polish sein. Wenn er reicht, ist ein Mini-Szenario-Feel-Slice sinnvoller.
