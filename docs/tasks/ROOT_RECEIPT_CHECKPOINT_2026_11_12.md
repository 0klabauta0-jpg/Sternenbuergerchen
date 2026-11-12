# Root receipts as prepared checkpoint part

Goal: preserve finalized launch/departure replay after the global mission restore.
Cause: Fleet, Supply and Campaign restore their completed receipts, while Root
receipts still reference old runtime owners. This additive helper reconstructs
only strictly confirmed receipts and freshly signed Fleet replay candidates.

Scope: new mission helper and focused real-owner verifier; no Root methods,
Adapter, Flow, Actors or transport changes. No active mission save authorization.
Contracts: OPEN_FUNCTIONS_RELEASE_2026_11_12 and CAMPAIGN_ACTIVE_MISSION_SAVE_2026_11_12;
existing Fleet area transition and Supply/Campaign command receipts.

Acceptance: actual satellite journey receipt capture; JSON typed roundtrip to
fresh legitimate restored owners; same Root requests replay with no repeated
fuel, campaign or flight effects. Corrupt, stale, incomplete or unsupported
receipts fail closed without live mutation. Dedicated bounded Godot check.

API: static capture(root, bindings), prepare(root, state, bindings),
validate(root, candidate, bindings), publish(root, candidate). Bindings have
fleet, supply, campaign, equipment, adapter. Caller binds authorities to the
target Root on detached restored owners before prepare. Prepare never binds or
publishes owners. Before validate, assign/configure those owners and adapter on
Root; configure_singleplayer_owners clears departure receipts on owner change.
Validate every global candidate before the synchronous no-signal/no-await tail;
publish only assigns the two receipt maps and consumes its opaque handle.

Only launch_to_orbit and finalized departures with an approach are supported.
No raw objects, process IDs, epochs or seals are serialized. Runtime owner
bindings and baseline receipt emptiness are checked; nonempty unsupported Root
receipt maps or unpublished events reject capture. Existing committed target
receipts are never silently replaced. Deliberately no Campaign group-signature
fabrication: underlying confirmed request results and departures must match.

Files: scripts/mission/root_receipt_checkpoint.gd,
scripts/tests/root_receipt_checkpoint_verifier.gd; evidence in existing QA folder.
Risks: this part needs global transaction order and final owner validation;
reapproach/cancellation and other receipt kinds remain explicitly unsupported.

## Focused evidence

Godot4.6.2, own checkout HEAD31c4aab2b, isolated APPDATA
tmp/open-functions-release/receipt-profile, profile root-receipt-true-journey-final,
90s hardlimit: exit0, ROOT_RECEIPT_CHECKPOINT passed=68 failed=0 and
ROOT_RECEIPT_TRUE_JOURNEY_PASS. Exact runnable source is the dedicated verifier.
Logs: docs/qa/open_functions_release_20261112/root-receipt-checkpoint{,.stderr}.log.
Earlier 64/0 run preserved as root-receipt-checkpoint-first{,.stderr}.log.

The verifier executes the regular base preparation, real crew boarding walk,
launch, orbit/quantum travel, satellite approach and actual landed mission. It
then captures the actual runtime Root (launch1/departure1), restores legitimate
fresh Fleet, Supply, Campaign and Equipment owners, and rebinds their authority
to a separate Root. Preparation before Root owner publication mutates nothing;
validation rejects those unpublished bindings. After binding, the same launch
and departure request IDs replay successfully. Full owner export snapshots are
unchanged and no finalized event repeats. Semantic recapture equals the source.

Negative cases cover foreign/fake/changed owners, changed complete owner baseline,
forged travel result, missing fuel request signature, changed approach, unfinished
event flags, unsupported committed receipt types, pending warp intent, consumed
candidate and occupied target receipt maps. Candidate validation repeats owner
snapshot, epoch/reference, Fleet confirmed replay and request-result checks.

Two existing scene UID-to-path fallback warnings remain. No Script/Parse/Compile/
ERROR or resource/ObjectDB leak lines in either bounded run. git diff --check
passes. No whole-mission Continue, local-space/Radar receipt restoration, native
visual approval, broad test suite or EXE claim follows from this owner proof.
