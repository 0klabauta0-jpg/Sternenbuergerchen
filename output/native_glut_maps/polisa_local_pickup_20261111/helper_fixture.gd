extends SceneTree
const HELPER = preload("res://scripts/mission/polisa_station_craft_runtime.gd")
var count := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	count += 1
	if not ok: failures += 1; print("FAIL ",label)
func _initialize() -> void:
	var map = load("res://scripts/terrain/terrain_map_data.gd").load_from_file("res://maps/polisa_station.json")
	var pads := HELPER.station_pads(map)
	check(pads.size()==7,"all real pad markers")
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/frontier_ship_visual_catalog.json"))
	for model: String in ["cutlass","buccaneer"]:
		var fact: Dictionary = catalog.ships[model+"_01"]
		check(FileAccess.get_sha256(fact.model_path)==fact.sha256,"actual catalog body identity "+model)
		var bmin: Array=fact.bounds_min; var bsize: Array=fact.bounds_size
		var projection := {"bounds":AABB(Vector3(bmin[0],bmin[1],bmin[2]),Vector3(bsize[0],bsize[1],bsize[2])),"model_scale":fact.scale,"cell_size":1.0,"yaw_degrees":0.0}
		for pad: Dictionary in pads:
			var all_fit := true
			for yaw in range(360):
				projection.yaw_degrees=yaw
				var result := HELPER.preview_admission({"craft_id":"new","model_id":model},[pad],projection,[],pad.pad_id)
				all_fit=all_fit and bool(result.ok)
			check(all_fit and HELPER.receipt_pad_compatible(model,pad.pad_id),"historical compatibility all yaw "+model+" "+pad.pad_id)
		projection.yaw_degrees=0
		var free := HELPER.preview_admission({"craft_id":"new","model_id":model},pads,projection,[])
		var occupied := [{"pad_id":free.pad_id,"footprint":free.footprint}]
		check(not HELPER.preview_admission({"craft_id":"new","model_id":model},pads,projection,occupied,free.pad_id).ok,"occupied pad reject")
		projection.cell_size=0.05
		check(not HELPER.preview_admission({"craft_id":"new","model_id":model},pads,projection,[]).ok,"actual renderer cellscale affects fit")
	check(not HELPER.receipt_pad_compatible("other","polisa_pad_01") and not HELPER.receipt_pad_compatible("cutlass","fake"),"receipt rejects unknown model/pad")
	var snapshot := {"crafts":{"a":{"parked":true,"capacity":4,"pilot_unit_id":"u"},"b":{"parked":true,"capacity":4,"pilot_unit_id":""}},"people":{"u":{"alive":true,"deployed":true,"boarding_pending":false,"fireteam_id":"ft1"},"v":{"alive":true,"deployed":true,"boarding_pending":false,"fireteam_id":"ft1"}},"membership":{"a":["u","v"],"b":[]}}
	check(HELPER.preview_handoff("a","b",PackedStringArray(["u","v"]),"u",snapshot).ok,"whole actual deployed team accepted")
	check(HELPER.preview_handoff("a","b",PackedStringArray(["u"]),"u",snapshot).ok,"known source pilot may leave temporary fireteam alone")
	snapshot.people.u.deployed=false
	check(not HELPER.preview_handoff("a","b",PackedStringArray(["u","v"]),"u",snapshot).ok,"no remote autoembark")
	snapshot.people.u.deployed=true; snapshot.people.u.boarding_pending=true
	check(not HELPER.preview_handoff("a","b",PackedStringArray(["u","v"]),"u",snapshot).ok,"pending presence reject")
	snapshot.people.u.boarding_pending=false; snapshot.membership.b=["u"]
	check(not HELPER.preview_handoff("a","b",PackedStringArray(["u","v"]),"u",snapshot).ok,"duplicate membership reject")
	print("POLISA_HELPER_RESULT checks=",count," failures=",failures)
	quit(1 if failures else 0)
