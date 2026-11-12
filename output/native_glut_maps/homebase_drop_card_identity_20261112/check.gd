extends SceneTree
class Screen extends "res://scripts/meta/homebase_screen.gd":
	var definitions: Array = []
	func _get_visible_homebase_aircraft_definitions() -> Array: return definitions
	func _get_assigned_pilot_id(_id: String) -> String: return "pilot"
	func _build_display_name(id: String) -> String: return "Name "+id
	func _get_profile_portrait_path(_id: String) -> String: return "portrait.png"

var passed := 0
var failed := 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS " if ok else "FAIL ",label)

func _initialize() -> void:
	var screen = Screen.new()
	var definition := {"craft_id":"arbitrary_id","display_name":"Named vessel","model_id":"buccaneer","craft_type":"fighter","visual_asset_id":"buccaneer_01","crew_capacity":1,"texture_path":"ship.png"}
	screen.definitions = [definition]
	var source_before := definition.duplicate(true)
	var cards: Array = screen._build_homebase_mission_drop_cards(PackedStringArray(["ft2"]),PackedStringArray(["person"]),"arbitrary_id",true)
	var card: Dictionary = cards[0]
	check(card.get("model_id")=="buccaneer" and card.get("craft_type")=="fighter" and card.get("visual_asset_id")=="buccaneer_01" and card.get("crew_capacity")==1 and definition==source_before,"Actual craft identity/capacity forwarded without source mutation")
	check(card.craft_id=="arbitrary_id" and card.state=="waiting" and card.payload_source=="homebase_direct" and card.pilot_unit_id=="pilot" and card.pilot_portrait_path=="portrait.png" and card.queued_fireteam_ids==["ft2"] and card.boarded_fireteam_ids==["ft2"] and card.embarked_unit_ids==["person"] and card.passenger_count==1,"Existing pilot/fireteam/payload fields preserved")
	screen.definitions=[{"craft_id":"cutlass_in_name_only","display_name":"Cutlass heavy eight"}]
	card=screen._build_homebase_mission_drop_cards(PackedStringArray(),PackedStringArray())[0]
	check(not card.has("model_id") and not card.has("craft_type") and not card.has("crew_capacity") and not card.has("visual_asset_id"),"Legacy names never invent model/role/capacity")
	screen.definitions=[{"craft_id":"starter","craft_type":"dropship","model_id":"cutlass"}]
	card=screen._build_homebase_mission_drop_cards(PackedStringArray(),PackedStringArray())[0]
	check(card.get("model_id")=="cutlass" and card.get("craft_type")=="dropship" and not card.has("crew_capacity") and not card.has("visual_asset_id"),"Starter-shaped latest definition keeps missing provenance absent")
	screen.free()
	print("HOMEBASE_DROP_CARD_IDENTITY passed=",passed," failed=",failed)
	quit(0 if failed==0 else 1)
