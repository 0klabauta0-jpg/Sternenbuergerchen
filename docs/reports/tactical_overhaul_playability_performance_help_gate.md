# Tactical Overhaul Playability Performance Help Gate

## Automated
- TASK_282 aggregates the tactical-overhaul contracts from TASK_269 through TASK_281 plus the post-help playability smoke from TASK_268.
- The gate builds a compact two-Fireteam tactical payload with Commander intents, Fireteam plan status, tactical rules, communication events, breakout state and Air-Asset status.
- The generated multiplayer snapshot is checked for deterministic ordering, ID-only payloads, public FTL skill effects and `SimulationRoot` authority.

## Playability
- Existing TASK_279 coverage remains the tactical End-to-End Mission smoke: secure LZ success, Enemy AT threat warning, Air-Asset loss, communication, breakout feedback and MetaLayerFlow recovery.
- Existing TASK_268 coverage remains the UI/Help/Playability smoke across main menu, lobby, editor, Homebase, FOB, Mission and Debrief.
- TASK_282 verifies that mission command, rule, plan, Air/LZ, Breakout and tactical-profile help entries remain present.

## Multiplayer
- TASK_281 is the authority smoke for CommanderIntent, Breakout response, Air-Asset commands, Host-only role override and client-side state-mutation rejects.
- TASK_282 checks that the Tactical snapshot carries `commander_intents`, `fireteam_plan_status`, `communication_events`, `tactical_rules`, `breakout_states` and `air_asset_status` as read-only display state.

## Performance
- TASK_282 reads the existing TASK_222 snapshot budget and checks the Tactical gate payload against `max_large_json_p99_bytes`.
- TASK_249 remains the audio/visual spam budget reference for Audio polyphony, dedupe and VFX.
- Communication and VFX/SFX event IDs are deduplicated before client apply.

## Manual
- Full-HD Mission readability, help popup timing, Bubble noise, Air-Asset loss fairness and Meta follow-up should still be played manually.
- The gate does not replace a real two-instance LAN test or a final balance pass.

## Balance
- Air-Asset risk values, AT frequency, Breakout thresholds and FTL progression weights remain balancing open items.
- Current automated checks protect integration, authority and readability contracts, not final campaign tuning.
