extends SceneTree
const CONTROLLER = preload("res://scripts/tests/mission_tactical_sandbox_controller.gd")
const ROOT = preload("res://scripts/core/simulation_root.gd")
const ACTOR = preload("res://scripts/npc/test_unit.gd")
const CODEC = preload("res://scripts/mission/checkpoint_value_codec.gd")
const POLISA_CRAFT = preload("res://scripts/mission/polisa_station_craft_runtime.gd")
var checks := 0
var failures := 0
func _initialize() -> void:
	var source := fixture()
	var target := fixture()
	var controller: Node = source.controller
	var state: Dictionary = controller.export_transport_checkpoint()
	if not state.has("value"): print(state)
	_check(state.get("schema") == "mission_transport_checkpoint.v1", "real owner export")
	if state.has("value"):
		var json: Dictionary = JSON.parse_string(JSON.stringify(state))
		var bindings := bind(target)
		var before: Dictionary = target.controller.export_transport_checkpoint()
		var prepared: Dictionary = target.controller.prepare_transport_checkpoint_candidate(json, bindings)
		_check(prepared.ok, "JSON prepare grounded real actors")
		_check(target.controller.export_transport_checkpoint() == before, "prepare does not mutate owner")
		if prepared.ok:
			_check(target.controller.validate_transport_checkpoint_candidate(prepared.candidate, bindings).ok, "global prepublish validation")
			target.controller._publish_transport_checkpoint(prepared.candidate)
			_check(target.controller.export_transport_checkpoint() == state, "complete owner roundtrip")
			_check(target.controller.get("_drop_sequence_units")[0] == target.actor and target.controller.get("_drop_sequence_units")[0] != source.actor, "actual target Actor rebound")
			_check(target.controller.get("_drop_sequence_phase") == "complete" and target.controller.get("_live_drop_bootstrap_consumed"), "ship restored grounded without arrival animation")
		for kind in ["duplicate", "foreign", "pilot", "position", "phase", "sequence_field", "field_type", "missing_sequence", "overlap", "extra", "revision"]:
			var bad: Dictionary = CODEC.decode_value(json.value).value
			match kind:
				"duplicate": bad.visits.craft.unit_ids.append("crew")
				"foreign": bad.visits.craft.unit_ids[0] = "stranger"
				"pilot": bad.fields._mission_drop_cards[0].pilot_unit_id = "stranger"
				"position": bad.primary.position = Vector2.ONE
				"phase": bad.primary.phase = "unloading"
				"sequence_field": bad.primary.erase("timer")
				"field_type": bad.fields._mission_drop_eta_seconds = "bad"
				"missing_sequence": bad.primary.phase = ""
				"overlap": bad.fields._embarked_unit_ids["crew"] = true
				"extra": bad["extra"] = 1
				"revision": bad.craft_identities.craft.model_id = "wrong"
			var altered := {"schema":json.schema,"value":CODEC.encode_value(bad).value}
			_check(not target.controller.prepare_transport_checkpoint_candidate(altered, bindings).ok, "reject malformed " + kind)
		var stale: Dictionary = target.controller.prepare_transport_checkpoint_candidate(json, bindings)
		target.actor.set_meta("dropship_embarked", true)
		_check(not target.controller.validate_transport_checkpoint_candidate(stale.candidate, bindings).ok, "reject changed Actor presence")
		target.actor.set_meta("dropship_embarked", false)
		stale = target.controller.prepare_transport_checkpoint_candidate(json, bindings)
		target.controller.set("_mission_drop_status_line", "changed")
		_check(not target.controller.validate_transport_checkpoint_candidate(stale.candidate, bindings).ok, "reject changed target owner")
		source.controller.set("_drop_sequence_phase", "unloading")
		_check(not source.controller.export_transport_checkpoint().get("ok", true), "refuse in-progress drop capture")
		source.controller.set("_drop_sequence_phase", "complete")
		source.simulation.effects_queue.append({"effect_type":"dropship_embark_unit","unit_id":"crew"})
		_check(not source.controller.export_transport_checkpoint().get("ok", true), "refuse queued boarding capture")
	source.host.free()
	target.host.free()
	_multicraft()
	_geometry()
	print("TRANSPORT_CHECKPOINT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

func _geometry() -> void:
	var rig := fixture()
	var view = load("res://scripts/terrain/terrain_map_3d_view.gd").new()
	var craft: Dictionary = rig.controller.get("_mission_drop_cards")[0]
	var projection: Dictionary = view.get_station_craft_body_projection(craft)
	var built: Dictionary = load("res://scripts/mission/polisa_ground_body_profile.gd").from_projection(craft, projection)
	_check(built.ok and built.profile.bounds is AABB, "actual ship mesh projection builds native AABB profile")
	if built.ok:
		rig.controller.set("_field_landing_by_craft", {"craft":{"resolved_lz_position":Vector2.ZERO,"ground_body_profile":built.profile}})
		var state: Dictionary = rig.controller.export_transport_checkpoint()
		_check(state.has("value"), "actual bounds encode in transport profile slot")
		if state.has("value"):
			var parsed: Dictionary = JSON.parse_string(JSON.stringify(state))
			var result: Dictionary = rig.controller.prepare_transport_checkpoint_candidate(parsed, bind(rig))
			_check(result.ok, "actual projected mesh bounds survive JSON prepare")
			if result.ok:
				_check(result.candidate.data.fields._field_landing_by_craft.craft.ground_body_profile.bounds == built.profile.bounds, "candidate restores exact native AABB")
				_check(rig.controller.validate_transport_checkpoint_candidate(result.candidate, bind(rig)).ok, "geometry-bearing candidate globally validates")
				rig.controller._publish_transport_checkpoint(result.candidate)
				_check(rig.controller.export_transport_checkpoint() == state, "actual mesh profile exact owner roundtrip")
			for kind in ["missing", "type", "size", "negative", "foreign_asset"]:
				var data: Dictionary = CODEC.decode_value(state.value).value
				var profile: Dictionary = data.fields._field_landing_by_craft.craft.ground_body_profile
				match kind:
					"missing": profile.erase("bounds")
					"type": profile.bounds = Vector2.ZERO
					"size": profile.bounds.transport_aabb_v1.pop_back()
					"negative": profile.bounds.transport_aabb_v1[3] = -1.0
					"foreign_asset": profile.asset_id = "foreign"
				_check(not rig.controller.prepare_transport_checkpoint_candidate({"schema":state.schema,"value":CODEC.encode_value(data).value}, bind(rig)).ok, "malformed projected bounds reject " + kind)
	view.free()
	rig.host.free()

func _multicraft() -> void:
	var source := fixture()
	var controller: Node = source.controller
	var actor := ACTOR.new()
	actor.unit_id = "pilot_b"
	actor.set_meta("dropship_embarked", true)
	source.host.add_child(actor)
	source.simulation._known_units_by_id["pilot_b"] = actor
	var visits: Dictionary = source.host.get_meta("singleplayer_visit_identities")
	# Existing crew method admits a card pilot in addition to visit.unit_ids.
	visits["craft_b"] = {"craft_id":"craft_b", "unit_ids":[], "location_id":"satellite"}
	source.host.set_meta("singleplayer_visit_identities", visits)
	var cards: Array = controller.get("_mission_drop_cards")
	cards.append({"craft_id":"craft_b","model_id":"buccaneer","pilot_unit_id":"pilot_b","state":"complete"})
	var sequence: Dictionary = POLISA_CRAFT.parked_sequence({"craft_id":"craft_b","model_id":"buccaneer","craft_type":"fighter"}, {"position":Vector2(900,900),"pad_id":"pad_b"})
	sequence["units"] = [actor]
	sequence["embarked_unit_ids"] = {"pilot_b":true}
	sequence["progress"] = 100.0
	sequence["service_reentry"] = true
	controller.set("_parallel_drop_sequences_by_craft", {"craft_b":sequence})
	var state: Dictionary = controller.export_transport_checkpoint()
	_check(state.has("value"), "parallel grounded craft captures pilot distinct from visit list")
	var bindings := bind(source)
	bindings.actors["pilot_b"] = actor
	bindings.craft_identities["craft_b"] = {"model_id":"buccaneer"}
	bindings.visits = visits
	if state.has("value"):
		var result: Dictionary = controller.prepare_transport_checkpoint_candidate(state, bindings)
		_check(result.ok, "parallel embarked pilot independent of selected craft aboard index")
		if result.ok:
			_check(controller.validate_transport_checkpoint_candidate(result.candidate, bindings).ok, "parallel global revalidation")
			controller._publish_transport_checkpoint(result.candidate)
			_check(controller.get("_parallel_drop_sequences_by_craft").craft_b.units[0] == actor, "parallel actual Actor rebound")
			_check(controller.export_transport_checkpoint() == state, "parallel exact roundtrip")
			_check(controller.get("_parallel_drop_sequences_by_craft").craft_b.station_pad_id == "pad_b" and controller.get("_parallel_drop_sequences_by_craft").craft_b.service_reentry, "real Polisa parked fields and service metadata preserved")
			result.candidate.data.primary.phase = "inbound"
			_check(not controller.validate_transport_checkpoint_candidate(result.candidate, bindings).ok, "candidate tampering rejected")
		actor.set_meta("dropship_embarked", false)
		bindings["presence_bindings"] = {"crew":false,"pilot_b":true}
		bindings["pilot_bindings"] = {"craft":"crew","craft_b":"pilot_b"}
		result = controller.prepare_transport_checkpoint_candidate(state, bindings)
		_check(result.ok and not actor.get_meta("dropship_embarked"), "prepare future verified presence without mutating Actor metadata")
		if result.ok:
			_check(controller.validate_transport_checkpoint_candidate(result.candidate, bindings).ok, "future presence globally validates before publication")
			controller._publish_transport_checkpoint(result.candidate)
			_check(actor.get_meta("dropship_embarked") and controller.export_transport_checkpoint() == state, "publish future presence and complete transport together")
		bindings.pilot_bindings.craft_b = "crew"
		_check(not controller.prepare_transport_checkpoint_candidate(state, bindings).ok, "canonical Flow pilot mapping mismatch rejects")
		bindings.pilot_bindings.craft_b = "pilot_b"
		bindings.presence_bindings.pilot_b = false
		_check(not controller.prepare_transport_checkpoint_candidate(state, bindings).ok, "future presence mismatch rejects")
		bindings.presence_bindings.pilot_b = true
	var other_root := ROOT.new()
	other_root._known_units_by_id["crew"] = source.actor
	other_root._known_units_by_id["pilot_b"] = actor
	bindings.simulation_root = other_root
	_check(not controller.prepare_transport_checkpoint_candidate(state, bindings).ok, "foreign Root cannot supply correct actors")
	other_root.free()
	source.host.free()

func fixture() -> Dictionary:
	var host := Node.new()
	host.set_meta("campaign_ground_pilot_id", "crew")
	host.set_meta("singleplayer_visit_identities", {"craft":{"craft_id":"craft","unit_ids":["crew"],"location_id":"satellite"}})
	var controller := CONTROLLER.new()
	controller.name = "TacticalController"
	host.add_child(controller)
	var simulation := ROOT.new()
	simulation.name = "SimulationRoot"
	host.add_child(simulation)
	var actor := ACTOR.new()
	actor.unit_id = "crew"
	actor.set_meta("dropship_embarked", false)
	host.add_child(actor)
	simulation._known_units_by_id["crew"] = actor
	controller.set("_mission_drop_cards", [{"craft_id":"craft","model_id":"cutlass","pilot_unit_id":"crew","state":"complete"}])
	controller.set("_mission_drop_craft_id", "craft")
	controller.set("_mission_drop_pilot_unit_id", "crew")
	controller.set("_deployed_unit_ids", {"crew":true})
	controller.set("_deployed_unit_positions", {"crew":Vector2.ZERO})
	controller.set("_drop_sequence_phase", "complete")
	controller.set("_drop_sequence_craft_id", "craft")
	controller.set("_drop_sequence_units", [actor])
	controller.set("_drop_sequence_unit_index", 1)
	controller.set("_live_drop_bootstrap_consumed", true)
	return {"host":host,"controller":controller,"simulation":simulation,"actor":actor}

func bind(f: Dictionary) -> Dictionary:
	return {"actors":{"crew":f.actor},"simulation_root":f.simulation,"visits":f.host.get_meta("singleplayer_visit_identities"),"craft_identities":{"craft":{"model_id":"cutlass"}}}

func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

