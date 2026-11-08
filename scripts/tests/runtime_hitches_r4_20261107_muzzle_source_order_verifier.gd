extends SceneTree
## Synthetic feed-order regression, not gameplay-shot evidence.
const VIEW: GDScript = preload("res://scripts/terrain/terrain_map_3d_view.gd")
const MAP: GDScript = preload("res://scripts/terrain/terrain_map_data.gd")
var passed: int = 0
var failed: int = 0

class FeedController extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var fixture_events: Array = []
	func get_fire_event_snapshot() -> Array:
		return fixture_events.duplicate(true)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var view: Node = VIEW.new()
	root.add_child(view)
	view.call("configure_from_map", MAP.call("create_empty", "r4_source_order", Vector2i(8, 8), Vector2.ZERO, 64.0, 32.0, 2))
	await frames(4)
	var old: Dictionary = event("r4_persisted_old", "alpha_0", 1)
	view.call("set_order_visual_payload", {"fire_event_dicts": [old]})
	await create_timer(0.82).timeout
	var events: Array = []
	for index in range(8):
		events.append(event("r4_fresh_%d" % index, "alpha_%d" % index, 100 + index))
	# Exercise the actual production wrapper, without Ready/UI or gameplay.
	# Only its snapshot provider is a synthetic isolated source.
	var controller: Node = FeedController.new()
	controller.set("fixture_events", events)
	var source_before: Array = events.duplicate(true)
	controller.call("_promote_release_first_exchange_visible_status_source_evidence", {"fire_event": old, "fire_event_id": "r4_persisted_old"}, Time.get_ticks_msec())
	var evidence_before: Dictionary = Dictionary(controller.get("_release_first_exchange_visible_status_source_evidence")).duplicate(true)
	var forwarded: Array = controller.call("_get_release_first_exchange_fire_visual_event_dicts")
	check(forwarded.size() == 9, "The real controller forwards eight source events plus its historical visual evidence")
	var forwarded_history: Dictionary = Dictionary(forwarded.back()) if not forwarded.is_empty() else {}
	check(bool(forwarded_history.get("presentation_history_only", false)), "The real controller marks only its appended historical copy as presentation history")
	check(Array(controller.get("fixture_events")) == source_before and events == source_before, "Historical annotation never mutates the original driver snapshot")
	check(Dictionary(controller.get("_release_first_exchange_visible_status_source_evidence")) == evidence_before, "Forwarding never rewrites the stored evidence owner or its source event")
	for index in range(mini(8, forwarded.size())):
		check(Dictionary(forwarded[index]) == Dictionary(source_before[index]), "Forwarding preserves fresh source event fields and tick: %d" % index)
	view.call("set_order_visual_payload", {"fire_event_dicts": forwarded})
	await frames(2)
	var snapshot: Dictionary = view.call("get_weapon_fire_feedback_snapshot")
	var actual: Array = []
	for item in Array(snapshot.get("entries", [])):
		actual.append(String(Dictionary(item).get("event_id", "")))
	check(actual.size() == 8, "An appended historical evidence row cannot consume a recent-source slot")
	for index in range(8):
		check(actual.has("r4_fresh_%d" % index), "Fresh source %d survives appended old evidence" % index)
	check(not actual.has("r4_persisted_old"), "Historical evidence never becomes a fresh muzzle pulse")
	var newly_received_old: Dictionary = event("r4_never_seen_history", "never_seen_history_source", 0)
	newly_received_old["presentation_history_only"] = true
	view.call("set_order_visual_payload", {"fire_event_dicts": [newly_received_old]})
	await frames(2)
	var history_exposed: bool = false
	for item in Array(Dictionary(view.call("get_weapon_fire_feedback_snapshot")).get("entries", [])):
		history_exposed = history_exposed or String(Dictionary(item).get("event_id", "")) == "r4_never_seen_history"
	check(not history_exposed, "A first receipt of a historical-only row is never presented as a new shot")
	controller.free()
	view.queue_free()
	await frames(2)
	print("R4_MUZZLE_SOURCE_ORDER: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("R4_MUZZLE_SOURCE_ORDER_PASS")
	quit(1 if failed else 0)

func event(id: String, source: String, tick: int) -> Dictionary:
	return {"event_id": id, "tick": tick, "attacker_unit_id": source, "attacker_team_id": "team_alpha", "target_unit_id": "enemy", "weapon_id": "rifle", "attacker_position": Vector2(96.0, 128.0), "target_position": Vector2(224.0, 128.0)}

func frames(count: int) -> void:
	for _frame in range(count):
		await process_frame

func check(ok: bool, message: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("PASS: " if ok else "FAIL: ", message)
