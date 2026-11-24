extends SceneTree
## Neue Gebaeudemodelle der Heimatbasis (Wunsch 24.11.): Zuordnung, Lage, Umschalt-Taste, Bedienbarkeit unveraendert.
## Kopflos, rechnend, echte Kampagnen-Heimatbasis. Es wird nur gelesen und der Schalter umgelegt.
const OVERRIDES := preload("res://scripts/meta/structure_model_overrides.gd")
const BASE_NAV := preload("res://scripts/meta/base_interior_navigation.gd")
const TOLERANCE: float = 0.5
var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func _check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
	print(("PASS " if value else "FAIL ") + label)


func _bounds(node: Node) -> AABB:
	var result := AABB()
	var first := true
	for n in node.find_children("*", "MeshInstance3D", true, false):
		var m := n as MeshInstance3D
		var a: AABB = m.global_transform * m.get_aabb()
		result = a if first else result.merge(a)
		first = false
	return result


func _rect_xz(box: AABB) -> Rect2:
	return Rect2(box.position.x, box.position.z, box.size.x, box.size.z)


func _press(code: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		root.push_input(e)
		await process_frame


## Hoehe der obersten Flaeche des Modells an einem Weltpunkt (x, z), per Strahl von oben auf das Dreiecksnetz.
func _floor_world_y(holder: Node3D, x: float, z: float) -> float:
	var best := -INF
	for n in holder.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var tm: TriangleMesh = mi.mesh.generate_triangle_mesh()
		var inv: Transform3D = mi.global_transform.affine_inverse()
		var hit: Dictionary = tm.intersect_ray(inv * Vector3(x, 20.0, z), (inv.basis * Vector3.DOWN).normalized())
		if not hit.is_empty():
			best = maxf(best, (mi.global_transform * Vector3(hit["position"])).y)
	return best


func _plane_to_grid(p: Vector2) -> Vector2i:
	var gy: int = roundi(p.y * 4.0 / (sqrt(3.0) * 0.5))
	return Vector2i(roundi(p.x * 4.0 - float(gy) * 0.5), gy)


func _check_replace(base: Control, stage: Node3D, layout: Dictionary, entry: Dictionary, holder: Node3D, old_nodes: Dictionary, person_height: float) -> void:
	var id := String(entry.get("id", ""))
	var old_id := String(entry.get("replaces", ""))
	var s: float = float(entry.get("scale", 1.0))
	var plane := Vector2.INF
	for a in layout.get("assets", []):
		if String(Dictionary(a).get("id", "")) == old_id:
			var p: Array = Dictionary(a).get("plane", [0, 0])
			plane = Vector2(float(p[0]), float(p[1]))
	_check(plane != Vector2.INF, "ersetztes Bestandsgebaeude im Layout: %s" % old_id)
	var off: Array = entry.get("offset", [0, 0, 0])
	var o := Vector2(plane.x + float(off[0]), plane.y + float(off[2]))
	_check(holder.position.distance_to(Vector3(o.x, float(off[1]), o.y)) < 0.001, "%s steht an der Stelle von %s plus Versatz (%.2f / %.2f)" % [id, old_id, o.x, o.y])
	_check(absf(holder.rotation.y) < 0.001, "%s: Eingang zur selben Seite (+z) wie das Habitat (Drehung 0)" % id)
	_check(Vector2(float(off[0]), float(off[2])).length() <= 0.6 + 0.0001, "%s: Versatz gegen die alte Mitte hoechstens 0,6 m (%.3f m)" % [id, Vector2(float(off[0]), float(off[2])).length()])
	_check(not old_nodes.has(old_id) and holder.visible, "%s: altes %s nicht in der Szene, neues Modell sichtbar" % [id, old_id])
	base.set("_capacity_visual_signature", "")
	base.call("_sync_capacity_visuals", stage)
	_check(not old_nodes.has(old_id) and stage.find_children("*" + old_id + "*", "", true, false).is_empty() and holder.visible, "%s: auch nach einem Sync kommt das alte %s nicht zurueck (kein Knoten, auch kein Bauplatz)" % [id, old_id])
	# Innenboden auf Lauf-Hoehe der Navigation (0,165 m).
	var probe: Array = entry.get("floor_probe_model", [0.1, -0.1])
	var floor_y: float = _floor_world_y(holder, holder.position.x + float(probe[0]) * s, holder.position.z - float(probe[1]) * s)
	_check(absf(floor_y - BASE_NAV.standing_y(Vector3(plane.x, 0.0, plane.y))) <= 0.03, "%s: Innenboden %.3f m auf Lauf-Hoehe %.3f m (+-0,03)" % [id, floor_y, BASE_NAV.standing_y(Vector3(plane.x, 0.0, plane.y))])
	# Grundriss innen (Rahmen aus der Vermessung, Modellmasse).
	var interior: Array = entry.get("interior_model", [])
	var rect := Rect2(Vector2(holder.position.x + float(interior[0]) * s, holder.position.z - float(interior[3]) * s), Vector2((float(interior[1]) - float(interior[0])) * s, (float(interior[3]) - float(interior[2])) * s))
	print("INFO %s Innenraum x %.2f..%.2f  z %.2f..%.2f" % [id, rect.position.x, rect.end.x, rect.position.y, rect.end.y])
	var targets: Dictionary = {}
	for t in layout.get("terminals", []):
		var td: Dictionary = t
		if String(td.get("id", "")) in ["personnel", "jobs"]:
			var anchor: Array = td.get("model_anchor_plane", [])
			if anchor.size() == 2:
				targets["Terminal %s Anker" % td.id] = Vector2(float(anchor[0]), float(anchor[1]))
			var tg: Array = td.get("grid", [])
			var tpl: Vector3 = BASE_NAV.plane_at_grid(Vector2i(int(tg[0]), int(tg[1])))
			targets["Terminal %s Benutzen-Stelle" % td.id] = Vector2(tpl.x, tpl.z)
	for b in layout.get("beds", []):
		var bd: Dictionary = b
		if String(bd.get("room_id", "")) != old_id:
			continue
		for key in ["sleep_plane", "rest_plane"]:
			var bp: Array = bd.get(key, [])
			if bp.size() == 2:
				targets["%s %s" % [bd.get("id", "bed"), key]] = Vector2(float(bp[0]), float(bp[1]))
	_check(targets.size() >= 6, "Ziele gesammelt: 2 Terminals mit je 2 Punkten, Schlafplaetze (%d)" % targets.size())
	var inner := rect.grow(-0.05)
	for key in targets:
		var q: Vector2 = targets[key]
		var edge: float = minf(minf(q.x - rect.position.x, rect.end.x - q.x), minf(q.y - rect.position.y, rect.end.y - q.y))
		_check(inner.has_point(q), "%s innerhalb des Pod-Grundrisses, nicht in einer Wand (Abstand zur Wand %.2f m)" % [key, edge])
	# Schlafplaetze auf den zwei Pod-Betten, Auftrags-Terminal am Bildschirm des Pods.
	var bed_centers: Array = entry.get("bed_model", [])
	var bed_index := 0
	for b in layout.get("beds", []):
		var bd2: Dictionary = b
		if String(bd2.get("room_id", "")) != old_id or bed_index >= bed_centers.size():
			continue
		var bc: Array = bed_centers[bed_index]
		var bed_world := Vector2(holder.position.x + float(bc[0]) * s, holder.position.z - float(bc[1]) * s)
		var sp: Array = bd2.get("sleep_plane", [0, 0])
		var d_bed: float = Vector2(float(sp[0]), float(sp[1])).distance_to(bed_world)
		_check(d_bed <= 0.1, "%s liegt auf einem Pod-Bett (Abstand %.3f m zur Bettmitte)" % [bd2.get("id", "bed"), d_bed])
		_check(absf(float(bd2.get("surface_y", 0.0)) - (float(entry.get("bed_top_model", 0.0)) * s + holder.position.y)) <= 0.05, "%s: Bettflaeche %.3f m auf Hoehe der Pod-Betten" % [bd2.get("id", "bed"), float(bd2.get("surface_y", 0.0))])
		bed_index += 1
	_check(bed_index == bed_centers.size() and bed_index == 2, "genau zwei Betten zugeordnet (%d)" % bed_index)
	var tv: Array = entry.get("tv_model", [0.0, 0.0])
	var tv_world := Vector2(holder.position.x + float(tv[0]) * s, holder.position.z - float(tv[1]) * s)
	var jobs_anchor := Vector2.INF
	for t in layout.get("terminals", []):
		if String(Dictionary(t).get("id", "")) == "jobs":
			var ja: Array = Dictionary(t).get("model_anchor_plane", [])
			jobs_anchor = Vector2(float(ja[0]), float(ja[1]))
	_check(jobs_anchor != Vector2.INF and jobs_anchor.distance_to(tv_world) <= 0.25, "jobs (Smart Mobile) liegt am Pod-Bildschirm (Abstand %.2f m)" % (jobs_anchor.distance_to(tv_world) if jobs_anchor != Vector2.INF else -1.0))
	# Beleg: der Kampagnenstart laedt die neuen Lagen aus base_interior_navigation.json (die groben Karten werden nicht gelesen).
	var jobs_grid: Array = []
	var coarse_layout: Dictionary = BASE_NAV.layout("res://maps/campaign_intro_base.json")
	for t in coarse_layout.get("terminals", []):
		if String(Dictionary(t).get("id", "")) == "jobs":
			jobs_grid = Dictionary(t).get("grid", [])
	var live_jobs_grid: Array = []
	for t in layout.get("terminals", []):
		if String(Dictionary(t).get("id", "")) == "jobs":
			live_jobs_grid = Dictionary(t).get("grid", [])
	_check(jobs_grid == live_jobs_grid and not live_jobs_grid.is_empty() and int(live_jobs_grid[0]) == 41, "Kampagnenstart-Pfad (campaign_intro_base.json) liefert die neue jobs-Lage %s, nicht die alte der groben Karte" % str(live_jobs_grid))
	# Erreichbarkeit vom Startpunkt der Figur aus (Wegsuche der Basis-Navigation).
	var personnel: Node = base.call("_personnel_runtime")
	var nav_graph: Object = personnel.get("_navigation_graph") if personnel != null else null
	var terrain0: Node = base.get("_terrain")
	if nav_graph != null:
		var spawn_cell: Array = layout.get("avatar_spawn_grid", [36, 40])
		var from_world: Vector2 = terrain0.call("grid_to_world", Vector2i(int(spawn_cell[0]), int(spawn_cell[1])))
		var goals: Dictionary = {}
		for t in layout.get("terminals", []):
			var tg2: Array = Dictionary(t).get("grid", [])
			if String(Dictionary(t).get("id", "")) == "flightdeck":
				continue  # liegt auf dem Landepad; war schon vor diesem Auftrag nicht ueber die Wegsuche erreichbar
			goals["Terminal %s" % Dictionary(t).get("id", "")] = Vector2i(int(tg2[0]), int(tg2[1]))
		for b in layout.get("beds", []):
			var bg: Array = Dictionary(b).get("grid", [])
			if bg.size() == 2 and String(Dictionary(b).get("room_id", "")) == old_id:
				goals["Bett %s" % Dictionary(b).get("id", "")] = Vector2i(int(bg[0]), int(bg[1]))
		for key in goals:
			var cell3: Vector2i = goals[key]
			var tile3: Variant = terrain0.call("get_tile_at_grid", cell3)
			var path: Array = nav_graph.call("find_world_path", from_world, terrain0.call("grid_to_world", cell3))
			_check(tile3 != null and bool(tile3.walkable) and not path.is_empty(), "%s: Benutzen-Stelle %s begehbar und vom Startpunkt erreichbar (Weg %d Punkte)" % [key, str(cell3), path.size()])
	else:
		_check(false, "Wegsuche der Basis-Navigation erreichbar")
	# Tuer: Mitte gegen das Feld des alten Eingangs, begehbare Felder bis hinter die Tuer.
	var door: Array = entry.get("door_model", [0.0, 0.07])
	var door_x: float = holder.position.x + float(door[0]) * s
	var door_half: float = float(door[1]) * s
	var door_grid: Array = []
	for it in layout.get("interiors", []):
		if String(Dictionary(it).get("id", "")) == old_id:
			door_grid = Dictionary(it).get("door_grid", [])
	var door_plane3: Vector3 = BASE_NAV.plane_at_grid(Vector2i(int(door_grid[0]), int(door_grid[1])))
	_check(absf(door_x - door_plane3.x) <= door_half - 0.05, "%s: Tuermitte x %.3f liegt am alten Eingangsfeld x %.3f (Tuerhalbbreite %.2f m)" % [id, door_x, door_plane3.x, door_half])
	var terrain: Node = base.get("_terrain")
	var tile: Variant = terrain.call("get_tile_at_grid", Vector2i(int(door_grid[0]), int(door_grid[1])))
	_check(tile != null and bool(tile.walkable), "%s: Eingangsfeld %s ist begehbar" % [id, str(door_grid)])
	var waypoint := Vector2(door_x, rect.end.y - 0.1)
	_check(inner.has_point(waypoint), "%s: Punkt hinter der Tuer liegt im Innenraum" % id)
	var walk_ok := true
	var steps := 12
	for i in steps + 1:
		var pt: Vector2 = Vector2(door_x, door_plane3.z).lerp(waypoint, float(i) / float(steps))
		var cell: Variant = terrain.call("get_tile_at_grid", _plane_to_grid(pt))
		if cell == null or not bool(cell.walkable):
			walk_ok = false
			print("INFO nicht begehbar bei %s" % str(pt))
	_check(walk_ok, "%s: Weg Eingangsfeld -> Punkt hinter der Tuer nur ueber begehbare Felder" % id)
	# Trennwaende und Tuer: der echte Weg (Wegsuche) vom Eingangsfeld zu Betten und Terminals muss durch die Luecken fuehren.
	var part_x: Array = entry.get("partition_x_model", [])
	var gap_y: Array = entry.get("partition_door_y_model", [0.0, 0.0])
	var personnel2: Node = base.call("_personnel_runtime")
	var nav2: Object = personnel2.get("_navigation_graph") if personnel2 != null else null
	if nav2 != null:
		var door_world: Vector2 = terrain.call("grid_to_world", Vector2i(int(door_grid[0]), int(door_grid[1])))
		var front_z: float = rect.end.y
		for key in targets:
			if not (String(key).contains("Benutzen-Stelle") or String(key).contains("rest_plane")):
				continue
			var q3: Vector2 = targets[key]
			var goal_cell: Vector2i = _plane_to_grid(q3)
			var goal_world: Vector2 = terrain.call("grid_to_world", goal_cell)
			var way: Array = nav2.call("find_world_path", door_world, goal_world)
			var bad := ""
			if way.is_empty():
				bad = "kein Weg"
			var prev := Vector2.INF
			for w in way:
				var cell4: Vector2i = terrain.call("world_to_grid", Vector2(w))
				var pl: Vector3 = BASE_NAV.plane_at_grid(cell4)
				var cur := Vector2(pl.x, pl.z)
				if prev != Vector2.INF:
					# Vordere Wand: Kreuzung der Linie z = Innenkante vorn nur durch die Tuer.
					if (prev.y - front_z) * (cur.y - front_z) < 0.0:
						var tt: float = (front_z - prev.y) / (cur.y - prev.y)
						var xc: float = lerpf(prev.x, cur.x, tt)
						if absf(xc - door_x) > door_half:
							bad += " Vorderwand bei x=%.2f" % xc
					for px in part_x:
						var wx: float = holder.position.x + float(px) * s
						if (prev.x - wx) * (cur.x - wx) < 0.0:
							var t2: float = (wx - prev.x) / (cur.x - prev.x)
							var zc: float = lerpf(prev.y, cur.y, t2)
							var gz0: float = holder.position.z - float(gap_y[1]) * s
							var gz1: float = holder.position.z - float(gap_y[0]) * s
							if zc < gz0 - 0.05 or zc > gz1 + 0.05:
								bad += " Trennwand x=%.2f bei z=%.2f" % [wx, zc]
				prev = cur
			_check(bad.is_empty(), "Weg Eingang -> %s fuehrt nur durch Tuer und Tuerluecken (%d Punkte)%s" % [key, way.size(), (" FEHLER:" + bad) if not bad.is_empty() else ""])


func _nav_of(base: Control) -> Object:
	var personnel: Node = base.call("_personnel_runtime")
	return personnel.get("_navigation_graph") if personnel != null else null


func _spawn_world(base: Control, layout: Dictionary) -> Vector2:
	var spawn_cell: Array = layout.get("avatar_spawn_grid", [36, 40])
	return base.get("_terrain").call("grid_to_world", Vector2i(int(spawn_cell[0]), int(spawn_cell[1])))


## Geschlossenes Gebaeude ersetzt ein Bestandsgebaeude (Lager statt Halle): Lage, Menschenmass, gesperrter Grundriss,
## Terminals AUSSEN an der Torseite auf begehbaren Feldern mit Abstand.
func _check_closed_replace(base: Control, layout: Dictionary, entry: Dictionary, holder: Node3D, old_nodes: Dictionary, person_height: float) -> void:
	var id := String(entry.get("id", ""))
	var old_id := String(entry.get("replaces", ""))
	var plane := Vector2.INF
	for a in layout.get("assets", []):
		if String(Dictionary(a).get("id", "")) == old_id:
			var p: Array = Dictionary(a).get("plane", [0, 0])
			plane = Vector2(float(p[0]), float(p[1]))
	_check(plane != Vector2.INF, "ersetztes Bestandsgebaeude im Layout: %s" % old_id)
	var off: Array = entry.get("offset", [0, 0, 0])
	_check(holder.position.distance_to(Vector3(plane.x + float(off[0]), float(off[1]), plane.y + float(off[2]))) < 0.001, "%s steht an der Stelle von %s plus Versatz" % [id, old_id])
	_check(not old_nodes.has(old_id) and holder.visible, "%s: altes %s nicht in der Szene, neues Modell sichtbar" % [id, old_id])
	var ratio: float = person_height / 1.8
	if entry.has("door_height_model"):
		var door_real: float = float(entry.get("door_height_model", 0.0)) * float(entry.get("scale", 1.0)) / ratio
		_check(door_real >= 1.95 and door_real <= 2.35, "Menschenmass: Tor wirkt %.2f m hoch (Figur %.3f m): %s" % [door_real, person_height, id])
	if entry.has("real_height_range"):
		var range_m: Array = entry.get("real_height_range", [0.0, 0.0])
		var height_real: float = _bounds(holder).size.y / ratio
		_check(height_real >= float(range_m[0]) and height_real <= float(range_m[1]), "Menschenmass: %s wirkt %.2f m hoch (erlaubt %.1f bis %.1f m, Figur %.3f m = 1,8 m)" % [id, height_real, float(range_m[0]), float(range_m[1]), person_height])
	var rect: Rect2 = _rect_xz(_bounds(holder))
	print("INFO %s Rahmen x %.2f..%.2f z %.2f..%.2f" % [id, rect.position.x, rect.end.x, rect.position.y, rect.end.y])
	var nav_graph: Object = _nav_of(base)
	var terrain: Node = base.get("_terrain")
	_check(nav_graph != null, "Wegsuche der Basis-Navigation erreichbar")
	if nav_graph == null:
		return
	# Grundriss wirklich gesperrt: kein offenes, begehbares Feld im Rahmen (innen 0,1 m eingerueckt).
	var open_inside := 0
	var sampled := 0
	var inner := rect.grow(-0.1)
	var sx := inner.position.x
	while sx <= inner.end.x:
		var sz := inner.position.y
		while sz <= inner.end.y:
			var cell: Vector2i = _plane_to_grid(Vector2(sx, sz))
			var tile: Variant = terrain.call("get_tile_at_grid", cell)
			if tile != null and bool(tile.walkable):
				sampled += 1
				if bool(nav_graph.call("is_grid_open", cell)):
					open_inside += 1
			sz += 0.1
		sx += 0.1
	_check(open_inside == 0, "%s: Grundriss gesperrt, kein offenes Feld im Rahmen (%d von %d begehbaren Probefeldern offen)" % [id, open_inside, sampled])
	# Benutzen-Stelle eines vorhandenen Terminals bleibt frei: weder im Rahmen noch im 0,5 m Rand, begehbar, offen, erreichbar.
	var from_world0: Vector2 = _spawn_world(base, layout)
	for tid0 in entry.get("keep_free_terminals", []):
		var found0: Array = layout.get("terminals", []).filter(func(t: Dictionary) -> bool: return String(t.get("id", "")) == String(tid0))
		_check(found0.size() == 1, "%s: genau ein Terminal %s (%d)" % [id, String(tid0), found0.size()])
		if found0.size() != 1:
			continue
		var tg0: Array = Dictionary(found0[0]).get("grid", [])
		var cell0 := Vector2i(int(tg0[0]), int(tg0[1]))
		var pl0: Vector3 = BASE_NAV.plane_at_grid(cell0)
		var tile0: Variant = terrain.call("get_tile_at_grid", cell0)
		_check(not rect.grow(0.5).has_point(Vector2(pl0.x, pl0.z)), "%s: Benutzen-Stelle %s (%.2f / %.2f) bleibt frei, mindestens 0,5 m vom Rahmen" % [id, String(tid0), pl0.x, pl0.z])
		_check(tile0 != null and bool(tile0.walkable) and bool(nav_graph.call("is_grid_open", cell0)), "%s: Benutzen-Stelle %s begehbar und offen" % [id, String(tid0)])
		_check(not Array(nav_graph.call("find_world_path", from_world0, terrain.call("grid_to_world", cell0))).is_empty(), "%s: %s vom Startpunkt erreichbar" % [id, String(tid0)])
	# Landepads und Anflug (Pad um 1,0 m vergroessert) bleiben frei.
	for pad in layout.get("landing_pads", []):
		var pp: Array = Dictionary(pad).get("plane", [0, 0])
		var ps: Array = Dictionary(pad).get("size", [8.0, 6.0])
		var pad_rect := Rect2(float(pp[0]) - float(ps[0]) * 0.5, float(pp[1]) - float(ps[1]) * 0.5, float(ps[0]), float(ps[1])).grow(1.0)
		_check(not rect.intersects(pad_rect), "%s: Rahmen liegt nicht auf %s samt 1 m Rand (Anflug frei)" % [id, String(Dictionary(pad).get("id", ""))])
	if not entry.has("gate_side"):
		return
	# Torseite: laut Eintrag (gate_side) Westseite = -x; Terminals davor, Streifen davor frei.
	var gate: Array = entry.get("gate_world", [])
	_check(gate.size() == 2 and String(entry.get("gate_side", "")) == "west" and absf(float(gate[0]) - rect.position.x) <= 0.2 and float(gate[1]) > rect.position.y and float(gate[1]) < rect.end.y, "%s: Tor liegt an der Westkante des Rahmens (gate_world %s)" % [id, str(gate)])
	var spots: Array = []
	var from_world: Vector2 = _spawn_world(base, layout)
	for tid in entry.get("outside_terminals", []):
		var found: Array = layout.get("terminals", []).filter(func(t: Dictionary) -> bool: return String(t.get("id", "")) == String(tid))
		_check(found.size() == 1, "%s: genau ein Terminal %s (%d)" % [id, String(tid), found.size()])
		if found.size() != 1:
			continue
		var tg: Array = Dictionary(found[0]).get("grid", [])
		var cell2 := Vector2i(int(tg[0]), int(tg[1]))
		var pl: Vector3 = BASE_NAV.plane_at_grid(cell2)
		var spot := Vector2(pl.x, pl.z)
		spots.append(spot)
		_check(not rect.grow(0.3).has_point(spot), "%s: Benutzen-Stelle %s (%.2f / %.2f) liegt ausserhalb des Grundrisses (mit 0,3 m Rand)" % [id, String(tid), spot.x, spot.y])
		_check(spot.x < rect.position.x and absf(spot.y - float(gate[1])) <= 2.0, "%s: Benutzen-Stelle %s liegt an der Torseite, hoechstens 2 m neben dem Tor" % [id, String(tid)])
		# Streifen zwischen Benutzen-Stelle und Tor: begehbar und offen.
		var strip_ok := true
		var wx := spot.x
		while wx <= rect.position.x - 0.4:  # die Karte endet beim alten Hallenrand etwa 0,3 m vor dem neuen Rahmen
			var c3: Vector2i = _plane_to_grid(Vector2(wx, spot.y))
			var t3: Variant = terrain.call("get_tile_at_grid", c3)
			if t3 == null or not bool(t3.walkable) or not bool(nav_graph.call("is_grid_open", c3)):
				strip_ok = false
			wx += 0.1
		_check(strip_ok, "%s: Streifen von %s bis zum Tor ist frei" % [id, String(tid)])
		var path: Array = nav_graph.call("find_world_path", from_world, terrain.call("grid_to_world", cell2))
		_check(not path.is_empty(), "%s: %s vom Startpunkt erreichbar (Weg %d Punkte)" % [id, String(tid), path.size()])
	_check(spots.size() == 3, "%s: drei Terminals aussen an der Torseite (%d)" % [id, spots.size()])
	var min_gap := INF
	for i in spots.size():
		for j in range(i + 1, spots.size()):
			min_gap = minf(min_gap, (spots[i] as Vector2).distance_to(spots[j]))
	_check(spots.size() == 3 and min_gap >= 1.0, "%s: Benutzen-Stellen nebeneinander mit je mindestens 1 m Abstand (kleinster %.2f m)" % [id, min_gap])


## Alle Terminals: je Kennung genau einmal, Benutzen-Stelle auf begehbarem, offenem Feld ausserhalb aller gesperrten Grundrisse,
## vom Startpunkt erreichbar (flightdeck liegt auf dem Landepad und war schon vorher nicht ueber die Wegsuche erreichbar).
## Landepads bleiben frei, der Kampagnenstart-Pfad liefert dieselben Lagen.
func _check_all_terminals(base: Control, layout: Dictionary) -> void:
	var blocking = load("res://scripts/meta/structure_model_blocking.gd")
	var nav_graph: Object = _nav_of(base)
	var terrain: Node = base.get("_terrain")
	var from_world: Vector2 = _spawn_world(base, layout)
	var seen: Dictionary = {}
	for t in layout.get("terminals", []):
		var td: Dictionary = t
		seen[String(td.get("id", ""))] = int(seen.get(String(td.get("id", "")), 0)) + 1
	for need in ["personnel", "jobs", "team", "mission", "workshop", "refuel"]:
		_check(int(seen.get(need, 0)) == 1, "Terminal %s genau einmal im Layout (%d)" % [need, int(seen.get(need, 0))])
	var block_rects: Array = blocking.blocked_rects()
	for t in layout.get("terminals", []):
		var td2: Dictionary = t
		var tid := String(td2.get("id", ""))
		if tid == "flightdeck":
			continue
		var tg: Array = td2.get("grid", [])
		var cell := Vector2i(int(tg[0]), int(tg[1]))
		var pl: Vector3 = BASE_NAV.plane_at_grid(cell)
		var tile: Variant = terrain.call("get_tile_at_grid", cell)
		_check(tile != null and bool(tile.walkable) and nav_graph != null and bool(nav_graph.call("is_grid_open", cell)), "Terminal %s: Benutzen-Stelle %s auf begehbarem, offenem Feld" % [tid, str(cell)])
		var inside_block := false
		for r in block_rects:
			if (r as Rect2).has_point(Vector2(pl.x, pl.z)):
				inside_block = true
		_check(not inside_block, "Terminal %s: Benutzen-Stelle ausserhalb aller gesperrten Grundrisse" % tid)
		var path: Array = nav_graph.call("find_world_path", from_world, terrain.call("grid_to_world", cell)) if nav_graph != null else []
		_check(not path.is_empty(), "Terminal %s: per Wegsuche vom Startpunkt erreichbar (%d Punkte)" % [tid, path.size()])
	for pad in layout.get("landing_pads", []):
		var pd: Dictionary = pad
		var pp: Array = pd.get("plane", [0, 0])
		var ps: Array = pd.get("size", [8.0, 6.0])
		var pad_rect := Rect2(float(pp[0]) - float(ps[0]) * 0.5, float(pp[1]) - float(ps[1]) * 0.5, float(ps[0]), float(ps[1]))
		var hit := false
		for r in block_rects:
			if (r as Rect2).intersects(pad_rect):
				hit = true
		_check(not hit, "Landepad %s: kein gesperrter Grundriss darauf" % String(pd.get("id", "")))
	var coarse: Dictionary = BASE_NAV.layout("res://maps/campaign_intro_base.json")
	var same := true
	for t in layout.get("terminals", []):
		var other: Array = coarse.get("terminals", []).filter(func(c: Dictionary) -> bool: return String(c.get("id", "")) == String(Dictionary(t).get("id", "")))
		if other.size() != 1 or Dictionary(other[0]).get("grid", []) != Dictionary(t).get("grid", []):
			same = false
	_check(same and Array(coarse.get("terminals", [])).size() == Array(layout.get("terminals", [])).size(), "Kampagnenstart-Pfad (campaign_intro_base.json) liefert dieselben Terminal-Lagen wie die Ansicht")


func _terminal_ids(base: Control) -> Array:
	var ids: Array = []
	for t in base.get("_terminals"):
		ids.append(String(Dictionary(t).get("id", "")))
	ids.sort()
	return ids


func _run() -> void:
	var config: Dictionary = OVERRIDES.load_config()
	var entries: Array = Array(config.get("entries", []))
	_check(not config.is_empty() and entries.size() == 3, "Zuordnung laedt, drei Eintraege (%d)" % entries.size())
	_check(entries.any(func(e: Dictionary) -> bool: return String(e.get("id", "")) == "treibstofftank" and String(e.get("mode", "")) == "replace" and String(e.get("replaces", "")) == "utility_fuel_01"), "Tankstation ersetzt die alte Zapfstelle (mode=replace, replaces=utility_fuel_01)")
	_check(entries.any(func(e: Dictionary) -> bool: return String(e.get("id", "")) == "home_pod" and String(e.get("mode", "")) == "replace" and String(e.get("replaces", "")) == "habitat_cutaway_01"), "Pod ersetzt das Habitat (mode=replace, replaces=habitat_cutaway_01)")
	_check(entries.any(func(e: Dictionary) -> bool: return String(e.get("id", "")) == "lager_werkstatt" and String(e.get("mode", "")) == "replace" and String(e.get("replaces", "")) == "freihafen_hall_01"), "Lager ersetzt die Halle (mode=replace, replaces=freihafen_hall_01)")
	_check(bool(config.get("enabled", false)) and not config.has("toggle_key"), "Vorgabe AN, keine Umschalt-Taste mehr (Karten und Begehbarkeit haengen an AN)")
	_check(absf(float(config.get("brightness", 0.0)) - 1.0) < 0.0001, "Helligkeits-Stellschraube vorhanden, Vorgabe 1,0")
	for entry_variant in entries:
		var entry: Dictionary = entry_variant
		var scene := load(String(entry.get("model", ""))) as PackedScene
		var inst: Node3D = scene.instantiate() as Node3D if scene != null else null
		_check(inst != null and inst.find_children("*", "MeshInstance3D", true, false).size() > 0, "Modell laesst sich instanzieren und hat Mesh-Instanzen: %s" % String(entry.get("id", "")))
		if inst != null:
			inst.free()
	root.size = Vector2i(1920, 1080)
	load("res://scripts/meta/game_start_contract.gd").request_start(self, "campaign", "new")
	var flow: Node = load("res://scenes/meta/meta_layer_test.tscn").instantiate()
	root.add_child(flow)
	for i in 8:
		await process_frame
	var screen: Node = flow.get_node("HomebaseScreen")
	screen.call("request_operation", "navigate", {"mode": "base"})
	for i in 20:
		await process_frame
	var presenter: Control = screen.get("_operations_presenter")
	var base: Control = presenter.get("_base")
	var layout: Dictionary = base.get("_layout")
	var stage: Node3D = base.get("_authored_stage")
	var group: Node3D = stage.get_node_or_null(OVERRIDES.GROUP_NAME) as Node3D
	_check(group != null, "Heimatbasis-Ansicht hat die Gruppe der neuen Modelle")
	if group == null:
		print("STRUCTURE_MODELS passed=%d failed=%d" % [passed, failed])
		quit(1)
		return
	_check(bool(base.get("_structure_models").call("is_enabled")), "Vorgabe: Schalter AN")
	var old_ids: Array = ["habitat_cutaway_01", "freihafen_hall_01"]
	var old_nodes: Dictionary = base.get("_asset_visual_nodes")
	var old_boxes: Dictionary = {}
	for id in old_ids:
		var replaced: bool = entries.any(func(e: Dictionary) -> bool: return String(e.get("mode", "")) == "replace" and String(e.get("replaces", "")) == id)
		if replaced:
			var loaded_sources: String = JSON.stringify(base.get("_asset_sources"))
			_check(not old_nodes.has(id) and stage.find_children("*" + id + "*", "", true, false).is_empty() and not loaded_sources.contains(id) and not Dictionary(base.get("_structure_visual_nodes")).has(id), "altes Gebaeude %s ist nicht geladen: kein Knoten in der Szene, Modellpfad nicht geladen" % id)
		else:
			_check(old_nodes.has(id) and (old_nodes[id] as Node3D).visible, "Bestandsgebaeude bei AN sichtbar: %s" % id)
			old_boxes[id] = _bounds(old_nodes[id])
	var anchors: Array = []
	var spots: Array = []
	var map_data_early: Object = base.get("_map_data")
	for t in layout.get("terminals", []):
		var anchor: Array = Dictionary(t).get("model_anchor_plane", [])
		if anchor.size() == 2:
			anchors.append(Vector2(float(anchor[0]), float(anchor[1])))
			spots.append(anchors.back())
		var tg: Array = Dictionary(t).get("grid", [])
		if tg.size() == 2:
			var tpl: Vector3 = BASE_NAV.plane_at_grid(Vector2i(int(tg[0]), int(tg[1])))
			spots.append(Vector2(tpl.x, tpl.z))
	for b in layout.get("beds", []):
		for key in ["sleep_plane", "rest_plane"]:
			var bp: Array = Dictionary(b).get(key, [])
			if bp.size() == 2:
				spots.append(Vector2(float(bp[0]), float(bp[1])))
	var spawn: Array = layout.get("avatar_spawn_grid", [])
	if spawn.size() == 2:
		var sp: Vector3 = BASE_NAV.plane_at_grid(Vector2i(int(spawn[0]), int(spawn[1])))
		spots.append(Vector2(sp.x, sp.z))
	var person_height := 0.0
	for c in stage.get_children():
		if String(c.name).begins_with("RosterPerson_"):
			person_height = maxf(person_height, _bounds(c).size.y)
	var people: Array = []
	for c in stage.get_children():
		if String(c.name).begins_with("RosterPerson_") or String(c.name).begins_with("ActualCraft_"):
			people.append(c)
	for entry_variant in entries:
		var entry: Dictionary = entry_variant
		var id := String(entry.get("id", ""))
		var holders: Array = group.get_children().filter(func(n: Node) -> bool: return n.has_meta("structure_model_id") and String(n.get_meta("structure_model_id")) == id)
		_check(holders.size() == 1, "genau EIN neues Modell je Zuordnung: %s (%d)" % [id, holders.size()])
		if holders.size() != 1:
			continue
		if String(entry.get("mode", "additional")) == "replace":
			if entry.has("interior_model"):
				_check_replace(base, stage, layout, entry, holders[0], old_nodes, person_height)
			else:
				_check_closed_replace(base, layout, entry, holders[0], old_nodes, person_height)
			continue
		var box: AABB = _bounds(holders[0])
		var center: Vector2 = OVERRIDES.site_center(layout, String(entry.get("site", "")))
		var size: Vector2 = OVERRIDES.site_size(layout, String(entry.get("site", "")))
		_check(center != Vector2.INF and size.x > 0.0, "Bauplatz im Layout gefunden: %s" % String(entry.get("site", "")))
		var site := Rect2(center - size * 0.5, size).grow(TOLERANCE)
		print("INFO %s Rahmen x %.2f..%.2f  z %.2f..%.2f  hoch %.2f  Unterkante %.3f | Bauplatz %s" % [id, box.position.x, box.end.x, box.position.z, box.end.z, box.size.y, box.position.y, str(site)])
		var raw_site := Rect2(center - size * 0.5, size)
		var rect := _rect_xz(box)
		print("INFO %s Ueberstand ueber den Bauplatz (m, negativ = innen): links %.2f rechts %.2f vorn(z-) %.2f hinten(z+) %.2f" % [id, raw_site.position.x - rect.position.x, rect.end.x - raw_site.end.x, raw_site.position.y - rect.position.y, rect.end.y - raw_site.end.y])
		# Menschenmass: Spielfigur (Hoehe aus dem Spiel) entspricht 1,8 m; Tuerhoehe muss dann 2,0 bis 2,3 m ergeben.
		var ratio: float = person_height / float(config.get("human_height_m", 1.8))
		var door_real: float = float(entry.get("door_height_model", 0.0)) * float(entry.get("scale", 1.0)) / ratio
		_check(door_real >= 1.95 and door_real <= 2.35, "Menschenmass: Tuer wirkt %.2f m hoch (Figur %.3f m, Faktor %.3f): %s" % [door_real, person_height, ratio, id])
		# Keine Benutzen-Stelle, kein Terminal, kein Feld der Karte, kein Landepad/Weg im Rahmen.
		var spots_inside := 0
		for s in spots:
			if rect.has_point(s):
				spots_inside += 1
		_check(spots_inside == 0, "keine Benutzen-Stelle/Terminal/Anker im Rahmen (%d von %d) : %s" % [spots_inside, spots.size(), id])
		var tiles_inside := 0
		for t in map_data_early.call("get_tiles"):
			var tp: Vector3 = BASE_NAV.plane_at_grid(Vector2i(t.grid_position))
			if rect.has_point(Vector2(tp.x, tp.z)):
				tiles_inside += 1
		_check(tiles_inside == 0, "kein Kartenfeld (Weg/Hindernis) im Rahmen (%d): %s" % [tiles_inside, id])
		for other_name in ["homebase_pad_01", "homebase_pad_02", "HomebaseBuiltPaths", "AuthoredServiceDrone"]:
			var other: Node = stage.get_node_or_null(other_name)
			if other != null:
				_check(not rect.intersects(_rect_xz(_bounds(other))), "ueberdeckt nicht %s: %s" % [other_name, id])
		_check(absf(box.position.y) <= 0.1, "Unterkante auf Bodenhoehe (+-0,1 m): %s (%.3f)" % [id, box.position.y])
		for old_id in old_boxes:
			_check(not _rect_xz(box).intersects(_rect_xz(old_boxes[old_id])), "ueberdeckt kein Bestandsgebaeude: %s gegen %s" % [id, old_id])
		var covers_anchor := false
		for a in anchors:
			if _rect_xz(box).grow(0.3).has_point(a):
				covers_anchor = true
		_check(not covers_anchor, "ueberdeckt keinen Terminal-Anker: %s" % id)
		var covers_person := false
		for p in people:
			if _rect_xz(box).intersects(_rect_xz(_bounds(p))):
				covers_person = true
		_check(not covers_person, "ueberdeckt keine Figur und kein Schiff: %s" % id)
		_check(holders[0].visible and group.visible, "sichtbar bei AN: %s" % id)
	_check_all_terminals(base, layout)
	var terminals_before: Array = _terminal_ids(base)
	var map_data: Object = base.get("_map_data")
	var tiles_before: int = Array(map_data.call("get_tiles")).size()
	var walkable_before := 0
	for t in map_data.call("get_tiles"):
		if bool(t.walkable):
			walkable_before += 1
	# Sicht-Schalter ueber die Programmschnittstelle (keine Taste): AUS zeigt das alte Bild.
	base.get("_structure_models").call("set_enabled", false)
	await process_frame
	_check(not group.visible and not bool(base.get("_structure_models").call("is_enabled")), "Sicht AUS: neue Modelle weg")
	for id in old_boxes:
		_check((old_nodes[id] as Node3D).visible and _bounds(old_nodes[id]).is_equal_approx(old_boxes[id]), "AUS: Bestandsbild unveraendert: %s" % id)
	_check(_terminal_ids(base) == terminals_before and terminals_before.size() == 7, "Terminals unveraendert, sieben mit Werkstatt (%s)" % str(terminals_before))
	base.get("_structure_models").call("set_enabled", true)
	await process_frame
	_check(group.visible and bool(base.get("_structure_models").call("is_enabled")), "Sicht wieder AN: neue Modelle da")
	_check(_terminal_ids(base) == terminals_before, "Terminals nach Rueckschalten gleich")
	_check(not old_nodes.has("habitat_cutaway_01") and not old_nodes.has("freihafen_hall_01"), "nach Rueckschalten: Habitat und Halle weiter nicht geladen")
	# Platz future_workshop ist leer: kein neues Modell steht dort.
	var ws_center: Vector2 = OVERRIDES.site_center(layout, "future_workshop")
	var ws_rect := Rect2(ws_center - Vector2(2.5, 2.0), Vector2(5.0, 4.0))
	var ws_hit := false
	for holder in group.get_children():
		if holder.has_meta("structure_model_id") and ws_rect.intersects(_rect_xz(_bounds(holder))):
			ws_hit = true
	_check(not ws_hit, "Platz future_workshop ist wieder leer")
	var walkable_after := 0
	for t in map_data.call("get_tiles"):
		if bool(t.walkable):
			walkable_after += 1
	_check(walkable_after == walkable_before and Array(map_data.call("get_tiles")).size() == tiles_before, "Begehbarkeit der Karte unveraendert (%d begehbare Felder)" % walkable_after)
	# Benutzen-Stellen erreichbar: Terminal anfordern wie bisher.
	var reachable := true
	for id in ["personnel", "jobs", "mission", "team"]:
		if not base.has_method("request_terminal"):
			reachable = false
	_check(reachable, "Benutzen-Stellen: Zugang (request_terminal) vorhanden")
	# Werkstatt-Terminal oeffnet die vorhandene Werkstatt-Ansicht der Basisverwaltung (wie refuel die Schiff-Ansicht).
	presenter.call("_terminal_requested", "refuel")
	_check(String(presenter.get("_flyout_kind")) == "ship", "Terminal refuel oeffnet die Basisverwaltung (ship)")
	presenter.call("_terminal_requested", "workshop")
	_check(String(presenter.get("_flyout_kind")) == "workshop", "Terminal workshop oeffnet die Basisverwaltung (workshop), keine neue Spielfunktion (%s)" % str(presenter.get("_flyout_kind")))
	print("STRUCTURE_MODELS passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)
