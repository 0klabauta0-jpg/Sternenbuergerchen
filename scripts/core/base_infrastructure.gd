extends RefCounted
## Real base capacity; power is a rate, never an inventory resource.
static func extend(state:Dictionary) -> void:
 if not state.base.has("infrastructure"):state.base.infrastructure={"solar":3,"solar_tier":1,"sender_tier":1,"sender_enabled":true,"fusion_small":0,"fusion_large":0}
 for field:String in ["fusion_small","fusion_large"]:
  if not state.base.infrastructure.has(field):state.base.infrastructure[field]=0
 if not "build_solar" in state.blueprints:state.blueprints.append("build_solar")
 if state.contract.status=="claimed" and not "research_energy" in state.blueprints:state.blueprints.append("research_energy")
static func validate(state:Dictionary) -> String:
 if not state.get("base") is Dictionary:return "Basisdaten ungültig."
 if not state.base.has("infrastructure"):return ""
 var value:Variant=state.base.infrastructure
 if not value is Dictionary or value.size()!=6:return "Basisversorgung ungültig."
 for id:String in ["solar","solar_tier","sender_tier","fusion_small","fusion_large"]:
  var v:Variant=value.get(id)
  if not (v is int or v is float) or not is_finite(float(v)) or float(v)!=floorf(float(v)) or float(v)<(0 if id.begins_with("fusion") else 1) or float(v)>(6 if id=="solar" else 3 if id=="solar_tier" else 2 if id=="sender_tier" else 1):return "Ausbaustufe ungültig."
 if not value.get("sender_enabled") is bool:return "Senderzustand ungültig."
 return ""
static func budget(state:Dictionary,recipe_id:String="") -> Dictionary:
 var data:Dictionary=state.base.get("infrastructure",{"solar":3,"solar_tier":1,"sender_tier":1,"sender_enabled":true,"fusion_small":0,"fusion_large":0})
 var supply:int=int(data.solar)*([8,14,22][int(data.solar_tier)-1])+int(data.get("fusion_small",0))*80+int(data.get("fusion_large",0))*240
 var idle:int=6+(int(data.sender_tier)*4 if data.sender_enabled else 0)
 var demand:int=0
 if not recipe_id.is_empty():demand=(12 if state.base.workbench_tier>=2 else 6)+(6 if recipe_id.begins_with("research_") else 0)
 return {"supply":supply,"idle":idle,"work":demand,"remaining":supply-idle-demand,"powered":supply>=idle+demand}
static func recipes() -> Dictionary:
 return {
 "build_solar":{"label":"Solarmodul bauen","materials":{"scrap":4,"parts":2},"duration":18.0,"min_skill":2,"tier":1,"output":{}},
 "research_energy":{"label":"Forschung · Energietechnik","materials":{"scrap":3,"parts":2},"duration":35.0,"min_skill":3,"tier":2,"output":{},"unlocks":["upgrade_solar","upgrade_solar_three","research_communications","research_fusion"]},
 "upgrade_solar":{"label":"Solarversorgung II","materials":{"alloy":2,"parts":3},"duration":25.0,"min_skill":3,"tier":2,"output":{}},
 "research_communications":{"label":"Forschung · Relaistechnik","materials":{"parts":3,"alloy":1},"duration":40.0,"min_skill":3,"tier":2,"output":{},"unlocks":["upgrade_sender"]},
 "upgrade_solar_three":{"label":"Solarversorgung III","materials":{"alloy":4,"parts":5},"duration":40.0,"min_skill":3,"tier":2,"output":{}},
 "research_fusion":{"label":"Forschung · Kleine Fusion","materials":{"alloy":3,"parts":4},"duration":60.0,"min_skill":3,"tier":2,"output":{},"unlocks":["build_fusion_small","research_fusion_large"]},
 "build_fusion_small":{"label":"Kleiner Fusionsreaktor","materials":{"alloy":8,"parts":10,"scrap":12},"duration":70.0,"min_skill":3,"tier":2,"output":{}},
 "research_fusion_large":{"label":"Forschung · Große Fusion","materials":{"alloy":6,"parts":8},"duration":90.0,"min_skill":3,"tier":2,"output":{},"unlocks":["build_fusion_large"]},
 "build_fusion_large":{"label":"Großer Fusionsreaktor","materials":{"alloy":16,"parts":20,"scrap":24},"duration":100.0,"min_skill":3,"tier":2,"output":{}},
 "upgrade_sender":{"label":"Sendestation II","materials":{"parts":4,"alloy":2},"duration":25.0,"min_skill":3,"tier":2,"output":{}}
 }
static func available(state:Dictionary,id:String) -> String:
 var data:Dictionary=state.base.infrastructure
 if id=="upgrade_solar_three" and data.solar_tier!=2:return "Solar III benötigt Solar II und ist nur einmal baubar."
 if id=="build_fusion_small" and (data.fusion_small>=1 or data.solar_tier<3):return "Kleine Fusion benötigt Solar III; ein Reaktorplatz verfügbar."
 if id=="build_fusion_large" and (data.fusion_large>=1 or data.fusion_small<1):return "Große Fusion benötigt den kleinen Reaktor; ein Reaktorplatz verfügbar."
 if id=="build_solar" and data.solar>=6:return "Alle sechs Solarplätze sind belegt."
 if id=="upgrade_solar" and data.solar_tier>=2:return "Solarversorgung bereits ausgebaut."
 if id=="upgrade_sender" and data.sender_tier>=2:return "Sendestation bereits ausgebaut."
 return ""
static func complete(state:Dictionary,id:String) -> void:
 match id:
  "build_solar":state.base.infrastructure.solar+=1
  "upgrade_solar":state.base.infrastructure.solar_tier=2
  "upgrade_solar_three":state.base.infrastructure.solar_tier=3
  "build_fusion_small":state.base.infrastructure.fusion_small=1
  "build_fusion_large":state.base.infrastructure.fusion_large=1
  "upgrade_sender":state.base.infrastructure.sender_tier=2

static func offers() -> Dictionary:
 return {"build_solar":{"label":"Solarmodul I · +8 bis 22 Leistung","price":140},"upgrade_solar":{"label":"Solar II · alle Module verbessern","price":420},"upgrade_solar_three":{"label":"Solar III · alle Module verbessern","price":850},"build_fusion_small":{"label":"Kleiner Fusionsreaktor · +80 Leistung","price":2200},"build_fusion_large":{"label":"Großer Fusionsreaktor · +240 Leistung","price":5800},"upgrade_sender":{"label":"Sendestation II","price":650},"research_energy":{"label":"Bauplan Energieforschung","price":180},"research_fusion":{"label":"Bauplan kleine Fusionsforschung","price":650},"research_fusion_large":{"label":"Bauplan große Fusionsforschung","price":1400}}
static func buy(state:Dictionary,id:String) -> String:
 if state.region!="base":return "Basisversorgung wird mit Lieferung und Montage an der Heimatbasis bestellt."
 if not offers().has(id):return "Unbekanntes Energieangebot."
 var offer:Dictionary=offers()[id]
 var blueprint:=id.begins_with("research_")
 if blueprint and id in state.blueprints:return "Bauplan bereits vorhanden."
 if not blueprint:
  var reason:=available(state,id)
  if not reason.is_empty():return reason
  if state.work.active:return "Montage erst nach Abschluss der laufenden Werkstattarbeit."
 var stock:Dictionary=state.market_stock.station.items
 var stock_id:="power:"+id
 if int(stock.get(stock_id,0))<=0:return "Lieferant ausverkauft. Nächsten Nachschub abwarten."
 if state.credits<int(offer.price):return "Nicht genügend Credits."
 state.credits-=int(offer.price)
 stock[stock_id]-=1
 if blueprint:state.blueprints.append(id)
 else:complete(state,id)
 return ""

static func site_access(state:Dictionary,destination:String) -> String:
 if preload("res://scripts/core/regions.gd").variant(destination)>=2 and int(state.base.get("infrastructure",{}).get("sender_tier",1))<2:
  return "Fernkoordinaten benötigen Sendestation II. Basis, Meridian und lokale Orte bleiben erreichbar."
 return ""
