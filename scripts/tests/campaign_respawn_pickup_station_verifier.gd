extends "res://scripts/tests/polisa_recruit_integration_verifier.gd"
## R4c Respawn (Abholen auf Polisa), Stationsseite: Nur wer auf Abholung wartet (awaiting_pickup) erscheint auf Polisa als Bewohner,
## ist uebernehmbar und wird zugelassen, auch ohne die Kennung "polisa_recruit_". Wer noch ausfaellt (respawning) tut das nicht.
## Aufbau wie polisa_recruit_integration_verifier (Fixture-Steuerung, echter Adapter, echte Basis-Runtime, echtes MissionSetup).
## S1 respawning: nicht zugelassen, nicht Bewohner, nicht uebernehmbar   S2 awaiting_pickup (andere Kennung): zugelassen, Bewohner, uebernehmbar
## S3 kein Platz im Einsatzbild: bleibt awaiting_pickup und station, beim naechsten Versuch abholbar (Punkt 4)
## S4 Angeworbene (polisa_recruit_) gehen denselben Weg wie vorher (Gegenprobe)
## Abschlusszeile: CAMPAIGN_RESPAWN_PICKUP_STATION passed=%d failed=%d

const PICKUP_STATION_GUARD = preload("res://scripts/tests/review2_isolated_user_guard.gd")

## Jede zugelassene Person bekommt eine eigene freie Zelle (der Vorlagen-Steuerung genuegt eine einzige).
class PickupController extends FixtureController:
	var cells := [Vector2i(2, 0), Vector2i(1, 0), Vector2i(3, 0)]
	var placed := {}
	func get_polisa_resident_spawn_grid() -> Dictionary: return {"ok": true, "spawn_grid": cells[mini(placed.size(), cells.size() - 1)]}
	func register_polisa_resident(id: String) -> Dictionary:
		var result: Dictionary = super.register_polisa_resident(id)
		if bool(result.get("ok", false)): placed[id] = true
		return result

func _pickup_profile(id: String, status: String) -> Dictionary:
	var profile := {"unit_id": id, "display_name": id, "availability_status": status, "respawns_used": 1, "roster_role_category": "shooter"}
	profile["recovery_state"] = {"state": status, "pickup_location_id": "polisa"} if status == "awaiting_pickup" else {"state": "respawning", "death_number": 1, "seconds_total": 3600, "seconds_remaining": 1200, "pickup_location_id": "polisa", "source": "left_behind"}
	return profile

func _add_spare_slot(rig: Dictionary, name: String) -> void:
	var spare := SelectionActor.new()
	spare.unit_id = name
	spare.team_id = "team_unused"
	spare.fireteam_id = ""
	rig.scene.add_child(spare)
	spare.set_process(false)
	spare.set_physics_process(false)
	spare.visible = false
	rig.setup.unit_paths.append(rig.setup.get_path_to(spare))
	rig.setup._friendly_unit_slot_paths.append(rig.setup.get_path_to(spare))

func _run() -> void:
	var verdict: Dictionary = PICKUP_STATION_GUARD.verdict_from_environment()
	if not bool(verdict.get("ok", false)):
		print("CAMPAIGN_RESPAWN_PICKUP_STATION refused: needs a throwaway profile (SB_REVIEW2_USER_DIR), nothing written. Reason: %s" % str(verdict.get("reason", "")))
		quit(2)
		return
	var rig: Dictionary = _selection_rig(PackedStringArray(["a"]))
	rig.setup.name = "MissionSetup"
	var controller := PickupController.new()
	controller.name = "TacticalController"
	rig.scene.add_child(controller)
	var flow := FixtureFlow.new()
	rig.scene.add_child(flow)
	var base_rig: Dictionary = _admission_rig([Vector2i.ZERO, Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)])
	var base = load("res://scripts/core/base_personnel_runtime.gd").new()
	base_rig.scene.add_child(base)
	base._flow = flow
	base._sim = base_rig.sim
	base._terrain = base_rig.terrain
	base._registry = base_rig.units
	base._layout = {"beds": []}
	base_rig.base = base
	base_rig.sim.configure_base_personnel(base)
	flow.base_owner = base
	flow.mission = rig.scene
	rig.units.name = "UnitRegistry"
	rig.sim.name = "SimulationRoot"
	rig.terrain.name = "TerrainRegistry"
	rig.setup.simulation_root_path = rig.setup.get_path_to(rig.sim)
	rig.setup.unit_registry_path = rig.setup.get_path_to(rig.units)
	rig.setup.terrain_registry_path = rig.setup.get_path_to(rig.terrain)
	rig.sim.unit_registry_path = rig.sim.get_path_to(rig.units)
	rig.sim.terrain_registry_path = rig.sim.get_path_to(rig.terrain)
	var adapter := FixtureAdapter.new()
	rig.scene.add_child(adapter)
	adapter.fixture_controller = controller
	adapter._flow = flow
	adapter._campaign_mode = true
	adapter._simulation = base_rig.sim
	adapter._base_personnel = base_rig.base
	adapter._campaign = load("res://scripts/core/singleplayer_campaign_state.gd").new()
	adapter._campaign.configure({}, {}, true)
	adapter._supply = load("res://scripts/core/singleplayer_supply_state.gd").new()
	adapter._supply.configure()
	base_rig.sim.configure_singleplayer_owners(adapter._campaign, adapter._supply)
	flow._location_registry.locations["polisa"] = rig.scene
	rig.scene.set_meta("location_id", "polisa")
	rig.scene.set_meta("singleplayer_visit_identities", {"ship": {"craft_id": "ship", "unit_ids": []}})
	var states: Dictionary = base._states

	# S1: respawning
	var down := _pickup_profile("pickup_down", "respawning")
	flow._all_team_units.append(down)
	base.sync_roster()
	_check(states.has("pickup_down") and String(states.pickup_down.status) == "station" and not base.get_actor("pickup_down").visible, "S1: Fixture: die Ausfallende steht unsichtbar auf station")
	_add_spare_slot(rig, "__slot_1")
	_add_spare_slot(rig, "__slot_2")
	for attempt in range(3):
		adapter._polisa_resident_retry_msec = 0
		adapter._restore_polisa_residents()
	_check(not controller.residents.has("pickup_down") and rig.units.get_unit("pickup_down") == null, "S1: eine Ausfallende (respawning) erscheint nicht als Bewohnerin und hat keinen Darsteller auf Polisa")
	var refused_admission: Dictionary = rig.setup.request_polisa_recruit_admission(down, Vector2i(2, 0))
	_check(not bool(refused_admission.get("ok", false)) and rig.units.get_unit("pickup_down") == null, "S1: das Einsatzbild lehnt die Zulassung einer Ausfallenden ab (%s)" % [refused_admission])
	var refused_claim: Dictionary = adapter.request_operation("station_claim_resident", {"craft_id": "ship", "unit_id": "pickup_down"})
	_check(not bool(refused_claim.get("ok", false)) and not Array(Dictionary(rig.scene.get_meta("singleplayer_visit_identities", {})).get("ship", {}).get("unit_ids", [])).has("pickup_down"), "S1: eine Ausfallende ist nicht uebernehmbar (%s)" % [refused_claim])

	# S2: awaiting_pickup, Kennung ohne polisa_recruit_
	var waiting := _pickup_profile("pickup_wait", "awaiting_pickup")
	flow._all_team_units.append(waiting)
	base.sync_roster()
	_check(String(states.pickup_wait.status) == "station" and base.has_station_recruits(), "S2: Fixture: die Wartende steht auf station")
	for attempt in range(3):
		adapter._polisa_resident_retry_msec = 0
		adapter._restore_polisa_residents()
	_check(controller.residents.has("pickup_wait") and rig.units.get_unit("pickup_wait") != null and not rig.sim.get_hex_unit_state("pickup_wait").is_empty(), "S2: eine Wartende erscheint als Bewohnerin auf Polisa (Darsteller, Bodenzustand)")
	_check(not controller.residents.has("pickup_down"), "S2: die Ausfallende bleibt auch jetzt unsichtbar")
	var claim: Dictionary = adapter.request_operation("station_claim_resident", {"craft_id": "ship", "unit_id": "pickup_wait"})
	_check(bool(claim.get("ok", false)) and Array(Dictionary(rig.scene.get_meta("singleplayer_visit_identities", {})).get("ship", {}).get("unit_ids", [])).has("pickup_wait") and not controller.residents.has("pickup_wait"), "S2: die Wartende ist fuer das Schiff uebernehmbar (%s)" % [claim])
	_check(String(states.pickup_wait.status) == "station", "S2: uebernommen, aber noch nicht abgeflogen: Basis-Zustand bleibt station (Punkt 5)")
	var waiting_after: Dictionary = {}
	for unit: Dictionary in flow._all_team_units:
		if String(unit.get("unit_id", "")) == "pickup_wait": waiting_after = unit
	_check(String(waiting_after.get("availability_status", "")) == "awaiting_pickup", "S2: uebernommen, aber noch nicht abgeflogen: Kader-Status bleibt awaiting_pickup (Punkt 5)")

	# S3: kein Platz im Einsatzbild
	var late := _pickup_profile("pickup_late", "awaiting_pickup")
	flow._all_team_units.append(late)
	base.sync_roster()
	var free_slots: int = rig.setup._friendly_unit_slot_paths.size() - rig.setup.selected_team_unit_ids.size()
	var filler: int = 0
	while free_slots > 0:
		filler += 1
		rig.setup.selected_team_unit_ids.append("__filler_%d" % filler)
		rig.setup.selected_team_fireteam_ids.append("")
		rig.setup.selected_team_unit_configs.append({"unit_id": "__filler_%d" % filler})
		free_slots -= 1
	for attempt in range(3):
		adapter._polisa_resident_retry_msec = 0
		adapter._restore_polisa_residents()
	_check(not controller.residents.has("pickup_late") and rig.units.get_unit("pickup_late") == null, "S3: ohne freien Platz im Einsatzbild erscheint die Wartende nicht (und nichts bleibt halb gesetzt)")
	_check(String(states.pickup_late.status) == "station" and not rig.setup._polisa_recruit_pending.has("pickup_late") and not rig.setup.selected_team_unit_ids.has("pickup_late"), "S3: sie bleibt station, ohne vorgemerkte Zulassung und ohne Eintrag in der Auswahl")
	for index in range(filler):
		var at: int = rig.setup.selected_team_unit_ids.find("__filler_%d" % (index + 1))
		if at >= 0:
			rig.setup.selected_team_unit_ids.remove_at(at)
			rig.setup.selected_team_fireteam_ids.remove_at(at)
			rig.setup.selected_team_unit_configs.remove_at(at)
	for attempt in range(3):
		adapter._polisa_resident_retry_msec = 0
		adapter._restore_polisa_residents()
	_check(controller.residents.has("pickup_late") and rig.units.get_unit("pickup_late") != null, "S3: beim naechsten Versuch mit freiem Platz ist sie wieder abholbar")

	# S4: Angeworbene wie vorher
	var recruit := {"unit_id": "polisa_recruit_pickup_control", "display_name": "Kontrolle", "recruit_location": "polisa"}
	flow._all_team_units.append(recruit)
	base.sync_roster()
	_add_spare_slot(rig, "__slot_3")
	for attempt in range(3):
		adapter._polisa_resident_retry_msec = 0
		adapter._restore_polisa_residents()
	_check(controller.residents.has("polisa_recruit_pickup_control") and rig.units.get_unit("polisa_recruit_pickup_control") != null, "S4: eine Angeworbene (polisa_recruit_) wird wie vorher Bewohnerin")
	var recruit_claim: Dictionary = adapter.request_operation("station_claim_resident", {"craft_id": "ship", "unit_id": "polisa_recruit_pickup_control"})
	_check(bool(recruit_claim.get("ok", false)), "S4: eine Angeworbene ist wie vorher uebernehmbar (%s)" % [recruit_claim])
	var stranger := {"unit_id": "plain_stranger", "display_name": "Fremde"}
	var stranger_admission: Dictionary = rig.setup.request_polisa_recruit_admission(stranger, Vector2i(2, 0))
	_check(not bool(stranger_admission.get("ok", false)), "S4: eine gewoehnliche Person ohne Kennung und ohne Wartestatus wird weiter abgelehnt (%s)" % [stranger_admission])

	rig.scene.free()
	base_rig.scene.free()
	print("CAMPAIGN_RESPAWN_PICKUP_STATION passed=%d failed=%d" % [passed, failed])
	quit(0 if failed == 0 else 1)
