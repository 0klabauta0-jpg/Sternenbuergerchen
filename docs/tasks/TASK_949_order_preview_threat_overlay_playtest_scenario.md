# TASK_949 - Order Preview Threat Overlay Playtest Scenario

## Ziel / Problem
Nach TASK_948 soll die Decision-Clarity-Arbeit wieder in eine konkrete kleine Spielentscheidung gehen. Der Spieler soll vor `GO` drei Bewegungsideen vergleichen koennen: sicherer Push, riskanter Uebergang und suizidaler Kill-Zone-Dash.

## Sinnhaftigkeit / Ursache
TASK_506 bis TASK_510 beweisen Ghost, Pfad, Threat-Level, Line-of-Fire und Contact-Awareness technisch. Was noch fehlt, ist ein kompakter Szenario-Payload, der diese Bausteine als kleine Spielerentscheidung zusammenbringt und fuer die F6-/HUD-Verdrahtung bereitstellt.

## Umfang
- `OrderPreviewThreatOverlayPlaytestScenario` als read-only Mission-Service.
- Reuse von `WaypointIntentPreviewResolver` und `TacticalDecisionThreatAnalyzer`.
- Drei Move-Choices mit Ghost, Pfad, ETA, Risiko, Risk-Farbe und Threat-Line-Zaehlern.
- Overlay-Summary fuer spaetere F6-/HUD-Anzeige.
- Naechsten Slice `TASK_950 - Wire Decision Scenario Into F6 Mission HUD` festlegen.

## Nicht-Ziele
- Kein neuer Command-Pfad.
- Kein echtes `GO`, Movement, FireEvent, Damage oder Multiplayer-State.
- Kein neues Pathfinding- oder Combat-System.
- Keine neue HUD-Wahrheit; der Service liefert nur Preview-Daten.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_948_tactical_decision_clarity_scenario_return.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_506_tactical_decision_clarity_contract.md`
- `docs/tasks/TASK_507_order_preview_ghosts_mvp.md`
- `docs/tasks/TASK_508_line_of_fire_threat_analyzer_mvp.md`
- `docs/tasks/TASK_509_combined_preview_overlay.md`
- `docs/tasks/TASK_568_frontier_probe_risky_contact_preview_fixture.md`

## Akzeptanzkriterien
- Fehlende oder falsche TASK_948-Quelle blockt den Snapshot.
- Gueltige TASK_948-Quelle erzeugt drei Move-Choices: `covered_push`, `exposed_crossing`, `kill_zone_dash`.
- Die Choices liefern `safe`, `risky` und `suicidal` mit Ghost/Pfad/ETA und Line-of-Fire-Daten.
- Overlay-Summary zaehlt Ghosts, Pfadlinien, Threat-Lines und Risk-Farben.
- Snapshot bleibt read-only und erzeugt keine Commands, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_949_order_preview_threat_overlay_playtest_scenario.md`
- `scripts/mission/order_preview_threat_overlay_playtest_scenario.gd`
- `scripts/tests/task_949_order_preview_threat_overlay_playtest_scenario.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_949_order_preview_threat_overlay_playtest_scenario.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_948_tactical_decision_clarity_scenario_return.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_506_tactical_decision_clarity_contract.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_949 erzeugt den spielbaren Entscheidungs-Payload, verdrahtet ihn aber noch nicht sichtbar in F6/HUD. Der naechste Task muss diese Preview-Choices in der Mission so anzeigen, dass man sie im Fenster ohne Task-Wissen lesen kann.

## Naechster Schritt
TASK_950 - Wire Decision Scenario Into F6 Mission HUD.
