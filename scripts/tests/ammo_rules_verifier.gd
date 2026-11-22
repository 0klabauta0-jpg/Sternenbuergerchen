extends SceneTree
## Verifies the pure ammunition rules scripts/core/ammo_rules.gd against data/combat/ammo_rules.json,
## the three ammunition fields of every weapon in weapon_data.gd and the item identities in the transfer contract.
## No scene, no user data. Task M1: nothing in the game uses these rules yet.
const R = preload("res://scripts/core/ammo_rules.gd")
const WD = preload("res://scripts/core/weapon_data.gd")
const INV = preload("res://scripts/mission/inventory_transfer_contract.gd")
const PANEL = preload("res://scripts/ui/components/personnel_inventory_panel.gd")
const AMMO_ITEMS := ["ammo_light", "ammo_rifle", "ammo_rail", "ammo_rocket"]
## Weapon id -> [ammo_class, magazine_size, reload_ticks], exactly as fixed in the plan (mun-plan.md, M1).
const PLAN_WEAPONS := {
	"pistol": ["ammo_light", 12, 30],
	"smg": ["ammo_light", 24, 30],
	"rifle": ["ammo_rifle", 20, 30],
	"sniper": ["ammo_rifle", 5, 45],
	"rail_gun": ["ammo_rail", 4, 60],
	"rocket_launcher": ["ammo_rocket", 1, 75],
}
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _run() -> void:
	var rules: Dictionary = R.load_rules()
	check(not rules.is_empty() and R.validate_rules(rules), "shipped rules file loads and is valid")
	check(R.compartment_capacity("suit", rules) == 1 and R.compartment_capacity("light", rules) == 3 and R.compartment_capacity("medium", rules) == 5 and R.compartment_capacity("heavy", rules) == 7, "compartment size per armor: suit 1, light 3, medium 5, heavy 7")
	check(R.compartment_capacity("", rules) == int(rules.default_compartment_capacity) and R.compartment_capacity("exoskeleton", rules) == int(rules.default_compartment_capacity), "empty or unknown armor gets the default size")
	check(int(rules.default_compartment_capacity) == 1, "the default size is 1")
	for item in AMMO_ITEMS:
		check(R.is_ammo_item(item, rules), "%s is an ammunition item" % item)
	check(not R.is_ammo_item("rifle", rules) and not R.is_ammo_item("a_benit", rules) and not R.is_ammo_item("", rules), "foreign items are not ammunition")
	check(Dictionary(rules.ammo_items).size() == AMMO_ITEMS.size(), "exactly four ammunition items are defined")

	# --- state sequence for a pistol magazine (numbers come from the weapon data) ---
	var pistol: Dictionary = WD.WEAPON_CATALOG["pistol"]
	var size: int = int(pistol.magazine_size)
	var reload: int = int(pistol.reload_ticks)
	var chunk: int = floori(reload / 3.0)
	var state: Dictionary = R.new_weapon_state(size)
	check(int(state.rounds) == size and int(state.reload_ticks_left) == 0, "a new weapon state holds a full magazine")
	check(R.can_fire(state, true) and not R.needs_reload(state), "a full magazine can fire and needs no reload")
	var before: Dictionary = state.duplicate(true)
	var after_one: Dictionary = R.after_shot(state)
	check(state == before and int(after_one.rounds) == size - 1, "after_shot returns a copy with one round less and leaves the input alone")
	for i in size:
		state = R.after_shot(state)
	check(int(state.rounds) == 0 and not R.can_fire(state, true) and R.needs_reload(state), "after a full magazine of shots: empty, cannot fire, needs reload")
	check(int(R.after_shot(state).rounds) == 0, "after_shot at 0 stays at 0")
	var begin_input: Dictionary = state
	var begin_copy: Dictionary = begin_input.duplicate(true)
	state = R.begin_reload(begin_input, reload)
	check(begin_input == begin_copy and not is_same(begin_input, state), "begin_reload leaves the input alone (input compared after the call)")
	check(int(state.reload_ticks_left) == reload and not R.can_fire(state, true) and not R.needs_reload(state), "while reloading: cannot fire and needs no second reload")
	for step in 3:
		var adv_input: Dictionary = state
		var adv_copy: Dictionary = adv_input.duplicate(true)
		state = R.advance_reload(adv_input, chunk, size)
		check(adv_input == adv_copy and not is_same(adv_input, state), "advance_reload leaves the input alone (step %d, input compared after the call)" % step)
		if step < 2:
			check(int(state.reload_ticks_left) == reload - chunk * (step + 1) and int(state.rounds) == 0 and not R.can_fire(state, true), "reload step %d: still counting down, still empty" % step)
	check(int(state.rounds) == size and int(state.reload_ticks_left) == 0 and R.can_fire(state, true), "after the last chunk: full magazine again, can fire")
	var overshoot: Dictionary = R.advance_reload(R.begin_reload({"rounds": 0, "reload_ticks_left": 0}, 5), 99, size)
	check(int(overshoot.rounds) == size and int(overshoot.reload_ticks_left) == 0, "a reload tick overshoot ends at 0 left and a full magazine")
	var idle: Dictionary = R.advance_reload(R.after_shot(R.new_weapon_state(size)), 10, size)
	check(int(idle.rounds) == size - 1 and int(idle.reload_ticks_left) == 0, "advance_reload without a running reload changes nothing")
	check(R.can_fire({"rounds": 0, "reload_ticks_left": 0}, false) and R.can_fire({"rounds": 0, "reload_ticks_left": 30}, false), "a weapon without ammunition need can always fire")

	# can_fire: the reload condition on its own (rounds left, but a reload is running)
	check(R.can_fire({"rounds": 5, "reload_ticks_left": 0}, true), "rounds left and no reload running can fire")
	check(not R.can_fire({"rounds": 5, "reload_ticks_left": 10}, true), "rounds left but a reload running cannot fire")
	# a zero or negative counter never gets stuck
	var zero_begin: Dictionary = R.begin_reload({"rounds": 0, "reload_ticks_left": 0}, 0)
	check(int(zero_begin.reload_ticks_left) >= 1 and not R.can_fire(zero_begin, true), "begin_reload with 0 ticks still starts a reload of at least one tick")
	check(int(R.advance_reload(zero_begin, 1, size).rounds) == size, "a 0-tick reload ends after one tick with a full magazine")
	var negative_state: Dictionary = {"rounds": 0, "reload_ticks_left": -3}
	var negative_copy: Dictionary = negative_state.duplicate(true)
	check(R.needs_reload(negative_state) and not R.can_fire(negative_state, true), "a negative counter with no rounds needs a reload")
	check(R.can_fire({"rounds": 2, "reload_ticks_left": -3}, true), "a negative counter with rounds left can fire")
	check(R.advance_reload(negative_state, 5, size) == negative_copy and negative_state == negative_copy, "advance_reload leaves a negative counter alone and the input unchanged")

	# --- invalid rules ---
	check(not R.validate_rules({}), "empty rules are invalid")
	for key in ["compartment_capacity_by_armor", "default_compartment_capacity", "ammo_items"]:
		var broken: Dictionary = rules.duplicate(true)
		broken.erase(key)
		check(not R.validate_rules(broken), "rules without %s are invalid" % key)
	var negative: Dictionary = rules.duplicate(true)
	negative.compartment_capacity_by_armor.heavy = -1
	check(not R.validate_rules(negative), "a negative compartment size is invalid")
	var negative_default: Dictionary = rules.duplicate(true)
	negative_default.default_compartment_capacity = -1
	check(not R.validate_rules(negative_default), "a negative default size is invalid")
	var no_suit: Dictionary = rules.duplicate(true)
	no_suit.compartment_capacity_by_armor.erase("suit")
	check(not R.validate_rules(no_suit), "rules without a size for the suit are invalid")
	var empty_items: Dictionary = rules.duplicate(true)
	empty_items.ammo_items = {}
	check(not R.validate_rules(empty_items), "rules without any ammunition item are invalid")
	check(R.load_rules("res://data/combat/does_not_exist.json").is_empty(), "a missing rules file yields empty rules and reports an error")

	# --- weapon data ---
	var all_have_fields := true
	var weapon_ids: Array = WD.WEAPON_CATALOG.keys()
	for weapon_id in weapon_ids:
		var w: Dictionary = WD.WEAPON_CATALOG[weapon_id]
		if not (w.has("ammo_class") and w.has("magazine_size") and w.has("reload_ticks")):
			all_have_fields = false
			print("missing ammo fields: ", weapon_id)
			continue
		var cls: String = String(w.ammo_class)
		var consistent: bool = (cls == "" and int(w.magazine_size) == 0 and int(w.reload_ticks) == 0) or (R.is_ammo_item(cls, rules) and int(w.magazine_size) > 0 and int(w.reload_ticks) > 0)
		if not consistent:
			all_have_fields = false
			print("inconsistent ammo fields: ", weapon_id)
	check(all_have_fields and weapon_ids.size() >= PLAN_WEAPONS.size(), "every weapon carries ammo_class, magazine_size and reload_ticks, consistently")
	for weapon_id in PLAN_WEAPONS:
		var w: Dictionary = WD.WEAPON_CATALOG[weapon_id]
		var want: Array = PLAN_WEAPONS[weapon_id]
		check(String(w.ammo_class) == want[0] and int(w.magazine_size) == want[1] and int(w.reload_ticks) == want[2], "%s: %s, %d rounds, reload %d" % [weapon_id, want[0], want[1], want[2]])
	for weapon_id in weapon_ids:
		if not PLAN_WEAPONS.has(weapon_id):
			var w: Dictionary = WD.WEAPON_CATALOG[weapon_id]
			check(String(w.ammo_class) == "" and int(w.magazine_size) == 0 and int(w.reload_ticks) == 0, "%s needs no ammunition" % weapon_id)

	# --- transfer contract: known, fits the backpack, not (yet) the armor compartment ---
	for item in AMMO_ITEMS:
		check(INV.known(item), "%s is known to the transfer contract" % item)
		check(INV.has_space({"capacity": 12, "items": {}}, item, 1), "%s fits an empty backpack" % item)
		check(INV.valid_container({"capacity": 12, "items": {item: 2}}), "a backpack holding two %s is a valid container" % item)
		check(INV.used({item: 3}) == 3, "%s takes one slot each" % item)
		# M2 (22.11.2026): changed expectation - the armor compartment now takes magazines (one place each); was "does not fit" in M1.
		check(INV.has_space({"capacity": 0, "armor_chip_capacity": 1, "items": {}}, item, 1), "%s fits the armor compartment of a person without a backpack (M2)" % item)
		check(INV.valid_container({"capacity": 0, "armor_chip_capacity": 1, "items": {item: 1}}), "a compartment-only container holding one %s is valid (M2)" % item)
		check(not INV.valid_container({"capacity": 0, "armor_chip_capacity": 1, "items": {item: 2}}), "a size-1 compartment without a backpack cannot hold two %s" % item)
	check(INV.has_space({"capacity": 0, "armor_chip_capacity": 1, "items": {}}, "satellite_chip", 1), "the armor compartment still takes a data chip")
	check(not INV.known("ammo_unknown"), "an unknown ammunition id is still unknown")
	check(INV.valid_container({"capacity": 12, "armor_chip_capacity": 1, "items": {"satellite_chip": 1, "ammo_light": 12}}), "chip in the compartment plus twelve magazines in the backpack is valid")
	# M2-5 (22.11.2026): changed expectation - the chip no longer takes the compartment place of a magazine, so 13 magazines
	# (1 in the compartment, 12 in the backpack) plus a chip fit; was "overfill" in M1. 14 still overfill.
	check(INV.valid_container({"capacity": 12, "armor_chip_capacity": 1, "items": {"satellite_chip": 1, "ammo_light": 13}}), "chip plus thirteen magazines fit (one in the compartment, twelve in the backpack)")
	check(not INV.valid_container({"capacity": 12, "armor_chip_capacity": 1, "items": {"satellite_chip": 1, "ammo_light": 14}}), "fourteen magazines plus a chip overfill a backpack")

	# --- display names ---
	var names_ok := true
	for item in AMMO_ITEMS:
		if String(PANEL.LABELS.get(item, "")) != String(rules.ammo_items[item]):
			names_ok = false
			print("label differs: ", item)
	check(names_ok, "the inventory panel shows the names from the rules file")
	print("AMMO_RULES passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)
