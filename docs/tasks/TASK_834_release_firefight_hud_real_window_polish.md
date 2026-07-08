# TASK_834 - Release Firefight HUD Real Window Polish

## Ziel / Problem
TASK_833 bringt die wichtigste `NEXT ... | WHY ...`-Zeile an die erste Stelle im Selected-Fireteam-Status. Im echten Release-Fenster bleibt dieser Block aber noch zu klein und zu technisch fuer den ersten Feuerwechsel.

## Sinnhaftigkeit / Ursache
Der Release-Pfad ist wieder bis `Einzelspieler -> Start Mission -> LZ -> Drop -> Preview -> GO -> Firefight` erreichbar. Jetzt muss der Spieler im echten Fenster den naechsten Griff lesen koennen, ohne die dichte Statuszeile zu entziffern. Die bestehende Anzeige ist logisch korrekt, braucht aber einen klareren Real-Window-Label-Contract.

## Umfang
- Selected-Fireteam-Status bekommt bei aktiver `NEXT ... | WHY ...`-Zeile einen groesseren, kontraststaerkeren Real-Window-Stil.
- Der vorhandene Text bleibt unveraendert und read-only.
- Autowrap und Mindesthoehe schuetzen die Decision-Line gegen Abschneiden im FullHD-/Ultrawide-Fenster.
- Snapshot und Verifier pruefen Stil, Prioritaet und read-only-Grenzen.
- Ein aelterer TASK_817-Source-Gate wird auf konkrete TASK_817-Akzeptanzkriterien ausgerichtet, damit ein alter Review-Status die sichtbare Decision-Line nicht faelschlich blockiert.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen Commands, FireEvents, DamageEvents oder Navigation.
- Kein neuer Missions- oder Multiplayer-State im HUD.
- Kein komplettes Bottom-Dock-Redesign.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_833_release_firefight_hud_readability_polish.md`
- `docs/tasks/TASK_817_station_reentry_release_candidate_targeted_firefight_polish.md`

## Akzeptanzkriterien
- TASK_833 bleibt gruen: die `NEXT ... | WHY ...`-Zeile ist weiter die erste Zeile.
- TASK_817 bleibt gruen, wenn Decision-Line, Sichtbarkeit und Read-only erfuellt sind, auch wenn der aeltere TASK_814-Source-Kontext weiter `review` meldet.
- Selected-Fireteam-Status meldet den Real-Window-Stil `task_834_release_firefight_hud_real_window_v1`.
- Fontgroesse, Outline, Autowrap und Mindesthoehe sind fuer den echten Fensterblick erhoeht.
- Snapshot bleibt read-only und erzeugt keine Commands, FireEvents, DamageEvents oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_834_release_firefight_hud_real_window_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_834_release_firefight_hud_real_window_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_833_release_firefight_hud_readability_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_832_release_first_go_firefight_deeplink_evidence.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Task macht die wichtigste Decision-Line lesbarer, ersetzt aber keinen manuellen Fensterblick auf die gesamte Bottom-Dock-Dichte. Danach bleibt ein echter Release-Capture sinnvoll.
