extends RefCounted
## Unwired authoring facts only. Space combat owns ships and access decisions.
const REVISION := "orbit_approach_limb_v1"
const MAP_SIZE := Vector2i(512, 256)
const ENTRY_BAND := Rect2i(0, 224, 512, 32)
const LIMB_WIDTH := 256
const VISIBLE_DEPTH := 4.0
const HALF_WIDTH := LIMB_WIDTH * 0.5
const RADIUS := (HALF_WIDTH * HALF_WIDTH + VISIBLE_DEPTH * VISIBLE_DEPTH) / (2.0 * VISIBLE_DEPTH)
const CIRCLE_CENTER := Vector2(MAP_SIZE.x * 0.5, VISIBLE_DEPTH - RADIUS)

static func contains_local_cell(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, MAP_SIZE).has_point(cell)

## Lower circular limb at the column center, in logical map cell coordinates.
static func limb_depth_at(column: int) -> float:
	if column < 0 or column >= MAP_SIZE.x: return 0.0
	var dx := float(column) + 0.5 - CIRCLE_CENTER.x
	if absf(dx) >= HALF_WIDTH: return 0.0
	return clampf(CIRCLE_CENTER.y + sqrt(maxf(0.0, RADIUS * RADIUS - dx * dx)), 0.0, VISIBLE_DEPTH)

## Tiefe der Anflugzone am Planetenrand (Felder). Die Zone reicht ueber die ganze Kartenbreite.
const ZONE_DEPTH := 4
## Erste Zeile der Zone (wie die Torzeile in der Kartenmitte) und Randstreifen links/rechts ohne Zone.
const ZONE_TOP_ROW := 4
const ZONE_EDGE_MARGIN := 16

static func build(body_id: String) -> Dictionary:
	if not _valid_body_id(body_id): return {"ok":false,"reason":"invalid_body_id"}
	var body_cells: Array[Vector2i] = []
	var candidates: Array[Vector2i] = []
	var extra: Array[Vector2i] = []
	for column in range(MAP_SIZE.x):
		var first_free_row := ceili(limb_depth_at(column))
		var in_limb := column >= (MAP_SIZE.x - LIMB_WIDTH) / 2 and column < (MAP_SIZE.x + LIMB_WIDTH) / 2
		if in_limb:
			for row in range(first_free_row): body_cells.append(Vector2i(column, row))
			# Wie bisher zuerst: die erste freie Zelle unter dem Planetenbogen (Reihenfolge der Suche bleibt gleich).
			candidates.append(Vector2i(column, first_free_row))
		# Anflugzone: ZONE_DEPTH Felder tief (Zeilen ZONE_TOP_ROW..), ueber die Breite ausser einem Randstreifen, damit der Fussabdruck
		# eines Schiffs (mehrere Felder) ganz auf die Karte passt. Die bisherigen Torzellen bleiben als erste Kandidaten bestehen.
		if column < ZONE_EDGE_MARGIN or column >= MAP_SIZE.x - ZONE_EDGE_MARGIN: continue
		for row in range(ZONE_TOP_ROW, ZONE_TOP_ROW + ZONE_DEPTH):
			if row >= first_free_row and not (in_limb and row == first_free_row): extra.append(Vector2i(column, row))
	candidates.append_array(extra)
	return {"ok":true,"revision":REVISION,"body_id":body_id,
		"body_map_id":"orbit_approach:" + body_id.uri_encode(),
		"map_bounds":Rect2i(Vector2i.ZERO, MAP_SIZE),"entry_band":ENTRY_BAND,
		"limb":{"nominal_width":LIMB_WIDTH,"visible_depth":VISIBLE_DEPTH,
			"circle_center":CIRCLE_CENTER,"radius":RADIUS},
		"body_cells":body_cells,"gate_cells":candidates}

static func gate_cells(body_id: String) -> Array[Vector2i]:
	var result := build(body_id)
	var cells: Array[Vector2i] = []
	if bool(result.get("ok", false)): cells.assign(result.gate_cells)
	return cells

static func _valid_body_id(body_id: String) -> bool:
	return not body_id.is_empty() and body_id == body_id.strip_edges()
