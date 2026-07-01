# TASK_749 - Station Homebase Follow-up Microcopy Polish

## Ziel / Problem
TASK_748 hat als konkreten sichtbaren Befund festgehalten: Die Station-Homebase-Next-Sortie-Zeile war technisch korrekt, aber zu lang und englisch-lastig. TASK_749 macht diesen Follow-up-Text kompakter und spielnaeher.

## Sinnhaftigkeit / Ursache
Nach Debrief und Rueckkehr zur Homebase soll der Spieler nicht eine Prozessliste lesen, sondern sofort wissen: Was mache ich jetzt, und was kommt danach? Die alte Zeile `Next sortie: Review gains -> Stage fireteam -> ...` war fuer einen Debug-/Contract-Pfad nuetzlich, aber im Spielmoment sperrig.

## Umfang
- Station-spezifische Next-Sortie-Zeile aus denselben Readiness-Steps bauen.
- Sichtbarer Text wird deutsch/kompakt: aktueller Schritt zuerst, danach kurze Folgepunkte.
- Frontier-/Altpfad bleibt auf der bisherigen Contract-Sprache.
- Existing Step-IDs bleiben unveraendert: `review_roster_gains`, `stage_fireteam`, `assign_loadout`, `prepare_transport`, `start_next_sortie`.
- TASK_746/747/748-Verifier an den bewussten Station-Polish anpassen.

## Nicht-Ziele
- Keine neue Homebase-Navigation.
- Kein Startbutton-Commit.
- Keine Staging-, MissionResult-, Progression- oder Loadout-Mutation.
- Kein Host/Client-Fenster-Recapture.
- Kein grosser Layoutumbau.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_748_station_scenario_homebase_readiness_visual_polish_findings.md`
- `docs/tasks/TASK_747_station_scenario_homebase_visible_readiness_review.md`
- `docs/tasks/TASK_746_station_scenario_homebase_next_sortie_readiness.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Station-Homebase-Readiness-Zeile beginnt mit `Naechste Sortie:`.
- Der aktuelle Schritt wird als `Fireteam bereitstellen` lesbar.
- Alte englische Debug-Marker wie `Next sortie`, `Review gains`, `Stage fireteam`, `Assign loadout`, `Load dropship`, `Start next sortie` erscheinen nicht in der sichtbaren Station-Zeile.
- Die Zeile bleibt unter 110 Zeichen und einzeilig.
- Snapshot und gerendertes Label stimmen ueberein.
- Readiness-Step-IDs bleiben vollstaendig erhalten.
- `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_navigation = false`, `creates_command = false`.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_746_station_scenario_homebase_next_sortie_readiness.gd`
- `scripts/tests/task_747_station_scenario_homebase_visible_readiness_review.gd`
- `scripts/tests/task_748_station_scenario_homebase_readiness_visual_polish_findings.gd`
- `scripts/tests/task_749_station_homebase_followup_microcopy_polish.gd`
- `docs/tasks/TASK_749_station_homebase_followup_microcopy_polish.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_746_station_scenario_homebase_next_sortie_readiness.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_747_station_scenario_homebase_visible_readiness_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_748_station_scenario_homebase_readiness_visual_polish_findings.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_749_station_homebase_followup_microcopy_polish.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
Der Text ist jetzt spielnaeher, aber noch kein echter Mensch/Fenster-Review. Der naechste sinnvolle Schritt ist ein Host/Client-Recapture des Station-Abschlusses oder ein kleiner visueller Panel-Polish, falls der echte Blick noch zu technisch wirkt.
