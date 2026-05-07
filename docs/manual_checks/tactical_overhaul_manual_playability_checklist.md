# Tactical Overhaul Manual Playability Checklist

## Mission Full-HD
- [ ] Full-HD Mission HUD: #17 Selected Fireteam and #18 Mission Control remain readable during Take/Secure.
- [ ] Command matrix buttons are reachable with help mode off, compact and expanded.
- [ ] Map markers for plan roles, Breakout and Communication do not overlap critical unit visibility.

## LZ And Air-Asset
- [ ] Secure LZ: Air-Asset warning is understandable and not perceived as unfair damage.
- [ ] Risky LZ: Enemy AT cause, warning and second-hit loss are clear.
- [ ] Air-Asset explosion VFX/SFX plays once and does not spam on clients.

## Breakout And Communication
- [ ] Breakout messages explain whether the FTL adapts, holds, requests orders or aborts.
- [ ] Communication bubbles support the map state without covering key controls.
- [ ] Rule text for tempo, fire rule, contact response, cover and security is understandable.

## Meta
- [ ] Debrief names Air-Asset loss consequences.
- [ ] Homebase recovery state is visible after Air-Asset damage.
- [ ] FOB blocks or explains unavailable transport craft.

## Multiplayer
- [ ] Two local instances: client command is accepted only for assigned team/fireteam.
- [ ] Client sees plan status, BreakoutState and AirAssetStatus as snapshot state.
- [ ] Client cannot mutate SimulationRoot state through tactical payloads.

## Performance
- [ ] Performance profiler shows no critical overlay, bubble or communication spam spikes.
- [ ] Audio polyphony and VFX remain within the TASK_249 budget.
- [ ] Snapshot size and apply behavior remain within TASK_222 budget.

## Balance
- [ ] AT threat frequency feels fair.
- [ ] FTL progression impact is visible but not overpowering.
- [ ] Air-Asset loss is dramatic without softlocking the campaign loop.
