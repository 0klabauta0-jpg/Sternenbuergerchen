# Simulation Tick Signal Fanout Audit

**Goal:** Attribute the expensive `SimulationRoot.tick_processed` fanout to a named listener and its internal scope before changing simulation behavior.

**Result:** The only direct listener is `MissionCombatLoopDriver`. In real start frames its Combat total consumed about 400-422 ms, almost entirely in `enemy_team_tactics_usec` (about 405-420 ms). The next task targets that internal tactics calculation, not the signal itself.
