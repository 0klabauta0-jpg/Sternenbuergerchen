# Polisa services remainder / 2026-11-11

## Delivered scope
On existing unmerged task/native-glut-maps-20261110. Two production files only:
Polisa UI and three fuel-value/registration snapshot projections in adapter.
Supply remains the sole fuel/credit owner. Near-full tanks request the actual
remaining amount up to10, display ceil(amount * ownerPrice), and show the current
craft tank. The action re-reads the adapter at click time; full tank, lost service,
unregistered ship or insufficient credits disable it. Offer and buy-order rows
show the actual selected craft inventory quantity. No new prices or balances.

Ship weapons/components and local ship pickup remain unimplemented. The concrete
owner/consumer/persistence boundary is recorded in
 docs/dev/polisa_ship_equipment_contract.md. Existing ship purchases still deliver
to home; no local pickup option or functional component sale was added.

## Small checks performed
Godot4.6.2, only headless domain fixture and two check-only calls:
- domain.log:11 assertions,0 failures. Includes real Supply before/after:
 95/100 +10 rejects without mutation; UI +5 reaches100 and charges owner price.
 Full tank and service lost after stale UI snapshot dispatch no request.
 Also credit/registration guards and selected-craft cargo isolation.
- check_screen.log and check_adapter.log: clean Godot headers, no script errors.
- git diff --check for the two production files: exit0 (line-ending notices only).

Initial fixture parse failure from naming a member ready (Node signal collision)
is retained in domain_initial_parse_failure.log; renamed service_ready before the
passing run. No other domain failure was suppressed.

## Limits
This proves the small command behavior and compilation only. No native travel,
merchant approach, broad UI/layout, save/continue, battle, FPS/GPU, Main integration
or EXE acceptance. Larger tests remain deferred by user. No commits or push by
this agent. Other dirty/untracked work belongs to concurrent tasks and was not
included or cleaned. Source freeze manifest covers only this delivered package.

## Read-only review follow-up
The final request handler guards invalid/freed adapters, both required methods,
and the Variant snapshot type before refresh or dispatch. One added assertion
proves null-adapter loss sends no command and disables refueling; final domain
rerun11/0 without script errors. Freed-adapter/method/type rejection share the
small explicit guard and were statically inspected, not separately matrix-tested.
Earlier check-only logs apply before this guard; the final domain run compiles
and executes the revised screen. No broader tests followed.
