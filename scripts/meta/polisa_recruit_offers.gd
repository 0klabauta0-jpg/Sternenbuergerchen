extends RefCounted
## Pure offer projection. Ownership, payment and admission are separate commands.
const SETUP = preload("res://scripts/meta/skirmish_start_configuration.gd")
const POINTS = preload("res://scripts/meta/skirmish_points_catalog.gd")

static func build_offers(batch_id: String, recruiter: Dictionary, occupied_portraits: Dictionary) -> Array:
	if batch_id.strip_edges().is_empty() or String(recruiter.get("unit_id", "")).is_empty(): return []
	var skills: Dictionary = recruiter.get("skill_values", {})
	var communication: Dictionary = recruiter.get("communication_values", {})
	var leadership := clampf(float(skills.get("leadership", recruiter.get("skill_leadership", 0.0))), 0.0, 1.0)
	var speech := clampf(float(communication.get("speech_quality", recruiter.get("speech_quality", 0.0))), 0.0, 1.0)
	if not is_finite(leadership) or not is_finite(speech): return []
	var aptitude := (leadership + speech) * 0.5
	var used := occupied_portraits.duplicate()
	var offers: Array = []
	var setup = SETUP.new()
	for index in range(4):
		var hash_value := (batch_id + ":" + str(index)).sha256_text()
		var roll := float(hash_value.substr(0, 4).hex_to_int()) / 65535.0
		var score := clampf(0.18 + 0.42 * aptitude + 0.4 * roll, 0.0, 1.0)
		var experience := "veteran" if score >= 0.72 else ("trained" if score >= 0.42 else "junior")
		var roles := ["operator", "medic", "engineer", "pilot"] if aptitude >= 0.35 else ["operator", "operator", "medic", "operator"]
		var role: String = roles[index]
		var id := "polisa_recruit_" + (batch_id + ":" + str(index)).sha256_text().substr(0, 16)
		var configuration := {"role":role, "experience":experience, "armor":"suit", "weapon":"pistol"}
		var profile: Dictionary = setup.build_points_person(configuration, id, used)
		profile.player_profile_id = "campaign"
		used[String(profile.get("portrait_id", ""))] = true
		var quality: float = float(POINTS.EXPERIENCE[experience].value)
		offers.append({"id":id, "profile":profile, "role":String(POINTS.ROLES[role].label), "experience":String(POINTS.EXPERIENCE[experience].label), "quality":quality, "price":200 + int(POINTS.EXPERIENCE[experience].cost) * 3 + int(POINTS.ROLES[role].cost) * 2})
	return offers
