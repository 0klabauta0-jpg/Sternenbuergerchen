# Mission Evacuation Abort Contract

## Scope

TASK_1069 adds a small mission-wide evacuation outcome for the current
singleplayer or host-authoritative Station Route. It reuses the existing
CombatLoopDriver result signal and MetaLayerFlow Debrief handoff.

## Authority

- `MissionCombatLoopDriver` owns the authoritative abort result.
- Only local server authority may accept an evacuation request.
- The Tactical Controller checks player-facing LZ eligibility and asks the
  Combat Driver to resolve; it does not write a MissionResult itself.
- Non-authority calls return a rejected result and do not create local result,
  movement, damage, fire or multiplayer truth.

## Eligibility

Evacuation is available only when all of these are true:

- a mission LZ exists;
- at least one selected Ground-Fireteam is active;
- every selected Ground-Fireteam anchor is within the evacuation LZ radius;
- the mission is active and the caller is local authority.

The button may explain a missing LZ or a Fireteam outside the radius. It never
stores eligibility as a second gameplay state.

## Result

An accepted request resolves the current mission once with:

- `result = aborted`
- `mission_outcome = aborted`
- `win_condition_type = evacuation`
- empty `winning_team_id`

The existing `combat_resolved` signal carries this result to MetaLayerFlow.
MetaLayerFlow continues to enrich it with team state and Mini AAR before
opening Debrief.

## Auftragsstatus in der Kampagne (seit Paket 3a, 15.11.2026)

Gilt nur in der Kampagne; Skirmish und Mehrspieler bleiben unverändert. Einzelheiten und Besitzer stehen in `docs/dev/campaign_casualty_retreat_contract.md`.

- Eine Evakuierung (`win_condition_type = evacuation`) ist in der Kampagne ein Rückzug und kein gescheiterter Auftrag. `SingleplayerCampaignState` setzt den Auftrag auf `failed`, zählt `retreat_count` hoch, setzt `reopen_at_home` und behält die Bindung an Ort und Schiff. Bei der Heimkehr wird der Auftrag vor dem Basis-Checkpoint wieder auf `accepted` gesetzt (Operation `reopen_retreated_job`); „Erneut annehmen“ ist dafür nicht nötig. Niederlage, Totalverlust, Zeitablauf und `abandon_job` bleiben Fehlschlag.
- Der Abflug vom Einsatzort bei aktivem Auftrag ist ebenfalls ein Rückzug (`win_condition_type = departure`), aber nur, wenn danach keine einsatzfähige eigene Person mehr am Ort bleibt. Bleiben Einsatzfähige am Ort, wird nichts ausgewertet und der Auftrag bleibt, wie er ist. Der Abflug läuft über das Abflug-Gate (`MetaLayerFlow._campaign_departure_gate`) durch dieselbe Verlustauswertung wie jedes Missionsende.
- Der Driver bleibt Besitzer des Ergebnisses; der Flow ergänzt in der Kampagne `casualties`, `fatality_unit_ids`, `casualty_total_loss` und `total_loss_reason`. Bei einem Rückzug werden Ausgefallene nach den Bergungsregeln verwundet oder als gefallen gemeldet (tot ist nur, wer zurückbleibt).
- Der Debrief zeigt bei einem Rückzug die Überschrift „Rückzug · Auftrag bleibt offen“ statt „Einsatz abgebrochen“; die Auftragstafel zeigt „Offen · N Rückzüge“ bzw. „Rückzug · wird an der Basis wieder geöffnet“.

## Multiplayer Boundary

TASK_1069 is not a unilateral PvP team extraction feature. In a multiplayer
mission, only host authority can end the shared mission through this path.
Client-side request transport and per-team extraction need a separate task.

## Non Goals

- No auto-GO or auto-withdraw.
- No dropship boarding animation.
- No new pathfinding, damage, combat or replication system.
