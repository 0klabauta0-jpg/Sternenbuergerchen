# TASK_1100 - Connected Interaction Snapshot Loss/Jitter Resilience

## Ziel / Problem
Der Interaction-State wird als Teil eines `unreliable` State-Snapshots repliziert. Ausgelassene oder verspätete Pakete duerfen sichtbaren Fortschritt und replizierte Scenario-Gates nicht auf einen aelteren Host-Tick zuruecksetzen.

## Sinnhaftigkeit / Ursache
TASK_1099 belegt, dass die Payload klein genug ist. Der naechste reale Multiplayer-Fallstrick ist deshalb Konvergenz bei Paketverlust, Jitter und Out-of-order-Zustellung. Ein Hold darf bei einem neueren autoritativen Tick legitim zurueckgesetzt werden; nur aeltere Ticks muessen wirkungslos bleiben.

## Umfang
- Snapshotfolge mit ausgelassenen Zwischenticks, verspätetem altem Tick und finalem Complete-State pruefen.
- Akzeptierten Snapshot-Tick read-only bis in das Interaction-Feedback tragen.
- Sicherstellen, dass ein alter Tick weder CombatDriver-State noch Gate noch sichtbare Zeile veraendert.
- Identischen neueren Complete-State ohne zusaetzliches Label-Update akzeptieren.

## Nicht-Ziele
- Kein Client-Prediction-/Rollback-System.
- Kein monotones Klemmen neuer autoritativer Hold-Resets.
- Kein neues RPC, kein Reliable-Umbau und keine UI-Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_1099_connected_interaction_snapshot_payload_budget.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Tick 10 mit 20 Prozent und Tick 13 mit 80 Prozent werden angewendet, ausgelassene Ticks sind unschaedlich.
- Ein danach eintreffender Tick 11 wird verworfen und veraendert weder Fortschritt, Gate-State noch Label-Update-Zahl.
- Complete auf Tick 20 bleibt trotz danach eintreffendem Tick 19 erhalten.
- Ein semantisch identischer Tick 21 aktualisiert den Quell-Tick, aber baut die sichtbare Zeile nicht erneut.
- Ein strikt neuerer Host-Tick darf den Hold legitim zuruecksetzen; eine neue gerenderte Dauer darf nicht durch Dedupe verborgen werden.
- Clientpfad erzeugt keine Commands oder Effects.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1100_connected_interaction_snapshot_loss_jitter_resilience.gd`
- `docs/dev/mission_interaction_point_contract.md`
- Status, Roadmap und HTML-Iststandsbericht

## Lokale Pruefung
- `task_1100_connected_interaction_snapshot_loss_jitter_resilience.gd`
- `task_1099_connected_interaction_snapshot_payload_budget.gd`
- `task_1091_connected_station_route_two_player_command_playtest.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Task simuliert Snapshotverlust deterministisch auf der Apply-Grenze. Echte schwankende Netzlatenz und Reconnect bleiben getrennte Folgetasks.
