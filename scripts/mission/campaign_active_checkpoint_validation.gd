extends RefCounted
## Domain checks for the private active checkpoint store. This helper does not
## enable saving: full scene reconstruction and one atomic global publish are
## still mandatory before the store may be exposed to a campaign.
const WORLD = preload("res://scripts/mission/campaign_active_restore_preflight.gd")
const SCENE = preload("res://scripts/mission/campaign_active_scene_preflight.gd")

static func validate_live(payload: Dictionary, flow: Node, adapter: Node) -> Dictionary:
	if payload.size()!=2 or payload.get("schema")!="campaign_active_checkpoint.v1" or not payload.get("components") is Dictionary: return {"ok":false,"reason":"invalid_active_checkpoint"}
	if not is_instance_valid(flow) or not is_instance_valid(adapter): return {"ok":false,"reason":"campaign_unavailable"}
	var world: Dictionary = WORLD.prepare(payload.components,adapter)
	if not world.get("ok",false): return world
	var mission: Node = flow.get("_active_mission")
	var scene: Dictionary = SCENE.prepare(mission,payload.components)
	world.root.free()
	if not scene.get("ok",false): return scene
	return SCENE.validate(scene)
