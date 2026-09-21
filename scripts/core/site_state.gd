extends RefCounted
const Regions=preload("res://scripts/core/regions.gd")
const Catalog=preload("res://scripts/core/catalog.gd")
static func empty_discovery() -> Dictionary:return {"radar_scanned":false,"satellite_found":false,"signals":[]}
static func extend(state:Dictionary) -> void:
 if state.has("site_revision"):return
 # Leave malformed legacy payloads unchanged for the validator to reject.
 if not state.get("ground") is Dictionary or not state.ground.get("enemies") is Dictionary or not state.get("resources") is Dictionary or not state.get("discovery") is Dictionary or not state.get("contract") is Dictionary or not state.has("wreck_remaining"):return
 state.site_revision=8;state.site_records={};state.discovery_site="rust";state.world_claims={}
 for region:String in Regions.ALL:
  if "_v" in region and not state.ground.enemies.has(region):state.ground.enemies[region]=Catalog.ground_enemies(region)
  if Regions.archetype(region)=="rust":
   state.world_claims[region]=false
   state.site_records[region]={"discovery":empty_discovery(),"wreck_remaining":8}
 for id:String in Catalog.resource_sites():
  if "_v" in id and not state.resources.has(id):state.resources[id]={"remaining":Catalog.resource_sites()[id].stock}
 state.site_records.rust={"discovery":state.discovery.duplicate(true),"wreck_remaining":state.wreck_remaining}
 state.world_claims.rust=state.contract.status in ["recovered","claimed"]
static func enter(state:Dictionary,region:String) -> void:
 if Regions.archetype(region)!="rust":return
 state.site_records[state.discovery_site]={"discovery":state.discovery.duplicate(true),"wreck_remaining":state.wreck_remaining}
 state.discovery_site=region
 var record:Dictionary=state.site_records[region]
 state.discovery=record.discovery.duplicate(true);state.wreck_remaining=state.get("world_wrecks",{}).get(region,record.wreck_remaining)
static func wreck(state:Dictionary) -> int:
 return int(state.get("world_wrecks",{}).get(state.get("discovery_site","rust"),state.wreck_remaining))
static func validate(state:Dictionary) -> String:
 if state.has("world_wrecks"):
  if not state.world_wrecks is Dictionary or state.world_wrecks.size()!=4:return "Gemeinsame Wrackbestände fehlen."
  for id:String in ["rust","rust_v2","rust_v3","rust_v4"]:
   var amount:Variant=state.world_wrecks.get(id)
   if not (amount is int or amount is float) or not is_finite(float(amount)) or float(amount)!=floorf(float(amount)) or amount<0 or amount>8:return "Gemeinsamer Wrackbestand ungültig."

 if state.get("site_revision")!=8:return "Ortsversion fehlt."
 if not state.get("site_records") is Dictionary or state.site_records.size()!=4 or not state.get("world_claims") is Dictionary or state.world_claims.size()!=4:return "Ortsstände fehlen."
 if not state.site_records.has(state.get("discovery_site")):return "Erkundungsort ungültig."
 for id:String in ["rust","rust_v2","rust_v3","rust_v4"]:
  if not state.world_claims.get(id) is bool:return "Bergungsbeleg ungültig."
  var record:Variant=state.site_records.get(id)
  if not record is Dictionary or not record.get("discovery") is Dictionary:return "Suchstand fehlt."
  var stock:Variant=record.get("wreck_remaining")
  if not (stock is int or stock is float) or not is_finite(float(stock)) or float(stock)!=floorf(float(stock)) or float(stock)<0 or float(stock)>8:return "Wrackrest ungültig."
  var d:Dictionary=record.discovery
  if not d.get("radar_scanned") is bool or not d.get("satellite_found") is bool or not d.get("signals") is Array or d.signals.size()!=(3 if d.radar_scanned else 0):return "Suchstand ungültig."
  var seen:Dictionary={}
  var found:=false
  for contact:Variant in d.signals:
   if not contact is Dictionary or not contact.get("id") in ["signal_01","signal_02","signal_03"] or seen.has(contact.id) or not contact.get("identified") is bool or not contact.get("position") is Array or contact.position.size()!=2:return "Suchkontakt ungültig."
   var kind:String="unknown" if not contact.identified else "satellite" if contact.id=="signal_01" else "mining_site" if contact.id=="signal_02" else "derelict"
   if contact.get("kind")!=kind or not contact.get("label") is String:return "Suchkontakttyp ungültig."
   if contact.id=="signal_01":found=contact.identified
   seen[contact.id]=true
   var expected:Array=Catalog.radar_contacts(id)[int(str(contact.id).right(2))-1].position
   if contact.position!=expected:return "Suchkontakt außerhalb des Ortes."
  if found!=d.satellite_found:return "Ortsentdeckung widersprüchlich."
 return ""
