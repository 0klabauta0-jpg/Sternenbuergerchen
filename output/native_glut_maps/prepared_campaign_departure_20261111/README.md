# Unwired Prepared Campaign Departure

Base 3fb8d2985. Only product file: scripts/core/singleplayer_campaign_state.gd. Own docs: PREPARED_CAMPAIGN_DEPARTURE_2026_11_11.md and prepared_campaign_departure_contract.md.

owner_check.gd / owner_check.log: PREPARED_CAMPAIGN_RESULT checks=12 failures=0 runtime_wired=false. Real Campaign bind/activate/apply_command run on the private small subset; no Root, Supply or Flight stub is presented as integration. NoSaveOwner subclass disallows using export/restore as a runtime clone. Cases include exact legacy receipt shape, no-job, real activation, group replay/conflict, stale inputs beyond revision, actual already_active receipt collision with unchanged revision, ambiguous legacy partial receipt rejection, built runtime pads03-06 and lifecycle/RNG behavior. Setup command assertions are not counted as scenario checks.

compile.log: Godot4.6.2 --check-only exit0, engine banner only. Diff check clean apart from repository CRLF normalization notice. No private --user-data-dir; this is an in-memory owner test reading definitions, with no save/profile write and no profile canary/hash guard claimed.

No productive caller, Root events/reentrancy proof, multi-owner atomic approach, Fuel/Campaign integration, Map/Actor/GPU/battle/save/network/performance matrix, commit or push. Future Root must revalidate every involved owner before the first publication, use the silent tail, and emit only after all owners/tokens/receipts are published.
