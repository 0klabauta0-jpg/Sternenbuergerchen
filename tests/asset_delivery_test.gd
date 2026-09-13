extends SceneTree
## Run in the working project or a fresh source snapshot without assets/local.
const Geo = preload("res://scripts/world/world_geometry.gd")
const CURATED_SHIP := "res://assets/curated/space/craft_cargoA.glb"
const LOCAL_SHIPS := {
	"craft_cargoA":"res://assets/local/entersaebel.glb",
	"freibeuter":"res://assets/local/freibeuter/freibeuter.glb",
	"geier":"res://assets/local/geier/geier.glb"
}
var checks := 0
var failures := 0

func _initialize() -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var require_curated := "--require-curated" in OS.get_cmdline_user_args()
	for id: String in LOCAL_SHIPS:
		var local_available := ResourceLoader.exists(LOCAL_SHIPS[id])
		if require_curated:
			_check(not local_available,id+" local ship absent in isolated delivery")
		var model := Geo.asset(stage, id, Vector3.ZERO, Vector3(9, 3, 12))
		var meshes := model.find_children("*", "MeshInstance3D", true, false)
		var rendered := not meshes.is_empty()
		for mesh: MeshInstance3D in meshes:
			rendered = rendered and mesh.mesh != null and mesh.get_aabb().size.length_squared() > 0.0
		_check(rendered,id+" has nonempty mesh geometry")
		var actual := (model.get_child(0) as Node).scene_file_path if model.get_child_count()>0 else ""
		var expected: String=LOCAL_SHIPS[id] if local_available else CURATED_SHIP
		_check(actual==expected,id+" instantiated intended local or curated scene")
		var bounds:=Geo._bounds(model,Transform3D.IDENTITY)
		_check(absf(bounds.size.z-12.0)<0.01 and absf(bounds.position.y)<0.01,id+" has normalized length and ground contact")
		print("ASSET_DELIVERY ",id," scene=",actual," meshes=",meshes.size()," valid=",rendered," bounds=",bounds)
	stage.free()
	print("ASSET_DELIVERY_RESULT checks=",checks," failures=",failures," require_curated=",require_curated)
	quit(0 if failures == 0 else 1)

func _check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error("ASSET_DELIVERY_FAIL "+label)
