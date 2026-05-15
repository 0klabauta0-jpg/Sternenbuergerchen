# TASK_419 - GO Recovery Action And NPC Speed

## Ziel / Problem

Der sichtbare Playtest-Ablauf soll weniger zwischen `GO` und `Plan` unterscheiden muessen. Wenn ein Fireteam durch Ad-hoc-Order oder Suppression aus dem Plan gefallen ist, soll `GO` die naechste sinnvolle Recovery-Aktion ausloesen koennen. Zusaetzlich sollen NPCs fuer den Drill spuerbar langsamer laufen.

## Sinn / Ursache

`Plan` ist aktuell eher eine Return-to-Plan-Funktion als ein echter Planungsstart. Fuer den Playtest ist es klarer, wenn `GO` aktive Fortsetzung, Recovery und neue Waypoints priorisiert. Die langsamere Bewegung macht Fireteam-Entscheidungen, Suppression und Folge-Waypoints besser beobachtbar.

## Umfang

- `GO` erkennt Recovery-Kontexte aus Ad-hoc-Orders, Suppression-Interrupts und unterbrochenen Plaenen.
- `GO` fuehrt Return-to-Plan aus, wenn das Fireteam nicht gepinnt ist.
- Gepinnte Fireteams werden von `GO` nicht zwangsweise in den Plan zurueckgeschoben, sondern als blockiert gemeldet.
- Die bestehende interne Plan-/Waypoint-Struktur bleibt erhalten.
- Die autoritative Move-Basisgeschwindigkeit in `SimulationRoot` wird von `120.0` auf `80.0` gesenkt.
- Headless-Verifier fuer GO-Recovery-Entscheidung, Suppression-Block, Speed-Konstante und Doku-Marker.

## Nicht-Ziele

- Kein Entfernen der Plan-Datenstruktur.
- Kein vollstaendiges Ausblenden oder Loeschen des sichtbaren `Plan`-Buttons.
- Keine neue Movement-Physik und keine Aenderung der Fireteam-Bewegungsstile.
- Keine neue Gegner-KI.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_417_fireteam_waypoint_completion_cleanup.md`
- `docs/tasks/TASK_418_fireteam_mini_card_suppression_explainer.md`

## Akzeptanzkriterien

- [x] `GO` kann einen Recovery-Kontext als Return-to-Plan ausfuehren.
- [x] `GO` blockiert Recovery, wenn das Fireteam aktuell suppressed/gepinnt ist.
- [x] Normale pending Waypoints, AreaOrders und laufende Phasen bleiben ueber `GO` erreichbar.
- [x] Die interne Plan-Struktur bleibt erhalten und wird nicht als zweite UI-Wahrheit ersetzt.
- [x] NPC-Move-Commands verwenden `80.0` als autoritative Basistempo-Konstante.
- [x] Ein Verifier prueft Verhalten, Speed-Wert und Doku-Status.

## Betroffene Dateien

- `docs/tasks/TASK_419_go_next_action_and_npc_speed.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/reports/fireteam_mini_card_explainer.html`
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_419_go_next_action_and_npc_speed.gd`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_419_go_next_action_and_npc_speed.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_418_fireteam_mini_card_suppression_explainer.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_417_fireteam_waypoint_completion_cleanup.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- `Plan` bleibt vorerst sichtbar, damit die Recovery-Funktion nicht in einem UI-Schritt verloren geht.
- Die langsamere Basistempo-Konstante wirkt global auf normale Move-Commands. Spezialmultiplikatoren fuer Rush/Bounding/Caterpillar bleiben unveraendert.
