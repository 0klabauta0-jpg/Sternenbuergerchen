extends SceneTree
## Grafik-Paket 1, Requisiten 01-10 (28.11.2026, Tripo): Frachtcontainer, Fass, Kistenstapel, Flutlichtmast, Funkmast,
## Drucktank, Barriere, Schrotthaufen, Generator (Solarpaneel-Reihe fehlt noch).
## Geprueft: Kachelkatalog (Palette "aussenposten", Objekt-Ebene, Deckung/Sicht/Begehbarkeit landen per apply_type_to_tile
## auf der Kachel = Simulationswahrheit), Modell-Zuordnung (scale 1 = echte Groesse) und die GLBs selbst
## (laden, Unterkante y=0, Mitte im Ursprung, Masse in Metern).
## Abschlusszeile: PAKET01_REQUISITEN passed=%d failed=%d
const MAPPING_PATH := "res://data/terrain_3d_asset_mapping.json"
const TOL := 0.04
# Deckungsstufen wie im Code (combat_fire_decision_resolver: >=70 voll, >=35 teilweise, >0 leicht):
# voll 70, halb 45, Masten nur blockierend (Funkmast: Geraetehaus = volle Deckung).
# type_id: [Laenge x, Hoehe y, Breite z, walkable, blocks_los, cover_value]
const PROPS := {
	"aussenposten_frachtcontainer_01": [6.0, 2.6, 2.5, false, true, 70],
	"aussenposten_fass_01": [0.6, 0.9, 0.6, false, false, 45],
	"aussenposten_kistenstapel_01": [1.6, 1.4, 1.21, false, false, 70],
	"aussenposten_flutlichtmast_01": [6.22, 8.0, 2.0, false, false, 0],
	"aussenposten_funkmast_01": [2.84, 10.0, 2.94, false, true, 70],
	"aussenposten_drucktank_01": [5.0, 2.6, 2.0, false, true, 70],
	"aussenposten_barriere_01": [2.0, 0.9, 0.6, false, false, 45],
	"aussenposten_schrotthaufen_01": [3.0, 1.2, 2.5, false, false, 45],
	"aussenposten_generator_01": [2.5, 1.6, 1.5, false, true, 70],
}
var passed := 0
var failed := 0


func _init() -> void:
	call_deferred("_run")


func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
	else:
		failed += 1
	print("PASS: " if ok else "FAIL: ", label)


func _run() -> void:
	var catalog = load("res://scripts/terrain/terrain_tile_catalog.gd").load_from_file()
	check(catalog != null, "Kachelkatalog laedt")
	var mapping: Dictionary = {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(MAPPING_PATH))
	if parsed is Dictionary:
		mapping = Dictionary(parsed.get("models", {}))
	check(not mapping.is_empty(), "Modell-Zuordnung laedt")
	var group_found := false
	if catalog != null:
		for group in catalog.get_palette_groups():
			if String(Dictionary(group).get("group_id", "")) == "aussenposten":
				group_found = true
	check(group_found, "Palettengruppe aussenposten vorhanden")
	for type_id in PROPS.keys():
		_check_prop(catalog, mapping, String(type_id), PROPS[type_id])
	print("PAKET01_REQUISITEN passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _check_prop(catalog, mapping: Dictionary, type_id: String, spec: Array) -> void:
	if catalog == null or not catalog.has_type(type_id):
		check(false, "%s im Kachelkatalog" % type_id)
		return
	check(catalog.is_object_layer_type(type_id), "%s liegt auf der Objekt-Ebene" % type_id)
	check(String(catalog.get_type(type_id).get("palette_group", "")) == "aussenposten", "%s in Gruppe aussenposten" % type_id)
	var tile = load("res://scripts/terrain/terrain_tile_data.gd").new()
	var applied: bool = catalog.apply_type_to_tile(tile, type_id)
	check(applied and String(tile.object_type_id) == type_id, "%s laesst sich auf eine Kachel setzen" % type_id)
	check(bool(tile.walkable) == bool(spec[3]), "%s begehbar=%s" % [type_id, spec[3]])
	check(bool(tile.blocks_los) == bool(spec[4]), "%s blockiert Sicht=%s" % [type_id, spec[4]])
	check(int(tile.cover_value) == int(spec[5]), "%s Deckung %d (ist %d)" % [type_id, spec[5], int(tile.cover_value)])
	var entry: Dictionary = Dictionary(mapping.get(type_id, {}))
	check(not entry.is_empty(), "%s hat eine Modell-Zuordnung" % type_id)
	check(is_equal_approx(float(entry.get("scale", 0.0)), 1.0), "%s scale 1 (echte Groesse)" % type_id)
	var path := String(entry.get("model_path", ""))
	check(ResourceLoader.exists(path), "%s Modell vorhanden: %s" % [type_id, path])
	var scene := load(path) as PackedScene if ResourceLoader.exists(path) else null
	if scene == null:
		check(false, "%s Modell laedt" % type_id)
		return
	var node := scene.instantiate() as Node3D
	var acc: Array = []
	_bounds(node, Transform3D.IDENTITY, acc)
	node.free()
	if acc.is_empty():
		check(false, "%s hat Netze" % type_id)
		return
	var box: AABB = acc[0]
	var size := box.size
	check(absf(box.position.y) <= 0.02, "%s Unterkante auf y=0 (ist %.3f)" % [type_id, box.position.y])
	var center := box.position + size * 0.5
	check(absf(center.x) <= 0.05 and absf(center.z) <= 0.05, "%s Mitte im Ursprung (%.2f, %.2f)" % [type_id, center.x, center.z])
	var want := Vector3(float(spec[0]), float(spec[1]), float(spec[2]))
	var ok := true
	for axis in 3:
		if absf(size[axis] - want[axis]) > maxf(TOL, want[axis] * 0.03):
			ok = false
	check(ok, "%s Masse %s m (ist %s)" % [type_id, want, size])


func _bounds(node: Node, parent: Transform3D, acc: Array) -> void:
	var xf := parent
	if node is Node3D:
		xf = parent * (node as Node3D).transform
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		var world: AABB = xf * (node as MeshInstance3D).mesh.get_aabb()
		if acc.is_empty():
			acc.append(world)
		else:
			acc[0] = (acc[0] as AABB).merge(world)
	for child in node.get_children():
		_bounds(child, xf, acc)
