extends "res://scripts/tests/playtest_l03_right_click_boarding_verifier.gd"
## Package C1: direct control of one person during a mission. Runs in the real
## landed sortie of the L03 verifiers (two-person team ft1: campaign_leader,
## campaign_pilot). Clicks and right clicks are real InputEventMouseButton
## events given to controller._unhandled_input (the viewport does not reach the
## controller headless, see the B verifier); the portrait click calls the
## portrait handler of the team card directly with a real mouse event.
## Stub units (enemy, downed comrade) are plain Node2D children of the mission
## root with the unit methods the controller reads; they are freed after use.
## Output: DCINFO lines, PASS:/FAIL: lines and a final
## PLAYTEST_DIRECT_UNIT_CONTROL summary line.

const LEADER_ID: String = "campaign_leader"
const PILOT_ID: String = "campaign_pilot"
const STUB_SOURCE: String = """extends Node2D
var uid: String = ""
var team: String = ""
var ft: String = ""
var vital: String = "fit"
var selected: bool = false
func get_unit_id() -> String: return uid
func get_team_id() -> String: return team
func get_fireteam_id() -> String: return ft
func get_vital_state() -> String: return vital
func get_health() -> int: return 0 if vital == "down" else 10
func get_display_name() -> String: return uid
func get_callsign() -> String: return uid
func set_tactical_selected(value: bool) -> void: selected = value
func is_tactical_selected() -> bool: return selected
"""

var _signal_events: Array = []

func _run() -> void:
	if not await _setup_sortie():
		await _finish()
		return
	if _controller.has_signal("direct_unit_action_resolved"):
		_controller.connect("direct_unit_action_resolved", _on_direct_signal)
	if not await _prepare_ground():
		_check(false, "DC precondition: team on the ground with free commands")
		await _finish()
		return
	await _wait_scene(Callable(self, "_never"), 3.0)
	_use_direct_input = true
	print("DCINFO leader=%s pilot=%s local_team=%s" % [_display(LEADER_ID), _display(PILOT_ID), str(_controller.call("get_local_command_team_id"))])
	await _scene_selection()
	await _scene_branches()
	await _scene_detach_and_rejoin()
	await _scene_replace_and_rejoin_early()
	await _scene_plan_off()
	# The enemy and multiplayer scenes make the ship leave, after which no
	# ground targets exist: pick the target for the down scene now.
	var down_target: Vector2 = _far_target(13.0, _grid_pos(PILOT_ID))
	await _scene_enemy()
	await _scene_multiplayer()
	await _scene_down(down_target)
	await _finish()

func _finish() -> void:
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame
	print("PLAYTEST_DIRECT_UNIT_CONTROL checks=%d failed=%d" % [_passed + _failed, _failed])
	quit(1 if _failed > 0 else 0)

func _on_direct_signal(unit_id: String, action: String, success: bool, details: Dictionary) -> void:
	_signal_events.append({"unit_id": unit_id, "action": action, "success": success, "details": details})

# ---------------------------------------------------------------- helpers

func _unit(id: String) -> Node:
	return _controller.call("_find_friendly_unit_by_id", id)

func _display(id: String) -> String:
	var unit: Node = _unit(id)
	return String(unit.call("get_display_name")) if unit != null and unit.has_method("get_display_name") else id

func _unit_world(id: String) -> Vector2:
	return (_unit(id) as Node2D).global_position

func _grid_pos(id: String) -> Vector2:
	return _ground_positions().get(id, Vector2.INF)

func _dist_to(id: String, target: Vector2) -> float:
	return _grid_pos(id).distance_to(target)

func _at(id: String, target: Vector2) -> bool:
	var state: Dictionary = _simulation.get_hex_unit_state(id)
	return not state.is_empty() and Vector2i(state.grid) == Vector2i(_registry.world_to_grid(target)) and not bool(Dictionary(state.get("movement_state", {})).get("moving", false))

func _sel_unit() -> String:
	return String(_controller.call("get_selected_unit_id")) if _controller.has_method("get_selected_unit_id") else "<missing get_selected_unit_id>"

## 1 detached, 0 not detached, -1 API missing.
func _detached(id: String) -> int:
	if not _controller.has_method("is_unit_detached"):
		return -1
	return 1 if bool(_controller.call("is_unit_detached", id)) else 0

func _events() -> Array:
	return Array(_controller.call("get_direct_unit_action_events")) if _controller.has_method("get_direct_unit_action_events") else []

func _events_for(id: String, action: String) -> Array:
	var result: Array = []
	for entry_variant: Variant in _events():
		var entry: Dictionary = entry_variant
		if String(entry.get("unit_id", "")) == id and String(entry.get("action", "")) == action:
			result.append(entry)
	return result

func _status_text() -> String:
	return String(_controller.get("_last_command_text"))

func _fmc() -> Object:
	return _controller.get("_fireteam_movement_controller")

func _fmc_excluded(id: String) -> int:
	var fmc: Object = _fmc()
	if fmc == null or not fmc.has_method("is_unit_excluded"):
		return -1
	return 1 if bool(fmc.call("is_unit_excluded", id)) else 0

func _team_executing() -> bool:
	var fmc: Object = _fmc()
	return fmc != null and bool(fmc.call("has_active_execution", _team_id))

func _command_of(id: String) -> Variant:
	var unit: Node = _unit(id)
	return unit.call("get_current_unit_command") if unit != null else null

func _command_token(id: String) -> String:
	var command: Variant = _command_of(id)
	return String(command.command_token) if command != null else ""

func _left_click(screen: Vector2, double_click: bool = false) -> void:
	await _send(_mouse_event(screen, MOUSE_BUTTON_LEFT, true, double_click))
	await _send(_mouse_event(screen, MOUSE_BUTTON_LEFT, false))
	await process_frame

func _frames(count: int) -> void:
	for i: int in count:
		await process_frame

func _make_stub(id: String, team: String, fireteam: String, vital: String, world: Vector2) -> Node2D:
	var script := GDScript.new()
	script.source_code = STUB_SOURCE
	script.reload()
	var node := Node2D.new()
	node.set_script(script)
	node.set("uid", id)
	node.set("team", team)
	node.set("ft", fireteam)
	node.set("vital", vital)
	node.name = id
	_controller.get_parent().add_child(node)
	node.global_position = world
	return node

func _free_stub(node: Node) -> void:
	if is_instance_valid(node):
		node.get_parent().remove_child(node)
		node.queue_free()

## Single-select the pilot with the real click sequence (team first, then person).
func _single_select_pilot() -> void:
	_controller.call("_set_selected_fireteams", PackedStringArray(), false)
	# The person may be walking: aim every click at its position at that moment.
	for attempt: int in range(3):
		await _left_click(_screen_of(_unit_world(PILOT_ID)))
		await _left_click(_screen_of(_unit_world(PILOT_ID)))
		if _sel_unit() == PILOT_ID:
			return
		_controller.call("_set_selected_fireteams", PackedStringArray(), false)
	print("L03DIAG single select failed: sel='%s' text='%s'" % [_sel_unit(), _status_text()])

func _far_target(fields: float, away_from: Vector2 = Vector2.INF) -> Vector2:
	var best: Vector2 = Vector2.INF
	var best_distance: float = -1.0
	for target: Vector2 in _candidate_targets(fields):
		var score: float = target.distance_to(away_from) if away_from.is_finite() else 0.0
		if best == Vector2.INF or score > best_distance:
			best = target
			best_distance = score
	return best

func _event_count() -> int:
	return _events().size()

# ---------------------------------------------------------------- scenes

# Selection rules.
func _scene_selection() -> void:
	_begin_scene("DC-sel")
	_controller.call("set_planning_enabled", true)
	var pilot: Node = _unit(PILOT_ID)
	var leader: Node = _unit(LEADER_ID)
	var pilot_screen: Vector2 = _screen_of(_unit_world(PILOT_ID))
	_controller.call("_set_selected_fireteams", PackedStringArray(), false)
	await _left_click(_screen_of(_unit_world(PILOT_ID)))
	_check(_team_selected_alone() and _sel_unit() == "", "DC-sel first click on a person selects the fireteam, no single person (selected=%s unit='%s')" % [str(_selected_ids()), _sel_unit()])
	await _left_click(_screen_of(_unit_world(PILOT_ID)))
	_check(_sel_unit() == PILOT_ID and _team_selected_alone(), "DC-sel second click on a person of the selected fireteam selects only that person (unit='%s')" % _sel_unit())
	_check(_status_text() == "Einzelsteuerung: " + _display(PILOT_ID), "DC-sel status line names the person: '%s'" % _status_text())
	_check(bool(pilot.call("is_tactical_selected")) and not bool(leader.call("is_tactical_selected")), "DC-sel only the single person carries the selection ring")
	await _left_click(_screen_of(_unit_world(PILOT_ID)))
	_check(_sel_unit() == "" and _team_selected_alone(), "DC-sel click on the single-selected person drops back to the fireteam")
	await _left_click(_screen_of(_unit_world(PILOT_ID)))
	await _left_click(_screen_of(_unit_world(LEADER_ID)))
	_check(_sel_unit() == LEADER_ID, "DC-sel click on another person of the fireteam switches the single selection (unit='%s')" % _sel_unit())
	# Click on other ground drops the single selection (tile selection).
	var ground: Vector2 = _far_target(4.0)
	await _left_click(_screen_of(ground))
	_check(_sel_unit() == "", "DC-sel click on other ground drops the single selection")
	# Double click on a person of the already selected fireteam.
	_controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	pilot_screen = _screen_of(_unit_world(PILOT_ID))
	await _send(_mouse_event(pilot_screen, MOUSE_BUTTON_LEFT, true, true))
	await _send(_mouse_event(pilot_screen, MOUSE_BUTTON_LEFT, false))
	await process_frame
	_check(_sel_unit() == PILOT_ID, "DC-sel double click on a person of the selected fireteam gives the single selection and nothing undoes it (unit='%s' text='%s')" % [_sel_unit(), _status_text()])
	# Portrait click.
	await _left_click(_screen_of(ground))
	_controller.call("_on_native_member_portrait_gui_input", _mouse_event(Vector2(5, 5), MOUSE_BUTTON_LEFT, true), LEADER_ID, _team_id)
	await process_frame
	_check(_sel_unit() == LEADER_ID, "DC-sel click on the portrait selects that person alone (unit='%s')" % _sel_unit())
	# Lasso.
	await _single_select_pilot()
	_check(_sel_unit() == PILOT_ID, "DC-sel single selection ready before the lasso")
	var start: Vector2 = _screen_of(_unit_world(PILOT_ID)) + Vector2(-140.0, -140.0)
	var finish: Vector2 = start + Vector2(280.0, 280.0)
	await _send(_mouse_event(start, MOUSE_BUTTON_LEFT, true))
	var motion := InputEventMouseMotion.new()
	motion.position = finish
	motion.global_position = finish
	await _send(motion)
	await _send(_mouse_event(finish, MOUSE_BUTTON_LEFT, false))
	await process_frame
	_check(_sel_unit() == "", "DC-sel lasso drops the single selection (selected=%s)" % str(_selected_ids()))
	# Left click on the ship.
	await _single_select_pilot()
	await _left_click(_ship_screen())
	_check(_sel_unit() == "", "DC-sel left click on the ship drops the single selection")
	# Escape.
	_controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	await _single_select_pilot()
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	await _send(key)
	_check(_sel_unit() == "", "DC-sel Escape drops the single selection")
	# A person who is down cannot be single-selected.
	var downed: Node2D = _make_stub("stub_downed", String(_controller.call("get_local_command_team_id")), _team_id, "down", _far_target(5.0))
	await _frames(2)
	_controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	var downed_screen: Vector2 = _screen_of(downed.global_position)
	await _left_click(downed_screen)
	await _left_click(downed_screen)
	_check(_sel_unit() == "", "DC-sel a person who is down cannot be single-selected (unit='%s')" % _sel_unit())
	_free_stub(downed)

# Right click target kinds: downed comrade, ship.
func _scene_branches() -> void:
	_begin_scene("DC-branch")
	_controller.call("set_planning_enabled", true)
	await _single_select_pilot()
	_check(_sel_unit() == PILOT_ID, "DC-branch single selection ready")
	var local_team: String = String(_controller.call("get_local_command_team_id"))
	# Downed comrade: no command, only the status text.
	var downed: Node2D = _make_stub("stub_downed", local_team, _team_id, "down", _far_target(6.0))
	await _frames(2)
	var token_before: String = _command_token(PILOT_ID)
	var events_before: int = _event_count()
	await _right_click(_screen_of(downed.global_position))
	await _frames(4)
	_check(_status_text() == "Liegende Kameraden lassen sich noch nicht tragen", "DC-branch downed comrade: status text (got '%s')" % _status_text())
	_check(_command_token(PILOT_ID) == token_before and _event_count() == events_before, "DC-branch downed comrade: no command and no event")
	_check(_sel_unit() == PILOT_ID and _menu_targets() == 0, "DC-branch downed comrade: selection stays, no menu")
	_free_stub(downed)
	# Own ship: no command, no boarding request, only the status text.
	events_before = _event_count()
	await _right_click(_ship_screen())
	await _frames(4)
	_check(_status_text() == "Einzelne Personen sitzen über den Trupp auf", "DC-branch ship: status text (got '%s')" % _status_text())
	_check(_command_token(PILOT_ID) == token_before and _event_count() == events_before and not _request_open(), "DC-branch ship: no command, no event, no boarding request")
# Move during a running fireteam order, not pulled back, event, rejoin.
func _scene_detach_and_rejoin() -> void:
	_begin_scene("DC-move")
	_controller.call("set_planning_enabled", true)
	_controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	var team_target: Vector2 = _far_target(5.0)
	var far_target: Vector2 = _far_target(13.0, team_target)
	_check(_issue_move(team_target), "DC-move fireteam order accepted")
	# A click within 56 px of the ship selects the ship first (existing left
	# click order), so wait until both people are clearly away from it.
	await _wait_scene(func() -> bool: return float(_member_distances().get(PILOT_ID, 0.0)) > _tile_size * 3.0 and float(_member_distances().get(LEADER_ID, 0.0)) > _tile_size * 3.0, 20.0)
	_check(_team_executing(), "DC-move fireteam order is running")
	await _single_select_pilot()
	var leader_before: float = _dist_to(LEADER_ID, team_target)
	var waypoints: int = _pending_waypoints()
	var events_before: int = _event_count()
	var pilot_before: Vector2 = _grid_pos(PILOT_ID)
	await _right_click(_screen_of(far_target))
	_check(_menu_targets() == 0 and _pending_waypoints() == waypoints, "DC-move plan mode on: right click opens no menu and adds no waypoint")
	_check(_detached(PILOT_ID) == 1 and _fmc_excluded(PILOT_ID) == 1, "DC-move the person is detached and excluded from the running order (detached=%d excluded=%d)" % [_detached(PILOT_ID), _fmc_excluded(PILOT_ID)])
	_check(_event_count() == events_before, "DC-move no event before the person arrives")
	var moved: float = await _wait_scene(func() -> bool: return pilot_before.distance_to(_grid_pos(PILOT_ID)) >= _tile_size * 2.0 and _dist_to(PILOT_ID, far_target) < pilot_before.distance_to(far_target) - _tile_size, 12.0)
	_check(moved >= 0.0, "DC-move the person walks toward its own target at once")
	_check(_dist_to(LEADER_ID, team_target) < leader_before - _tile_size * 0.5 or _dist_to(LEADER_ID, team_target) <= _tile_size * 1.5, "DC-move the rest of the fireteam keeps walking to the fireteam target")
	# The fireteam order completes without waiting for the person.
	var team_done: float = await _wait_scene(func() -> bool: return not _team_executing(), 90.0)
	_check(team_done >= 0.0, "DC-move the fireteam order completes while the person is still on its way")
	_check(not _at(PILOT_ID, far_target) and _dist_to(PILOT_ID, team_target) > _tile_size * 1.5, "DC-move the person was not pulled back to the fireteam target (distance to fireteam target %.0f)" % _dist_to(PILOT_ID, team_target))
	# Arrival -> event.
	var arrived: float = await _wait_scene(func() -> bool: return _at(PILOT_ID, far_target), 120.0)
	await _frames(30)
	var move_events: Array = _events_for(PILOT_ID, "move")
	_check(arrived >= 0.0, "DC-move the person arrives at its own target")
	_check(move_events.size() == 1, "DC-move exactly one move event (%d)" % move_events.size())
	if move_events.size() == 1:
		var entry: Dictionary = move_events[0]
		_check(bool(entry.get("success", false)) and entry.has("details") and entry.details is Dictionary and Vector2(entry.details.get("target", Vector2.INF)).distance_to(far_target) < _tile_size, "DC-move event: unit_id, action move, success true, details.target (%s)" % str(entry))
	_check(_signal_events.size() == _event_count() and (_signal_events.is_empty() or String(Dictionary(_signal_events[0]).get("unit_id", "")) == PILOT_ID), "DC-move the signal carries the same events (%d signal, %d list)" % [_signal_events.size(), _event_count()])
	_check(_detached(PILOT_ID) == 1, "DC-move the person stays detached after arriving until the fireteam gets a new order")
	# Next fireteam order: the person is part of it again.
	var next_target: Vector2 = _far_target(3.0)
	_controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	var before: Vector2 = _grid_pos(PILOT_ID)
	_check(_issue_move(next_target), "DC-move next fireteam order accepted")
	_check(_detached(PILOT_ID) == 0 and _fmc_excluded(PILOT_ID) == 0, "DC-move the next fireteam order re-includes the person (detached=%d excluded=%d)" % [_detached(PILOT_ID), _fmc_excluded(PILOT_ID)])
	var follows: float = await _wait_scene(func() -> bool: return before.distance_to(next_target) - _dist_to(PILOT_ID, next_target) >= _tile_size * 2.0, 30.0)
	_check(follows >= 0.0, "DC-move the person walks with the fireteam order again")
	await _wait_scene(func() -> bool: return not _team_executing(), 90.0)

# A direct order replaced by another emits nothing; rejoin before arrival fails the move.
func _scene_replace_and_rejoin_early() -> void:
	_begin_scene("DC-replace")
	_controller.call("set_planning_enabled", true)
	await _single_select_pilot()
	var first: Vector2 = _far_target(10.0)
	var second: Vector2 = _far_target(6.0, first)
	var events_before: int = _event_count()
	await _right_click(_screen_of(first))
	await _wait_scene(Callable(self, "_never"), 1.0)
	await _right_click(_screen_of(second))
	_check(_event_count() == events_before, "DC-replace the replaced direct order emits nothing")
	var arrived: float = await _wait_scene(func() -> bool: return _at(PILOT_ID, second), 120.0)
	await _frames(30)
	var entries: Array = _events_for(PILOT_ID, "move")
	var new_entries: Array = entries.slice(maxi(entries.size() - (_event_count() - events_before), 0))
	_check(arrived >= 0.0 and _event_count() == events_before + 1 and new_entries.size() == 1 and bool(Dictionary(new_entries[0]).get("success", false)) and Vector2(Dictionary(Dictionary(new_entries[0]).get("details", {})).get("target", Vector2.INF)).distance_to(second) < _tile_size, "DC-replace exactly one new event, for the second target, success (%d new)" % (_event_count() - events_before))
	# Rejoin before arrival.
	var far: Vector2 = _far_target(13.0, second)
	events_before = _event_count()
	await _right_click(_screen_of(far))
	await _wait_scene(Callable(self, "_never"), 1.5)
	_controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)
	_check(_issue_move(_far_target(4.0)), "DC-replace fireteam order while the person is on its way accepted")
	await _frames(40)
	var late: Array = _events_for(PILOT_ID, "move")
	var last: Dictionary = late[late.size() - 1] if not late.is_empty() else {}
	_check(_event_count() == events_before + 1 and not bool(last.get("success", true)) and String(Dictionary(last.get("details", {})).get("reason", "")) == "rejoined", "DC-replace rejoin before arriving: one move event, success false, reason rejoined (%s)" % str(last))
	await _wait_scene(func() -> bool: return not _team_executing(), 90.0)

# Plan mode off: the same direct order, the rest of the team stays put.
func _scene_plan_off() -> void:
	_begin_scene("DC-planoff")
	_controller.call("set_planning_enabled", false)
	await _single_select_pilot()
	var leader_before: Vector2 = _grid_pos(LEADER_ID)
	var pilot_before: Vector2 = _grid_pos(PILOT_ID)
	var target: Vector2 = _far_target(9.0, pilot_before)
	await _right_click(_screen_of(target))
	_check(_detached(PILOT_ID) == 1 and not _team_executing(), "DC-planoff plan mode off: only the person is sent, no fireteam order starts")
	var moved: float = await _wait_scene(func() -> bool: return pilot_before.distance_to(target) - _dist_to(PILOT_ID, target) >= _tile_size * 2.0, 20.0)
	_check(moved >= 0.0, "DC-planoff the person walks to the clicked tile")
	_check(_grid_pos(LEADER_ID).distance_to(leader_before) < 1.0, "DC-planoff the rest of the fireteam stays where it is")
	_check(_menu_targets() == 0, "DC-planoff no menu")
	await _wait_scene(func() -> bool: return _at(PILOT_ID, target), 90.0)
	_controller.call("set_planning_enabled", true)

# Enemy under the pointer: engage_area on its position. Runs late: a hostile
# stub unit makes the mission "not non-combat", after which the campaign ship
# no longer stays landed, so nothing after this scene may need the ship.
func _scene_enemy() -> void:
	_begin_scene("DC-enemy")
	_controller.call("set_planning_enabled", true)
	await _single_select_pilot()
	_check(_sel_unit() == PILOT_ID, "DC-enemy single selection ready")
	var leader_token: String = _command_token(LEADER_ID)
	var waypoints: int = _pending_waypoints()
	var enemy: Node2D = _make_stub("stub_enemy", "hostile_test", "", "fit", _far_target(5.0))
	await _frames(2)
	await _right_click(_screen_of(enemy.global_position))
	await _frames(6)
	var engage_events: Array = _events_for(PILOT_ID, "engage")
	_check(engage_events.size() == 1 and bool(Dictionary(engage_events[0]).get("success", false)) and bool(Dictionary(Dictionary(engage_events[0]).get("details", {})).get("accepted_only", false)), "DC-enemy right click on an enemy emits one engage event, success, accepted_only (events=%s)" % str(engage_events))
	var command: Variant = _command_of(PILOT_ID)
	_check(command != null and String(command.command_type) == "engage_area" and String(command.source_command_type) == "direct_control" and Vector2(command.target_position).distance_to(enemy.global_position) < _tile_size, "DC-enemy the person holds an engage_area command (source direct_control) on the enemy position")
	_check(_command_token(LEADER_ID) == leader_token, "DC-enemy the rest of the fireteam keeps its command")
	_check(_menu_targets() == 0 and _pending_waypoints() == waypoints, "DC-enemy no waypoint menu and no waypoint for the enemy click")
	_check(_detached(PILOT_ID) == 1, "DC-enemy the person is detached after the engage order")
	_free_stub(enemy)

# Connected multiplayer client: nothing is sent. Runs late: a client peer makes
# the campaign ship leave, so nothing after this scene may need the ship.
func _scene_multiplayer() -> void:
	_begin_scene("DC-mp")
	await _single_select_pilot()
	var token_before: String = _command_token(PILOT_ID)
	var events_before: int = _event_count()
	var ground: Vector2 = _far_target(3.0)
	var original_peer: MultiplayerPeer = _controller.multiplayer.multiplayer_peer
	var peer := ENetMultiplayerPeer.new()
	var created: int = peer.create_client("127.0.0.1", 59555)
	if created == OK:
		_controller.multiplayer.multiplayer_peer = peer
	events_before = _event_count()
	await _right_click(_screen_of(ground))
	await _frames(4)
	var client_text: String = _status_text()
	_controller.multiplayer.multiplayer_peer = original_peer
	if created == OK:
		_check(client_text == "Einzelsteuerung gibt es im Mehrspieler noch nicht" and _command_token(PILOT_ID) == token_before and _event_count() == events_before, "DC-mp multiplayer client: message and nothing sent (got '%s')" % client_text)
	else:
		print("DCINFO multiplayer client could not be created headless (code %d); branch not exercised" % created)

# A person who goes down ends the detachment and fails the pending move.
func _scene_down(far: Vector2) -> void:
	_begin_scene("DC-down")
	await _single_select_pilot()
	var events_before: int = _event_count()
	await _right_click(_screen_of(far))
	await _wait_scene(Callable(self, "_never"), 1.0)
	print("DCINFO down: pilot=%s far=%s dist=%.0f events=%d->%d" % [str(_grid_pos(PILOT_ID)), str(far), _dist_to(PILOT_ID, far), events_before, _event_count()])
	_check(_detached(PILOT_ID) == 1, "DC-down person detached before going down")
	var pilot: Node = _unit(PILOT_ID)
	pilot.call("apply_damage", 100000, {"source": "dc_test"})
	await _wait_scene(Callable(self, "_never"), 2.0)
	_check(String(pilot.call("get_vital_state")) != "fit", "DC-down the person is down (%s)" % String(pilot.call("get_vital_state")))
	_check(_detached(PILOT_ID) == 0 and _fmc_excluded(PILOT_ID) == 0, "DC-down a person who goes down is removed from the detached set (detached=%d)" % _detached(PILOT_ID))
	var entries: Array = _events_for(PILOT_ID, "move")
	var last: Dictionary = entries[entries.size() - 1] if not entries.is_empty() else {}
	_check(_event_count() == events_before + 1 and not bool(last.get("success", true)) and String(Dictionary(last.get("details", {})).get("reason", "")) == "down", "DC-down the pending move fails with reason down (%s)" % str(last))
	_check(_sel_unit() == "", "DC-down the single selection ends")
