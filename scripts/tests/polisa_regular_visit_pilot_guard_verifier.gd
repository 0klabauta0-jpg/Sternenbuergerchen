extends SceneTree

class UnitFixture extends Node2D:
	func get_health() -> int: return 100
class SimFixture extends Node:
	var effects_queue: Array = []
class ControllerFixture extends "res://scripts/tests/mission_tactical_sandbox_controller.gd":
	var pilot: Node
	var soldier: Node
	var card := {"craft_id":"visitor", "pilot_unit_id":"pilot", "station_pad_id":""}
	func _find_mission_dropship_card_entry(_id: String) -> Dictionary: return card.duplicate(true)
	func _find_raw_mission_dropship_card_entry(_id: String) -> Dictionary: return card.duplicate(true)
	func _get_campaign_sortie_unit(id: String) -> Node: return pilot if id == "pilot" else (soldier if id == "soldier" else null)

func _initialize() -> void:
	var mission = Node.new(); mission.set_meta("location_id", "polisa")
	mission.set_meta("singleplayer_visit_identities", {"visitor":{"craft_id":"visitor", "unit_ids":["pilot"]}})
	var simulation = SimFixture.new(); simulation.name = "SimulationRoot"; mission.add_child(simulation)
	var controller = ControllerFixture.new(); mission.add_child(controller)
	var unit = UnitFixture.new(); controller.pilot = unit
	controller._parallel_drop_sequences_by_craft["visitor"] = {"embarked_unit_ids":{"pilot":true}}
	assert(not controller.get_campaign_pilot_flight_guard("visitor").get("ok", false))
	unit.set_meta("dropship_embarked", true)
	controller._parallel_drop_sequences_by_craft["visitor"].embarked_unit_ids.clear()
	assert(not controller.get_campaign_pilot_flight_guard("visitor").get("ok", false))
	controller._parallel_drop_sequences_by_craft["visitor"].embarked_unit_ids["pilot"] = true
	simulation.effects_queue.append({"unit_id":"pilot", "effect_type":"dropship_embark_unit"})
	assert(not controller.get_campaign_pilot_flight_guard("visitor").get("ok", false))
	simulation.effects_queue.clear()
	var guard: Dictionary = controller.get_campaign_pilot_flight_guard("visitor")
	assert(guard.get("ok", false) and guard.get("pilot_unit_id") == "pilot")
	# A deployed passenger blocks a journey, but not a local support sortie.
	var soldier = UnitFixture.new(); controller.soldier = soldier
	controller._deployed_unit_ids["soldier"] = true
	mission.set_meta("singleplayer_visit_identities", {"visitor":{"craft_id":"visitor", "unit_ids":["pilot", "soldier"]}})
	assert(not controller.get_campaign_pilot_flight_guard("visitor").get("ok", false))
	assert(controller.get_campaign_air_support_pilot_guard("visitor").get("ok", false))
	unit.set_meta("dropship_embarked", false)
	assert(not controller.get_campaign_air_support_pilot_guard("visitor").get("ok", false))
	soldier.free(); unit.free(); mission.free()
	print("POLISA_REGULAR_VISIT_PILOT_GUARD passed")
	quit(0)
