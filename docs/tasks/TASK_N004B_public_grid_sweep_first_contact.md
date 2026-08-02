# TASK_N004B - Public grid_sweep First-Contact Trace

Status: active - implementation approved; runtime evidence open
Started: 2026-08-02T16:15:12+02:00
Last plan audit: 2026-08-02T17:05:26+02:00 - independent final audit approved
Parent gate: [TASK_N004](TASK_N004_canonical_product_mission.md)
Working base: task/project-forward-strangler at
008d00bba589bcd1dc8a771c07ea0e4ba90ac89f

## Problem

N004A has a canonical mission scene and a green structural verifier, but the
visible normal Singleplayer route still enters a test-named Meta scene and
uses test-named direct runtime implementations. The current evidence has no
integrated, twice freshly executed player path from the actual main menu to
the authored grid_sweep first contact. The external TASK-1180 candidate
therefore remains a candidate, not product evidence.

An audit also found a release-deeplink compatibility path in MetaLayerFlow
that calls private controller/test helpers. It may not be inherited by the new
public trace.

## Goal

A headless playtest requests exactly the player-visible actions:

~~~
Main Menu -> Singleplayer -> Homebase Start
-> canonical MissionRuntime -> LZ -> Dropship -> natural Deboard
-> authored objective take plan -> GO
-> SimulationRoot commit/tick -> new contact -> new decision
~~~

The result is two versioned JSON traces from two fresh Godot processes on the
same already-committed runtime/test code. Each trace proves the exact plan,
command token, selected/deboarded fireteam, commit tick, new contact, and
fired/waiting/blocked decision. Current Truth is updated only in a later
evidence commit that names that executed code commit.

## Required public route

- project.godot main scene -> scenes/ui/main_menu.tscn -> SingleplayerButton
  -> scenes/meta/meta_layer.tscn (MetaLayer) -> canonical Homebase ->
  MissionRuntime.
- The route contract resolves static targets passed into scene-change calls,
  including SINGLEPLAYER_SCENE_PATH, as graph edges. A dynamic scene change
  never ends the transitive product dependency check.
- The canonical Meta scene uses canonical Homebase/FOB/Debrief scenes.
  Historical *_test*.tscn resources remain one-way compatibility wrappers,
  with no incoming product edge.
- The active mission uses canonical mission_runtime_setup.gd and
  unit_runtime.gd; their historical test-named paths/classes are forwarding
  compatibility definitions.
- The product graph may not import/preload scripts/tests or scenes/tests.
  This task does not rename the historical tactical controller filename; it
  stays in its productive scripts/tactical boundary and must only shrink or
  gain short delegates.

## Binding architecture rules

- Only SimulationRoot commits UnitCommands or runtime status.
- UI, renderer, Playtest adapter, and trace can request actions or read state;
  they never write gameplay truth.
- N004B never calls issue_right_click_command_for_test, private controller
  methods, teleports, direct enemy/objective mutations, combat injections, or
  forced results.
- The controller exposes short public LZ/drop/waypoint delegates and a
  read-only mission identity snapshot. A common internal world-position LZ
  operation serves both visible mouse input and the public delegate.
- MetaLayerFlow supplies a validated immutable MissionRuntimeIdentity before
  `mission_host.add_child(mission_instance)`. Its factory validates the
  selected catalog map against the scenario, resolves marker ID/radius/world
  position with the existing scenario/map resolver, and fingerprints the full
  identity before that add. MissionSetup captures an immutable defensive
  receipt in `_enter_tree()` with `received_before_enter_tree=true` and
  rejects any later configuration without changing it. Mission ID is explicit
  launch provenance, because different mission IDs can share map/scenario
  files; it is never inferred from them.
- The complete `_enter_tree()` receipt is versioned and read-only: schema,
  phase, timing proof, source, mission/map/scenario, objective marker, radius,
  world position, and fingerprint. The trace copies it verbatim and verifies it
  against the active identity snapshot.
- The existing configuration helper is split into a pre-add new-instance /
  preview path (which supplies identity) and an entered active-mission refresh
  path (which cannot replace identity). A rejected post-tree identity call
  leaves the frozen receipt unchanged.
- A bound canonical MissionSetup ignores and reports `runtime_identity_locked`
  for `--scenario-file` and `--mission-scenario`; it cannot change a product
  mission after the pre-tree handoff. The old compatibility wrapper may retain
  an unbound legacy test override only.
- Every accepted release-singleplayer command-line deeplink is deprecated with
  the stable public MainMenu snapshot status
  legacy_deeplink_no_public_path. It remains on the menu and does not hand off
  to MetaLayerFlow. No reachable handler/helper may call private controller,
  forced setup, or test-helper code. The visible Main Menu route remains the
  only supported launch path.
- The trace is read-only: read_only=true, ui_sets_gameplay_truth=false, and
  snapshots_are_truth=false.
- N005 and N006 remain blocked until the N004B evidence commit exists.

## Evidence protocol

1. Commit A: canonical main-menu -> Meta -> Homebase route plus wrappers.
2. Commit B: public mission action/identity boundary and structural contracts.
3. Commit C: read-only trace, end-to-end verifier, and evidence runner.
4. Run run-01 and run-02 in distinct Godot processes on clean Commit-C runtime
   code. Each creates docs/qa/artifacts/n004b/COMMIT_C_SHA-run-0N.json.
5. Commit D: add both artefacts and update CURRENT_GAME_STATE.md,
   CURRENT_EVIDENCE.md, IMPLEMENTATION_STATUS.md, and the evidence manifest.
   Commit D names Commit C as the executed code; it never claims it executed
   itself.

The JSON schema contains run ID, timestamps, exact code SHA, Godot version,
product route, scenario/map identity, immutable pre-tree handoff receipt,
bounded stages, action receipts, baseline, plan ID, command token, fireteam,
commit tick, causal contact/decision correlation, final result, and
errors/timeouts.

## Acceptance

1. A static and runtime route contract drives the actual visible main-menu
   Singleplayer button to canonical MetaLayer, Homebase, and MissionRuntime;
   it resolves dynamic scene-change targets, prints all discovered dependency
   edges, and finds no forbidden test-path edge.
2. The four action delegates, mission identity snapshot, canonical mission
   root, release-deeplink no-bypass rule, and two actual visible Homebase
   selections pass their structural contract. `grid_sweep` and `fob_transfer`
   each have an immutable MissionSetup `_enter_tree()` receipt proving their
   explicit pre-tree handoff; their distinct mission IDs cannot be inferred
   from the shared map/scenario pair. Each receipt names schema, phase, timing
   proof, source, mission ID, map path, scenario path, objective marker ID,
   capture radius, objective world position, and fingerprint. A post-tree
   identity configuration attempt is rejected and leaves the receipt unchanged.
   Before each selection, the public bootstrap snapshot confirms the deferred
   post-show guard has run;
   a synthetic scenario-override attempt is rejected as
   `runtime_identity_locked` without changing map, scenario, or receipt.
3. The verifier starts from the main menu, uses only public methods, runs the
   authored grid_sweep path, and reaches go_committed, a post-GO correlated
   contact, and a strictly valid decision.
4. Two fresh runs on exactly Commit C create distinct, schema-valid JSON
   artefacts with the same embedded code SHA. A stale event/contact/count-only
   result is rejected.
5. N004 route/action contracts, N003 parity, N004A architecture, TASK-542,
   and TASK-543 are green. TASK-1179 is run and recorded; its known N002A
   post-result lifecycle signature remains a separately labelled release
   blocker rather than a fake green regression.
6. Commit D records all claims with Commit C, date, test type, artefact path,
   result, scope, maturity, ownership, and the N002A caveat. It does not claim
   release readiness.

## Bootstrap and workspace hygiene

Before every functional headless run in a fresh worktree:

~~~powershell
godot4.cmd --headless --editor --import --path . --quit
~~~

The generated .godot cache remains ignored. Broad generated UID sidecars are
never staged. A cleanup may remove only exact, untracked UIDs after
git clean -n -f -- '*.uid' proves the scope; tracked UID sidecars remain.
The final evidence runner performs that dry-run/count before its functional
process and removes no other untracked file.
Diagnostic traces go to user://; only the two final versioned JSON files are
written into the repository.

## Dependencies

N003 is satisfied. N002A is a parallel release gate whose lifecycle repair is
not hidden by this task. N004B changes no landscape (N005), combat cadence
(N006), campaign/progression, engine version, or multiplayer rules beyond
preserving the N003 command contract.
