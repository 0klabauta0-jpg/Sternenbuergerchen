# Pure host visible projection — frozen, unwired

Product only NEW scripts/multiplayer/multiplayer_visible_snapshot_projection.gd.
Own verifier scripts/tests/multiplayer_visible_snapshot_projection_verifier.gd,
Task MULTIPLAYER_VISIBLE_PROJECTION_2026_11_12.md and this QA. No existing
Root/Driver/FoW/contract/shared runner/receiver edits, no stage/commit or flags.

API: project_state(dto,recipient_team,context), project_reliable_vitals(vitals,
dto,recipient_team,context). Context requires canonical actual team and explicit
own_unit_ids,visible_unit_ids,fireteam_team_ids plus reference_provenance=host_raw.
Optional craft_team_ids/asset_team_ids are future authoritative callerprovenance;
no new registry/truth here. Unknown context/version rejects. Own IDs must exactly
match all DTO units of the recipient team. No inferred spectator/alias team.

Only original V1-shaped HOSTDTO before lossy normalization is usable. Source must
preserve unit/target/attacker/pilot/lock references with related coordinates until
this projection. Existing normalized target_position without its discarded
target_unit_id cannot be classified honestly; no coordinate matching, synthetic
association context or wholesale deletion of own intended free areas occurs.
Caller declaration does not itself prove visibility; Root/Driver must supply it.

Output is explicit full-recipient envelope schema_version2 + projection_schema
multiplayer.visible_state.v1. Existing V1 receiver rejects the wrapper in the real
contract test. This does NOT bump or edit the existing global V1 contract. Future
receiver must explicitly apply full scope and hide omitted prior enemy actors.
Reliable wrapper uses recipient_vital_delta and the identical ID/vital filter.

Policy for existing V1 lists:
- Own units retain all V1 fields; visible enemies get explicit displayallowlist,
  without target, command, fireteam plan, tactics profile or skill internals.
  Actual TestUnit._build_remote_runtime_dict/apply_remote_snapshot reader fields
  runtime_state,fire_mode,tactical_stance(+revision) remain observable scalar data;
  they do not authorize publication of active/source command or target fields.
- Contacts require own OBSERVING fireteam plus allowed target. contact.team_id
  denotes target, not observer. Hidden targets and historical hidden coordinates
  do not survive just because the observer owns the contact.
- Character/FT/commander/plan/rules/breakout/communication/thought readouts require
  proven own unit/team/FT. Own rows/free own target areas remain. Enemy rows omitted;
  mixed internal unitmaps/assignments use own IDs only. Watched visible target IDs
  remain, hidden focus is removed. Empty optional unit reference does not erase FT.
- Fireevents keep allowed participants only, removing hidden endpoint, paired
  coordinates and hidden attacker weapon data. Opaque event/bubble IDs use stable
  hashes, never raw embedded private unit IDs. No perception/audio fact is invented.
- Dropship/card/airasset records require explicit team/owner map or (cards only)
  unambiguous all-own crew proof. Own uncrewed cards can use explicit owner map.
  Conflicting ownership never falls back to crew inference. Top dropship geometry
  cannot inherit team from any contained card. Unknown records alone fail closed.
- Hidden locks/pilot names and nested identity maps are scrubbed. Missioninteraction
  states retain proven own progress; normalizer recomputes counts. Objective and
  public missionresult summary remain. Actual Driver team_states are unit-shaped
  debrief rows without team_id; own unit rows preserved via explicit allowlist.
  Asset VFX/SFX status events have generic V1 position: any hidden unit/target/
  attacker endpoint drops the entire coupled event before normalization. Own
  unlinked asset effects keep their position and remain in both event lists.

20/0 and both helper/verifier standalone compile Exit0, Godot4.6.2, clean logs,
source_unchanged=true, real_profile_unchanged=true, private_canary=true in report.json.
Dependency closure exactly5 scripts: newhelper, newverifier, existing V1normalizer,
rostercontract and Isolationguard. No Root/Ground/Movement closure or parallel WIP.

RED: original missing helper0/1 in red.log. Additional actual failures preserved:
references_red.log13/2 (Driver debrief/provenance), groups_red.log15/2 (mixed internal
membership/conflicting card proof), ft_red.log17/1 (optional empty unit reference),
packed_members_red.log17/1 (actual PackedStringArray shape). Each final path is green.
Parent review REDs: status_event_red.log18/1 uses actual V1 status position and
hidden target/attacker plus retained unlinked effects; enemy_display_red.log19/1
uses actual TestUnit scalar display fields. Both closed by current20/0.
Small input-setup/type diagnostics were not used as product success evidence.

Run this one pure probe:

```powershell
python output/native_glut_maps/multiplayer_visible_projection_20261112/run.py
```

No Root sightgetter/host publish/reliable dispatch/receiver integration, live peers,
native game or full AP7 claim. The helper never updates Detection/FoW or owns state.
