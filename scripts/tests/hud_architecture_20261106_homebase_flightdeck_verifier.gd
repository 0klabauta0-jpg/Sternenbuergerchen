extends SceneTree
## Synthetic presentation fixtures; no normal flight, timers or saved roster.

const PRESENTER: GDScript = preload("res://scripts/meta/homebase_operations_presenter.gd")
const THEME: GDScript = preload("res://scripts/ui/tactical_ui_theme.gd")

class SnapshotOwner extends Control:
	var snapshot: Dictionary = {}
	var operation_count: int = 0

	func get_operations_snapshot() -> Dictionary:
		return snapshot.duplicate(true)

	func request_operation(_operation: String, _payload: Dictionary) -> Dictionary:
		operation_count += 1
		return {"ok": false, "message": "Presentation fixture has no runtime owner"}

var _passed: int = 0
var _failed: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("HUD_HOMEBASE_FLIGHTDECK_VERIFY_BEGIN")
	var owner := SnapshotOwner.new()
	owner.snapshot = _snapshot({})
	root.add_child(owner)
	var presenter: Control = PRESENTER.new()
	presenter.call("configure", owner)
	owner.add_child(presenter)
	await process_frame
	presenter.set_process(false)
	var heading: Label = presenter.get("_mission_name") as Label
	var selector: OptionButton = presenter.get("_mission_selector") as OptionButton
	var status: Label = presenter.get("_craft_status") as Label
	_assert(heading.text == "Einsatz", "Field title identifies the mission selector without repeating its value")
	_assert(selector.get_item_text(selector.selected) == "Operation: Grid Sweep", "Selector still shows the actual selected mission")
	_assert(String(selector.get_item_metadata(selector.selected)) == "grid_sweep", "Selector preserves actual selected mission ID")
	var selector_id: int = selector.get_instance_id()
	var status_id: int = status.get_instance_id()
	var cases: Array[Dictionary] = [
		{"id": "no_craft", "craft": {}, "tone": "neutral"},
		{"id": "missing_pilot", "craft": _craft({"pilot_id": "", "status": "Pilot fehlt"}), "tone": "blocked"},
		{"id": "ready", "craft": _craft({"can_start": true, "has_payload": true, "progress": 100.0, "status": "Bereit"}), "tone": "ready"},
		{"id": "transit", "craft": _craft({"busy": true, "pilot_id": "", "status": "Unterwegs"}), "tone": "transit"},
		{"id": "boarding", "craft": _craft({"has_payload": true, "progress": 40.0, "status": "Boarding läuft"}), "tone": "transit"},
		{"id": "preparation", "craft": _craft({"can_board": true, "status": "Vorbereitung"}), "tone": "pending"},
		{"id": "ready_again", "craft": _craft({"can_start": true, "status": "Localized readiness text"}), "tone": "ready"},
		{"id": "neutral_again", "craft": {}, "tone": "neutral"}
	]
	for entry in cases:
		var craft: Dictionary = Dictionary(entry.craft)
		owner.snapshot = _snapshot(craft)
		var owner_bytes: PackedByteArray = var_to_bytes(owner.snapshot)
		presenter.call("refresh")
		_assert(status.get_theme_color("font_color").is_equal_approx(THEME.status_color(String(entry.tone))), "%s uses the existing semantic theme tone" % entry.id)
		_assert(status.text == String(craft.get("status", "Kein Schiff verfügbar")), "%s preserves the runtime status text" % entry.id)
		_assert(var_to_bytes(owner.snapshot) == owner_bytes and owner.operation_count == 0, "%s refresh neither changes snapshot nor sends an operation" % entry.id)
		_assert(bool((presenter.get("_start") as Button).disabled) == (not bool(craft.get("can_start", false))), "%s preserves start gate" % entry.id)
		_assert(bool((presenter.get("_board") as Button).disabled) == (not bool(craft.get("can_board", false))), "%s preserves boarding gate" % entry.id)
		_assert(bool((presenter.get("_unboard") as Button).disabled) == (not bool(craft.get("can_unboard", false))), "%s preserves return gate" % entry.id)
		_assert(is_equal_approx((presenter.get("_progress") as ProgressBar).value, float(craft.get("progress", 0.0))), "%s preserves runtime progress" % entry.id)
		_assert(bool((presenter.get("_pilot_selector") as OptionButton).disabled) == (bool(craft.get("busy", false)) or craft.is_empty()), "%s preserves pilot gate" % entry.id)
	owner.snapshot = _snapshot(_craft({}))
	owner.snapshot["mission_id"] = "other_mission"
	owner.snapshot["mission_name"] = "Second mission from runtime"
	presenter.call("refresh")
	_assert(heading.text == "Einsatz" and selector.get_item_text(selector.selected) == "Second mission from runtime", "Mission change updates only the real selector value")
	_assert(String(selector.get_item_metadata(selector.selected)) == "other_mission", "Mission change preserves the selected owner ID")
	_assert(selector.get_instance_id() == selector_id and status.get_instance_id() == status_id, "Refresh reuses the existing selector and status controls")
	_assert(selector.get_signal_connection_list("item_selected").size() == 1, "Original mission selector callback remains connected once")
	_assert(owner.operation_count == 0, "Display-only fixture never requests an operation")
	owner.queue_free()
	await process_frame
	print("=== RESULTS: %d passed, %d failed ===" % [_passed, _failed])
	print("HUD_HOMEBASE_FLIGHTDECK_VERIFY_PASS" if _failed == 0 else "HUD_HOMEBASE_FLIGHTDECK_VERIFY_FAIL")
	quit(0 if _failed == 0 else 1)


func _snapshot(craft: Dictionary) -> Dictionary:
	return {"mode": "squad", "roster": [], "focused_unit": {}, "focused_fireteam": {},
		"focused_fireteam_id": "", "fireteams": [], "loadout_options": {},
		"selected_craft": craft, "crafts": [craft] if not craft.is_empty() else [],
		"missions": [{"id": "grid_sweep", "label": "Operation: Grid Sweep"},
			{"id": "other_mission", "label": "Second mission from runtime"}],
		"mission_id": "grid_sweep", "mission_name": "Operation: Grid Sweep"}


func _craft(overrides: Dictionary) -> Dictionary:
	var craft: Dictionary = {"id": "fixture_cutlass", "name": "Cutlass fixture", "pilot_id": "fixture_pilot",
		"pilot_options": [{"id": "fixture_pilot", "label": "Fixture pilot"}], "busy": false,
		"can_start": false, "can_board": false, "can_unboard": false, "has_payload": false,
		"progress": 0.0, "status": "Vorbereitung"}
	craft.merge(overrides, true)
	return craft


func _assert(ok: bool, message: String) -> void:
	if ok:
		_passed += 1
		print("PASS: %s" % message)
	else:
		_failed += 1
		push_error("FAIL: %s" % message)
