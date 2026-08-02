# N004B Public `grid_sweep` First-Contact Trace Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> `superpowers:subagent-driven-development` (recommended) or
> `superpowers:executing-plans` to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce two fresh, exact-commit, evidence-backed
`Main Menu -> Singleplayer -> Homebase -> grid_sweep -> First Contact`
traces without creating a second gameplay authority.

**Architecture:** N004B first makes the actual visible singleplayer route a
canonical runtime route. It then exposes a narrow public action boundary on the
existing tactical controller and adds a read-only, causally correlated trace.
The verifier uses the visible menu and player actions only. `SimulationRoot`
remains the sole authority for command and runtime-state commits. Runtime code,
the two run artefacts, and the evidence record are committed in three distinct
phases, so every claim names the code that actually ran.

**Tech Stack:** Godot 4.6.2, GDScript, existing
`MissionCommandEntryAdapter`, `FireteamCommandGateway`,
`SimulationRoot`, JSON evidence manifest, and PowerShell on Windows.

## Audit revision

This revision incorporates the independent plan audit on 2026-08-02:

- The real menu route currently loads `meta_layer_test.tscn`; a verifier that
  starts below it is not a public-path proof.
- Runtime code and evidence cannot truthfully be committed together before the
  two executions. The runtime/test code must be committed first.
- stdout is not a durable evidence artefact. Each fresh process must write one
  versioned JSON trace whose embedded code commit is checked.
- Contact and decision must be newer than, and correlated to, the exact
  `plan_id`, command token, selected fireteam, and authoritative commit tick
  created by this run.
- Mission identity is launch provenance, not a map/scenario inference:
  `grid_sweep` and `fob_transfer` may share both files. The launch contract
  must capture an immutable receipt in `MissionSetup._enter_tree()` and prove
  that a validated identity including the authored objective was supplied
  before `mission_host.add_child(mission_instance)`.

## Global constraints

- Base this branch only on `task/project-forward-strangler` commit
  `008d00bba589bcd1dc8a771c07ea0e4ba90ac89f`; do not merge or clean the
  user's dirty `main` checkout.
- Before every functional headless Godot stage run execute
  `godot4.cmd --headless --editor --import --path . --quit`. Use
  `godot4.cmd`, not the WinGet GUI shim.
- A productive start graph may not import or preload `scripts/tests` or
  `scenes/tests`. The product route must use canonical resources whose names
  do not describe them as test screens; legacy test scenes remain wrappers.
- The active public route must also stop loading the two direct runtime
  implementations currently named `mission_test_setup.gd` and
  `test_unit.gd`. Their old paths/classes remain compatibility wrappers. This
  slice does not rename the 35k-line tactical controller's historical
  `sandbox` filename; it remains under the productive `scripts/tactical`
  boundary and is addressed by later strangler work.
- UI, renderer, trace, and verifier may request a player action or read a
  snapshot. They may never write UnitCommand, unit runtime status, objective
  state, enemy positions, combat events, or mission results.
- The command assertion path is exactly
  `MissionCommandEntryAdapter -> FireteamCommandGateway -> GO ->
  SimulationRoot -> authoritative tick`.
- The verifier must not call a method whose name begins with `_`, any
  `*_for_test` method, direct `SimulationRoot.enqueue_command`, or a
  teleport/forced-combat/forced-objective helper.
- A decision is valid only if its status is exactly `fired`, `waiting`, or
  `blocked`. A `fired` result needs a new, correlated fire event. A
  `waiting` or `blocked` result needs a new, concrete reason and a
  correlated post-GO contact.
- Do not stage broad import-generated `*.uid` files. Before deleting them,
  require a UID-only `git clean -n -f -- '*.uid'` dry-run and retain every
  tracked UID sidecar.
- `TASK_N002A` remains a separate release gate. N004B must not claim release
  readiness.

## Commit and evidence sequence

```text
Commit A: canonical public menu/meta route
    -> Commit B: public mission actions and identity snapshot
        -> Commit C: read-only trace, verifier, JSON-runner
            -> fresh process run 01 on C -> JSON artefact
            -> fresh process run 02 on C -> JSON artefact
                -> Commit D: artefacts + Current Truth + Evidence Manifest
```

At no point may a run artefact say it executed Commit D. It must name Commit C.

---

### Task 1: Canonical public menu-to-homebase route

**Files:**

- Create canonical runtime scenes:
  - `scenes/meta/meta_layer.tscn`
  - `scenes/meta/homebase_screen.tscn`
  - `scenes/meta/fob_screen.tscn`
  - `scenes/meta/debrief_screen.tscn`
- Create canonical runtime scripts:
  - `scripts/mission/mission_runtime_setup.gd`
  - `scripts/npc/unit_runtime.gd`
- Turn the existing `*_test*.tscn` counterparts into compatibility wrappers.
- Turn `mission_test_setup.gd` and `test_unit.gd` into compatibility
  wrappers/classes around their canonical implementations.
- Modify: `scripts/ui/main_menu_screen.gd`
- Create: `scripts/tests/task_n004b_public_start_path_contract.gd`

**Product route after this task:**

```text
project.godot main scene
  -> scenes/ui/main_menu.tscn
  -> visible SingleplayerButton
  -> scenes/meta/meta_layer.tscn (MetaLayer)
  -> HomebaseScreen
  -> MetaLayerFlow -> scenes/mission/mission_runtime.tscn
```

- [ ] **Step 1: Write the failing public-route contract**

  Create `task_n004b_public_start_path_contract.gd` as an
  `extends SceneTree` verifier. It must instantiate the actual
  `run/main_scene`, locate the visible `SingleplayerButton`, activate its
  public pressed signal, and wait with a bounded readiness predicate until the
  current scene is `res://scenes/meta/meta_layer.tscn`.

  Assert all of the following:

  - the menu route snapshot names `meta_layer.tscn`;
  - the active root is named `MetaLayer`;
  - the instantiated Homebase child has the canonical runtime identity;
  - `MetaLayerFlow` preloads `mission_runtime.tscn`;
  - the canonical mission uses `mission_runtime_setup.gd` and
    `unit_runtime.gd`, not the direct legacy implementation paths;
  - the product dependency walk has no reachable
    `res://scripts/tests/` or `res://scenes/tests/` edge.

  The dependency walker must start at run/main_scene and recursively follow
  packed-scene external resources plus active literal preload/load resource
  edges reached by those scenes. It must also resolve every static scene target
  passed to change_scene_to_file or change_scene_to_packed, including
  MainMenuScreen.SINGLEPLAYER_SCENE_PATH. A dynamic transition is an explicit
  parent-to-child graph edge, not a reason to stop the traversal. The verifier
  prints the complete edge chain for a violation. It deliberately does **not**
  scan verifier source files or inactive legacy wrappers.

- [ ] **Step 2: Run the contract red**

  ```powershell
  godot4.cmd --headless --editor --import --path . --quit
  godot4.cmd --headless --path . --script res://scripts/tests/task_n004b_public_start_path_contract.gd
  ```

  Expected: failure because `SINGLEPLAYER_SCENE_PATH`, the active meta
  root, and direct MissionSetup/unit implementation paths still carry the old
  test identities.

- [ ] **Step 3: Extract the smallest canonical route**

  Move the existing productive scene contents to the four canonical scene
  files, rename their canonical root identities, and make
  the former `*_test*.tscn` files small instance wrappers that preserve their
  historical root names and paths for old verifiers.

  Update the canonical meta scene's child resources to the canonical Homebase,
  FOB, and Debrief resources. Point
  `MainMenuScreen.SINGLEPLAYER_SCENE_PATH` only at
  `meta_layer.tscn`. Extract canonical `MissionSetup` and unit runtime
  implementations under their productive names, then retain the old named
  scripts as narrow forwarding compatibility definitions. Do not move
  productive scripts into `scripts/tests`; `MetaLayerFlow` remains the
  productive script.

  This is a strangler migration, not a rewrite: layout/resources and existing
  public behavior stay unchanged. Old test paths are compatibility endpoints,
  not production dependencies.

- [ ] **Step 4: Verify and commit Commit A**

  ```powershell
  godot4.cmd --headless --editor --import --path . --quit
  godot4.cmd --headless --path . --script res://scripts/tests/task_n004b_public_start_path_contract.gd
  git diff --check
  ```

  The verifier must report zero failures and explicitly print the resolved
  route, canonical root names, direct MissionSetup/unit paths, and its
  dependency-edge count.

  ```powershell
  git add scenes/meta scripts/mission/mission_runtime_setup.gd scripts/mission/mission_test_setup.gd scripts/npc/unit_runtime.gd scripts/npc/test_unit.gd scripts/ui/main_menu_screen.gd scripts/tests/task_n004b_public_start_path_contract.gd
  git commit -m "feat: expose canonical singleplayer runtime route"
  ```

### Task 2: Public mission actions, identity snapshot, and structural contract

**Files:**

- Create: `scripts/tests/task_n004b_public_grid_sweep_contract.gd`
- Create: `scripts/mission/mission_runtime_identity.gd`
- Modify: `scenes/mission/mission_runtime.tscn:27`
- Modify: `scripts/tactical/mission_tactical_sandbox_controller.gd`
- Modify: `scripts/ui/main_menu_screen.gd`
- Modify: `scripts/meta/meta_layer_flow.gd`
- Modify: `scripts/tests/task_n004_product_mission_entry_architecture.gd`

**Interfaces produced by the controller:**

```gdscript
func get_mission_identity_snapshot() -> Dictionary
func begin_dropship_lz_placement(craft_id: String) -> Dictionary
func place_dropship_lz_from_world_position(world_position: Vector2) -> Dictionary
func request_mission_dropship_drop(craft_id: String) -> Dictionary
func plan_selected_fireteam_waypoint_from_world_position(
    world_position: Vector2,
    command_type: String = "take",
    append_mode: bool = false
) -> Dictionary
```

**Mission identity handoff interface:**

```gdscript
func configure_runtime_identity(identity: MissionRuntimeIdentity) -> Dictionary
func get_runtime_identity_handoff_receipt() -> Dictionary
```

`configure_runtime_identity()` is a MetaLayerFlow-only launch configuration
operation: it must reject calls once its `MissionSetup` is inside the tree.
`get_runtime_identity_handoff_receipt()` is a public defensive-copy query, not
a setter or a second simulation authority.

`execute_selected_fireteam_orders()` remains the public GO action.

The existing MainMenu release-deeplink snapshot remains read-only but gains
`deprecated`, `status`, and `reason` fields. Every accepted
release-singleplayer flag reports `deprecated=true`, `status=blocked`, and
`reason=legacy_deeplink_no_public_path`.

- [ ] **Step 1: Write the failing structural contract**

  Create `task_n004b_public_grid_sweep_contract.gd` as an
  `extends SceneTree` verifier with two independent blocks. The first loads
  only `res://scenes/mission/mission_runtime.tscn`, instantiates it, and
  asserts:

  ```gdscript
  _assert(mission.name == "MissionRuntime", "Canonical mission root has product identity")
  _assert(controller.has_method("get_mission_identity_snapshot"), "Controller exposes read-only mission identity")
  _assert(controller.has_method("begin_dropship_lz_placement"), "Controller exposes public LZ arming")
  _assert(controller.has_method("place_dropship_lz_from_world_position"), "Controller exposes public world LZ placement")
  _assert(controller.has_method("request_mission_dropship_drop"), "Controller exposes public dropship request")
  _assert(controller.has_method("plan_selected_fireteam_waypoint_from_world_position"), "Controller exposes public waypoint planning")
  _assert(controller.has_method("execute_selected_fireteam_orders"), "Controller exposes public GO")
  ```

  It must additionally inspect the implementation bodies of the five new
  methods. The bodies may delegate to a shared internal world-position
  operation, but may not contain `*_for_test`, private dynamic calls,
  `enqueue_command`, direct UnitCommand construction, teleport writes,
  Objective writes, combat-event writes, or mission-result writes.

  Read `mission_runtime.tscn` and assert it contains neither
  `res://scripts/tests/` nor `res://scenes/tests/`.

  The second block proves the real MetaLayerFlow launch handoff rather than
  merely observing a scene after it has entered the tree. For each fresh
  canonical `meta_layer.tscn` instance it first waits through the public
  `get_singleplayer_start_bootstrap_snapshot()` until
  `visible_homebase_post_show_guard_pending=false` **and**
  `visible_homebase_post_show_guard_ran=true`. Task 2 adds the pending field
  as a read-only snapshot value; the contract may not read MetaLayer metadata
  directly. Only after that settled predicate does it find the visible Homebase
  `MissionSelector` OptionButton and `StartMissionButton`, finds the catalog
  index by the selector's mission-ID metadata, calls `select(index)`, then
  emits its public `item_selected` signal (selection alone does not emit it).
  It asserts the visible Homebase selection changed, waits for an enabled Start
  button, emits its public `pressed` signal, waits for public
  `get_active_mission()`, and then reads only the MissionSetup/controller
  snapshots. The `grid_sweep` case deliberately selects `fob_transfer` first
  and then `grid_sweep`, because the bootstrap may already default to grid and
  correctly ignore a duplicate selector event. The `fob_transfer` case selects
  fob only after that post-show guard settles, so the bootstrap repair cannot
  reset it.
  The contract may not use `set`, `_on_*`, a direct `_start_mission` call, a
  private MetaLayerFlow method, or direct mission configuration.

  `MissionRuntimeIdentity` is a small value with private fields and defensive
  snapshots. MetaLayerFlow creates it from the selected catalog definition
  before `mission_host.add_child(mission_instance)`: normalised mission ID,
  map/scenario paths, authored objective marker ID, capture radius, resolved
  world position, source=`meta_layer_selected_mission_definition`, and a
  deterministic fingerprint. Its factory uses the existing
  `MissionScenarioData` plus `TerrainMapData` resolution and validates that the
  scenario's map agrees with the selected catalog map. It rejects a missing
  mission ID, map path, scenario path, marker, radius, or objective position
  rather than inventing a default. `MissionSetup` accepts the value only before
  entering the tree, retains a defensive value copy, and captures an immutable
  `pre_tree_handoff` receipt in `_enter_tree()`. Its schema is exactly
  `sternenbuergerchen.mission_runtime_identity_handoff.v1`; it contains
  `schema`, `phase=enter_tree`, `received_before_enter_tree=true`, `source`,
  `mission_id`, `map_path`, `scenario_path`, `objective_marker_id`,
  `capture_radius`, `objective_world_position`, and
  `identity_fingerprint`. Later configuration attempts return a stable
  rejection and leave that receipt unchanged.

  The contract asserts both receipts are present and valid, `grid_sweep` is
  explicitly `grid_sweep`, `fob_transfer` is explicitly `fob_transfer`, their
  mission IDs/fingerprints differ, and their shared map/scenario/objective
  tuple is the catalog/authored pair. It also makes one controlled post-tree
  configuration attempt with a defensive identity copy and asserts the stable
  rejection plus byte-for-byte unchanged receipt. This proves identity is
  selected, supplied, and frozen before node entry; it does not infer identity
  from the shared files.

  The same active `grid_sweep` MissionSetup must reject a synthetic public
  `--scenario-file=` and `--mission-scenario=` override after receipt capture:
  it returns `override_applied=false`, `rejected=true`,
  `reason=runtime_identity_locked`, and `read_only=true`; the active
  map/scenario values, controller identity snapshot, and handoff receipt remain
  unchanged. This closes the existing `_ready()` command-line override bypass.
  The old `mission_test_setup.gd` compatibility wrapper may retain its historic
  override behavior only when no MissionRuntimeIdentity has been supplied; it
  may never override a locked identity.

  The contract must construct the reachable call graph for every accepted
  --release-singleplayer startup-flag variant and its local helpers. No reachable
  release handler may call a private controller method, a test helper, a forced
  LZ/deboard/contact/fire/result helper, or a helper that reaches one.
  N004B deliberately deprecates these automation shortcuts at MainMenuScreen:
  every such flag must keep the menu active and expose the existing read-only
  deeplink snapshot with deprecated=true, status=blocked, and
  reason=legacy_deeplink_no_public_path. MetaLayerFlow receives no active
  deeplink handoff. The contract checks all snapshot fields and reports the
  complete caller-to-callee chain for any bypass.


- [ ] **Step 2: Run the contract red**

  ```powershell
  godot4.cmd --headless --editor --import --path . --quit
  godot4.cmd --headless --path . --script res://scripts/tests/task_n004b_public_grid_sweep_contract.gd
  ```

  Expected: failure because the root is still `MissionReactivityTest` and
  the public actions/identity snapshot do not exist.

- [ ] **Step 3: Implement the smallest public boundary**

  Rename only the canonical mission root to `MissionRuntime`; retain the
  legacy wrapper root name in `scenes/tests/mission_reactivity_test.tscn`.

  Extract the existing LZ acceptance/validation into one shared internal
  **world-position** operation. Both the visible screen-position handler and
  `place_dropship_lz_from_world_position()` must delegate to it. The verifier
  must never do a world-to-screen-to-world conversion.

  The public actions return defensive receipts with `accepted`, a stable
  non-empty rejection `reason`, the normalised `craft_id` or selected
  fireteam IDs, and only observable planning/drop state. The public waypoint
  method must use the existing N003
  `MissionCommandEntryAdapter -> FireteamCommandGateway` planning path and
  return its `plan_id`, planned fireteam IDs, and expected command tokens.
  It may not issue a UnitCommand.

  `get_mission_identity_snapshot()` is read-only and must provide, from
  existing authored/runtime state:

  ```json
  {
    "mission_id": "grid_sweep",
    "scenario_path": "res://data/mission_scenarios/...",
    "map_path": "res://maps/Ground_Mission01_32x32.json",
    "objective_position": {"x": 0, "y": 0},
    "pre_tree_handoff": {
      "schema": "sternenbuergerchen.mission_runtime_identity_handoff.v1",
      "phase": "enter_tree",
      "received_before_enter_tree": true,
      "source": "meta_layer_selected_mission_definition",
      "mission_id": "grid_sweep",
      "map_path": "res://maps/Ground_Mission01_32x32.json",
      "scenario_path": "res://data/mission_scenarios/ground_mission01_default.json",
      "objective_marker_id": "objective_point",
      "capture_radius": 96.0,
      "objective_world_position": {"x": 768, "y": 960},
      "identity_fingerprint": "..."
    },
    "selected_craft_id": "...",
    "payload_unit_ids": [],
    "deboarded_unit_ids": [],
    "selected_fireteam_ids": [],
    "read_only": true,
    "ui_sets_gameplay_truth": false,
    "snapshots_are_truth": false
  }
  ```

  Values must be the real active scenario/map/craft/payload state; no
  hard-coded test coordinates or claimed deboarding are allowed. If an
  existing snapshot lacks stable IDs needed for correlation, add only the
  smallest read-only field to the producer. Do not relax the later verifier.

  Mission ID is explicit launch provenance, not an inference from map or
  scenario: grid_sweep and fob_transfer currently share those files. Create a
  small immutable `MissionRuntimeIdentity` value that MetaLayerFlow builds
  from the selected catalog definition before `mission_host.add_child`. Its
  factory reuses `MissionScenarioData` plus `TerrainMapData` to resolve and
  validate the authored objective from that scenario/map pair at that time.
  `_configure_mission_instance` must call
  `MissionSetup.configure_runtime_identity()` before the instance is added;
  the setter rejects post-tree calls. In `MissionSetup._enter_tree()`, freeze
  a defensive `pre_tree_handoff` receipt with the validated values, phase,
  boolean timing proof, and stable fingerprint. The controller identity
  snapshot exposes only a defensive copy of that receipt. The contract must
  prove two actual visible Homebase selections (`grid_sweep` and
  `fob_transfer`) and may not use a direct controller or MetaLayerFlow
  configuration call to do so.

  Today `_configure_mission_instance` is also used to refresh an already
  active mission. Split its responsibilities rather than silently attempting
  the new pre-tree setter on an entered node: the new-instance/preview path
  validates and supplies identity before `add_child`, while the active-mission
  refresh path updates only the existing mutable planning/runtime selection
  fields and never replaces identity. A post-tree identity configuration is a
  rejected no-op whose immutable receipt remains byte-for-byte equivalent.

  The canonical MissionSetup implementation must also reject
  `--scenario-file` and `--mission-scenario` overrides whenever a valid
  MissionRuntimeIdentity is present. It reports the stable read-only
  `runtime_identity_locked` rejection and does not change its scenario/map
  fields. The old compatibility wrapper may preserve an unbound legacy test
  override only when no identity exists; it cannot bypass a bound product
  identity.

  Deprecate all accepted --release-singleplayer startup-flag variants in
  MainMenuScreen, before any scene change. The existing read-only deeplink
  snapshot returns deprecated=true, status=blocked, and
  reason=legacy_deeplink_no_public_path; the menu stays active and no mission,
  controller, or gameplay mutation is requested. Remove the scheduled
  MetaLayerFlow release-handler chains and their forced setup helpers from
  productive code. If a historical verifier still needs old automation, place
  the smallest isolated behavior in scripts/tests and update only that
  verifier; no productive caller may reach it. The visible Main Menu
  Singleplayer route remains the sole supported launch path.


- [ ] **Step 4: Verify and commit Commit B**

  ```powershell
  godot4.cmd --headless --editor --import --path . --quit
  godot4.cmd --headless --path . --script res://scripts/tests/task_n004b_public_grid_sweep_contract.gd
  godot4.cmd --headless --path . --script res://scripts/tests/task_n004_product_mission_entry_architecture.gd
  git diff --check
  ```

  ```powershell
  git add scenes/mission/mission_runtime.tscn scripts/mission/mission_runtime_identity.gd scripts/tactical/mission_tactical_sandbox_controller.gd scripts/ui/main_menu_screen.gd scripts/meta/meta_layer_flow.gd scripts/tests/task_n004b_public_grid_sweep_contract.gd scripts/tests/task_n004_product_mission_entry_architecture.gd
  git commit -m "feat: expose public grid sweep mission actions"
  ```

### Task 3: Read-only correlated trace and committed verifier code

**Files:**

- Create: `scripts/mission/public_grid_sweep_first_contact_trace.gd`
- Create: `scripts/tests/task_n004b_public_grid_sweep_first_contact.gd`
- Create: `scripts/tools/run_task_n004b_public_grid_sweep_evidence.ps1`
- Create: `docs/qa/artifacts/n004b/README.md`

**No current-truth document or evidence manifest is changed in this task.**

- [ ] **Step 1: Write the end-to-end verifier red**

  The verifier is an `extends SceneTree` process that starts at the actual
  main menu, activates the visible Singleplayer control, waits for
  `MetaLayer`, finds Homebase, and calls only public player actions:

  ```text
  visible Singleplayer button
  -> HomebaseScreen.request_mission_start()
  -> active MissionRuntime
  -> get_mission_identity_snapshot()
  -> begin LZ -> place LZ at authored position -> request drop
  -> natural deboard
  -> plan selected fireteam to authored objective with "take"
  -> execute_selected_fireteam_orders() (GO)
  ```

  Before gameplay, the verifier must scan **its own source and the trace
  source** for forbidden helper calls, direct simulation queueing, direct
  position/objective/combat/result writes, and test-scene imports. It must
  also use the Task-1 product dependency walker for the route actually loaded.

  The initial red state is the absence of
  `PublicGridSweepFirstContactTrace`. Do not use legacy TASK-1179 or
  TASK-1180 internals as an implementation template.

- [ ] **Step 2: Implement causal correlation and a read-only trace**

  `PublicGridSweepFirstContactTrace` is a small `RefCounted` reader with a
  capture API that accepts immutable correlation context. It may call only
  public query/snapshot APIs and `SimulationRoot.get_tick()`; it creates no
  command or effect.

  Before GO the verifier captures this baseline:

  - active `mission_id`, scenario and map identity;
  - the complete immutable `pre_tree_handoff` identity receipt: schema,
    phase, timing proof, source, mission/map/scenario, objective marker/radius
    /world position, and fingerprint. Every field is non-empty/valid and the
    defensive receipt must equal the active identity snapshot;
  - selected/deboarded fireteam and unit IDs;
  - contact identifiers/count and fire-event identifiers;
  - decision status/reason;
  - current authoritative tick.

  It connects `SimulationRoot.commander_intent_committed` before GO and
  accepts only an emitted command whose `source_context`,
  `plan_id`, `command_token`, and `fireteam_id` match the new plan
  receipt. It records the emitted `commit_tick`.

  A contact passes only when it is first observed at or after `commit_tick`,
  belongs to the planned/deboarded fireteam, and is absent from the baseline.
  A decision passes only when:

  - `fired`: at least one event with a new stable event ID belongs to the
    planned fireteam and is observed at or after `commit_tick`; or
  - `waiting` / `blocked`: the status/reason pair is new relative to the
    baseline, the reason is concrete and non-empty, and the correlated contact
    exists.

  If current public snapshots do not expose enough stable IDs to prove these
  statements, Task 3 first adds the smallest **read-only** snapshot field
  (for example fireteam ID, event ID, observed tick, or plan-token provenance)
  and adds an explicit schema assertion. A count-only or selected-state-only
  substitute is not sufficient.

  Every capture includes:

  ```json
  {
    "schema": "sternenbuergerchen.n004b.public_grid_sweep_trace.v2",
    "read_only": true,
    "ui_sets_gameplay_truth": false,
    "snapshots_are_truth": false,
    "identity_pre_tree_receipt": {
      "schema": "sternenbuergerchen.mission_runtime_identity_handoff.v1",
      "phase": "enter_tree",
      "received_before_enter_tree": true,
      "source": "meta_layer_selected_mission_definition",
      "mission_id": "grid_sweep",
      "map_path": "res://maps/Ground_Mission01_32x32.json",
      "scenario_path": "res://data/mission_scenarios/ground_mission01_default.json",
      "objective_marker_id": "objective_point",
      "capture_radius": 96.0,
      "objective_world_position": {"x": 768, "y": 960},
      "identity_fingerprint": "..."
    },
    "correlation": {
      "plan_id": "...",
      "command_token": "...",
      "fireteam_id": "...",
      "commit_tick": 0
    }
  }
  ```

  Bounded stage names are
  `menu_ready`, `meta_runtime`, `homebase_ready`, `mission_ready`,
  `identity_ready`, `lz_armed`, `lz_placed`, `drop_requested`,
  `deboarded`, `plan_created`, `go_committed`, `contact`, and
  `decision`. A timeout prints and writes the last read-only trace; it never
  introduces a shortcut.

- [ ] **Step 3: Define durable artefacts and the runner**

  The verifier accepts exactly these user arguments:

  ```text
  --run-id=diagnostic OR run-01 OR run-02
  --runtime-code-commit=diagnostic-uncommitted OR a 40-character SHA
  --artifact-path=user://diagnostic.json OR res://docs/qa/artifacts/n004b/COMMIT_SHA-run-id.json
  ```

  A diagnostic may use only run-id diagnostic, the literal code marker
  diagnostic-uncommitted, and a user:// artefact. It is never evidence. The
  two final run IDs require a 40-character SHA and a versioned repository
  artefact path.

  It resolves the path, writes only that JSON artefact, and records:

  - schema, run ID, start/end timestamps, exit/pass result and final stage;
  - exact runtime-code commit, command line, Godot version, map/scenario IDs,
    and the complete immutable pre-tree identity receipt copied verbatim from
    the active identity snapshot;
  - all action receipts and every bounded stage;
  - baseline, GO receipt, commit signal payload/tick and post-GO correlation;
  - final read-only trace, timeout/error text if any, and no hidden state.

  The PowerShell runner accepts only a versioned `res://` artefact path,
  obtains `git rev-parse HEAD`, rejects staged/tracked
  code changes, validates the SHA supplied to the verifier, and invokes the
  bootstrap plus the Godot verifier. After bootstrap it must perform the
  UID-only dry-run, print its exact count, and remove only those untracked
  UID sidecars before the functional run; tracked UID sidecars and all
  non-UID files remain untouched. Run 02 permits only the already validated
  Run-01 JSON as an untracked repository artefact; it rejects all other
  untracked files. After each run it parses the JSON and verifies its schema,
  run ID, embedded SHA, `passed=true`, final `decision` stage, and the complete
  pre-tree receipt field set; it rejects a receipt that differs from the active
  identity snapshot or omits map, scenario, objective marker/radius/position,
  source, timing proof, or fingerprint.

- [ ] **Step 4: Verify red/green and commit Commit C**

  Run the verifier red before the trace class exists. After implementing it,
  run one diagnostic process. If any named stage fails, stop feature work and
  apply `superpowers:systematic-debugging` to that exact stage. Never move
  enemies, force a drop, alter the objective, or force combat to make it pass.

  Once the diagnostic run is green, leave its `user://` diagnostic artefact
  outside the repository and run:

  ```powershell
  godot4.cmd --headless --editor --import --path . --quit
  godot4.cmd --headless --path . --script res://scripts/tests/task_n004b_public_grid_sweep_first_contact.gd -- --run-id=diagnostic --runtime-code-commit=diagnostic-uncommitted --artifact-path=user://n004b-diagnostic.json
  git diff --check
  git add scripts/mission/public_grid_sweep_first_contact_trace.gd scripts/tests/task_n004b_public_grid_sweep_first_contact.gd scripts/tools/run_task_n004b_public_grid_sweep_evidence.ps1 docs/qa/artifacts/n004b/README.md
  git commit -m "test: add public grid sweep first contact trace"
  ```

  Record the resulting SHA as **Commit C**. No N004B run may be used as
  evidence until this commit exists and the worktree code is clean.

### Task 4: Two exact-commit runs, regressions, and truthful evidence

**Files created after Commit C:**

- docs/qa/artifacts/n004b/COMMIT_C_SHA-run-01.json
- docs/qa/artifacts/n004b/COMMIT_C_SHA-run-02.json

**Files modified only after both artefacts pass:**

- `docs/CURRENT_GAME_STATE.md`
- `docs/qa/CURRENT_EVIDENCE.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `data/project_evidence_manifest.json`

- [ ] **Step 1: Produce exactly two fresh-process artefacts on Commit C**

  Execute twice in separate PowerShell/Godot processes, without changing
  runtime code between them:

  ```powershell
  scripts/tools/run_task_n004b_public_grid_sweep_evidence.ps1 -RunId run-01
  scripts/tools/run_task_n004b_public_grid_sweep_evidence.ps1 -RunId run-02
  ```

  Both JSON files must embed the same Commit-C SHA and pass final schema,
  product-route, GO, contact, and decision correlation checks. A stale,
  mismatched, duplicate, or partially written artefact is a blocker.

- [ ] **Step 2: Run architecture and behavior regressions**

  ```powershell
  godot4.cmd --headless --path . --script res://scripts/tests/task_n004b_public_start_path_contract.gd
  godot4.cmd --headless --path . --script res://scripts/tests/task_n004b_public_grid_sweep_contract.gd
  godot4.cmd --headless --path . --script res://scripts/tests/task_n004_product_mission_entry_architecture.gd
  godot4.cmd --headless --path . --script res://scripts/tests/task_n003_command_authority_parity.gd
  godot4.cmd --headless --path . --script res://scripts/tests/task_542_mission_first_contact_readability_pass.gd
  godot4.cmd --headless --path . --script res://scripts/tests/task_543_mission_first_engagement_feedback_pass.gd
  godot4.cmd --headless --path . --script res://scripts/tests/task_1179_ground_mission_objective_playthrough.gd
  git diff --check
  ```

  N004B itself and the listed architectural/readability regressions must be
  green. TASK-1179 is always run and recorded, but its known N002A
  post-result freed-instance signature remains a separately labelled release
  blocker, not a passed N004B regression. Any earlier assertion failure, a
  changed lifecycle signature, or a new N004B error blocks this task.

- [ ] **Step 3: Commit evidence as Commit D**

  Add both JSON artefacts and update Current Truth in player-path language.
  The evidence manifest record must include `delivery_state`,
  `product_maturity`, `scope`, date/time, exact Commit-C SHA, test type,
  two artefact paths, run results, ownership, and the N002A caveat. It must
  not use task counts as a progress metric or claim release readiness.

  ```powershell
  git add docs/qa/artifacts/n004b docs/CURRENT_GAME_STATE.md docs/qa/CURRENT_EVIDENCE.md docs/IMPLEMENTATION_STATUS.md data/project_evidence_manifest.json
  git commit -m "docs: record public grid sweep first contact evidence"
  ```

  Commit D is the evidence record. It must explicitly say its two artefacts
  executed the immutable runtime/test code at Commit C.

## Plan self-review

- **Actual product path:** Task 1 drives the main-menu Singleplayer control
  through a dynamic scene-transition edge, then follows and migrates the
  canonical Meta, Homebase, and mission graph. Release startup flags are
  explicitly rejected, not treated as a second player path; the end-to-end
  verifier starts there again.
- **Causal evidence:** Task 2 proves explicit identity provenance before node
  entry, while Task 3 establishes pre-GO baselines and exact
  plan/token/fireteam/tick correlation. Task 4 rejects count-only, stale, or
  post-hoc identity evidence.
- **Truthful commits:** Commit C precedes both fresh runs; Commit D only records
  their versioned JSON artefacts and current truth.
- **Architecture discipline:** all new game-facing methods are short
  delegations or read-only snapshots. `SimulationRoot` remains the sole
  mutation authority, and no new behavior is added to test paths.
- **Scope:** N002A remains separately visible, while N005 and N006 remain
  blocked until N004B has Commit-D evidence.
