extends RefCounted
## Original 24px line icons; rendered as vectors, no font glyph dependencies.
static var _cache: Dictionary={}
const SHAPES := {
	"scrap":"<path d='m2 16 8-4 12 4-8 5zM2 10l8-4 12 4-8 5zM2 10v6m12-1v6m8-11v6'/>",
	"parts":"<path d='m8 2 5 3v6l-5 3-5-3V5zM8 6v4m-2-2h4M16 11l5 3v6l-5 3-5-3v-6z'/><circle cx='16' cy='17' r='2'/>",
	"blackbox":"<rect x='3' y='5' width='18' height='15' rx='2'/><path d='M8 5V2h8v3M7 10h10M7 14h4m3 0h3M7 18h10'/>",
	"ore":"<path d='m3 15 5-10 8-3 6 12-7 8H6zM8 5l7 17m1-20-4 10 10 2M3 15l9-3'/>",
	"alloy":"<path d='m3 9 9-5 9 5v10l-9 3-9-3zM3 9l9 4 9-4M12 13v9M7 7l10 4'/>",
	"repair_attachment":"<path d='M5 22v-9l-3-3V4l4 3 4-3v6l-3 3v9M15 4h7v9h-7zM18 13v9'/>",
	"orbit":"<circle cx='12' cy='12' r='5'/><ellipse cx='12' cy='12' rx='11' ry='4' transform='rotate(-35 12 12)'/><circle cx='3' cy='17' r='2'/>",
	"multitool":"<path d='M3 8h13l5 4-5 3H9l-1 7H4l1-10H3zM16 8V4h5'/>",
	"medgun":"<path d='M3 8h14v8H9l-1 6H4l1-10H3zM17 10h5M10 5v8M6 9h8'/>",
	"med_charge":"<path d='M7 2h10v20H7zM12 7v10M9 12h6'/>",
	"backpack":"<path d='M5 7h14v15H5zM8 7V3h8v4M8 13h8v6H8zM3 10v8m18-8v8'/>",
	"mining_attachment":"<path d='M3 8q9-10 18 0M12 4v10M8 14h8v7H8z'/>",
	"salvage_attachment":"<path d='M6 13h12v9H6zM8 13 3 3m13 10 5-10M12 13V1'/>",
	"network":"<circle cx='12' cy='12' r='9'/><path d='M3 12h18M12 3c-5 6-5 12 0 18M12 3c5 6 5 12 0 18'/>",
	"back":"<path d='m10 4-8 8 8 8M2 12h20'/>",
	"armor":"<path d='m4 3 5-2 3 4 3-4 5 2-2 8 2 10-8 2-8-2 2-10zM8 10h8M8 15h8'/>",
	"mining":"<path d='M3 8q9-10 18 0M12 4 6 22M16 9l6 10-8 3-3-7z'/>",
	"elevator":"<path d='M3 2h18v20H3zM12 5l-4 4m4-4 4 4M12 19l-4-4m4 4 4-4'/>",
	"crew":"<circle cx='12' cy='8' r='4'/><path d='M4 22v-4c0-5 16-5 16 0v4M8 4l-2 5 2 4h8l2-4-2-5'/>",
	"target":"<circle cx='12' cy='12' r='7'/><circle cx='12' cy='12' r='2'/><path d='M12 1v5m0 12v5M1 12h5m12 0h5'/>",
	"contracts":"<path d='M6 3h12v18H6zM9 7h6m-6 4h6m-6 4h3'/>",
	"workbench":"<path d='M14 3a6 6 0 0 0-7 7L2 16l6 6 6-7a6 6 0 0 0 7-7l-5 3-3-3z'/>",
	"storage":"<path d='m3 7 9-5 9 5v11l-9 5-9-5zM3 7l9 5 9-5M12 12v11M7 4l10 6'/>",
	"shuttle":"<path d='m12 2 5 10 5 7-8-2-2 5-2-5-8 2 5-7zM9 11h6'/>",
	"market":"<path d='M3 6h16l-4-4M21 18H5l4 4M19 6l-4 4M5 18l4-4'/>",
	"satellite":"<path d='m8 8 8 8 4-4-8-8zM3 11l4-4 3 3-4 4zm11 7 4-4 3 3-4 4zM15 3l6-2-2 6M13 11l7-7'/>",
	"base":"<path d='m2 11 10-9 10 9M5 9v13h14V9M9 22v-8h6v8'/>",
	"pause":"<path d='M7 4v16M17 4v16' stroke-width='4'/>",
	"play":"<path d='m6 3 15 9-15 9z'/>",
	"menu":"<path d='M3 5h18M3 12h18M3 19h18'/>",
	"close":"<path d='m5 5 14 14M19 5 5 19'/>",
	"toolkit":"<path d='M3 8h18v13H3zM8 8V4h8v4M3 14h18M10 12v4h4v-4'/>",
	"field_repair":"<path d='M4 12h16M12 4v16M3 3h18v18H3z'/>",
	"repair":"<path d='M14 3a6 6 0 0 0-7 7L2 16l6 6 6-7a6 6 0 0 0 7-7l-5 3-3-3z'/>",
	"cutter":"<path d='m3 18 10-10 3 3L6 21zM13 8l3-6 6 6-6 3M17 5l4-4'/>",
	"load":"<path d='M3 16v6h18v-6M12 2v14m-6-6 6 6 6-6'/>",
	"unload":"<path d='M3 16v6h18v-6M12 17V3m-6 6 6-6 6 6'/>",
	"credit":"<path d='m12 2 9 5v10l-9 5-9-5V7zM16 8h-5a4 4 0 0 0 0 8h5'/>",
	"save":"<path d='M3 2h15l3 3v17H3zM7 2v7h10V2M7 22v-8h10v8'/>",
	"lock":"<rect x='4' y='10' width='16' height='12' rx='1'/><path d='M8 10V6a4 4 0 0 1 8 0v4M12 14v4'/>",
	"log":"<path d='M4 3h16v18H4zM8 7h8m-8 5h8m-8 5h5'/>",
	"check":"<path d='m3 12 6 6L21 5'/>",
	"helmet":"<path d='M3 13v-2a9 9 0 0 1 18 0v8l-5 3H8l-5-3zM4 10h16v6H4M9 19h6'/>",
	"upgrade_workbench":"<path d='M2 12h20M5 12v10m14-10v10M8 7l4-5 4 5M12 2v8'/>",
}

static func texture(id: String) -> Texture2D:
	if _cache.has(id): return _cache[id]
	var shape: String=SHAPES.get(id,SHAPES.target)
	var source: String="<svg xmlns='http://www.w3.org/2000/svg' width='24' height='24' viewBox='0 0 24 24'><g fill='none' stroke='#d8e4e4' stroke-width='1.6' stroke-linecap='square' stroke-linejoin='miter'>"+shape+"</g></svg>"
	var image:=Image.new()
	image.load_svg_from_string(source,2.0)
	_cache[id]=ImageTexture.create_from_image(image)
	return _cache[id]
