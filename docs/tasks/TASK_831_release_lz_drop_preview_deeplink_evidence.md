# TASK_831 - Release LZ Drop Preview Deep-Link Evidence

## Ziel / Problem
Nach TASK_830 erreicht der exportierte Build reproduzierbar die Mission/LZ-Phase. Der naechste kritische Spielergriff ist `LZ setzen -> Drop -> Move Preview`, weil dort sichtbar werden muss, ob Payload, Deboarding und erste Commander-Entscheidung zusammenpassen.

## Sinnhaftigkeit / Ursache
TASK_812 prueft diesen Pfad headless. Fuer den echten Release-Capture fehlt aber ein stabiler, expliziter Einstieg, der ohne fragile Fenster-/Maus-Injektion bis zum Pre-GO-Move-Preview-Zustand kommt.

## Umfang
- `--release-singleplayer-lz-drop-preview` oeffnet ueber das Main Menu den Singleplayer-Pfad.
- Der MetaLayer startet die Mission, schliesst den Dropship-Transit ab, setzt eine LZ, loest Drop aus und plant eine Move-Preview.
- Der Pfad nutzt bestehende TacticalController-/Dropship-Card-/Command-Testpfade und fuehrt kein `GO` aus.
- Ein Snapshot meldet LZ, deployed Fireteam, geplante Waypoints, Waypoint-Preview, Visualisierung und GO-Bereitschaft.

## Nicht-Ziele
- Kein automatischer GO.
- Kein Combat-/Firefight-Autostart.
- Kein neuer Dropship-, LZ-, Movement- oder UI-Wahrheitszustand.
- Kein Ersatz fuer den normalen manuellen Spielerflow.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_830_release_start_mission_deeplink_evidence.md`
- `docs/tasks/TASK_812_station_reentry_release_candidate_lz_drop_preview_actionability_smoke.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Main Menu behandelt `--release-singleplayer-lz-drop-preview` als Singleplayer-Route.
- MetaLayer erkennt denselben Parameter und erreicht `current_meta_view = mission`.
- LZ ist gesetzt, Fireteam ist deployed und der First-Move-Preview-Snapshot ist `pass`.
- Planned Waypoint, Waypoint-Intent-Preview und Visualisierung sind vorhanden.
- `GO` ist bereit, aber nicht ausgefuehrt.

## Betroffene Dateien
- `scripts/ui/main_menu_screen.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_831_release_lz_drop_preview_deeplink_evidence.gd`
- `docs/tasks/TASK_831_release_lz_drop_preview_deeplink_evidence.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_831_release_lz_drop_preview_deeplink_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_812_station_reentry_release_candidate_lz_drop_preview_actionability_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_830_release_start_mission_deeplink_evidence.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Deep-Link ist QA-Evidenz und nutzt bestehende schnelle Test-Hilfswege fuer Deboarding. Der echte manuelle Timing-/Feel-Playtest bleibt danach sinnvoll.
- Der naechste sichtbare Release-Schritt ist `GO -> First Movement/Contact`, nicht weiterer Homebase-Polish.
