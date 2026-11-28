extends SceneTree
## Authored synthetic identities only. A frozen prechange signature protects
## the existing RNG sequence, names, gameplay values, traits and relationships.
const CATALOG = preload("res://scripts/meta/portrait_identity_catalog.gd")
const GENERATOR = preload("res://scripts/meta/start_roster_generator.gd")
const PRESETS = preload("res://scripts/npc/unit_roster_presets.gd")
const CAMPAIGN = preload("res://scripts/meta/campaign_start_configuration.gd")
const BASELINE_PATH := "res://docs/qa/character_identity_20261110/seeded_baseline.json"
const CASES := [["identity_baseline_alpha", 20], ["identity_baseline_beta", 24], ["identity_baseline_gamma", 30]]
var passed := 0
var failed := 0

func _init() -> void:
	call_deferred("_run")

func _signature(roster: Dictionary) -> String:
	var units: Array = Array(roster.units).duplicate(true)
	for unit: Dictionary in units:
		unit.erase("portrait_id")
		unit.erase("portrait_path")
		unit.erase("personality")  # neues Feld seit Funk Paket 3, gehoert nicht zur alten Vorgabe
	return JSON.stringify(units, "", true).sha256_text()

func _run() -> void:
	if OS.get_environment("CHARACTER_IDENTITY_CAPTURE") == "1":
		var baseline: Dictionary = {"source_commit": "7011ce4b2", "scope": "All unit profile fields except portrait_id and portrait_path, before identity correction", "cases": []}
		for item: Array in CASES:
			var roster: Dictionary = GENERATOR.generate_start_roster(String(item[0]), int(item[1]))
			var names: Array = []
			for unit: Dictionary in roster.units:
				names.append(unit.display_name)
			baseline.cases.append({"seed": item[0], "size": item[1], "signature": _signature(roster), "names": names})
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BASELINE_PATH).get_base_dir())
		FileAccess.open(BASELINE_PATH, FileAccess.WRITE).store_string(JSON.stringify(baseline, "\t", true) + "\n")
		print("PRECHANGE_IDENTITY_BASELINE captured=3")
		quit(0)
		return
	var baseline: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASELINE_PATH))
	for item: Dictionary in baseline.cases:
		var roster: Dictionary = GENERATOR.generate_start_roster(String(item.seed), int(item.size))
		_check(_signature(roster) == String(item.signature), "Seed %s preserves every non-portrait profile field" % item.seed)
		_check(bool(roster.valid), "Consistent generated roster remains valid")
	var stock: Dictionary = PRESETS.get_homebase_roster()[0]
	_check(String(stock.get("portrait_id", "")) == "char_portrait_004" and String(stock.portrait_path).ends_with("/char_portrait_004.tres"), "Stock Anja uses explicit authored woman commander portrait ID and path")
	var campaign: Array = CAMPAIGN.new().call("_initial_roster")
	_check(String(campaign[0].unit_id) == "campaign_leader" and String(campaign[0].get("portrait_id", "")) == "char_portrait_004", "New campaign receives corrected same-identity stock portrait")
	var catalog_owner = CATALOG.new()
	var generator_owner = GENERATOR.new()
	if _check(catalog_owner.has_method("get_presentation_group") and generator_owner.has_method("get_authored_first_name_group"), "Authored presentation and synthetic name metadata are available"):
		_check(String(catalog_owner.call("get_presentation_group", "char_portrait_003")) == "male" and String(catalog_owner.call("get_presentation_group", "char_portrait_004")) == "female", "Known art prompt quadrants keep their explicit authored groups")
		_check(String(catalog_owner.call("get_presentation_group", "char_portrait_019")) == "unspecified", "Documented ambiguous art stays unspecified")
		_check(String(catalog_owner.call("get_presentation_group", "unknown_custom_portrait")) == "unspecified", "Unknown portrait does not inherit a classification from the fallback image")
		_check(String(generator_owner.call("get_authored_first_name_group", "Jamie")) == "unspecified", "Unknown custom first name receives no inferred identity")
		for item: Array in CASES:
			var used: Dictionary = {}
			var matched := 0
			var roster: Dictionary = GENERATOR.generate_start_roster(String(item[0]), int(item[1]))
			for unit: Dictionary in roster.units:
				var name_group: String = generator_owner.call("get_authored_first_name_group", String(unit.display_name).get_slice(" ", 0))
				var art_group: String = catalog_owner.call("get_presentation_group", String(unit.portrait_id), String(unit.portrait_path))
				if name_group != "unspecified":
					_check(art_group == name_group, "Generated %s matches authored presentation metadata" % unit.display_name)
					matched += 1
				_check(not used.has(unit.portrait_id), "Normal seeded batch keeps distinct portrait " + String(unit.portrait_id))
				used[unit.portrait_id] = true
			_check(matched > 0, "Seeded batch exercises known authored name groups")
		var entries: Dictionary = CATALOG.load_catalog().entries_by_id
		var exhausted: Dictionary = {}
		for id: String in entries:
			if String(entries[id].presentation_group) == "male":
				exhausted[id] = true
		var unspecified: Dictionary = CATALOG.select_generated_entry(entries.char_portrait_003, "male", exhausted)
		_check(String(unspecified.get("presentation_group", "")) == "unspecified" and String(unspecified.get("assignment_diagnostic", "")) == "compatible_pool_exhausted_unspecified", "Group exhaustion uses explicitly unspecified art before any reuse")
		exhausted[String(unspecified.get("id", ""))] = true
		var reused: Dictionary = CATALOG.select_generated_entry(entries.char_portrait_003, "male", exhausted)
		_check(String(reused.get("presentation_group", "")) == "male" and String(reused.get("assignment_diagnostic", "")) == "compatible_pool_exhausted_reuse", "Exhausted supply explicitly reuses compatible art instead of opposite presentation")
	var custom: Dictionary = GENERATOR.generate_start_roster("identity_custom_preserved", 20)
	custom.units[0].display_name = "Jamie Custom"
	custom.units[0].portrait_id = "char_portrait_003"
	custom.units[0].portrait_path = "res://Assets/curated/portraits/frontier_20261105/portraits/char_portrait_003.tres"
	var before: Dictionary = custom.duplicate(true)
	var existing: Dictionary = GENERATOR.build_first_start_snapshot(custom, "ignored_new_seed")
	_check(not bool(existing.get("created", true)) and custom == before and existing.get("roster", {}) == before, "Existing custom identity is neither regenerated nor rewritten")
	custom.units[0].display_name = "Anja Custom"
	before = custom.duplicate(true)
	existing = GENERATOR.build_first_start_snapshot(custom, "ignored_new_seed")
	_check(existing.get("roster", {}) == before and custom == before, "Saved custom identity is preserved even when its first name appears in authored generator metadata")
	print("CHARACTER_IDENTITY_CONSISTENCY passed=%d failed=%d" % [passed, failed])
	quit(1 if failed else 0)

func _check(condition: bool, message: String) -> bool:
	if condition:
		passed += 1
	else:
		failed += 1
		printerr("FAIL: ", message)
	return condition
