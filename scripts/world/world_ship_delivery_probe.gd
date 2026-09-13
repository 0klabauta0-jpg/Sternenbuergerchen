extends SceneTree
## Can run in a minimal source snapshot containing curated assets only.
const Ship=preload("res://scripts/world/world_ship.gd")
const Geo=preload("res://scripts/world/world_geometry.gd")
const Layout=preload("res://scripts/core/world_layout.gd")
var checks:=0
var failures:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,label: String) -> void:
	checks+=1
	if not value:failures+=1;push_error(label)
func run() -> void:
	check(not DirAccess.dir_exists_absolute("res://assets/local"),"private assets absent")
	for model in ["cutlass","vulture"]:
		var stage:=Node3D.new();root.add_child(stage)
		var craft:=Ship.build(stage,model)
		var profile:=Layout.ship_profile(model)
		check(craft.get_child(0).scene_file_path=="res://assets/curated/space/craft_cargoA.glb","curated source "+model)
		var bounds:=Geo._bounds(craft,Transform3D.IDENTITY)
		check(bounds.size.x<=float(profile.size[0])+0.01 and bounds.size.z<=float(profile.size[1])+0.01,"whole fallback fits nav profile "+model)
		Ship.present(stage,{"model":model,"mode":"landed","yaw":0.0,"turret_yaw":0.7,"seats":{"gunner":"jaro"}},{"jaro":{"assignment":"aboard"}})
		if model=="cutlass":
			check(craft.has_meta("turret"),"fallback has turret pivot")
			check(is_equal_approx((craft.get_meta("turret") as Node3D).rotation.y,0.7),"fallback turret follows snapshot")
			check((craft.get_meta("gunner") as Node3D).visible,"fallback occupied gunner")
		print("SHIP_FALLBACK ",model," bounds ",bounds)
		stage.free()
	print("SHIP_DELIVERY_CHECKS ",checks," failures ",failures);quit(0 if failures==0 else 1)
