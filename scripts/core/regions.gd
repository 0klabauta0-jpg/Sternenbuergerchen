extends RefCounted
## Stable region identity shared by saves, simulation, travel and projection.
const ALL: Array[String]=["base","rust","station","space","orbit","bunker_surface","bunker_depths","bunker_medium","bunker_medium_depths","bunker_hard","bunker_hard_depths","distribution","distribution_friendly","tradepost"]
const DESTINATIONS: Array[String]=["base","rust","station","bunker_surface","bunker_medium","bunker_hard","distribution_friendly","distribution","tradepost"]
const MARKETS: Array[String]=["station","distribution_friendly","distribution","tradepost"]
const LABELS={"base":"Rostgrenze · Heimatbasis","rust":"Signal im Staub","station":"Meridian · Orbitaler Freihafen","space":"Zufälliger Raumkontakt","orbit":"Rostwelt · Orbit","bunker_surface":"Karst · Bunker leicht","bunker_depths":"Karst · Untergrund","bunker_medium":"Kluft · Bunker mittel","bunker_medium_depths":"Kluft · Untergrund","bunker_hard":"Bastion · Bunker schwer","bunker_hard_depths":"Bastion · Untergrund","distribution_friendly":"Freihafen · freundlich","distribution":"Knotenwerk · feindlich","tradepost":"Staubmarkt · Handelsposten"}
static func archetype(region: String) -> String:
	if region in ["bunker_medium","bunker_hard"]:return "bunker_surface"
	if region in ["bunker_medium_depths","bunker_hard_depths"]:return "bunker_depths"
	if region=="distribution_friendly":return "distribution"
	return region
static func underground(region: String) -> bool:return archetype(region)=="bunker_depths"
static func bunker(region: String) -> bool:return archetype(region) in ["bunker_surface","bunker_depths"]
static func depth_scale(region: String) -> float:return {"bunker_depths":2.0,"bunker_medium_depths":2.5,"bunker_hard_depths":3.0}.get(region,1.0)
static func difficulty(region: String) -> int:return 3 if region.begins_with("bunker_hard") else 2 if region.begins_with("bunker_medium") else 1
static func surface(region: String) -> String:return {"bunker_depths":"bunker_surface","bunker_medium_depths":"bunker_medium","bunker_hard_depths":"bunker_hard"}.get(region,region)
static func elevator_target(region: String) -> String:
	return surface(region) if underground(region) else {"bunker_surface":"bunker_depths","bunker_medium":"bunker_medium_depths","bunker_hard":"bunker_hard_depths"}.get(region,"")
static func object_base(id: String) -> String:return id.split("__")[0]
static func object_id(region: String,id: String) -> String:
	if archetype(region)!=region and id in ["surface_cache","bunker_cache","bunker_terminal","distribution_cache","distribution_wreck"]:return id+"__"+region
	return id
static func risk(region: String) -> int:return {"base":0,"rust":20,"station":35,"bunker_surface":25,"bunker_medium":30,"bunker_hard":40,"distribution_friendly":15,"distribution":35,"tradepost":25}.get(region,0)
