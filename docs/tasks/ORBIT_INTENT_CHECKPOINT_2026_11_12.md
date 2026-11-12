# Prepared orbit intent/automatic preference checkpoint

Goal/cause: retain adapter-owned per-craft route intent and explicit automatic
disable preference alongside independently restored Fleet/Flight/navigation.
Source behavior inspected at2f37621a6 on task/two-moon-native-20261112:
scripts/meta/singleplayer_runtime_adapter.gd, SimulationRoot orbit-transit methods,
orbit_surface_locations, AIR_LEGACY_RADAR_ORBIT_2026_11_12 and
orbit_quantum_travel_contract; global task CAMPAIGN_ACTIVE_MISSION_SAVE_2026_11_12.

Scope: new helper and focused owner verifier only. No existing Root, Adapter,
Flow, Combat, Capture or Preflight modifications. No capability rollout, owner
commands, navigation reconstruction, new flight truth, imports or commits.

API: static capture(adapter,bindings), prepare(adapter,state,bindings),
validate(adapter,candidate,bindings), publish(adapter,candidate). Bindings have
simulation_root,fleet,combat,campaign; pending-free states retain exactly these
four bindings. Stable flying pending requests additionally require the canonical
future space_operation_requests Dictionary from the complete Adapter checkpoint. Fleet supplies real restored
Flight objects; Combat must already reference those same objects for local
transit. The canonical surface-location helper from the source integration is
required for nonempty route intents. No UI-selected destination is consulted.

Prepare and final validate leave the target adapter's existing Root/Fleet/
Campaign pointers unchanged; their identity, two maps and capability are stamped.
All new candidate owner/flight/navigation snapshots must stay unchanged. Caller
validates all parts before the global signal-/await-free owner assignment tail,
then publishes this helper after owner assignment by assigning only its two maps.
The capability _surface_orbit_path_enabled is absent from wire and never written;
an explicitly opted-in capture can restore into a default-false target adapter.

Accepted statuses: warp confirmed by actual quantum target; local flying by
actual actor/Flight/control/status; manual by actual local Flight and absence of
automatic or braking control; arrived only by the actual local Combat arrived
status and no active automatic control. Never infer arrival from UI intent alone.
Starting, completing, malformed or non-flying pending requests, auto braking, queued Root
warp search/completion and unknown intent fields reject. Auto-disabled values
must be true and craft IDs must exist. Typed bounded wire preserves exact types;
runtime object refs are rebuilt only through explicit owner bindings.

Acceptance/verifier: fresh real owners, JSON roundtrip and no-mutation preflight;
foreign/stale owner or route/control state, unsafe windows, malformed fields,
fake capability payload and unsupported states reject. Existing target capability
stays false after publish. Actual automatic/manual flight continuation and full
Continue remain global integration gates.

Files: scripts/mission/orbit_intent_checkpoint.gd and
scripts/tests/orbit_intent_checkpoint_verifier.gd. Godot execution is explicitly
deferred while the exclusive real1x Space trip owns the runner; no passing
runtime claim until a coordinated focused check is authorized.

Implementation handoff: code and runnable verifier template are provided, but
NO Godot process has been started and no compile/runtime pass is claimed.
At the initial handoff the checkout did not yet contain the pinned surface
catalog or orbit fields. Root subsequently merged Source2f as55461323c; the
standalone helper has still not been run.
The existing Navigation validator also rejects orbit_auto_* control keys until
Companion's separately owned navigation join lands. This helper adds no such
serialization support. Verifier local setup uses real Fleet/Flight/Combat/
Equipment/Root owners and actual automatic-enable/disable commands, but starts
from an explicitly identified manual local fixture projection. It is not a
native route or whole-world restoration proof. Arrived-after-surface/approach
and any other unconfirmed arrival state remain failclosed in this narrow helper.

Source review correction after Merge55461323c: Root writes ok=true/reason=""
after an accepted movement batch, while the adapter keeps flying. The helper
therefore requires a strict boolean true status and accepts exactly reason
"transit" (initial command) or "" (accepted continuing batch). All same-Flight,
actor, area, route and automatic-control checks remain required. The verifier
now advances both actual Root owners one real movement step before capture and
asserts this producer status and retained flying intent. This change remains
UNRUN under the exclusive Space-run restriction; no runtime success is claimed.

Stable flying pending-request correction from actual84/0 roundtrip producer:
pending_approach and pending_warp are registered user requests, not scheduled
callbacks. Only status=completing queues the callback and remains rejected.
At most one pending request is accepted. Inbound approach has exactly
request_id/signature for space_begin_approach and {craft_id,location_id};
outbound warp has exactly request_id/signature/payload for space_start_quantum,
with matching craft, a canonical different target orbit and optional canonical
marker. Signature must exactly equal the producer's sorted JSON. Unknown fields,
empty IDs, duplicate request IDs across crafts, disabled automatic state and
any existing entry for that request ID in future space_operation_requests reject.
The producer returns pending before _remember_space_operation, so a completed
Replaybinding for the same ID would prevent the queued action from executing.

Capture checks the actual adapter replay map and compares an optionally supplied
map against it. Prepare/validate require the explicit future map for pending
states, stamp its full contents and never publish it. Full Adapter restoration
owns publishing space_requests in the same global tail. Old actual Adapter map
is also stamped to reject intervening changes. Pending-free four-binding calls
remain compatible. No wire schema expansion beyond the two intent/preference
maps; pending data is preserved in its exact known producer slots.

Verifier template now obtains both original pending shapes through real Adapter
_request_space_operation calls: canonical satellite inbound and outbound warp.
It checks an actual accepted Root step with status reason="", JSON preparation,
request/signature/replay-map conflicts and unknown/current target/marker cases.
The local fixture uses real Fleet quantum commands to reach the canonical
satellite orbit before local admission; accelerated fixture setup is explicitly
not a native journey. All modifications remain UNRUN while Companion owns the
exclusive runner; no Godot process was started.

Focused execution on integrated55461323c plus exact Pending producer fix385368575
(locally cherry-picked29845b56a): ORBIT_INTENT_CHECKPOINT passed=39 failed=0,
exit0,1.831s, Godot4.6.2, isolated profile. Logs and command/profile metadata in
docs/qa/orbit_checkpoint_20261112/orbit-intent-first*. No Script/Parse/Compile/
ERROR or leak lines; stderr empty. Both actual normal Pending producers and
successful Root movement tick were exercised. Source/target capability behavior
and manual/off are projection-owner checks, not whole-file Scene-Continue.
Navigation/Fleet local serialization and global activation remain separate gates.
Read-only review found/fixed normal reason-empty status; the Pendingproducer
cross-direction conflict was corrected separately by385368575 with its own
focused proof. No broad runtime, performance, native renderer or EXE acceptance.
