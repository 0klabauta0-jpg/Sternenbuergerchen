# TASK_832 - Release First GO Firefight Deep-Link Evidence

## Ziel / Problem
Nach TASK_831 kommt der erste echte Commander-Moment nach der Vorschau: `GO`, Bewegung, erster Kontakt und erste Engagement-Reaktion. Dieser Pfad muss im exportierten Build reproduzierbar erreichbar sein, ohne fragile Maus-/Fenster-Injektion.

## Sinnhaftigkeit / Ursache
TASK_813 prueft den Ablauf headless. Fuer Release-Captures und Tester fehlt aber ein expliziter EXE-Parameter, der denselben Pfad bis nach `GO` herstellt und sichtbar macht, ob Bewegung, Kontaktmeldung und Feuerentscheidung zusammenpassen.

## Umfang
- `--release-singleplayer-first-go-firefight` oeffnet ueber das Main Menu den Singleplayer-Pfad.
- Der MetaLayer nutzt den bestehenden TASK_831-Pfad bis LZ, Drop und Move-Preview.
- Danach wird `GO` ueber `execute_selected_fireteam_orders()` ausgefuehrt.
- Fuer reproduzierbare Lesbarkeit wird ein vorhandener Gegner nahe ans ausgewaehlte Fireteam gesetzt und der bestehende Kontakt-/Engagement-Pfad angestossen.
- Ein Snapshot meldet GO-Ausfuehrung, Movement-State, Kontaktanzahl, Engagement-Status und Read-only-Grenzen.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein neues Zielerkennungs-, Damage- oder Multiplayer-Authority-System.
- Kein automatisches Missionsende oder Debrief.
- Kein Ersatz fuer den normalen manuellen Spielerflow.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_831_release_lz_drop_preview_deeplink_evidence.md`
- `docs/tasks/TASK_813_station_reentry_release_candidate_first_go_firefight_actionability_smoke.md`
- `docs/tasks/TASK_543_mission_first_engagement_feedback_pass.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Main Menu behandelt `--release-singleplayer-first-go-firefight` als Singleplayer-Route.
- MetaLayer erkennt denselben Parameter und erreicht `current_meta_view = mission`.
- LZ/Drop/Move-Preview bleibt vor `GO` gruen.
- `GO` ist ausgefuehrt und Movement-Feedback ist sichtbar.
- Erster Kontakt und Engagement-Status sind im Snapshot lesbar.
- Der Snapshot bleibt read-only und setzt keine Gameplay- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/ui/main_menu_screen.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_832_release_first_go_firefight_deeplink_evidence.gd`
- `docs/tasks/TASK_832_release_first_go_firefight_deeplink_evidence.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_832_release_first_go_firefight_deeplink_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_813_station_reentry_release_candidate_first_go_firefight_actionability_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_831_release_lz_drop_preview_deeplink_evidence.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Deep-Link ist QA-Evidenz und positioniert fuer den Nachweis einen vorhandenen Gegner reproduzierbar. Ein echter Fenster-Playtest fuer Kampfdramaturgie, Timing und HUD-Schoenheit bleibt danach sinnvoll.
- Der naechste sichtbare Schritt ist ein Release-Capture mit `--release-singleplayer-first-go-firefight` und danach gezielter HUD-/Feel-Polish auf Basis des Bildes.
