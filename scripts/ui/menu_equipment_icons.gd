extends RefCounted
## Illustrated menu identities. Map models and combat data remain unchanged.
const PATH="res://Assets/curated/ui/menu_equipment_20261110/icons_01.png"
const CELLS={"suit":0,"armor_light":0,"rifle":1,"pistol":2,"medictool":3,"mining_tool":4,"satellite_chip":5,"outpost_chip":5}
static var _cache:Dictionary={}
static func get_icon(item_id:String)->Texture2D:
	if not CELLS.has(item_id):return null
	if not _cache.has(item_id):
		var atlas:Texture2D=load(PATH)
		if atlas==null:return null
		var cell:int=int(CELLS[item_id])
		var texture:=AtlasTexture.new();texture.atlas=atlas
		var edge:=Vector2(atlas.get_width()/3.0,atlas.get_height()/2.0)
		texture.region=Rect2(Vector2(cell%3,int(cell/3))*edge,edge)
		texture.filter_clip=true
		_cache[item_id]=texture
	return _cache[item_id]
