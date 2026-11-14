shader_type spatial;
render_mode diffuse_burley;

// Static material-only study: no displacement, normal change, animation or light.
uniform vec4 base_color : source_color = vec4(0.7, 0.72, 0.63, 1.0);
uniform vec4 dust_color : source_color = vec4(0.60, 0.42, 0.28, 1.0);
uniform vec3 building_origin = vec3(0.0);
uniform float building_height = 1.0;
uniform float pattern_seed = 3.2;
uniform float wear_strength : hint_range(0.0, 1.0) = 1.0;
// Dust, sun bleaching, directed wash, selective edge abrasion.
uniform vec4 role_strength = vec4(0.55, 0.42, 0.50, 0.30);
// Immutable mesh bounds; shared material variants require no instance buffer.
uniform vec3 wear_part_min = vec3(-0.5);
uniform vec3 wear_part_max = vec3(0.5);
varying vec3 building_position;
varying vec3 surface_normal_world;
varying vec3 part_position;

float stable_hash(vec2 p) {
	uvec2 q = uvec2(ivec2(p));
	uint h = (q.x * 1597334677u) ^ (q.y * 3812015801u);
	h = (h ^ (h >> 16u)) * 2246822519u;
	h = (h ^ (h >> 13u)) * 3266489917u;
	h = h ^ (h >> 16u);
	return float(h & 16777215u) / 16777215.0;
}

float soft_field(vec2 p) {
	vec2 cell = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(stable_hash(cell), stable_hash(cell + vec2(1.0, 0.0)), u.x),
		mix(stable_hash(cell + vec2(0.0, 1.0)), stable_hash(cell + vec2(1.0)), u.x), u.y);
}

float middle_distance(vec3 d) {
	return max(min(d.x, d.y), min(max(d.x, d.y), d.z));
}

void vertex() {
	building_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz - building_origin;
	surface_normal_world = normalize(MODEL_NORMAL_MATRIX * NORMAL);
	part_position = VERTEX;
}

void fragment() {
	vec3 n = normalize(surface_normal_world);
	vec3 p = building_position;
	float up = smoothstep(0.25, 0.86, n.y);
	float wall = 1.0 - up;
	vec2 wall_uv = mix(vec2(p.x, p.y), vec2(p.z, p.y), smoothstep(0.45, 0.90, abs(n.x)));
	vec2 roof_uv = vec2(p.x * 0.92 + p.z * 0.38, p.z * 0.92 - p.x * 0.38);
	vec2 uv = mix(wall_uv, roof_uv, up);
	vec2 seed = vec2(pattern_seed, pattern_seed * 0.37);
	// Metre-scale softly layered pigment, then a much weaker middle brush scale.
	float broad = soft_field(uv * vec2(1.05, 0.86) + seed);
	float middle = soft_field(uv * vec2(3.7, 2.2) + seed.yx + vec2(broad * 0.6, 4.3));
	float pigment = (broad - 0.5) * 0.38 + (middle - 0.5) * 0.075;
	vec3 paint = base_color.rgb * (1.0 + pigment * wear_strength);
	// Upper surfaces fade toward warm chalk; broad quiet areas remain intact.
	float bleaching = up * smoothstep(0.18, 0.80, broad) * role_strength.y;
	vec3 faded = mix(base_color.rgb, vec3(0.66, 0.63, 0.52), 0.18);
	// Grafikpass R1: roofs keep their petrol/slate identity under the warm sun;
	// the former 1.46 lift read as white-blue glass at play distance.
	faded = max(faded, base_color.rgb * 1.18);
	paint = mix(paint, faded, bleaching * 0.50 * wear_strength);
	// Dust is concentrated at the base, with a softly broken accumulation line.
	float relative_height = max(p.y, 0.0) / max(building_height, 0.2);
	float dust_height = relative_height + (broad - 0.5) * 0.065;
	float base_dust = (1.0 - smoothstep(0.035, 0.27, dust_height))
		* mix(0.54, 0.94, middle) * role_strength.x;
	float roof_deposit = up * smoothstep(0.57, 0.83, middle) * role_strength.x * 0.14;
	paint = mix(paint, dust_color.rgb, clamp((base_dust * 0.50 + roof_deposit) * wear_strength, 0.0, 0.55));
	// Sparse long wash marks descend on selected facade zones, never an all-over grid.
	float flow_region = smoothstep(0.48, 0.78, soft_field(vec2(wall_uv.x * 1.6, pattern_seed + 1.7)));
	float flow = soft_field(wall_uv * vec2(13.0, 1.2) + vec2(broad * 0.9, pattern_seed * 0.21));
	float run = wall * flow_region * smoothstep(0.57, 0.84, flow)
		* smoothstep(0.13, 0.66, relative_height) * role_strength.z;
	paint *= 1.0 - run * 0.18 * wear_strength;
	paint = mix(paint, dust_color.rgb * 0.90, run * 0.12 * wear_strength);
	// Per-component mesh bounds localize abrasion to a few physical edge areas.
	vec3 half_size = max((wear_part_max - wear_part_min) * 0.5, vec3(0.0001));
	vec3 center = (wear_part_min + wear_part_max) * 0.5;
	vec3 distances = max(half_size - abs(part_position - center), vec3(0.0));
	float edge = 1.0 - smoothstep(0.003, 0.014, middle_distance(distances));
	float edge_selection = smoothstep(0.62, 0.84, soft_field(uv * vec2(18.0, 7.0) + seed + vec2(5.4, 0.8)));
	float abrasion = edge * edge_selection * role_strength.w * wear_strength;
	vec3 undercoat = mix(base_color.rgb * 0.50, vec3(0.19, 0.23, 0.22), 0.26);
	paint = mix(paint, undercoat, abrasion * 0.65);
	// Grafikpass R1: reference hulls are warm cream with petrol roofs. Pale
	// neutral paint is pulled towards sand-cream so sunlit panels no longer
	// clip to cold white; blue-green paint gains a little depth.
	float grade_gamma = OUTPUT_IS_SRGB ? 1.0 : 2.2;
	vec3 graded = OUTPUT_IS_SRGB ? paint : pow(max(paint, vec3(0.0)), vec3(1.0 / 2.2));
	float high = max(graded.r, max(graded.g, graded.b));
	float low = min(graded.r, min(graded.g, graded.b));
	float pale_hull = smoothstep(0.58, 0.78, high) * (1.0 - smoothstep(0.10, 0.24, high - low));
	float petrol = smoothstep(0.02, 0.12, min(graded.g, graded.b) - graded.r) * (1.0 - smoothstep(0.62, 0.80, high));
	paint = mix(paint, paint * pow(vec3(0.92, 0.84, 0.69), vec3(grade_gamma)), pale_hull * 0.85);
	paint = mix(paint, paint * pow(vec3(0.74, 0.93, 0.98), vec3(grade_gamma)), petrol * 0.70);
	ALBEDO = clamp(paint, vec3(0.0), vec3(1.0));
	ROUGHNESS = clamp(0.92 + (base_dust + bleaching) * 0.035 * wear_strength, 0.0, 1.0);
	METALLIC = 0.0;
	SPECULAR = 0.5;
}
