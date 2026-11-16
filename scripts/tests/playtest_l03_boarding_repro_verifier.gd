extends "res://scripts/tests/flugdeck_pilot_actual_sortie_verifier.gd"
## Package A0 (playtest L03): reproduces boarding and unboarding problems in one
## real sortie. Test only, no production change. The scenes S1 to S5 run one
## after another in the same landed sortie; between scenes the team boards or
## deploys again. Some scenes are expected to be red. The expectations are not
## weakened to make them green.
## Output: L03DIAG lines once per simulated second, one L03SCENE line per scene,
## PASS:/FAIL: lines and a final PLAYTEST_L03_BOARDING summary line.

const REAL_TIME_LIMIT_MSEC: int = 1500000
const BOARD_LIMIT_SECONDS: float = 120.0
const FAR_BOARD_LIMIT_SECONDS: float = 200.0
const MOVE_PROOF_SECONDS: float = 5.0
const SETUP_LIMIT_SECONDS: float = 90.0
const DIAG_INTERVAL_SECONDS: float = 1.0
const WAIT_SCALE: int = 4

var _game_seconds: float = 0.0
var _scene_start: float = 0.0
var _scene_name: String = ""
var _phase: String = ""
var _controller: Node
var _simulation: Node
var _registry: Node
var _tile_size: float = 64.0
var _real_deadline_msec: int = 0
var _physics_frames: int = 0
var _lock_frames: int = 0
var _tick_at_start: int = 0

func _run() -> void:
	Engine.time_scale = 4.0
	START.request_start(self, "campaign", "new")
	_flow = FLOW.instantiate()
	root.add_child(_flow)
	await process_frame
	_screen = _flow.get_node("HomebaseScreen")
	_runtime = _flow.get("_singleplayer_runtime")
	if not await _prepare_initial_base():
		await _finish()
		return
	var operations: Dictionary = _screen.call("get_operations_snapshot")
	var craft: Dictionary = operations.selected_craft
	_craft_id = String(craft.id)
	_pilot_id = String(craft.pilot_id)
	_team_id = String(Array(craft.payload_fireteam_ids)[0])
	for team: Dictionary in Array(operations.fireteams):
		if String(team.id) == _team_id:
			for unit: Dictionary in Array(team.members):
				_crew_ids.append(String(unit.id))
	_check(_screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "job accepted")
	_check(_screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"}).get("ok", false), "destination selected")
	if not await _launch_and_land("satellite_recovery", "res://maps/satellite_crash_site.json"):
		await _finish()
		return
	var mission: Node = _flow.get("_active_mission")
	_controller = mission.get_node("TacticalController")
	_simulation = mission.get_node("SimulationRoot")
	_registry = _simulation.get_hex_ground_terrain_registry()
	var origin: Vector2 = _registry.grid_to_world(Vector2i(0, 0))
	var neighbour: Vector2 = _registry.grid_to_world(Vector2i(1, 0))
	if origin.distance_to(neighbour) > 1.0:
		_tile_size = origin.distance_to(neighbour)
	_real_deadline_msec = Time.get_ticks_msec() + REAL_TIME_LIMIT_MSEC
	print("L03INFO crew=%s craft=%s team=%s tile=%.1f" % [str(_crew_ids), _craft_id, _team_id, _tile_size])
	_select_team()
	_tick_at_start = int(_simulation.call("get_tick"))
	await _scene_s1()
	await _scene_s2()
	await _scene_s3()
	await _scene_s4()
	await _scene_s5()
	# Sanity numbers: simulation ticks against counted physics frames, and how
	# many frames the two lock sets were non-empty while this script was waiting.
	print("L03INFO sim_ticks=%d physics_frames=%d game_seconds=%.1f lock_frames_nonempty=%d" % [int(_simulation.call("get_tick")) - _tick_at_start, _physics_frames, _game_seconds, _lock_frames])
	await _finish()

## The base setup waits use real milliseconds (12 s for the mission instance);
## on a loaded machine that is too short and fails before any scene starts.
func _wait(predicate: Callable, milliseconds: int, label: String) -> bool:
	return await super._wait(predicate, milliseconds * WAIT_SCALE, label)

func _finish() -> void:
	if is_instance_valid(_flow):
		_flow.queue_free()
	await process_frame
	print("PLAYTEST_L03_BOARDING checks=%d failed=%d" % [_passed + _failed, _failed])
	quit(1 if _failed > 0 else 0)

# ---------------------------------------------------------------- scenes

# S1: landed, deployed, commands free, press Aufsitzen.
func _scene_s1() -> void:
	_begin_scene("S1")
	_phase = "setup"
	if not await _prepare_ground():
		_end_scene(false, 0.0, "precondition failed: team not on ground with free commands")
		return
	_phase = "board"
	var started: float = _game_seconds
	var answer: Dictionary = _controller.request_selected_team_boarding()
	if not bool(answer.get("ok", false)):
		_end_scene(false, 0.0, "request refused: %s" % _clean(String(answer.get("message", ""))))
		return
	var waited: float = await _wait_scene(_aboard_or_dropped, BOARD_LIMIT_SECONDS)
	var seconds: float = _game_seconds - started
	if _is_aboard():
		_end_scene(true, seconds, "all aboard %s" % _distance_text())
	elif waited >= 0.0:
		_end_scene(false, seconds, "request dropped silently, not aboard %s ui=%s" % [_distance_text(), _clean(_ui_message())])
	else:
		_end_scene(false, seconds, "not aboard after limit %s open=%s" % [_distance_text(), str(_request_open())])

# S2: march about ten fields away, one second later Aufsitzen.
func _scene_s2() -> void:
	_begin_scene("S2")
	_phase = "setup"
	if not await _prepare_ground():
		_end_scene(false, 0.0, "precondition failed: team not on ground with free commands")
		return
	_phase = "march"
	if not _start_march(10.0):
		_end_scene(false, 0.0, "setup: no march order accepted")
		return
	await _wait_scene(Callable(self, "_never"), 1.0)
	var before: String = _distance_text()
	_phase = "board"
	var started: float = _game_seconds
	var answer: Dictionary = _controller.request_selected_team_boarding()
	if not bool(answer.get("ok", false)):
		_end_scene(false, 0.0, "request refused: %s dist_at_request %s" % [_clean(String(answer.get("message", ""))), before])
		return
	var waited: float = await _wait_scene(_aboard_or_dropped, BOARD_LIMIT_SECONDS)
	var seconds: float = _game_seconds - started
	if _is_aboard():
		_end_scene(true, seconds, "all aboard, dist_at_request %s" % before)
	elif waited >= 0.0:
		_end_scene(false, seconds, "request dropped silently, dist_at_request %s now %s ui=%s" % [before, _distance_text(), _clean(_ui_message())])
	else:
		_end_scene(false, seconds, "not aboard after limit, dist_at_request %s now %s open=%s" % [before, _distance_text(), str(_request_open())])

# S3: Aufsitzen right after the deploy, while the two lock sets are still filled.
func _scene_s3() -> void:
	_begin_scene("S3")
	_phase = "setup"
	if not await _ensure_aboard():
		_end_scene(false, 0.0, "precondition failed: team not aboard")
		return
	_select_team()
	_phase = "unboard"
	var deploy: Dictionary = _controller.request_campaign_crew_deployment(_craft_id)
	if not bool(deploy.get("ok", false)):
		_end_scene(false, 0.0, "deploy refused: %s" % _clean(str(deploy)))
		return
	var started: float = _game_seconds
	_phase = "board-first"
	var locks_at_request: String = _lock_text()
	var first: Dictionary = _controller.request_selected_team_boarding()
	var first_message: String = _clean(String(first.get("message", "")))
	var first_ok: bool = bool(first.get("ok", false))
	var detail: String = "first=%s msg='%s' ui='%s' locks_at_request=%s" % ["accepted" if first_ok else "refused", first_message, _clean(_ui_message()), locks_at_request]
	if not first_ok and first_message.is_empty():
		_end_scene(false, _game_seconds - started, "silent refusal: " + detail)
		return
	if not first_ok:
		# One retry once the player could reasonably press the button again.
		_phase = "wait-retry"
		var cleared: float = await _wait_scene(_deployed_and_free, SETUP_LIMIT_SECONDS)
		if cleared < 0.0:
			_end_scene(false, _game_seconds - started, "locks never cleared " + detail)
			return
		detail += " retry_after=%.1fs" % (_game_seconds - started)
		_phase = "board-retry"
		var second: Dictionary = _controller.request_selected_team_boarding()
		if not bool(second.get("ok", false)):
			_end_scene(false, _game_seconds - started, "retry refused: '%s' %s" % [_clean(String(second.get("message", ""))), detail])
			return
	var board_started: float = _game_seconds
	var waited: float = await _wait_scene(_aboard_or_dropped, BOARD_LIMIT_SECONDS)
	var seconds: float = _game_seconds - started
	if _is_aboard():
		_end_scene(true, seconds, "aboard %.1fs after accepted request; %s" % [_game_seconds - board_started, detail])
	elif waited >= 0.0:
		_end_scene(false, seconds, "accepted request dropped silently %s ui=%s; %s" % [_distance_text(), _clean(_ui_message()), detail])
	else:
		_end_scene(false, seconds, "not aboard after limit %s; %s" % [_distance_text(), detail])

# S4: team stands about fifteen fields away, then Aufsitzen.
func _scene_s4() -> void:
	_begin_scene("S4")
	_phase = "setup"
	if not await _prepare_ground():
		_end_scene(false, 0.0, "precondition failed: team not on ground with free commands")
		return
	_phase = "march"
	var in_place: bool = false
	var attempts: int = 0
	for target: Vector2 in _candidate_targets(15.0):
		if attempts >= 3:
			break
		if not _issue_move(target):
			continue
		attempts += 1
		var march_started: float = _game_seconds
		var arrived: float = await _wait_scene(_settled_after_two_seconds.bind(march_started), SETUP_LIMIT_SECONDS)
		var stats: Vector2 = _distance_range()
		if arrived >= 0.0 and stats.x >= 15.0 * _tile_size * 0.6:
			in_place = true
			break
	if not in_place:
		_end_scene(false, 0.0, "setup: team could not be placed about 15 fields away %s" % _distance_text())
		return
	var before: String = _distance_text()
	_phase = "board"
	var started: float = _game_seconds
	var answer: Dictionary = _controller.request_selected_team_boarding()
	if not bool(answer.get("ok", false)):
		_end_scene(false, 0.0, "request refused: %s dist_at_request %s" % [_clean(String(answer.get("message", ""))), before])
		return
	var dropped_at: float = -1.0
	var waited: float = await _wait_scene(_aboard_or_dropped, FAR_BOARD_LIMIT_SECONDS)
	var seconds: float = _game_seconds - started
	if waited >= 0.0 and not _is_aboard():
		dropped_at = seconds
	if _is_aboard():
		_end_scene(true, seconds, "all aboard, dist_at_request %s" % before)
	elif dropped_at >= 0.0:
		_end_scene(false, seconds, "request dropped silently at %.1fs, dist_at_request %s now %s ui=%s" % [dropped_at, before, _distance_text(), _clean(_ui_message())])
	else:
		_end_scene(false, seconds, "not aboard after limit, dist_at_request %s now %s open=%s" % [before, _distance_text(), str(_request_open())])

# S5: right-click style move order at the moment the deploy reports done.
func _scene_s5() -> void:
	_begin_scene("S5")
	_phase = "setup"
	if not await _ensure_aboard():
		_end_scene(false, 0.0, "precondition failed: team not aboard")
		return
	_select_team()
	_phase = "unboard"
	var deploy: Dictionary = _controller.request_campaign_crew_deployment(_craft_id)
	if not bool(deploy.get("ok", false)):
		_end_scene(false, 0.0, "deploy refused: %s" % _clean(str(deploy)))
		return
	var deployed_after: float = await _wait_scene(_all_deployed, SETUP_LIMIT_SECONDS)
	if deployed_after < 0.0:
		_end_scene(false, 0.0, "deploy never reported all crew on the ground")
		return
	_phase = "order"
	var locks_at_order: String = _lock_text()
	var before_positions: Dictionary = _ground_positions()
	var started: float = _game_seconds
	var accepted: bool = false
	var chosen: Vector2 = Vector2.ZERO
	for target: Vector2 in _candidate_targets(6.0):
		if _issue_move(target):
			accepted = true
			chosen = target
			break
	var command_text: String = _clean(String(_controller.get("_last_command_text")))
	# Movement only counts when it brings a member closer to the ordered target,
	# so the unload walk of the deploy itself cannot make the scene green.
	var predicate: Callable = _moved_toward.bind(before_positions, chosen) if accepted else Callable(self, "_never")
	var moved: float = await _wait_scene(predicate, MOVE_PROOF_SECONDS)
	var detail: String = "order=%s locks_at_order=%s cmd='%s' deploy_reported_after=%.1fs" % ["accepted" if accepted else "refused", locks_at_order, command_text, deployed_after]
	if moved >= 0.0:
		_end_scene(true, _game_seconds - started, "moved after %.1fs; %s" % [moved, detail])
		return
	# Informational only: how long the locks keep the next order out.
	var free_after: float = await _wait_scene(_flags_clear, SETUP_LIMIT_SECONDS)
	_end_scene(false, _game_seconds - started, "no movement within %.0fs; locks_free_after=%.1fs; %s" % [MOVE_PROOF_SECONDS, free_after + MOVE_PROOF_SECONDS, detail])

# ---------------------------------------------------------------- helpers

func _begin_scene(scene: String) -> void:
	_scene_name = scene
	_scene_start = _game_seconds
	_phase = "start"
	print("L03BEGIN %s" % scene)

func _end_scene(passed: bool, seconds: float, detail: String) -> void:
	print("L03SCENE %s result=%s seconds=%.1f detail=%s" % [_scene_name, "pass" if passed else "fail", seconds, detail])
	_check(passed, "L03 %s: %s" % [_scene_name, detail])

func _step() -> void:
	await physics_frame
	_game_seconds += 1.0 / float(Engine.physics_ticks_per_second)
	_physics_frames += 1
	if is_instance_valid(_controller) and not _flags_clear():
		_lock_frames += 1

## Waits in simulated time, one L03DIAG line per second. Returns the seconds
## waited when the predicate became true, or -1.0 on the limit.
func _wait_scene(predicate: Callable, limit: float) -> float:
	var start: float = _game_seconds
	var next_diag: float = start
	while _game_seconds - start < limit and Time.get_ticks_msec() < _real_deadline_msec:
		if _game_seconds >= next_diag:
			_diag()
			next_diag += DIAG_INTERVAL_SECONDS
		if bool(predicate.call()):
			return _game_seconds - start
		await _step()
	_diag()
	return -1.0

func _diag() -> void:
	var parts: Array[String] = []
	var distances: Dictionary = _member_distances()
	for id: String in _crew_ids:
		var value: float = float(distances.get(id, -9.0))
		var label: String = "%.0f" % value
		if value == -1.0:
			label = "aboard"
		elif value == -2.0:
			label = "dead"
		elif value == -3.0:
			label = "noaccess"
		parts.append("%s=%s" % [id, label])
	print("L03DIAG %s phase=%s t=%.1f dist=[%s] req=%s post=%d act=%d aboard=%s cmd='%s' ui='%s'" % [
		_scene_name, _phase, _game_seconds - _scene_start, ", ".join(parts), str(_request_open()),
		Dictionary(_controller.get("_post_drop_security_pending_fireteam_ids")).size(),
		Dictionary(_controller.get("_runtime_activation_pending_fireteam_ids")).size(),
		str(_is_aboard()), _clean(String(_controller.get("_last_command_text"))), _clean(_ui_message())])

## Read-only: distance to the ship access in world units, -1 aboard, -2 dead, -3 no access.
func _member_distances() -> Dictionary:
	var result: Dictionary = {}
	var access: Dictionary = _controller.get_campaign_ground_ship_access(_craft_id)
	for id: String in _crew_ids:
		var unit: Node = _controller.call("_find_friendly_unit_by_id", id)
		if unit == null or int(unit.call("get_health")) <= 0:
			result[id] = -2.0
			continue
		var state: Dictionary = _simulation.get_hex_unit_state(id)
		if state.is_empty():
			result[id] = -1.0
			continue
		if not bool(access.get("ok", false)):
			result[id] = -3.0
			continue
		var grid: Vector2i = state.grid
		result[id] = _registry.grid_to_world(grid).distance_to(Vector2(access.position))
	return result

## x = shortest, y = longest distance of living members on the ground.
func _distance_range() -> Vector2:
	var shortest: float = INF
	var longest: float = -1.0
	var distances: Dictionary = _member_distances()
	for id: String in _crew_ids:
		var value: float = float(distances.get(id, -9.0))
		if value < 0.0:
			continue
		shortest = minf(shortest, value)
		longest = maxf(longest, value)
	if longest < 0.0:
		return Vector2(-1.0, -1.0)
	return Vector2(shortest, longest)

func _distance_text() -> String:
	var range_: Vector2 = _distance_range()
	return "[min=%.0f max=%.0f]" % [range_.x, range_.y]

func _lock_text() -> String:
	return "post=%d act=%d" % [Dictionary(_controller.get("_post_drop_security_pending_fireteam_ids")).size(), Dictionary(_controller.get("_runtime_activation_pending_fireteam_ids")).size()]

func _ui_message() -> String:
	return String(_controller.get_selected_team_boarding_snapshot().get("message", ""))

func _clean(text: String) -> String:
	return text.replace("\n", " ").replace("'", "`")

func _select_team() -> void:
	_controller.call("_set_selected_fireteams", PackedStringArray([_team_id]), false)

func _request_open() -> bool:
	return Dictionary(_controller.get("_selected_team_boarding_requests")).has(_team_id)

func _is_aboard() -> bool:
	var embarked: Dictionary = _controller.get("_embarked_unit_ids")
	for id: String in _crew_ids:
		if not embarked.has(id):
			return false
	return not _crew_ids.is_empty()

func _all_deployed() -> bool:
	var deployed: Dictionary = _controller.get("_deployed_unit_ids")
	for id: String in _crew_ids:
		if not deployed.has(id):
			return false
	return not _crew_ids.is_empty()

func _flags_clear() -> bool:
	return Dictionary(_controller.get("_post_drop_security_pending_fireteam_ids")).is_empty() and Dictionary(_controller.get("_runtime_activation_pending_fireteam_ids")).is_empty()

func _deployed_and_free() -> bool:
	return _all_deployed() and _flags_clear()

func _aboard_or_dropped() -> bool:
	return _is_aboard() or not _request_open()

func _never() -> bool:
	return false

func _settled_after_two_seconds(since: float) -> bool:
	if _game_seconds - since < 2.0:
		return false
	for id: String in _crew_ids:
		var state: Dictionary = _simulation.get_hex_unit_state(id)
		if state.is_empty():
			continue
		if bool(Dictionary(state.get("movement_state", {})).get("moving", false)) or bool(Dictionary(state.get("route_state", {})).get("has_commitments", false)):
			return false
	return true

func _ground_positions() -> Dictionary:
	var result: Dictionary = {}
	for id: String in _crew_ids:
		var state: Dictionary = _simulation.get_hex_unit_state(id)
		if state.is_empty():
			continue
		var grid: Vector2i = state.grid
		result[id] = _registry.grid_to_world(grid)
	return result

func _moved_toward(before: Dictionary, target: Vector2) -> bool:
	var now: Dictionary = _ground_positions()
	for id: String in before.keys():
		if now.has(id) and Vector2(before[id]).distance_to(target) - Vector2(now[id]).distance_to(target) >= _tile_size * 0.5:
			return true
	return false

## Team on the ground and both lock sets empty. Deploys first if aboard.
func _prepare_ground() -> bool:
	_select_team()
	if _is_aboard():
		var deploy: Dictionary = _controller.request_campaign_crew_deployment(_craft_id)
		if not bool(deploy.get("ok", false)):
			print("L03NOTE %s deploy refused: %s" % [_scene_name, _clean(str(deploy))])
			return false
		if await _wait_scene(_all_deployed, SETUP_LIMIT_SECONDS) < 0.0:
			return false
	var cleared: float = await _wait_scene(_flags_clear, SETUP_LIMIT_SECONDS)
	return cleared >= 0.0 and _all_deployed()

## Recovery between scenes: if the previous scene left the team outside, send it back.
func _ensure_aboard() -> bool:
	_select_team()
	if _is_aboard():
		return true
	if await _wait_scene(_flags_clear, SETUP_LIMIT_SECONDS) < 0.0:
		return false
	var answer: Dictionary = _controller.request_selected_team_boarding()
	print("L03NOTE %s recovery boarding request: %s" % [_scene_name, _clean(str(answer))])
	if not bool(answer.get("ok", false)):
		return false
	await _wait_scene(_aboard_or_dropped, FAR_BOARD_LIMIT_SECONDS)
	return _is_aboard()

## Walkable, unblocked cells at the given distance (in fields) from the ship access.
func _candidate_targets(fields: float) -> Array[Vector2]:
	var access: Dictionary = _controller.get_campaign_ground_ship_access(_craft_id)
	var result: Array[Vector2] = []
	if not bool(access.get("ok", false)):
		return result
	var origin: Vector2 = access.position
	var origin_grid: Vector2i = access.grid
	var blocked: Variant = _controller.get_ground_ship_blocked_cells().get("blocked_cells", [])
	var span: int = int(ceil(fields)) + 3
	var scored: Array = []
	for dx: int in range(-span, span + 1):
		for dy: int in range(-span, span + 1):
			var cell: Vector2i = origin_grid + Vector2i(dx, dy)
			if blocked.has(cell) or not _registry.is_walkable(cell):
				continue
			var world: Vector2 = _registry.grid_to_world(cell)
			var gap: float = absf(world.distance_to(origin) / _tile_size - fields)
			if gap <= 0.6:
				scored.append([gap, world])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	for entry: Array in scored:
		result.append(entry[1])
		if result.size() >= 12:
			break
	return result

## Same two calls the right-click move and GO use: waypoint, then execute.
func _issue_move(target: Vector2) -> bool:
	_select_team()
	var targets: Array = _controller.call("_create_waypoints_for_selected_fireteams", target, true)
	if targets.is_empty():
		return false
	return bool(_controller.execute_selected_fireteam_orders())

func _start_march(fields: float) -> bool:
	for target: Vector2 in _candidate_targets(fields):
		if _issue_move(target):
			return true
	return false
