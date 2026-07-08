# BUGFIX - Release Homebase Direct Start Copy Clarity

## Ziel / Problem
Der frische `EXE -> Einzelspieler`-Pfad ist technisch wieder startbar, die sichtbare Homebase konnte aber weiterhin wie ein alter FOB-Transfer wirken: `Mission slots 4 / 3`, `Transfer ready` und ein Summary-Text mit `send the team to FOB`. Fuer Spieler sieht das wie ein Widerspruch oder ein blockierter Workflow aus.

## Sinnhaftigkeit / Ursache
Der Homebase-Screen nutzte fuer Homebase-Direct-Sorties noch dieselben Textbausteine wie fuer den alten FOB-Transfer. Die Gameplay-Wahrheit war korrekt, aber die Anzeige vermischte Direct-Sortie, FOB-Transfer und Slotzaehlung inklusive Pilot.

## Umfang
- Homebase-Direct zeigt `Mission payload` statt irrefuehrender `Mission slots`.
- Transfer-Zeile nennt `Direct sortie` und `Start Mission ready`.
- Summary nennt den naechsten Griff `Start Mission -> LZ -> Drop -> Preview -> GO`.
- Der bestehende Normal-Klick-Verifier prueft die sichtbaren Missionstexte.

## Nicht-Ziele
- Kein neuer Singleplayer-Flow.
- Kein Entfernen des echten FOB-Transfer-Workflows.
- Keine Aenderung an Payload-, Boarding-, Dropship- oder Missionsstart-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/BUGFIX_release_singleplayer_normal_click_homebase_guard.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`

## Akzeptanzkriterien
- Der sichtbare Singleplayer-Normalstart zeigt `Operation: Grid Sweep`.
- Die Homebase zeigt `Mission payload` statt ueberlaufender Slotzaehlung.
- Die Transfer-Zeile enthaelt `Direct sortie`.
- Die Summary sagt nicht mehr, dass der Spieler das Team zur FOB schicken soll.
- `Start Mission` bleibt aktiv.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/bugfix_release_singleplayer_normal_click_homebase_guard.gd`
- `docs/tasks/BUGFIX_release_homebase_direct_start_copy_clarity.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_release_singleplayer_normal_click_homebase_guard.gd`
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_388_homebase_fireteam_roster_shipcard_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Fix ist Anzeige- und Snapshot-Polish. Der echte Fensterblick bleibt Pflicht, weil ein alter laufender Prozess weiterhin denselben Screenshot verursachen kann.
