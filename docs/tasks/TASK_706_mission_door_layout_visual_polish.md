# TASK_706 - Mission Door Layout/Visual Polish

## Ziel / Problem
Nach TASK_705 ist der Door-Host/Client-Pfad technisch belegbar und der echte Zwei-Fenster-Run als Manual-Packet vorbereitet. Ohne neue menschliche Workbench-Notizen ist der beste autonome Anschluss, die sichtbare Door-Anzeige robuster zu machen und den aktuellen Projektstand als frische Handbuch-Workbench zusammenzufassen.

## Sinnhaftigkeit / Ursache
Die Door-Interaktion hat inzwischen Runtime-State, Collision/LOS-Producer, Button, Shortcut, Authority-Feedback und Manual-Run-Paket. Was noch leicht reiben kann, ist die Lesbarkeit im Missionsbild: Door closed/opening/open muss als Objektzustand erkennbar sein, ohne dass UI eine zweite Gameplay-Wahrheit setzt.

## Umfang
- Neuer kompakter HTML-Bericht unter `docs/reports/` mit Iststand, Handbuch, Reibungen, Playtest-Checkliste und naechstem Griff.
- Read-only Door-Layout-/Visual-Polish-Felder im bestehenden Object-Reaction-Snapshot.
- Terrain-3D-Render-Snapshot reicht diese Felder weiter und nutzt sie fuer sichtbare Door-Proxy-Akzente.
- Verifier prueft Report, Contract, Snapshot-Felder, Render-Felder und read-only-Grenzen.

## Nicht-Ziele
- Kein neues Door-State-System.
- Kein Gameplay-/Terrain-/Authority-Umbau.
- Kein echter menschlicher Zwei-Fenster-Klickbefund.
- Kein kompletter Missions- oder UI-Refactor.

## Relevante Contracts / Dokumente
- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_705_host_client_door_real_click_manual_run_packet.md`

## Akzeptanzkriterien
- Neuer Bericht existiert als HTML-Workbench mit sichtbarem `JSON exportieren`.
- Bericht nennt TASK_705 als letzten Stand und TASK_706 als aktuellen Door-Polish-Slice.
- Door-Reaction-Eintraege liefern `door_visual_polish_style_id`, `door_layout_readout`, `door_layout_tone` und `door_layout_visual_weight`.
- Render-Snapshot exportiert dieselben Felder fuer Door-Entries.
- Door-Proxy bekommt sichtbare, zustandsabhaengige Layout-Akzente, ohne Gameplay-Wahrheit zu setzen.
- Bestehender Door-Animation-/Asset-Swap-Verifier bleibt gruen.

## Betroffene Dateien
- `docs/tasks/TASK_706_mission_door_layout_visual_polish.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/reports/project_current_state_handbook_refresh_2026_06_30.html`
- `scripts/mission/mission_interaction_object_reaction.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_706_mission_door_layout_visual_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_706_mission_door_layout_visual_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_696_door_runtime_visual_animation_asset_swap.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die sichtbare echte Fensterwirkung bleibt erst nach einem menschlichen FullHD-/Host-Client-Blick entschieden.
- Der neue Bericht ist Arbeitsnotiz und Handbuch, keine Runtime-Wahrheit.
