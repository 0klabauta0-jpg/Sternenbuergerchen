# TASK_811 - Station Reentry Release Candidate Mission Launch Actionability Smoke

## Ziel / Problem
Nach dem gruenen Homebase-CTA muss der naechste Spielergriff wirklich funktionieren: `Start Mission` soll vom `Einzelspieler`-Start in eine sichtbare Mission fuehren, in der LZ, Dropship, Payload und erste Order-Kontrollen lesbar sind.

## Sinnhaftigkeit / Ursache
TASK_810 prueft den Homebase-Zustand vor dem Start. Die naechste Reibung liegt direkt danach: Ein aktiver Handoff allein reicht nicht, wenn der Spieler nach dem Klick nicht in der Mission landet oder dort keinen klaren LZ-/Drop-Griff sieht.

## Umfang
- Read-only Snapshot `MetaLayerFlow.get_release_candidate_mission_launch_actionability_snapshot()`.
- Main-Menu-`Einzelspieler`-Verifier mit echtem `Start Mission`-Button-Press.
- Kombination aus bestehendem Homebase-to-Mission-Handoff und TASK_539-Insertion-Readability-Snapshot.
- Pruefung von sichtbarer Mission, Handoff-Gate, LZ-Naechstschritt, Drop-blockiert-bis-LZ, Fireteam-Status und ersten Order-Kontrollen.

## Nicht-Ziele
- Kein LZ-Setzen, kein Drop ausloesen, kein GO.
- Kein Screenshot-/Pixeltest.
- Keine neue Gameplay-, UI- oder Multiplayer-Wahrheit.
- Kein Umbau des Mission-Tactical-Controllers.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_810_station_reentry_release_candidate_first_mission_cta_visual_smoke.md`
- `docs/tasks/TASK_539_mission_insertion_first_order_readability_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Der Testpfad lautet `MainMenu -> Einzelspieler -> Homebase -> Start Mission -> Mission`.
- Der sichtbare `Start Mission`-Button loest den Handoff aus.
- `current_meta_view` ist danach `mission`, eine aktive Mission existiert und der MissionHost ist sichtbar.
- Homebase-to-Mission-Handoff bleibt `pass`.
- TASK_539-Insertion-Snapshot bleibt read-only und `pass`.
- LZ ist als naechster Schritt sichtbar.
- Drop ist vor LZ sichtbar, aber deaktiviert.
- Ausgewaehltes Fireteam sowie Move/Defend/GO-Kontrollen bleiben lesbar.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_811_station_reentry_release_candidate_mission_launch_actionability_smoke.gd`
- `docs/tasks/TASK_811_station_reentry_release_candidate_mission_launch_actionability_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_811_station_reentry_release_candidate_mission_launch_actionability_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_810_station_reentry_release_candidate_first_mission_cta_visual_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_539_mission_insertion_first_order_readability_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Smoke stoppt vor LZ-Setzung und Drop. TASK_812 sollte danach LZ setzen, Drop ausloesen und den ersten Preview-/GO-Moment pruefen.
- Der Test bewertet Control-/Snapshot-Zustand, nicht menschliche Schoenheit. Sichtbarer Feinschliff bleibt Folgearbeit, wenn der echte Fensterblick reibt.
