# TASK_1086 - Release Mission Ready-Time Performance Pass

## Ziel / Problem
Der readiness-basierte Release-Lauf aus TASK_1085 erreicht `deeplink_final` erst nach rund 50 Sekunden. Der reproduzierbare Testpfad soll schneller bereit sein, ohne GO, SimulationRoot-Autoritaet, Kontaktaufbau oder echte FireEvent-Evidence zu umgehen.

## Ursache / Sinnhaftigkeit
Der Trace zeigt mehrere feste Frame-Wartefenster. Besonders die 45 Frames nach GO und die 10 Frames vor dem finalen Snapshot kosten auf der schweren Missionsszene zusammen rund 20 Sekunden, obwohl der benoetigte Runtime-Zustand frueher beobachtbar sein kann. Feste Framezahlen skalieren zudem mit der UI-/Framekostenlast und sind deshalb kein stabiler Readiness-Vertrag.

## Umfang
- Release-Trace exportiert pro Stufe Delta- und Gesamtdauer.
- Starre Wartefenster im First-GO-/First-Exchange-Direkteinstieg werden durch begrenzte, zustandsbasierte Polls ersetzt.
- GO bleibt ueber `execute_selected_fireteam_orders()` und `SimulationRoot` autoritativ.
- Der finale Zustand verlangt weiterhin sichtbaren Kontakt, echte FireEvent-Evidence und konsistente HUD-Quellen.
- Der echte Release-Capture misst die neue End-to-End-Zeit.

## Nicht-Ziele
- Kein normaler Spielerbefehl wird beschleunigt oder uebersprungen.
- Kein Combat-, Pathfinding- oder Multiplayer-Rewrite.
- Keine Gameplay-Wahrheit im Meta-Layer oder HUD.
- Keine Optimierung auf einen Headless-Testwert ohne echten Release-Nachweis.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1085_stable_first_exchange_visible_state.md`
- `docs/tasks/TASK_1084_release_deeplink_runtime_authority_repair.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Ein Verifier belegt die neuen Readiness-Bedingungen und scheitert vor der Implementierung.
- Der finale Trace enthaelt pro Stufe `elapsed_msec` und `delta_msec`.
- Keine feste 45-Frame- oder finale 10-Frame-Pause bleibt im First-GO-/First-Exchange-Pfad.
- TASK_1085 bleibt gruen: `CONTACT FIRE` steht in #17/#18, #19 behaelt echte Event-Evidence.
- TASK_1084 bleibt gruen: keine direkte Runtime-State-Mutation im Meta-Layer.
- TASK_1082/TASK_1083 bleiben fuer Multiplayer-ROE und Zwei-Instanz-Replikation gruen.
- Ein frischer Godot-4.6.2-Release erreicht denselben sichtbaren Endzustand deutlich vor der bisherigen Referenz von 50.046 ms; der Headless-Verifier nutzt wegen Lastschwankungen ein konservatives 45-Sekunden-Regressionsbudget.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_1086_release_mission_ready_time_performance_pass.gd`
- `scripts/tools/capture_release_first_go_firefight_real_window.ps1`
- Status-, Roadmap-, Contract- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1086 Red/Green
- TASK_1085, TASK_1084, TASK_832, TASK_868
- TASK_1082, TASK_1083
- echter Release-Export, Provenance-Startcheck und readiness-basierter Window-Capture
- HTML-Inline-JavaScript und `git diff --check`

## Risiken / offene Punkte
Zustands-Polls brauchen harte Obergrenzen und aussagekraeftige Blocker. Falls die eigentliche Missionsinstanziierung oder ein einzelner UI-Refresh danach dominiert, wird dieser Befund als naechster enger Task behandelt statt durch weitere Testabkuerzungen verdeckt.
