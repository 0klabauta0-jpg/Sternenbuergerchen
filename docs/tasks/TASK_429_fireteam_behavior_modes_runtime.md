# TASK_429 - Fireteam Behavior Modes Runtime

## Ziel / Problem

Die Fireteam-Basisbefehle `Move`, `Engage`, `Take` und `Defend` brauchen nachvollziehbare C/N/A-Regeln im aktuellen Mission-Tactical-Pfad. Alte Reste wie `OVW`, stille Legacy-Fallbacks und dauerhaft wartende Defend-Waypoints sollen fuer diese Basisrunde nicht mehr verdecken, was wirklich passiert.

## Sinn / Ursache

Der Playtest soll zuerst stabile Grundregeln pruefen: Geschwindigkeit, Sicht, Waffenhaltung, Deckung, Angriffswert und Defense-Sektoren. Erst danach werden Charakterbogenwerte, Skills und komplexere KI-Regeln daraufgelegt.

## Umfang

- Gemeinsame Runtime-Modifikatoren fuer `Move`, `Defend`, `Take` und `Engage`.
- C/N/A kann aktive Mission-Tactical-Ausfuehrung aktualisieren.
- Abgeschlossene Waypoints werden entfernt; ohne Folgeauftrag startet automatisch `Defend`.
- Sichtbare Security wird als `DEF 360` oder `DEF <Richtung>` gefuehrt.
- Neue Befehle fallen nicht still in alte Legacy-Ausfuehrung zurueck.
- Drillmap-Buesche liegen als Ground-Tiles, nicht als falsch gedrehte Props mit Bodengaps.

## Nicht-Ziele

- Kein neues Flank-Verhalten.
- Kein finaler Charakterbogen-/Skill-Balance-Pass.
- Kein kompletter Combat-AI-Umbau.
- Kein Entfernen aller Legacy-Dateien ausserhalb der aktuell betroffenen Befehle.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/fireteam_behavior_control_checklist.html`

## Akzeptanzkriterien

- [x] `FireteamMovementController.get_behavior_stance_modifiers()` liefert die dokumentierten C/N/A-Werte fuer `Move`, `Defend`, `Take` und `Engage`.
- [x] Runtime-Commands tragen `behavior_*`-Diagnosefelder fuer Speed, Sicht, Deckung, Angriff, Bewegung und Waffe.
- [x] `defend` blockiert den Plan nicht dauerhaft als wartender Waypoint.
- [x] Ohne Folgeauftrag geht das Fireteam automatisch in `Defend`.
- [x] `FireteamSecurityController` liefert `DEF 360`/Directional-Sektoren mit verteilten Blickwinkeln und leichter Scan-Bewegung.
- [x] `move`, `defend`, `take` und `engage` melden einen Behavior-Fehler, wenn der neue Runtime-Pfad nicht starten kann.
- [x] Drillmap-Busch-Cover ist als Ground-Tile authoriert und Scenario-/Generator-Ausgaben validieren nach dem Speichern.

## Betroffene Dateien

- `docs/tasks/TASK_429_fireteam_behavior_modes_runtime.md`
- `docs/dev/fireteam_behavior_modes_contract.md`
- `docs/reports/fireteam_behavior_control_checklist.html`
- `docs/reports/fireteam_command_decision_reference.html`
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tactical/fireteam_security_controller.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tactical/visuals/fireteam_order_visualizer.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tools/generate_fireteam_command_drill_24x24.gd`
- `scripts/tests/task_429_fireteam_behavior_modes_runtime.gd`
- `scripts/tests/task_424_fireteam_drill_enemy_visibility_grounding.gd`
- `scripts/tests/task_427_fireteam_decision_feedback_aim_pose.gd`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tools/generate_fireteam_command_drill_24x24.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_429_fireteam_behavior_modes_runtime.gd`
- [x] Relevante TASK_421/TASK_424/TASK_425/TASK_426/TASK_427-Regressionen
- [x] `git diff --check`

## Risiken / offene Punkte

- Die Prozentwerte sind erste Runtime-Konstanten und muessen spaeter bewusst mit Charakterbogenwerten verbunden werden.
- `overwatch_ready` existiert als Kompatibilitaetsfeld weiter, ist fuer dieses neue Basisverhalten aber deaktiviert.
- Legacy-Pfade ausserhalb von `move`, `defend`, `take` und `engage` sind nicht Teil dieser Runde.
