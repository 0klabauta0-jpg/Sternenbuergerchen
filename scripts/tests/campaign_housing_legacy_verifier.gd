extends SceneTree
## Alter Bettbeleg (Einzelbett, 100/500 Cr) an der ECHTEN Hex-Basis: der Beleg laedt ohne neue Abbuchung, wird zum
## Alt-Gebaeude (zwei Betten, Einzelkopie auf Stellplatz 1), Schlaefer und Personen bleiben gueltig und nie im Fussabdruck.
## Die Basis-Personalliste liegt im Hex-Stand unter hex_tactical.base_personnel (nicht oben im Stand).
const START = preload("res://scripts/meta/game_start_contract.gd")
const STORE = preload("res://scripts/meta/campaign_checkpoint_store.gd")
const CAPACITY = preload("res://scripts/meta/base_capacity_layout.gd")
var failed := 0
var flow: Node
var adapter: Node
var base: Node
var sim: Node
func check(value: bool, label: String) -> void:
	print(("PASS: " if value else "FAIL: ") + label)
	if not value: failed += 1
func _init() -> void: call_deferred("run")

func _boot(mode: String) -> bool:
	START.request_start(self, "campaign", mode)
	flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	adapter = flow.get("_singleplayer_runtime")
	if adapter == null:
		check(false, "Stand (%s) laedt (Fehler: %s)" % [mode, String(flow.get("_campaign_start").get("error_message"))])
		return false
	base = adapter.get_base_personnel_runtime()
	sim = base.get_simulation_root()
	sim.set_physics_process(false)
	return true

func _free() -> void:
	flow.queue_free(); await process_frame

## Frischer Stand, dann der alte Beleg (Einzelbett) eingeschrieben; `before` darf die Basis vorher veraendern.
func _write_legacy_checkpoint(before: Callable) -> bool:
	if not await _boot("new"): return false
	if before.is_valid(): before.call()
	var saved: Dictionary = flow.get("_campaign_start").save_home_checkpoint(flow, adapter, true)
	check(saved.get("ok", false), "frischer Stand gespeichert: " + str(saved.get("reason", "")))
	var loaded: Dictionary = STORE.load_checkpoint()
	if not loaded.get("ok", false): check(false, "frischer Stand lesbar"); await _free(); return false
	var payload: Dictionary = loaded.payload
	var signature := JSON.stringify({"operation":"campaign_build_bed","payload":{}}, "", true)
	payload.supply.requests["old-bed-1"] = {"signature":signature,"result":{"ok":true,"operation":"campaign_build_bed","request_id":"old-bed-1","bed_count":3,"cost":100}}
	var modified: Dictionary = STORE.save_checkpoint(payload)
	check(modified.get("ok", false), "alter Bettbeleg-Stand akzeptiert: " + str(modified.get("reason", "")))
	await _free()
	return modified.get("ok", false)

func _in_footprint(unit_id: String) -> bool:
	var blocked := {}
	for cell in base.get_ground_ship_blocked_cells().blocked_cells: blocked[cell] = true
	return blocked.has(base.get_terrain_registry().world_to_grid(base.get_actor(unit_id).position))

func _check_old_purchase() -> void:
	check(adapter._supply.get_campaign_housing_count() == 1 and adapter._supply.get_campaign_bed_count() == 4, "alter Beleg wird Alt-Gebaeude ohne neue Abbuchung (1 Gebaeude, 4 Betten)")
	var snapshot: Dictionary = base.get_snapshot()
	check(Array(snapshot.layout.beds).size() == 4 and base.get_recruitment_bed_capacity().beds == 4, "Bettenzahl im Layout und in der Anwerbekapazitaet: 4 (2 + 2 je Alt-Gebaeude)")
	check(Array(snapshot.layout.campaign_housing).size() == 1 and String(snapshot.layout.campaign_housing[0].id) == "campaign_habitat_01", "genau ein Alt-Gebaeude (Einzelkopie) auf Stellplatz 1")
	var ids: Array = Array(snapshot.layout.beds).map(func(bed): return String(bed.id))
	check(ids.has("field_bed_01") and ids.has("field_bed_02"), "Alt-Betten field_bed_01/02 vorhanden (%s)" % str(ids))

## Vor dem Speichern: die Person steht genau dort, wo spaeter die Wand des Alt-Gebaeudes liegt.
func _place_leader_on_future_wall() -> void:
	var terrain: Node = base.get_terrain_registry()
	var infrastructure := {"campaign_housing":1, "campaign_housing_beds":[2], "hex_containers":true}
	var houses: Array = CAPACITY.hex_container_housing(base._source_layout, terrain, infrastructure).houses
	var before_mask := {}
	for cell in base.get_ground_ship_blocked_cells().blocked_cells: before_mask[cell] = true
	base._navigation_graph.set_campaign_housing(houses)
	var after: Array = Array(base.get_ground_ship_blocked_cells().blocked_cells)
	base._navigation_graph.set_campaign_housing([])
	var wall := Vector2i(-99999, -99999)
	for cell: Vector2i in after:
		if not before_mask.has(cell) and terrain.is_walkable(cell): wall = cell; break
	check(wall != Vector2i(-99999, -99999), "Fixture: Wandzelle des kuenftigen Alt-Gebaeudes gefunden (%s)" % str(wall))
	var moved: Dictionary = sim._hex_ground_runtime.relocate_unit("campaign_leader", wall, sim.get_hex_ground_revision())
	check(moved.get("ok", false), "Fixture: Person auf die Wandzelle gesetzt: " + str(moved))
	for i in range(3): sim._physics_process(0.05)
	print("FIXTURE Person auf Wandzelle ", wall, " Actor-Zelle ", terrain.world_to_grid(base.get_actor("campaign_leader").position))

func run() -> void:
	# A: Schlaefer im Alt-Bett field_bed_01 (Beleg alt, Schlaf im neuen Alt-Gebaeude), Speichern und erneut Laden.
	if not await _write_legacy_checkpoint(Callable()): quit(1); return
	if not await _boot("continue"): quit(1); return
	_check_old_purchase()
	var sleep: Dictionary = base.request_operation("base_sleep", {"unit_id":"campaign_leader", "bed_id":"field_bed_01"})
	check(sleep.get("ok", false), "Person geht ins Alt-Bett field_bed_01: " + str(sleep))
	for i in range(6000):
		sim._physics_process(0.05)
		if base._states.campaign_leader.status == "sleeping": break
	check(base._states.campaign_leader.status == "sleeping" and base.get_snapshot().bed_occupants.get("field_bed_01") == "campaign_leader", "Person schlaeft im Alt-Bett field_bed_01")
	var saved: Dictionary = flow.get("_campaign_start").save_home_checkpoint(flow, adapter, true)
	check(saved.get("ok", false), "Speichern mit Schlaefer im Alt-Bett: " + str(saved.get("reason", "")))
	await _free()
	if not await _boot("continue"): quit(1); return
	_check_old_purchase()
	check(base.get_snapshot().bed_occupants.get("field_bed_01") == "campaign_leader" and base._states.campaign_leader.status == "sleeping", "Schlaefer liegt nach dem Laden weiter im Alt-Bett field_bed_01")
	await _free()
	# B: Person steht beim Speichern dort, wo jetzt die Wand des Alt-Gebaeudes steht.
	if not await _write_legacy_checkpoint(_place_leader_on_future_wall): quit(1); return
	if not await _boot("continue"): quit(1); return
	_check_old_purchase()
	var leader_cell: Vector2i = base.get_terrain_registry().world_to_grid(base.get_actor("campaign_leader").position)
	print("NACH LADEN Person: Zelle ", leader_cell, " Status ", base._states.campaign_leader.status, " Hex-Zelle ", sim._hex_ground_runtime.get_unit_grid("campaign_leader"))
	check(not _in_footprint("campaign_leader") and base._states.campaign_leader.status in ["outside", "sleeping"], "Person steht nach dem Laden NICHT im Fussabdruck des Alt-Gebaeudes")
	await _free()
	if failed == 0: print("CAMPAIGN_HOUSING_LEGACY_PASS")
	quit(0 if failed == 0 else 1)
