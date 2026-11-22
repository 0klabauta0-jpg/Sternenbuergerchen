extends RefCounted
## Rauchwolke fuer Wracks (grey = Bruchlandung/Satellit, black = ausgebrannt).
## CPUParticles3D, weil das Projekt sonst keine Partikel nutzt und CPU-Partikel
## im Headless-/Kompatibilitaetsmodus zuverlaessig laufen. Alle Zahlen in data/fx/wreck_smoke.json.
const RULES_PATH := "res://data/fx/wreck_smoke.json"
static func load_rules(path: String = RULES_PATH) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}
static func preset_for_crash_outcome(outcome: String) -> String:
	if outcome == "explosion": return "black"
	if outcome == "crash": return "grey"
	return ""
static func build(preset_id: String, rules: Dictionary) -> Node3D:
	var presets: Dictionary = rules.get("presets", {})
	if not presets.has(preset_id):
		push_warning("WreckSmoke: unknown preset '%s'" % preset_id)
		return null
	var p: Dictionary = presets[preset_id]
	var root := Node3D.new(); root.name = "WreckSmoke_" + preset_id
	var parts := CPUParticles3D.new(); parts.name = "Particles"
	parts.amount = int(p.amount); parts.lifetime = float(p.lifetime); parts.preprocess = float(p.lifetime) * 0.9
	parts.local_coords = false; parts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parts.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE; parts.emission_sphere_radius = float(p.radius)
	parts.direction = Vector3.UP; parts.spread = float(p.spread_deg)
	parts.initial_velocity_min = float(p.speed) * 0.8; parts.initial_velocity_max = float(p.speed) * 1.2
	parts.gravity = Vector3(float(p.drift), 0.0, float(p.drift) * 0.4)
	var start := maxf(float(p.size_start), 0.01); var ratio := float(p.size_end) / start
	parts.scale_amount_min = start * 0.85; parts.scale_amount_max = start * 1.15
	var curve := Curve.new(); curve.min_value = 0.0; curve.max_value = maxf(1.0, ratio) * 1.05
	curve.add_point(Vector2(0.0, 1.0)); curve.add_point(Vector2(1.0, ratio)); parts.scale_amount_curve = curve
	var base := Color(String(p.color_base)); base.a = float(p.alpha_base)
	var tip := Color(String(p.color_tip)); tip.a = float(p.alpha_tip)
	var ramp := Gradient.new(); ramp.set_color(0, base); ramp.set_color(1, tip); parts.color_ramp = ramp
	var quad := QuadMesh.new(); quad.size = Vector2.ONE
	var puff := GradientTexture2D.new(); puff.fill = GradientTexture2D.FILL_RADIAL; puff.fill_from = Vector2(0.5, 0.5); puff.fill_to = Vector2(0.5, 0.0)
	puff.width = 64; puff.height = 64
	var soft := Gradient.new(); soft.set_color(0, Color(1, 1, 1, 1)); soft.set_color(1, Color(1, 1, 1, 0)); puff.gradient = soft
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES; material.vertex_color_use_as_albedo = true
	material.albedo_texture = puff; material.cull_mode = BaseMaterial3D.CULL_DISABLED; material.disable_receive_shadows = true
	quad.material = material; parts.mesh = quad
	parts.emitting = true
	root.add_child(parts)
	return root
