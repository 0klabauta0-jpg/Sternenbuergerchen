extends SceneTree

const BOOTSTRAP_PATH := "res://scripts/mission/multiplayer_dropship_bootstrap.gd"
const MISSION_SCENE := preload("res://scenes/tests/mission_reactivity_test.tscn")
const LOBBY_SCENE := preload("res://scenes/ui/multiplayer_lobby.tscn")

var _failed := 0


func _initialize() -> void:
	_assert(FileAccess.file_exists(BOOTSTRAP_PATH), "Multiplayer Dropship bootstrap contract exists")
	if not FileAccess.file_exists(BOOTSTRAP_PATH):
		quit(1)
		return
	var bootstrap: GDScript = load(BOOTSTRAP_PATH)
	var mission := MISSION_SCENE.instantiate()
	root.add_child(mission)
	await process_frame
	var controller: Node = mission.get_node("TacticalController")
	var assignments := {
		"peer_fireteams": {1: PackedStringArray(["blue"]), 2: PackedStringArray(["gold"])},
		"peer_roles": {1: "host", 2: "commander"},
	}
	var state: Dictionary = Dictionary(bootstrap.call("build_initial_planning_state", controller, assignments))
	var cards: Array = Array(state.get("mission_drop_cards", []))
	_assert(cards.size() == 2, "Bootstrap creates one Dropship per assigned Fireteam")
	_assert(String(state.get("mission_drop_state", "")) == "waiting", "Bootstrap starts in visible waiting state")
	_assert(Array(state.get("deployed_unit_ids", ["unexpected"])).is_empty(), "Bootstrap does not pre-deploy payload")
	_assert(Array(state.get("embarked_unit_ids", [])).size() >= 2, "Bootstrap embarks assigned Fireteam members")
	_assert(_card_has_payload(cards, "dropship_blue", "blue"), "Blue payload owns Dropship Blue")
	_assert(_card_has_payload(cards, "dropship_gold", "gold"), "Gold payload owns Dropship Gold")
	_assert(String(state.get("mission_drop_source", "")) == "multiplayer_lobby", "Bootstrap records multiplayer lobby source")
	_assert(bool(state.get("ui_sets_gameplay_truth", true)) == false, "Bootstrap does not claim UI gameplay authority")
	var lobby := LOBBY_SCENE.instantiate()
	root.add_child(lobby)
	await process_frame
	_assert(lobby.has_method("initialize_multiplayer_mission_dropships"), "Product lobby exposes Host-only mission Dropship bootstrap")
	if lobby.has_method("initialize_multiplayer_mission_dropships"):
		var client_mission := MISSION_SCENE.instantiate()
		root.add_child(client_mission)
		await process_frame
		_assert(not bool(lobby.call("initialize_multiplayer_mission_dropships", client_mission, assignments, false)), "Client cannot seed parallel Dropship truth")
		_assert(Array(Dictionary(client_mission.get_node("TacticalController").call("get_planning_state")).get("mission_drop_cards", [])).is_empty(), "Client bootstrap leaves mission Dropship state untouched")
		_assert(bool(lobby.call("initialize_multiplayer_mission_dropships", client_mission, assignments, true)), "Host seeds product mission Dropship state")
		_assert(Array(Dictionary(client_mission.get_node("TacticalController").call("get_planning_state")).get("mission_drop_cards", [])).size() == 2, "Host product bootstrap installs both Dropship cards")
		client_mission.queue_free()
	lobby.queue_free()
	mission.queue_free()
	await process_frame
	print("TASK_1148 Multiplayer Dropship bootstrap: %d/14 PASS" % (14 - _failed))
	quit(1 if _failed > 0 else 0)


func _card_has_payload(cards: Array, craft_id: String, fireteam_id: String) -> bool:
	for card_variant in cards:
		var card := Dictionary(card_variant)
		if String(card.get("craft_id", "")) != craft_id:
			continue
		return Array(card.get("boarded_fireteam_ids", [])).has(fireteam_id) and not Array(card.get("embarked_unit_ids", [])).is_empty()
	return false


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failed += 1
	push_error("FAIL: %s" % message)
