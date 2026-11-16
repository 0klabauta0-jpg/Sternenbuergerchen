extends SceneTree
var failed := 0
func _init() -> void:
	call_deferred("_run")
func _run() -> void:
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	await process_frame
	var screen: Control = flow.get_node("HomebaseScreen")
	var runtime: Node = flow.get("_singleplayer_runtime")
	var craft: String = String(flow.get_meta("singleplayer_bootstrap_craft_id"))
	screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"})
	screen.call("request_operation", "select_destination", {"location_id": "satellite_crash", "job_id": "satellite_recovery"})
	# Seit c9d84f58d laufen die Basispersonen wirklich zum Schiff (Einschiffen per base_board + Simulation).
	screen.call("request_operation", "base_board", {"craft_id": craft, "fireteam_id": "ft1", "whole_fireteam": true})
	var personnel: Node = runtime.call("get_base_personnel_runtime")
	var sim: Node = personnel.call("get_simulation_root")
	for tick in range(3000):
		sim.call("_physics_process", 0.05)
		screen.call("_debug_advance_homebase_direct_boarding", 0.05)
		if personnel.call("is_pilot_aboard", craft) and bool(personnel.call("get_payload_presence", craft).all_aboard) and bool(screen.call("_has_homebase_direct_launch_payload_for_craft", craft)):
			break
	# Im Spiel ruft meta_layer_flow das jeden Frame auf; das Tutorial rueckt sonst nicht zur Abflugstufe vor.
	runtime.call("observe_campaign_progress")
	_check(runtime.call("authorize_departure", craft).get("ok", false), "Fixture uses actual authorized departure binding")
	# Focused mid-flight boundary fixture, not a full transport acceptance test.
	# Die Regel retry_requires_home greift schon durch den Schiffsstandort (_aircraft_location_by_craft = "mission"),
	# nicht durch die Attrappe. Die Attrappe braucht nur authorize_return -> preview_return: Dort verlangt preview_return im Ausflug
	# einen Missionsregler mit Pilotenwache, und die Attrappe antwortet fuer die Pilotenwache fest mit ok.
	# Die echte Wache prueft campaign_five_actual_sorties_verifier.
	var guard_script := GDScript.new()
	guard_script.source_code = "extends Node\nvar _deployed_unit_ids: Dictionary = {}\nfunc get_campaign_pilot_flight_guard(_craft_id, _extra = true):\n\treturn {\"ok\": true}\nfunc _find_mission_dropship_card_entry(_craft_id) -> Dictionary:\n\treturn {}\n"
	guard_script.reload()
	var mission_stub := Node.new()
	var controller_stub := Node.new()
	controller_stub.name = "TacticalController"
	controller_stub.set_script(guard_script)
	mission_stub.add_child(controller_stub)
	flow.set("_active_mission", mission_stub)
	flow.set("_active_singleplayer_identity", {"craft_id": craft})
	flow.set("_aircraft_location_by_craft", {craft: "mission"})
	_check(screen.call("request_operation", "abandon_job", {"job_id": "satellite_recovery"}).get("ok", false), "Abandon records failed mission without erasing return binding")
	var retry: Dictionary = screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"})
	_check(not retry.get("ok", true) and retry.get("reason") == "retry_requires_home", "Retry while away is rejected")
	_check(runtime.call("get_snapshot").campaign.departures_by_craft_id.has(craft), "Rejected retry retains original route identity")
	_check(runtime.call("authorize_return", craft).get("ok", false), "Craft can still authorize its original reverse route")
	flow.set("_active_mission", null)
	flow.set("_active_singleplayer_identity", {})
	mission_stub.free()
	flow.set("_aircraft_location_by_craft", {craft: "homebase"})
	_check(screen.call("request_operation", "accept_job", {"job_id": "satellite_recovery"}).get("ok", false), "Failed job can be retried after actual home boundary")
	_check(String(runtime.call("get_snapshot").campaign.jobs.satellite_recovery.status) == "accepted", "Retry returns same job to accepted state")
	flow.queue_free()
	await process_frame
	print("CAMPAIGN_RETRY failed=", failed)
	quit(1 if failed else 0)
func _check(value: bool, label: String) -> void:
	if not value:
		failed += 1
	print("PASS: " if value else "FAIL: ", label)
