extends RefCounted
## Research uses the authoritative work reservation and completion lifecycle.
static func recipes() -> Dictionary:
	return {
		"research_materials":{"label":"Forschung · Werkstoffkunde","materials":{"scrap":2,"parts":2},"duration":45.0,"min_skill":3,"tier":2,"output":{},"unlocks":["refine_alloy","research_medicine"]},
		"refine_alloy":{"label":"Legierung veredeln","materials":{"ore":3,"scrap":2},"duration":18.0,"min_skill":3,"tier":2,"output":{"alloy":1}},
		"research_medicine":{"label":"Forschung · Medizintechnik","materials":{"alloy":1,"parts":3},"duration":60.0,"min_skill":3,"tier":2,"output":{},"unlocks":["med_charge_efficient"]},
		"med_charge_efficient":{"label":"Med-Ladungen · Serienfertigung","materials":{"parts":2},"duration":12.0,"min_skill":3,"tier":2,"output":{"med_charge":8}}
	}
