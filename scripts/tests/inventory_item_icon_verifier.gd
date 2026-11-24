extends SceneTree
## Inventar-Bilder (24.11.2026): Munition -> Magazin-Bild, Frachtkiste und C-Benit-Kiste -> Kisten-Bild, sonstige Gegenstaende unveraendert.
## Geprueft wird die ZUORDNUNG (Pfadwahl in _item_icon_path) und dass die Quelldateien des Kits existieren; die neuen Bilder
## muessen im Pruefbaum nicht importiert sein.
## Abschlusszeile: INVENTORY_ITEM_ICON passed=%d failed=%d
const PANEL = "res://scripts/ui/components/personnel_inventory_panel.gd"
const KIT := "res://Assets/curated/versorgung_kit_20261124/"
const CHIP := "res://Assets/curated/ui/campaign_inventory/chip.svg"
const AMMO := ["ammo_light", "ammo_rifle", "ammo_rail", "ammo_rocket"]
var passed := 0
var failed := 0
var _panel: Object

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("PASS: " if ok else "FAIL: ", label)

func _path(item: String) -> String:
	if _panel == null or not _panel.has_method("_item_icon_path"):
		return "<fehlt>"
	return String(_panel.call("_item_icon_path", item))

func _run() -> void:
	_files_part()
	_panel = (load(PANEL) as GDScript).new()
	check(_panel != null and _panel.has_method("_item_icon_path"), "Panel hat die Pfadwahl _item_icon_path")
	_assign_part()
	_fallback_part()
	if _panel != null:
		_panel.free()
	print("INVENTORY_ITEM_ICON passed=%d failed=%d" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _files_part() -> void:
	for f in ["icon_ammo_box.png", "icon_magazine.png", "icon_cargo_crate.png", "ammo_box_01.glb", "magazine_01.glb", "cargo_crate_01.glb", "kit_manifest.json"]:
		check(FileAccess.file_exists(KIT + f), "Kit-Datei vorhanden: " + f)

func _assign_part() -> void:
	var mag := KIT + "icon_magazine.png"
	for a in AMMO:
		check(_path(a) == mag, "%s -> Magazin-Bild" % a)
		check(_path(a) != CHIP and _path(a) != "", "%s nicht das Chip-Symbol" % a)
	check(_path("cargo_crate") == KIT + "icon_cargo_crate.png", "cargo_crate -> Kisten-Bild")
	check(_path("c_benit_crate") == KIT + "icon_cargo_crate.png", "c_benit_crate -> Kisten-Bild")
	check(_path("cargo_crate") != _path("ammo_light"), "Kisten-Bild und Magazin-Bild verschieden")

func _fallback_part() -> void:
	check(_path("erfundene_crate") == "", "erfundene _crate-Kennung: keine eigene Zuordnung (bleibt Chip-Regel)")
	check(_path("pistol") == "" and _path("datapad") == "", "pistol und datapad: keine eigene Zuordnung")
	if _panel == null or not _panel.has_method("_item_icon"):
		check(false, "Panel hat _item_icon")
		return
	var chip: Texture2D = load(CHIP)
	check(chip != null and _panel.call("_item_icon", "erfundene_crate") == chip, "erfundene _crate-Kennung zeigt weiter das Chip-Symbol")
	var menu = load("res://scripts/ui/menu_equipment_icons.gd")
	check(_panel.call("_item_icon", "pistol") == menu.get_icon("pistol"), "pistol zeigt wie vorher das Menue-Bild")
	check(_panel.call("_item_icon", "datapad") == null, "datapad zeigt wie vorher kein Bild")
	check(_panel.call("_item_icon", "c_benit_chip") == chip, "_chip-Gegenstand zeigt weiter das Chip-Symbol")
