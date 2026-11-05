extends RefCounted

# Small authored vector shapes. They encode display meaning only; the caller
# supplies the badge read from the runtime owner, never a second unit state.
static var _textures: Dictionary = {}


static func icon_id_for_badge(badge_text: String) -> String:
	var badge: String = badge_text.strip_edges().to_upper()
	if badge == "DOWN":
		return "down"
	if badge == "BLEEDOUT":
		return "bleedout"
	if badge.begins_with("RESPAWN"):
		return "respawn"
	if badge.begins_with("HP "):
		return "wounded"
	if badge == "CONTACT" or badge == "ENGAGE":
		return "contact"
	if badge == "MOVE" or badge == "FLANK":
		return "move"
	if badge == "DEF" or badge == "HOLD":
		return "defend"
	if badge == "TAKE":
		return "take"
	return ""


static func get_icon(icon_id: String) -> Texture2D:
	if _textures.has(icon_id):
		return _textures[icon_id] as Texture2D
	var paths: String = ""
	match icon_id:
		"wounded":
			paths = '<g transform="rotate(-40 32 32)"><rect x="14" y="23" width="36" height="18" rx="5"/><path d="M27 23v18m10-18v18"/><path d="M19 29v6m26-6v6" stroke-width="3"/></g>'
		"down":
			paths = '<circle cx="16" cy="37" r="4"/><path d="M25 39h24M30 39l8-10h10M31 19h14m-7-7v14"/>'
		"bleedout":
			paths = '<path d="M32 12C26 23 18 30 18 39a14 14 0 0 0 28 0c0-9-8-16-14-27z"/><path d="M32 30v10m0 7v1"/>'
		"respawn":
			paths = '<path d="M16 25a19 19 0 1 1-1 15M15 14v13h13"/><path d="M33 21v13l9 5"/>'
		"shot":
			paths = '<path d="M32 10l4 14 13-8-8 14 13 4-15 4 7 14-13-9-6 12-1-15-16 4 12-10-9-11 14 3z" stroke-width="3"/>'
		"contact":
			paths = '<circle cx="32" cy="32" r="13"/><path d="M32 10v12m0 20v12M10 32h12m20 0h12"/>'
		"move":
			paths = '<path d="M13 32h35M34 18l14 14-14 14"/>'
		"defend":
			paths = '<path d="M32 11l17 7v14c0 11-9 19-17 22-8-3-17-11-17-22V18z"/><path d="M24 32l6 6 12-14"/>'
		"take":
			paths = '<path d="M19 52V12h27l-6 10 6 10H19"/>'
		_:
			return null
	var svg: String = '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64"><circle cx="32" cy="32" r="30" fill="#09212a" fill-opacity="0.94" stroke="#d4eff0" stroke-width="2"/><g fill="none" stroke="#fff5d6" stroke-width="4" stroke-linecap="round" stroke-linejoin="round">%s</g></svg>' % paths
	var image := Image.new()
	if image.load_svg_from_string(svg) != OK:
		return null
	var texture := ImageTexture.create_from_image(image)
	_textures[icon_id] = texture
	return texture
