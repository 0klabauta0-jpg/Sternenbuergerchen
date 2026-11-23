extends SceneTree
## Wohncontainer auf der ECHTEN Heimatbasis (Hex-Boden): Kauf ueber den Adapter, Betten, Hexwege,
## Sperrmaske, Stellplatz-Pruefung, Speichern/Laden, Obergrenze. Ohne langen Kampagnenlauf.
const START = preload("res://scripts/meta/game_start_contract.gd")
const NAV = preload("res://scripts/meta/base_interior_navigation.gd")
const CAPACITY = preload("res://scripts/meta/base_capacity_layout.gd")
var passed := 0
var failed := 0
var flow: Node
var adapter: Node
var base: Node

func check(condition: bool, text: String) -> void:
	if condition: passed += 1
	else:
		failed += 1
		print("FAIL: " + text)

func _init() -> void: call_deferred("_run")

func _start(mode: String) -> void:
	START.request_start(self, "campaign", mode)
	flow = load("res://scenes/meta/meta_layer_test.tscn").instantiate(); root.add_child(flow)
	await process_frame
	adapter = flow.get("_singleplayer_runtime")
	base = adapter.get_base_personnel_runtime()

func _blocked() -> Dictionary:
	var blocked := {}
	for cell in base.get_ground_ship_blocked_cells().blocked_cells: blocked[cell] = true
	return blocked

func _reaches(from: Vector2i, to: Vector2i, blocked: Dictionary) -> bool:
	if blocked.has(to): return false
	var path: Array = load("res://scripts/terrain/terrain_pathfinder.gd").new().find_path_with_options(from, to, base.get_terrain_registry(), {"blocked_grids":blocked})
	return not path.is_empty() and Vector2i(path[-1]) == to

func _bed_cells(snapshot: Dictionary) -> Array:
	var cells: Array = []
	for bed: Dictionary in snapshot.layout.beds: cells.append(Vector2i(int(bed.grid[0]), int(bed.grid[1])))
	return cells

## Beide alten Betten, alle Bettplaetze, Terminals und der Zugang zu den Pads sind ueber echte Hexwege erreichbar.
func _everything_reachable(label: String) -> void:
	var layout: Dictionary = base.get_snapshot().layout
	var terrain: Node = base.get_terrain_registry()
	var blocked := _blocked()
	var spawn := Vector2i(int(layout.avatar_spawn_grid[0]), int(layout.avatar_spawn_grid[1]))
	var unreachable: Array = []
	for cell in _bed_cells(base.get_snapshot()):
		if not _reaches(spawn, cell, blocked): unreachable.append("Bett " + str(cell))
	for terminal: Dictionary in layout.terminals:
		if terminal.get("enabled", true) == false: continue
		# Terminals nahe am Landepad liegen im Schiffsfussabdruck: wie im Spiel den naechsten freien Punkt nehmen.
		var spot: Vector2 = base._navigation_graph.nearest_available_world(terrain.grid_to_world(Vector2i(int(terminal.grid[0]), int(terminal.grid[1]))))
		if not _reaches(spawn, terrain.world_to_grid(spot), blocked): unreachable.append("Terminal " + String(terminal.id))
	for pad: Dictionary in layout.landing_pads:
		var raw: Array = pad.get("interaction_grid", pad.grid)
		var world: Vector2 = base._navigation_graph.nearest_available_world(terrain.grid_to_world(Vector2i(int(raw[0]), int(raw[1]))))
		if not _reaches(spawn, terrain.world_to_grid(world), blocked): unreachable.append("Pad " + String(pad.id))
	check(unreachable.is_empty(), "%s: Betten, Terminals und Pads erreichbar (nicht erreichbar: %s)" % [label, str(unreachable)])

func _buy(request_id: String) -> Dictionary:
	return adapter.request_operation("campaign_build_housing", {"request_id":request_id})

func _credits() -> int:
	return int(adapter._supply.get_supply_snapshot().credits)

func _sorted_cells(cells: Array) -> Array:
	var result := cells.duplicate()
	result.sort_custom(func(a, b): return a.x < b.x or (a.x == b.x and a.y < b.y))
	return result

func _bed_ids(snapshot: Dictionary) -> Array:
	var ids: Array = []
	for bed: Dictionary in snapshot.layout.beds: ids.append(String(bed.id))
	ids.sort()
	return ids

func _run() -> void:
	await _start("new")
	adapter._supply._credits = 20000 # nur Fixture
	var leader := "campaign_leader"
	var terrain: Node = base.get_terrain_registry()
	var sim: Node = base.get_simulation_root()
	sim.set_physics_process(false)
	var offer: Dictionary = adapter._housing_offer()
	check(bool(offer.container) and int(offer.sites) >= 3, "Hex-Basis bietet Wohncontainer an, mindestens drei Stellplaetze (%s)" % str(offer))
	check(Array(base.get_snapshot().layout.beds).size() == 2 and base.get_recruitment_bed_capacity().beds == 2, "vor dem Bau: zwei Betten")
	_everything_reachable("vor dem Bau")
	# Person steht auf dem Stellplatz -> housing_site_busy, nichts bewegt sich
	var actor: Node2D = base.get_actor(leader)
	var home_position: Vector2 = actor.position
	actor.position = terrain.grid_to_world(Vector2i(CAPACITY.HEX_CONTAINER_SITES[0]) + Vector2i(32, 28))
	var busy: Dictionary = _buy("hex-busy")
	check(not busy.get("ok", false) and busy.get("reason") == "housing_site_busy" and not String(busy.get("message", "")).is_empty(), "Person auf dem Stellplatz: housing_site_busy mit Text (%s)" % str(busy))
	check(_credits() == 20000 and adapter._supply.get_campaign_housing_count() == 0 and Array(base.get_snapshot().layout.beds).size() == 2, "abgelehnter Kauf: keine Abbuchung, keine Betten")
	actor.position = home_position
	# Kauf
	var result: Dictionary = _buy("hex-1")
	check(result.get("ok", false), "Kauf gelingt: " + str(result))
	var snapshot: Dictionary = base.get_snapshot()
	check(_credits() == 19000 and adapter._supply.get_campaign_housing_count() == 1 and adapter._supply.get_campaign_bed_count() == 6, "Kauf: Credits -1000, sechs Betten")
	check(Array(snapshot.layout.beds).size() == 6 and base.get_recruitment_bed_capacity().beds == 6 and Array(snapshot.layout.campaign_housing).size() == 2, "Layout: sechs Betten, zwei Habitat-Kopien, Anwerbekapazitaet 6")
	var ids: Array = _bed_ids(snapshot)
	check(ids.has("container_01_bed_1") and ids.has("container_01_bed_4") and ids.size() == 6, "stabile Bett-Ids container_01_bed_1..4 (%s)" % str(ids))
	check(snapshot.layout.beds.all(func(bed): return String(bed.get("visual_kind", "")) != "field_bunk"), "keine Feldbetten")
	_everything_reachable("nach Container 1")
	# Wandzelle ist als Ziel gesperrt
	var offset: Vector3 = NAV.plane_at_grid(Vector2i(CAPACITY.HEX_CONTAINER_SITES[0]))
	var wall := Rect2(10.6 + offset.x, 4.1 + offset.z, 8.0, 3.5)
	var wall_cell := Vector2i(-99999, -99999)
	for cell: Vector2i in base.get_ground_ship_blocked_cells().blocked_cells:
		var plane := NAV.plane_at_grid(cell)
		if wall.has_point(Vector2(plane.x, plane.z)): wall_cell = cell; break
	check(wall_cell != Vector2i(-99999, -99999) and terrain.is_walkable(wall_cell), "Container-Fussabdruck steht in der Sperrmaske (Wandzelle %s)" % str(wall_cell))
	var into_wall: Dictionary = base.request_operation("base_move", {"unit_id":leader, "target_position":terrain.grid_to_world(wall_cell)})
	check(not into_wall.get("ok", false) and into_wall.get("reason") == "target_blocked", "Wandzelle als Ziel gesperrt (%s)" % str(into_wall))
	# Person geht in ein neues Bett und schlaeft
	var bed_id := "container_01_bed_3"
	var sleep: Dictionary = base.request_operation("base_sleep", {"unit_id":leader, "bed_id":bed_id})
	check(sleep.get("ok", false), "Person kann zum neuen Bett gehen: " + str(sleep))
	for i in range(6000):
		sim._physics_process(0.05)
		if base._states[leader].status == "sleeping": break
	check(base._states[leader].status == "sleeping" and base.get_snapshot().bed_occupants.get(bed_id) == leader, "Person schlaeft im neuen Container-Bett")
	# Speichern + Laden: gleicher Container, gleiche Sperrmaske, Schlafender bleibt
	var mask_before: Array = _sorted_cells(base.get_ground_ship_blocked_cells().blocked_cells)
	var planes_before: Array = Array(snapshot.layout.campaign_housing).map(func(h): return h.plane)
	var saved: Dictionary = flow.get("_campaign_start").call("save_home_checkpoint", flow, adapter, true)
	check(saved.get("ok", false), "Speichern mit Container und Schlafendem: " + str(saved.get("reason", "")))
	flow.queue_free(); await process_frame
	await _start("continue")
	terrain = base.get_terrain_registry()
	sim = base.get_simulation_root()
	sim.set_physics_process(false)
	var reloaded: Dictionary = base.get_snapshot()
	check(adapter._supply.get_campaign_housing_count() == 1 and adapter._supply.get_campaign_bed_count() == 6 and base.get_recruitment_bed_capacity().beds == 6, "Laden: ein Container, sechs Betten")
	check(_bed_ids(reloaded) == ids, "Laden: dieselben Bett-Ids")
	check(Array(reloaded.layout.campaign_housing).map(func(h): return h.plane) == planes_before, "Laden: Container steht am selben Platz")
	check(_sorted_cells(base.get_ground_ship_blocked_cells().blocked_cells) == mask_before, "Laden: dieselbe Sperrmaske (%d Zellen)" % mask_before.size())
	check(reloaded.bed_occupants.get(bed_id) == leader and base._states[leader].status == "sleeping", "Laden: Schlafender schlaeft weiter im selben Container-Bett")
	_everything_reachable("nach Laden")
	# Laufender Weg beim Bau: abgebrochen, danach neu befehlbar
	base.request_operation("base_wake", {"unit_id":leader})
	var layout: Dictionary = base.get_snapshot().layout
	var pad_raw: Array = Array(layout.landing_pads).back().get("interaction_grid", Array(layout.landing_pads).back().grid)
	var far: Vector2 = base._navigation_graph.nearest_available_world(terrain.grid_to_world(Vector2i(int(pad_raw[0]), int(pad_raw[1]))))
	var walk: Dictionary = base.request_operation("base_move", {"unit_id":leader, "target_position":far})
	for i in range(4): sim._physics_process(0.05)
	check(walk.get("ok", false) and base._states[leader].status == "moving", "Person ist unterwegs, als der zweite Container gebaut wird (%s)" % str(walk))
	var second: Dictionary = _buy("hex-2")
	check(second.get("ok", false), "zweiter Container gebaut: " + str(second))
	check(base._states[leader].status != "moving" and base._states[leader].action.is_empty(), "laufender Weg wurde abgebrochen")
	var again: Dictionary = base.request_operation("base_move", {"unit_id":leader, "target_position":far})
	check(again.get("ok", false), "Person ist nach dem Bau neu befehlbar: " + str(again))
	for i in range(3000):
		sim._physics_process(0.05)
		if base._states[leader].status != "moving": break
	check(base._states[leader].status == "outside" and base.get_actor(leader).position.distance_to(far) < 1.0, "Person kommt nach dem Bau am Ziel an, bleibt nirgends haengen (%s, Abstand %.1f)" % [str(base._states[leader].status), base.get_actor(leader).position.distance_to(far)])
	_everything_reachable("nach Container 2")
	# alle Stellplaetze nacheinander, danach Ablehnung mit Text
	var sites: int = CAPACITY.hex_container_site_count()
	for number in range(3, sites + 1):
		var next: Dictionary = _buy("hex-%d" % number)
		check(next.get("ok", false), "Container %d gebaut: %s" % [number, str(next)])
		_everything_reachable("nach Container %d" % number)
	check(adapter._supply.get_campaign_housing_count() == sites and base.get_recruitment_bed_capacity().beds == 2 + 4 * sites and _credits() == 19000 - 1000 * (sites - 1), "alle Stellplaetze belegt: Betten und Credits stimmen")
	var credits_full := _credits()
	var over: Dictionary = _buy("hex-over")
	check(not over.get("ok", false) and String(over.get("message", "")) == "Kein freier Stellplatz für einen weiteren Wohncontainer" and _credits() == credits_full, "naechster Kauf abgelehnt mit Text (%s)" % str(over))
	flow.queue_free(); await process_frame
	print("CAMPAIGN_HOUSING_HEX passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
