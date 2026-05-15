# TASK_418 - Fireteam Mini Card Suppression Explainer

## Ziel / Problem

Die kompakte Fireteam-Karte oben links soll Suppression direkt zeigen. Der bisherige SUPP-Balken sitzt im unteren Selected-Fireteam-Panel und ist im Playtest zu weit vom schnellen Kartenblick entfernt.

## Sinn / Ursache

Suppression erklaert, warum ein Fireteam einen GO-Ablauf unterbricht, langsamer wird oder pinned bleibt. Diese Information gehoert deshalb in die erste Fireteam-Uebersicht, nicht nur in ein Detailpanel.

## Umfang

- Kompakte Suppression-Anzeige auf der Fireteam-Mini-Karte oben links.
- Fireteam-Status-Snapshot enthaelt Suppression-Wert, Schwelle, Prozent und Status.
- HTML-Erklaerung mit schematischem Abbild der Mini-Karte und kurzer Legende.
- Dokumentierte Einschaetzung: sichtbarer Ablauf laeuft ueber GO; der sichtbare `Plan`-Button wird mit TASK_422 entfernt, die interne Return-/Recovery-Funktion bleibt erhalten.
- Headless-Verifier fuer Mini-Karten-SUPP-Anzeige, Snapshot-Felder und HTML-Marker.

## Nicht-Ziele

- Kein Entfernen der bestehenden Plan-/Waypoint-Datenstruktur.
- Kein Umbau der GO-Ausfuehrungslogik.
- Keine neue Suppression-Simulation.
- Keine Aenderung an `SimulationRoot` oder UnitCommand-Verarbeitung.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/tasks/TASK_416_fireteam_command_drill_map.md`
- `docs/tasks/TASK_417_fireteam_waypoint_completion_cleanup.md`

## Akzeptanzkriterien

- [x] Die Fireteam-Mini-Karte zeigt `SUPP` im kompakten Text und als kleinen Balken.
- [x] Der Balken liest den bestehenden `_suppression_state_by_fireteam`-State und erzeugt keine neue Gameplay-Wahrheit.
- [x] `get_fireteam_status_card_snapshot()` meldet Suppression-Felder fuer Tests und UI.
- [x] Die HTML erklaert Karte, SUPP, READY/RDY, GO und dass der alte `Plan`-Button nicht mehr dauerhaft sichtbar ist.
- [x] Ein Verifier prueft UI-Knoten, Snapshot-Felder, HTML und Doku-Status.

## Betroffene Dateien

- `docs/tasks/TASK_418_fireteam_mini_card_suppression_explainer.md`
- `docs/reports/fireteam_mini_card_explainer.html`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_418_fireteam_mini_card_suppression_explainer.gd`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_418_fireteam_mini_card_suppression_explainer.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_369_fireteam_status_card_enhancement.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_417_fireteam_waypoint_completion_cleanup.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- Die Mini-Karte bleibt bewusst kompakt. Ein manueller Fenster-Sichtcheck ist sinnvoll, falls mehrere Fireteams gleichzeitig im linken Panel gescrollt werden.
- Das Entfernen des sichtbaren `Plan`-Buttons erfolgt in TASK_422. Die Return-to-Plan-Funktion bleibt intern erhalten und wird sichtbar ueber `GO` bedient.
