# TASK_830 - Release Start Mission Deep-Link Evidence

## Ziel / Problem
Nach TASK_829 erreicht der exportierte Build reproduzierbar die Homebase. Fuer den naechsten sichtbaren Release-Schritt fehlt noch ein stabiler QA-Start, der den ersten `Start Mission`-Griff bis zur Mission/LZ-Phase belegt.

## Sinnhaftigkeit / Ursache
Headless-Smokes decken `Homebase -> Start Mission -> Mission` bereits ab. Der reale EXE-Capture endet aber bislang an der Homebase, weil Fenster-/Maus-Injektion fuer den sichtbaren Build zu fragil ist. Ein expliziter Deep-Link gibt uns reproduzierbare Evidenz, ohne den normalen Spielerpfad zu veraendern.

## Umfang
- `--release-singleplayer-start-mission` oeffnet ueber das Main Menu den Singleplayer-Pfad.
- Der MetaLayer wartet auf die Homebase-Actionability-Guards und loest danach denselben `request_mission_start()`-Pfad aus wie der sichtbare Button.
- Ein Snapshot meldet Argument, Status, aktuelle View, aktive Mission und Insertion-Gate.
- Der checked Release-Launcher nutzt weiterhin seine bestehenden `-LaunchArguments`.

## Nicht-Ziele
- Kein automatischer Missionsstart im normalen Spielerpfad.
- Kein neuer Mission-, Dropship-, LZ- oder Combat-Flow.
- Keine zweite Mission-Wahrheit im UI.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_829_release_singleplayer_deeplink_evidence.md`
- `docs/tasks/TASK_811_station_reentry_release_candidate_mission_launch_actionability_smoke.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Main Menu behandelt `--release-singleplayer-start-mission` als Singleplayer-Route.
- MetaLayer erkennt denselben Parameter und startet erst nach sichtbarer Homebase-Actionability.
- Der Start nutzt `HomebaseScreen.request_mission_start()` und keine separate Mission-Erzeugung.
- Der Snapshot zeigt `current_meta_view = mission`, `active_mission_exists = true` und `insertion_gate = pass`.

## Betroffene Dateien
- `scripts/ui/main_menu_screen.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_830_release_start_mission_deeplink_evidence.gd`
- `docs/tasks/TASK_830_release_start_mission_deeplink_evidence.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_830_release_start_mission_deeplink_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_811_station_reentry_release_candidate_mission_launch_actionability_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_829_release_singleplayer_deeplink_evidence.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Deep-Link ist ein QA-Haken. Der normale Spieler soll weiterhin bewusst `Einzelspieler` und danach `Start Mission` klicken.
- Der reale Capture muss nach Export zeigen, dass die EXE nicht nur Homebase, sondern die Mission/LZ-Phase erreicht.
