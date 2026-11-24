extends RefCounted
## Domain checks for the private active checkpoint store. This helper does not
## enable saving: full scene reconstruction and one atomic global publish are
## still mandatory before the store may be exposed to a campaign.
const WORLD = preload("res://scripts/mission/campaign_active_restore_preflight.gd")
const SCENE = preload("res://scripts/mission/campaign_active_scene_preflight.gd")
const TRANSACTION = preload("res://scripts/mission/campaign_active_world_transaction.gd")

static func validate_live(payload: Dictionary, flow: Node, adapter: Node) -> Dictionary:
	if payload.size()!=2 or payload.get("schema")!="campaign_active_checkpoint.v1" or not payload.get("components") is Dictionary: return {"ok":false,"reason":"invalid_active_checkpoint"}
	if not is_instance_valid(flow) or not is_instance_valid(adapter): return {"ok":false,"reason":"campaign_unavailable"}
	var world: Dictionary = WORLD.prepare(payload.components,adapter)
	if not world.get("ok",false): return world
	var mission: Node = flow.get("_active_mission")
	var scene: Dictionary = SCENE.prepare(mission,payload.components)
	# Luftrollen 5b-1: dieselbe Luftblock-Pruefung wie beim Laden, gegen die lebende Mission; Quelle ist der lebende Kampagnen-Root, Kandidaten aus der Welt-Vorbereitung.
	var air: Dictionary = {"ok":true}
	if scene.get("ok",false) and payload.components.has("air_sortie") and payload.components.air_sortie is Dictionary: air = TRANSACTION.prepare_air(payload.components.air_sortie,String(payload.components.identity.location_id),mission,world,adapter.get("_simulation"))
	world.root.free()
	if not scene.get("ok",false): return scene
	if not air.get("ok",false): return air
	return SCENE.validate(scene)
