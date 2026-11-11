extends SceneTree
const COMMANDS = preload("res://scripts/mission/singleplayer_supply_command_contract.gd")
var _passed := 0
var _failed := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1920, 1080)
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	var runtime: Node = flow.get("_singleplayer_runtime")
	var simulation: Node = runtime.get("_simulation")
	var state: RefCounted = simulation.call("get_personnel_loadout_state")
	var actor: Node = runtime.get("_base_personnel").call("get_actor", "campaign_leader")
	_check(actor != null and actor.call("get_armor_id") == "suit", "Actual base actor reads new campaign suit")
	var snap: Dictionary = runtime.call("get_snapshot")
	_check(not snap.supply.inventory["base:homebase"].items.has("armor_light"), "No free armor stock before blueprint")
	var id := "campaign_leader"
	var craft := String(screen.call("get_operations_snapshot").selected_craft.id)
	var equip := {"unit_id": id, "craft_id": craft, "source_container_id": "base:homebase", "slot": "armor", "item_id": "armor_light"}
	_check(not screen.call("request_operation", "inventory_equip", equip).get("ok", false), "Cannot equip unowned light armor")
	var supply: RefCounted = runtime.get("_supply")
	var locked := COMMANDS.build_command("campaign_fabricate", {"blueprint_id": "light_armor"}, "armor:locked")
	_check(supply.apply_command(locked, {"at_home": true}).get("reason") == "blueprint_locked", "Early manufacture requires earned blueprint")
	# Domain fixture for the already-tested campaign completion receipt boundary.
	# Do not autosave fixture-only campaign receipts as if a real sortie occurred.
	flow.set_process(false)
	var receipt := {"completion_id": "armor:upload", "job_id": "satellite_recovery", "runtime_verified": true, "reward": {"credits": 150, "blueprint_id": "light_armor"}}
	_check(supply.apply_command(COMMANDS.build_command("apply_reward", {"completion_id": receipt.completion_id}, "armor:reward"), {"completion_receipt": receipt}).ok, "Verified receipt opens existing recipe")
	var before: Dictionary = supply.get_supply_snapshot()
	var craft_command := COMMANDS.build_command("campaign_fabricate", {"blueprint_id": "light_armor"}, "armor:craft")
	_check(supply.apply_command(craft_command, {"at_home": true}).ok, "Earned recipe manufactures actual armor")
	_check(supply.get_supply_snapshot().credits == before.credits - 20, "Existing twenty-credit price debited")
	_check(screen.call("request_operation", "inventory_equip", equip).get("ok", false), "Existing inventory operation equips finite armor")
	_check(actor.call("get_armor_id") == "light" and state.call("get_loadout", id).armor == "light", "Actor reads changed canonical owner")
	screen.call("request_operation", "focus_unit", {"unit_id": id})
	screen.call("request_operation", "navigate", {"mode": "squad"})
	var presenter: Node = screen.get("_operations_presenter")
	presenter.call("refresh")
	var panel: Node = presenter.get("_inventory_panel")
	var remove_armor: Button = panel.get("_remove_armor")
	_check(remove_armor.visible and not remove_armor.disabled, "Shared equipment view exposes usable armor removal")
	if DisplayServer.get_name() != "headless":
		flow.get("_campaign_tutorial").call("hide_hints")
		for index in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/native_glut_maps/armor_actual_equipment.png")
	remove_armor.pressed.emit()
	_check(state.call("get_loadout", id).armor == "suit", "Actual armor removal button reaches canonical owner")
	_check(actor.call("get_armor_id") == "suit", "Suit restored without a stock suit")
	var inventory: Dictionary = supply.get_supply_snapshot().inventory
	_check(int(inventory["base:homebase"].items.get("armor_light", 0)) == 1 and not inventory["base:homebase"].items.has("suit"), "Exactly one armor returned; no suit minted")
	_check(inventory["unit:" + id + ":backpack"].capacity == 0 and inventory["unit:" + id + ":backpack"].armor_chip_capacity == 1, "Suit has chip slot without backpack")
	var legacy := {id: {"armor": "heavy", "weapon_1": "rifle", "weapon_2": "none"}}
	state.call("restore_snapshot", legacy)
	_check(actor.call("get_armor_id") == "heavy", "Legacy worn class preserved by restore")
	screen.call("request_operation", "navigate", {"mode": "base"})
	await process_frame
	var base: Node = screen.get("_operations_presenter").get("_base")
	base.call("_update_personnel_controls")
	var visuals: Dictionary = base.get("_person_visuals")
	if DisplayServer.get_name() != "headless":
		_check(visuals.has(id) and String(visuals[id].model.get_meta("worn_armor_id", "")) == "heavy", "Actual base world follows restored armor")
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://output/native_glut_maps/armor_actual_base.png")
	flow.queue_free()
	await process_frame
	print("CAMPAIGN_SUIT_EQUIPMENT %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)

func _check(ok: bool, message: String) -> void:
	if ok: _passed += 1
	else:
		_failed += 1
		push_error(message)
