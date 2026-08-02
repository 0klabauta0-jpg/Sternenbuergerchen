# N004B - Public grid_sweep First-Contact Trace

Design status: approved after independent final plan audit on 2026-08-02
Implementation status: approved for task-by-task implementation; runtime
evidence is still open.

## Why this exists

N004A introduced a canonical mission resource, but this is not yet a complete
player-path proof. The actual normal flow still begins at the Main Menu and
then enters test-named Meta/Homebase resources. Historic evidence can therefore
not prove that a real Commander can use the visible route to reach the authored
grid_sweep mission, plan a command, press GO, and receive a real first-contact
decision.

The design has four non-negotiable properties:

1. The proof starts at the visible Main Menu Singleplayer button.
2. Gameplay mutations remain exclusively with SimulationRoot.
3. The first contact and decision are causally tied to the plan just created
   by this run, not merely to whichever contact happens to be visible.
4. Evidence records the immutable code commit that ran, rather than claiming
   that a later documentation commit ran itself.

## Product path after N004B

~~~
project.godot main scene
  -> MainMenu SingleplayerButton
  -> scenes/meta/meta_layer.tscn (MetaLayer)
  -> canonical HomebaseScreen
  -> MetaLayerFlow
  -> scenes/mission/mission_runtime.tscn (MissionRuntime)
  -> LZ and Dropship
  -> natural Deboard
  -> public Take plan
  -> MissionCommandEntryAdapter
  -> FireteamCommandGateway
  -> GO
  -> SimulationRoot
  -> tactical runtime and combat
  -> read-only snapshots and JSON trace
~~~

The former meta_layer_test, homebase_test_screen, fob_test_screen, debrief_test
screen, and mission_reactivity_test resources remain compatibility wrappers
for historical verifiers. They receive no incoming edge from the normal
product route.

The route graph follows dynamic transitions too: MainMenu passes the
SINGLEPLAYER_SCENE_PATH constant to its scene-change call, so that resolved
constant is a first-class graph edge to canonical MetaLayer rather than an
uninspected string.

The active mission also stops directly loading the runtime implementations
named mission_test_setup and test_unit. Their productive equivalents become
mission_runtime_setup and unit_runtime. The old scripts/classes forward for
compatibility. This is identity cleanup around the active route, not a broad
rename of historic test vocabulary or the large tactical controller filename.

## Authority model

~~~
Visible input / headless player action
  -> public controller delegate
  -> MissionCommandEntryAdapter
  -> FireteamCommandGateway
  -> SimulationRoot (only command/status authority)
  -> tick
  -> runtime state and combat
  -> public read-only snapshots
  -> trace artefact
~~~

The public controller delegates only request existing visible behavior:

~~~
get_mission_identity_snapshot()
begin_dropship_lz_placement(craft_id)
place_dropship_lz_from_world_position(world_position)
request_mission_dropship_drop(craft_id)
plan_selected_fireteam_waypoint_from_world_position(
    world_position, command_type = take, append_mode = false
)
execute_selected_fireteam_orders()
~~~

The world-position LZ delegate and the mouse-path LZ handler share one internal
world-position validation/acceptance operation. That avoids an unreliable
world-to-screen-to-world conversion in headless tests. Public receipts contain
only acceptance, stable rejection reason, selected craft/fireteam, planned
target, plan ID, and command tokens. They never set a unit command or runtime
state directly.

All accepted release-singleplayer command-line deeplinks are deprecated in
productive code at MainMenuScreen. Its existing read-only deeplink snapshot
reports deprecated=true, status=blocked, and
reason=legacy_deeplink_no_public_path while leaving the menu usable. It must
not hand off to MetaLayerFlow, start a mission, or reach private controller,
forced setup, contact/fire, or test-helper behavior. Historical forced
automation may exist only in an isolated test harness with no productive
caller. This removes an accidental second launch path instead of pretending
that an artificial setup is ordinary play.

## Identity and provenance snapshot

The public mission identity snapshot is a small read-only contract. Its static
identity comes from an immutable MissionRuntimeIdentity value that MetaLayerFlow
creates from the selected mission definition and supplies before
`mission_host.add_child(mission_instance)`. The factory reuses
MissionScenarioData plus TerrainMapData to resolve the authored objective from
the selected scenario/map pair before the add and rejects incomplete identity
rather than inventing a default. Dynamic craft/payload/deboard fields are read
from runtime state. This is not inferred from verifier constants, map, or
scenario: grid_sweep and fob_transfer can share the same map/scenario pair.

MissionRuntimeIdentity has private fields and defensive snapshots: normalised
mission ID, map/scenario paths, authored marker ID, capture radius, resolved
world position, source=`meta_layer_selected_mission_definition`, and a
deterministic fingerprint. MissionSetup accepts that value only before it
enters the tree. At `_enter_tree()` it freezes a defensive receipt; later
configuration attempts are rejected and cannot alter it. The receipt is
exposed read-only through the MissionSetup/controller identity snapshot:

~~~
schema
phase = enter_tree
received_before_enter_tree = true
mission_id
scenario_path
map_path
objective_marker_id
capture_radius
objective_world_position
identity_fingerprint
source = meta_layer_selected_mission_definition
~~~

The structural contract launches fresh canonical MetaLayer instances through
the visible Homebase MissionSelector and StartMissionButton: it selects by
selector metadata, emits the public selector signal, and presses the visible
button. Before each selection it waits for the public bootstrap snapshot to
report `visible_homebase_post_show_guard_pending=false` and
`visible_homebase_post_show_guard_ran=true`; that prevents a deferred bootstrap
repair from silently overwriting the test's mission choice. It runs grid_sweep
and fob_transfer in fresh Meta instances, asserts complete pre-tree receipts,
distinct mission IDs/fingerprints, and the expected shared
map/scenario/objective tuple. A controlled post-tree configuration attempt is
rejected and leaves the frozen receipt unchanged. That is a timing proof from
`MissionSetup._enter_tree()`, not an observation that an ID was patched in
after the mission was already active.

The existing MetaLayerFlow configuration helper currently also refreshes an
already active mission. N004B splits the new-instance/preview configuration
(which supplies identity before `add_child`) from the entered-mission refresh
(which may update planning selections but never identity). A rejected post-tree
identity call leaves the frozen receipt exactly unchanged.

The canonical MissionSetup rejects `--scenario-file` and `--mission-scenario`
after its identity is bound. Its read-only rejection says
`runtime_identity_locked` and leaves active map/scenario fields, identity
snapshot, and receipt unchanged. The legacy compatibility wrapper can retain
the old test override only when it is unbound; it cannot replace product
identity after entry.

~~~
mission_id
scenario_path
map_path
objective_position
selected_craft_id
payload_unit_ids
deboarded_unit_ids
selected_fireteam_ids
read_only = true
ui_sets_gameplay_truth = false
snapshots_are_truth = false
~~~

For N004B, the verifier asserts mission_id grid_sweep and uses that snapshot's
authored objective position as well as a valid pre-tree receipt. It never
injects an enemy, moves a target, or asserts a hit/success outcome.

## Causal trace contract

The trace reader is a state-light RefCounted. It calls only public snapshots
and SimulationRoot.get_tick. It has no mutation API.

Before GO, the verifier captures a baseline:

- active scenario/map and selected/deboarded units;
- immutable pre-tree MissionRuntimeIdentity receipt and fingerprint;
- selected fireteam;
- tick;
- contact IDs/count;
- fire-event IDs;
- current decision status/reason.

It connects commander_intent_committed before GO and accepts only a signal
whose source context, plan ID, command token, and fireteam match the new
planning receipt. That creates a commit tick.

After GO, a successful contact must be newly observed at or after that tick,
belong to the planned/deboarded fireteam, and not appear in the baseline. The
decision contract is strict:

- fired requires a new stable fire-event ID correlated to the same fireteam
  and observed after the commit tick;
- waiting or blocked requires a new concrete reason plus the correlated
  contact;
- a count-only signal, a pre-existing selected contact, or a generic fallback
  text is not evidence.

If a producer lacks stable IDs, tick, or fireteam provenance, the smallest
read-only field is added to the relevant snapshot producer first. The verifier
does not weaken its causality checks.

Every capture contains:

~~~
schema: sternenbuergerchen.n004b.public_grid_sweep_trace.v2
read_only: true
ui_sets_gameplay_truth: false
snapshots_are_truth: false
correlation:
  plan_id
  command_token
  fireteam_id
  commit_tick
~~~

The bounded stages are menu_ready, meta_runtime, homebase_ready, mission_ready,
identity_ready, lz_armed, lz_placed, drop_requested, deboarded, plan_created,
go_committed, contact, and decision. A timeout only captures the final
read-only state and explains its stage; it never changes gameplay to get past
that stage.

## Evidence chain

The evidence chain intentionally separates code from observations:

~~~
Commit A: canonical visible start route
Commit B: public action/identity boundary
Commit C: trace + verifier + evidence runner
Run 01: fresh process, Commit C, JSON trace
Run 02: fresh process, same Commit C, JSON trace
Commit D: JSON traces plus current-truth/evidence record
~~~

The runner obtains the current Git SHA, passes it to the verifier, and checks
it in each JSON artefact. Run 02 permits only Run 01 as a previously generated
repository artefact; it rejects unrelated untracked files. The final evidence
record points to the two versioned JSON files and names Commit C as the
executed code. It contains date/time, test type, result, scope, maturity,
ownership, and the independent N002A caveat.

Diagnostic traces use user:// and never pollute versioned evidence. Final
artefacts live under docs/qa/artifacts/n004b with the Commit-C SHA in their
names.

Godot import can generate broad untracked UID sidecars in a fresh worktree.
Before each functional evidence process, the runner prints an exact UID-only
dry-run count and removes only that verified untracked UID set. It preserves
tracked UID sidecars, all non-UID files, and the already validated Run-01 JSON
needed by Run 02.

## Product-route structural checks

The first contract uses both runtime and static evidence:

1. It activates the actual visible Singleplayer button and asserts the active
   scene path/root is the canonical MetaLayer path/root.
2. It checks canonical Homebase and MissionRuntime identities on the real
   path.
3. It recursively walks packed-scene external-resource edges, active
   preload/load resource edges, and resolved static scene-change targets from
   the main scene. Any reachable scripts/tests or scenes/tests edge is printed
   with its parent path and blocks the task.
4. It confirms old test resources are reverse-only compatibility wrappers.
5. The action contract scans the reachable call graph from every accepted
   release-singleplayer argument handler and helper for private/test-helper or
   forced-setup bypasses, and asserts the stable deprecation status.

The static graph does not scan test verifiers or dead historical wrappers as
product code. Nor does this task rename every historical identifier; it only
prevents such identities from serving as the active Main Menu route.

## Explicit non-goals

- No terrain/landscape work from N005.
- No combat cadence refactor from N006.
- No Godot upgrade; that needs a separate compatibility gate.
- No new multiplayer authority or transport contract.
- No campaign, blueprint, mining, base-building, or progression logic.
- No Big Bang rewrite of MetaLayerFlow or the tactical controller.
- No forced contact, fire, drop, objective, result, teleport, or test-only
  helper to make a trace green.

## Independent N002A boundary

TASK-1179's known post-result freed-instance lifecycle finding is a release
blocker but not a reason to fake or delay the N004B public-route evidence.
N004B always re-runs and records it. It may complete only if the N004B route,
action, trace, and non-N002A regressions are valid; it must label N002A as
open and must never claim release readiness.
