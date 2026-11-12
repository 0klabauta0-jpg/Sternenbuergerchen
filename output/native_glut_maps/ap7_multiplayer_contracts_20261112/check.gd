extends SceneTree
const SNAPSHOT = preload("res://scripts/multiplayer/multiplayer_snapshot_contract.gd")
const COMMAND = preload("res://scripts/multiplayer/multiplayer_command_contract.gd")
class SnapshotSpy extends SNAPSHOT:
	var builds := 0
	func build_state_snapshot(data: Dictionary) -> Dictionary:
		builds += 1
		return super.build_state_snapshot(data)
var checks := 0
var failures := 0
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS " if ok else "FAIL ",label)
func _init() -> void:
	var snapshots := SnapshotSpy.new()
	var commands := COMMAND.new()
	var valid := {"schema_version":1,"tick":5,"units":[{"unit_id":"known","position":Vector2(1,2)}]}
	check(snapshots.validate_for_apply(valid,4).get("accepted",false),"actual INT1 snapshot keeps existing normalised shape")
	snapshots.builds = 0
	var rejected := true
	for version in [2,0,-1,1.0,"1",true,null]:
		var candidate := {"schema_version":version,"tick":6,"units":[]}
		var result: Dictionary = snapshots.validate_for_apply(candidate,4)
		rejected = rejected and not result.get("accepted",false) and result.get("reason") == "unsupported_snapshot_version"
	check(rejected and snapshots.builds == 0,"unknown or malformed explicit version rejects before any normalisation")
	var legacy := snapshots.validate_for_apply({"tick":7,"units":[]},4)
	check(legacy.get("accepted",false) and legacy.snapshot.schema_version == 1,"missing version remains explicit LegacyV1 compatibility")
	var original := valid.duplicate(true)
	check(not snapshots.validate_for_apply(valid,5).get("accepted",true) and valid == original,"existing out-of-order guard and source immutability remain")
	var move := {"command_type":"move_to_position","unit_id":"a","team_id":"blue","target_position":Vector2(3,4),"facing_angle":0.5,"security_mode":"facing"}
	var host := {"peer_role":"host"}
	check(commands.validate(move,host).get("accepted",false),"legitimate Move target/facing intent remains accepted")
	var authority_rejected := true
	for key in ["occupant_by_grid","units_by_id","reservation_schema_version","committed_segments","committed_corridor_grants","admission_slots_by_grid","_hex_lifecycle","hex_ground","hex_state","visibility","visibility_state","visible","detection_state","reservations"]:
		var direct := move.duplicate(true); direct[key] = {}
		var nested := move.duplicate(true); nested.metadata = {"samples":[{"wrapped":{key:{}}}]}
		authority_rejected = authority_rejected and not commands.validate(direct,host).get("accepted",true) and not commands.validate(nested,host).get("accepted",true)
	check(authority_rejected,"actual Ground plus targeted sight/reservation keys reject at top and nested Dictionary/Array levels")
	var geometry := move.duplicate(true)
	geometry.metadata = {"target_position":Vector2(5,6),"lz_position":Vector2(7,8),"world_polygon":[Vector2.ZERO,Vector2.RIGHT,Vector2.ONE],"tile_positions":[Vector2i(1,2)],"facing_angle":1.5,"security_mode":"facing","notes":{"health":"informational legacy metadata"}}
	geometry.metadata["coordinate_notes"] = {Vector2i(1,2):"legacy non-string metadata key"}
	var intent := {"contract_category":"commander_intent","command_id":"ap7_intent","verb":"move","team_id":"blue","fireteam_id":"ft1","target_position":Vector2(3,4),"security_mode":"facing","metadata":geometry.metadata.duplicate(true)}
	check(commands.validate(geometry,host).get("accepted",false) and commands.validate(intent,host).get("accepted",false),"real CommanderIntent and nested intent geometry/unrelated metadata retain compatibility")
	var deep := move.duplicate(true)
	var cursor := deep
	for index in range(20):
		cursor["notes"] = {}
		cursor = cursor.notes
	var depth_result := commands.validate(deep,host)
	check(not depth_result.get("accepted",true) and depth_result.get("reason") == "authority_payload_depth_limit","excessive nesting rejects clearly without silent cutoff")
	var wide := move.duplicate(true)
	wide.metadata = range(4100)
	var wide_result := commands.validate(wide,host)
	check(not wide_result.get("accepted",true) and wide_result.get("reason") == "authority_payload_node_limit","excessive payload nodes reject clearly without skipping late values")
	var cyclic := move.duplicate(true)
	cyclic.metadata = {}; cyclic.metadata.self = cyclic.metadata
	var cyclic_result := commands.validate(cyclic,host)
	check(not cyclic_result.get("accepted",true) and cyclic_result.get("reason") == "authority_payload_depth_limit","bounded raw walk rejects a cycle before deep-copy/category parsing")
	cyclic.metadata.erase("self")
	print("AP7_MULTIPLAYER_CONTRACT_RESULT checks=%d failures=%d full_ap7=false"%[checks,failures])
	quit(1 if failures else 0)
