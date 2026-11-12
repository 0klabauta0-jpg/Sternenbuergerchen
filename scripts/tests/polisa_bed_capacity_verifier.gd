extends SceneTree

func _init() -> void:
	var capacity = load("res://scripts/meta/base_capacity_layout.gd")
	var source := {"beds":[{"id":"bed_a"},{"id":"bed_b"}]}
	var expanded := {"beds":[{"id":"bed_a"},{"id":"bed_b"},{"id":"field_bed_01"}]}
	var failures := 0
	if capacity.recruitment_bed_capacity(source, expanded, {}) != 2: failures += 1
	if capacity.recruitment_bed_capacity(source, expanded, {"paid":true,"beds":3}) != 3: failures += 1
	if capacity.recruitment_bed_capacity(source, {"beds":[]}, {"paid":true,"beds":3}) != 0: failures += 1
	if capacity.recruitment_bed_ids(source, expanded, {}) != ["bed_a", "bed_b"]: failures += 1
	if capacity.recruitment_bed_ids(source, expanded, {"paid":true}) != ["bed_a", "bed_b", "field_bed_01"]: failures += 1
	if capacity.recruitment_bed_ids(source, expanded, {"campaign_beds":2}) != ["bed_a", "bed_b"]: failures += 1
	if capacity.recruitment_bed_ids(source, expanded, {"campaign_beds":3}) != ["bed_a", "bed_b", "field_bed_01"]: failures += 1
	if capacity.recruitment_bed_capacity(source, expanded, {"campaign_beds":4}) != 3: failures += 1
	print("PASS: built bed capacity" if failures == 0 else "FAIL: built bed capacity")
	quit(0 if failures == 0 else 1)
