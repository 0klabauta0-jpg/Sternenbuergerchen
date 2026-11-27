shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform vec4 base_color : source_color = vec4(0.76, 0.49, 0.30, 1.0);
uniform bool surface_blending = false;
// Opt-in location palette; existing mission and station materials keep their route.
uniform bool homebase_palette = false;
uniform bool quiet_tactical_surface = false;
uniform sampler2D surface_mask : filter_linear, repeat_disable;
uniform vec4 surface_bounds = vec4(0.0,0.0,1.0,1.0);
uniform vec4 world_to_grid = vec4(1.0,0.0,0.0,1.0);
uniform bool rock_strata = false;
uniform float slope_normal_softening = 0.0;
uniform bool paved_surface = false;
uniform bool authored_paving_wear = false;
uniform vec4 wear_service_span = vec4(11.2,10.45,15.0,10.45);
uniform vec4 wear_hall_span = vec4(13.2,8.48,13.2,10.45);
uniform vec4 wear_utility_span = vec4(15.15,10.25,16.1,9.15);
uniform bool marking_surface = false;
uniform vec4 sediment_color : source_color = vec4(0.73, 0.51, 0.33, 1.0);
// Grafikpass R1: broad wind-laid drifts and rust pans. Low-frequency value and
// hue only, so wide fields stay quiet and no cell lattice is drawn.
uniform float drift_strength : hint_range(0.0, 1.5) = 0.8;
uniform float rock_facet_strength : hint_range(0.0, 1.5) = 1.0;
// Grafikpass R2: narrow sand strips on otherwise firm ground read as a worn
// footpath that wanders inside its hexes. Set by the profile per map.
uniform bool trail_surface = false;
// Direction towards the profile sun (rotation -52/-32). Faces turned away
// from it receive a warm bounce so shaded cliffs keep their stone colour.
uniform vec3 sun_direction_world = vec3(-0.326, 0.788, 0.522);
// 1.0 paints roads into the ground; lower when a built road deck covers them.
uniform float road_paint_strength : hint_range(0.0, 1.0) = 1.0;
// Versuch Bodentexturen: tileable ground photos in WORLD space replace the
// computed base colour. The default is OFF, so every material that does not
// get the switch from the art profile keeps the old picture; OFF is exact.
uniform bool ground_tiles_enabled = false;
uniform sampler2D ground_tex_normal : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D ground_tex_gravel : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D ground_tex_clay : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D ground_tex_rock : source_color, filter_linear_mipmap, repeat_enable;
const bool GROUND_BASE_OWN_TEXTURE = false;
uniform sampler2D ground_tex_base : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D ground_tex_paving : source_color, filter_linear_mipmap, repeat_enable;
// Grafik 1 (27.11.), nur Einsatz-Stimmung (mission_variation > 0): geschichteter Canyon-Fels (04)
// und helle Sandsteinflecken (05) statt 01 auf Erhoehungen; Sand (07) und der staubige
// Wegrand mit Grauplatten (10). Jede Abfrage steht hinter einer Gewichtsschwelle,
// ein Pixel liest im Regelfall hoechstens drei bis vier Texturen.
uniform sampler2D ground_tex_rock_canyon : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D ground_tex_rock_light : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D ground_tex_sand : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D ground_tex_paving_edge : source_color, filter_linear_mipmap, repeat_enable;
// Anteil heller Sandsteinflecken auf Fels (Schwelle des Rauschens: hoeher = weniger Flaeche).
uniform float ground_rock_light_threshold : hint_range(0.0, 1.0) = 0.50;
// Grossflaechiges Farb-/Helligkeitsrauschen (Einsatzkarten). 0 = aus (Vorgabe, Heimatbasis, Editor).
// Wellenlaenge rund 20 bis 45 m; Staerke 1.0 = plus/minus etwa 8 % Helligkeit.
uniform float mission_variation : hint_range(0.0, 2.0) = 0.0;
// Edge length of one texture tile in metres (one field is about 1 m).
uniform float ground_tile_meters : hint_range(1.0, 16.0) = 4.0;
// The ONE brightness knob for all ground textures (old ground was about 0.43 luminance).
uniform float ground_tile_brightness : hint_range(0.2, 1.5) = 0.92;
// The base concrete slabs are far paler than the rest; scaled down on its own.
uniform float ground_base_tile_gain : hint_range(0.1, 1.0) = 0.45;
// How much of the old zoom dependent darkening (gravel, cracks, wind ripples) stays on top.
uniform float ground_detail_keep : hint_range(0.0, 1.0) = 0.35;
// Wide soft patches of the variants: patches per metre, coverage thresholds of
// the noise (higher = less area; gravel about a quarter, clay about a tenth) and edge softness.
uniform float ground_patch_scale : hint_range(0.02, 0.5) = 0.11;
uniform float ground_patch_gravel : hint_range(0.0, 1.0) = 0.58;
uniform float ground_patch_clay : hint_range(0.0, 1.0) = 0.70;
uniform float ground_patch_softness : hint_range(0.02, 0.4) = 0.10;
varying vec3 ground_world_position;
varying vec3 ground_world_normal;
varying float ramp_incline;

float patch_hash(vec2 p) {
	// Integer lattice hashing keeps shared corners identical after GPU inlining.
	// A sine hash can disagree between equivalent corner expressions and expose
	// the noise lattice as large hard-edged polygons on otherwise flat ground.
	uvec2 q = uvec2(ivec2(p));
	uint h = (q.x * 1597334677u) ^ (q.y * 3812015801u);
	h = (h ^ (h >> 16u)) * 2246822519u;
	h = (h ^ (h >> 13u)) * 3266489917u;
	h = h ^ (h >> 16u);
	return float(h & 16777215u) / 16777215.0;
}

float broad_patch(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(patch_hash(i), patch_hash(i + vec2(1.0, 0.0)), u.x),
		mix(patch_hash(i + vec2(0.0, 1.0)), patch_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float detail_visibility(vec2 p) {
	// Use continuous coordinates: derivatives of fract/floor themselves jump at
	// cell borders. Fade detail before its noise cells become subpixel samples.
	float footprint = max(length(dFdx(p)), length(dFdy(p)));
	return 1.0 - smoothstep(0.25, 0.75, footprint);
}

// Signed drift field in map space: positive is pale blown sand, negative is
// the darker scoured pan between drifts. Two octaves, stretched downwind.
float wind_drift(vec2 p) {
	vec2 wind = vec2(p.x * 0.80 + p.y * 0.60, p.y * 0.80 - p.x * 0.60);
	float meander = broad_patch(p * 0.045 + vec2(31.0, 17.0)) - 0.5;
	wind.y += meander * 4.5;
	float long_band = broad_patch(wind * vec2(0.034, 0.170) + vec2(5.3, 9.1));
	float short_band = broad_patch(wind * vec2(0.075, 0.400) + vec2(13.7, 2.9));
	float ripple = broad_patch(wind * vec2(0.170, 0.900) + vec2(long_band * 2.0, 4.4));
	return clamp((long_band * 0.50 + short_band * 0.32 + ripple * 0.18) * 2.6 - 1.3, -1.0, 1.0);
}

// Quarry-stone blocks for cliff faces. Returns x: block tone (-1..1),
// y: joint weight (0..1), z: position inside the block (-1 foot .. 1 crown).
vec3 fracture_facets(vec2 face) {
	vec2 q = face * vec2(1.05, 0.52);
	vec2 cell = floor(q);
	vec2 local = fract(q);
	float nearest = 8.0;
	float second = 8.0;
	float tone = 0.0;
	float rise = 0.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 offset = vec2(float(x), float(y));
			vec2 id = cell + offset;
			vec2 site = offset + vec2(patch_hash(id + vec2(101.0, 57.0)), patch_hash(id + vec2(211.0, 139.0)));
			vec2 delta = site - local;
			float distance = abs(delta.x) * 0.92 + abs(delta.y) * 0.55 + length(delta) * 0.35;
			if (distance < nearest) {
				second = nearest;
				nearest = distance;
				tone = patch_hash(id + vec2(331.0, 419.0));
				rise = -delta.y;
			} else if (distance < second) {
				second = distance;
			}
		}
	}
	float gap = second - nearest;
	float edge = max(fwidth(gap), 0.02);
	return vec3(tone * 2.0 - 1.0, 1.0 - smoothstep(0.03 - edge, 0.10 + edge, gap), clamp(rise * 1.6, -1.0, 1.0));
}

float wheel_mark(vec2 p,vec2 a,vec2 b) {
	vec2 segment=b-a;
	float t=clamp(dot(p-a,segment)/dot(segment,segment),0.0,1.0);
	return (1.0-smoothstep(0.025,0.075,length(p-a-segment*t)))*smoothstep(0.0,0.15,t)*(1.0-smoothstep(0.8,1.0,t));
}

float dusty_shoulder(vec2 p,vec2 a,vec2 b,float width) {
	vec2 segment=b-a;
	float t=dot(p-a,segment)/dot(segment,segment);
	float edge=abs(length(p-a-segment*clamp(t,0.0,1.0))-width*0.46);
	return (1.0-smoothstep(0.02,0.14,edge))*smoothstep(0.0,0.14,t)*(1.0-smoothstep(0.86,1.0,t));
}

void vertex() {
	ramp_incline = 1.0 - clamp(NORMAL.y, 0.0, 1.0);
	NORMAL = normalize(mix(NORMAL, vec3(0.0, 1.0, 0.0), slope_normal_softening));
	ground_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	ground_world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	if (marking_surface) {
		float wear_area = broad_patch(ground_world_position.xz * 5.5 + vec2(3.1, 8.7));
		float chip = broad_patch(ground_world_position.xz * 95.0);
		if (wear_area > 0.45 && chip > mix(0.82, 0.45, wear_area)) { discard; }
	}
	// Bodentexturen: what the old code computes anyway is only recorded here
	// (darkening factor and the road / rock / water weights); nothing old changes.
	float tile_detail = 1.0;
	float tile_road = 0.0;
	float tile_rock = 0.0;
	float tile_water = 0.0;
	float tile_sand = 0.0;
	// Authored tints are sRGB ratios; a linear target needs the matching power.
	float tint_gamma = OUTPUT_IS_SRGB ? 1.0 : 2.2;
	float drift_mask = paved_surface ? 0.30 : 1.0;
	// Continuous world coordinates keep the same broad paint patches across tile seams.
	float patch = broad_patch(ground_world_position.xz * 0.40);
	float region = broad_patch(ground_world_position.xz * 0.13 + vec2(12.1, 4.8));
	float grit = mix(0.5, broad_patch(ground_world_position.xz * 18.0), detail_visibility(ground_world_position.xz * 18.0));
	float sediment = broad_patch(ground_world_position.xz * 1.6 + vec2(region * 3.0, patch));
	float value = mix(0.87, 1.12, smoothstep(0.10, 0.88, patch));
	if (slope_normal_softening > 0.0) {
		// A broad, quiet value change makes the actual grade readable at play distance.
		// No extra texture, geometry, or gameplay classification is introduced.
		value *= 1.0 - 0.18 * smoothstep(0.05, 0.32, ramp_incline);
	}
	vec3 pigment = mix(base_color.rgb * vec3(0.91, 0.89, 0.91), base_color.rgb * vec3(1.14, 1.10, 1.0), region);
	value *= mix(0.97, 1.025, grit);
	// Soft sediment fields break up the flat paint without drawing a square/hex grid.
	value *= mix(0.94, 1.035, smoothstep(0.20, 0.80, sediment));
	if (rock_strata) {
		// Broken broad pigment beds support the mesh, without regular ring stripes.
		float layer = broad_patch(vec2(ground_world_position.y * 2.1 + region * 0.7,
			ground_world_position.x * 0.17 + ground_world_position.z * 0.13));
		value *= mix(0.90, 1.045, layer);
		// Warped, discontinuous beds and short vertical wash marks: the fine scale
		// follows the cliff rather than drawing uniform rings around every block.
		vec2 face = vec2(ground_world_position.x + ground_world_position.z * 0.63,
			ground_world_position.y);
		float wash = broad_patch(face * vec2(6.5, 0.65) + vec2(region * 1.5, 0.0));
		float bed = broad_patch(vec2(face.x * 0.72, face.y * 6.0 + patch * 1.8));
		float seams = (1.0 - smoothstep(0.035, 0.11, abs(bed - 0.48)))
			* smoothstep(0.38, 0.70, broad_patch(face * 2.7));
		float exposed = smoothstep(0.40, 0.88, ground_world_normal.y);
		value *= 1.0 - (seams * 0.065 + smoothstep(0.60, 0.84, wash) * 0.055) * (1.0 - exposed);
		pigment = mix(pigment, base_color.rgb * vec3(1.28, 1.20, 1.09),
			exposed * (0.12 + 0.22 * broad_patch(ground_world_position.xz * 2.5)));
		pigment = mix(pigment, base_color.rgb * vec3(1.17, 1.06, 0.97),
			smoothstep(0.46, 0.74, wash) * 0.17 * (1.0 - exposed));
		// Grafikpass R1: jointed fracture blocks on the walls (selected cliff
		// variant), a shaded foot and a sun-bleached crown. Geometry is unchanged.
		float wall = (1.0 - exposed) * rock_facet_strength;
		float along = abs(ground_world_normal.x) > abs(ground_world_normal.z) ? ground_world_position.z : ground_world_position.x;
		vec3 facets = fracture_facets(vec2(along, ground_world_position.y) * 1.6 + vec2(region * 0.6, 0.0));
		value *= pow(1.0 + facets.x * 0.13 * wall, tint_gamma);
		value *= pow(1.0 - facets.y * 0.30 * wall, tint_gamma);
		// Each block catches light on its upper edge and shades towards its
		// foot: chunky quarried stone instead of a flat printed crack pattern.
		value *= pow(1.0 + facets.z * 0.11 * wall * (1.0 - facets.y), tint_gamma);
		float foot = 1.0 - smoothstep(-0.05, 0.85, ground_world_position.y);
		value *= pow(1.0 - foot * 0.20 * wall, tint_gamma);
		pigment = mix(pigment, pigment * pow(vec3(0.86, 0.74, 0.78), vec3(tint_gamma)), facets.y * 0.55 * wall);
		float crown = exposed * rock_facet_strength;
		pigment = mix(pigment, pigment * pow(vec3(1.10, 1.09, 1.03), vec3(tint_gamma)), crown * 0.75);
	} else {
		// Broad brush-like silt fans with a consistent wind direction. Wide quiet
		// fields remain; only selected deposits receive small dark crust fragments.
		vec2 p = ground_world_position.xz;
		vec2 flow = vec2(p.x * 0.90 + p.y * 0.43, p.y * 0.90 - p.x * 0.43);
		float stroke = broad_patch(flow * vec2(0.85, 1.6) + vec2(region * 1.2, patch * 1.4));
		float deposit = smoothstep(0.48, 0.78, broad_patch(p * 0.80 + vec2(7.2, 1.4)));
		float crust = smoothstep(0.55, 0.82, broad_patch(p * 9.0 + vec2(stroke * 0.45, 0.0))) * detail_visibility(p * 9.0);
		float silt = deposit * smoothstep(0.28, 0.70, stroke);
		pigment = mix(pigment, base_color.rgb * vec3(1.40, 1.29, 1.12), silt * 0.50);
		value *= 1.0 - deposit * crust * (paved_surface && !surface_blending ? 0.025 : 0.06);
		value *= mix(0.94, 1.04, stroke);
	}
	if (paved_surface && !surface_blending) {
		if (authored_paving_wear) {
			float wheels=max(wheel_mark(ground_world_position.xz,wear_hall_span.xy+vec2(-0.28,0.0),wear_hall_span.zw+vec2(-0.28,0.0)),wheel_mark(ground_world_position.xz,wear_hall_span.xy+vec2(0.28,0.0),wear_hall_span.zw+vec2(0.28,0.0)));
			value*=1.0-wheels*0.18;
		}
		// Scuffed aggregate and dusty, broad paint loss. No regular tile lattice.
		float scuff = smoothstep(0.46, 0.72, broad_patch(ground_world_position.xz * 3.7));
		float worn = smoothstep(0.42, 0.75, sediment) * scuff;
		pigment = mix(pigment, base_color.rgb * vec3(1.24, 1.18, 1.04), worn * 0.58);
		value *= mix(0.90, 1.045, mix(0.5, broad_patch(ground_world_position.xz * 11.0), detail_visibility(ground_world_position.xz * 11.0)));
		// Local deposits on quiet straight approach spans soften selected road
		// shoulders without a second coplanar overlay or a universal orange border.
		vec2 p=ground_world_position.xz;
		float shoulder=authored_paving_wear?dusty_shoulder(p,wear_service_span.xy,wear_service_span.zw,1.04):0.0;
		shoulder=max(shoulder,authored_paving_wear?dusty_shoulder(p,wear_hall_span.xy,wear_hall_span.zw,0.84):0.0);
		shoulder=max(shoulder,authored_paving_wear?dusty_shoulder(p,wear_utility_span.xy,wear_utility_span.zw,0.64):0.0);
		float broken_deposit=shoulder*smoothstep(0.40,0.80,broad_patch(p*7.0+vec2(patch,region)));
		pigment=mix(pigment,sediment_color.rgb,broken_deposit*0.30);
	}
	if (surface_blending && !rock_strata && !marking_surface) {
		// One map-space paint field spans every mesh. A hex can contain sand,
		// a feathered shoulder and road; hex outlines remain a separate overlay.
		vec2 p = ground_world_position.xz;
		vec2 grid = vec2(dot(p,world_to_grid.xy),dot(p,world_to_grid.zw));
		vec2 warp = vec2(broad_patch(p*2.2),broad_patch(p*2.2+vec2(8.0,3.0)))-0.5;
		vec2 uv = (grid+warp*0.18-surface_bounds.xy+0.5)/surface_bounds.zw;
		vec4 weights = texture(surface_mask,uv);
		// A built road deck cannot follow a graded ramp, so the ramp itself keeps
		// full paint and takes the asphalt tone of the deck it connects.
		float graded = smoothstep(0.04, 0.14, ramp_incline);
		float road = smoothstep(0.12,0.85,weights.r) * mix(road_paint_strength, 1.0, graded);
		float rock = smoothstep(0.05,0.95,weights.g);
		float sand = clamp(weights.b+(broad_patch(p*0.21)-0.5)*0.42,0.0,1.0);
		tile_road = road;
		tile_rock = rock;
		tile_water = weights.a;
		float trail = 0.0;
		if (trail_surface) {
			// A second, slowly meandering lookup lets the worn line drift off
			// the cell centres; a firm core with a loose, broken verge.
			vec2 meander = vec2(broad_patch(p*0.50+vec2(17.0,3.0)),broad_patch(p*0.50+vec2(2.0,29.0)))-0.5;
			vec2 trail_uv = (grid+meander*0.80+warp*0.22-surface_bounds.xy+0.5)/surface_bounds.zw;
			float worn = texture(surface_mask,trail_uv).b;
			float core = smoothstep(0.40,0.66,worn);
			float verge = smoothstep(0.14,0.44,worn)*(1.0-core);
			trail = core;
			// A footpath is compacted earth, not a bright sand road: stay closer
			// to the surrounding ground than a full sand field.
			sand = clamp(core*0.62+verge*smoothstep(0.35,0.75,broad_patch(p*2.3+vec2(5.0,1.0)))*0.30,0.0,1.0);
		}
		// Sand-Gewicht fuer die Sandtextur (07): ohne Strasse und Wasser; bei Wegspuren
		// ist `sand` oben schon auf den schmalen Pfad zurueckgenommen.
		tile_sand = sand * (1.0 - road) * (1.0 - clamp(weights.a, 0.0, 1.0));
		vec3 earth = mix(vec3(0.65,0.36,0.25),vec3(0.81,0.54,0.34),sand);
		earth = mix(earth,vec3(0.62,0.38,0.30),rock*0.65);
		// Dust remains at the irregular road shoulder and in small worn patches.
		float road_wear = broad_patch(p*4.0)*0.16;
		// Blown dust thins the paving irregularly instead of a clean painted band.
		float road_dust = smoothstep(0.50,0.82,broad_patch(p*0.75+vec2(3.3,8.8)))*0.38;
		vec3 paving = mix(vec3(0.50,0.475,0.40), vec3(0.295,0.305,0.32), graded * step(road_paint_strength, 0.99));
		earth = mix(earth,paving,road*(1.0-road_wear)*(1.0-road_dust*(1.0-graded)));
		earth = mix(earth,vec3(0.25,0.45,0.50),weights.a);
		drift_mask = clamp(1.0 - road * 0.72 - weights.a - trail * 0.35, 0.0, 1.0);
		if (trail_surface) {
			// Trodden centre: paler and finer, with scuffed darker flecks.
			earth *= 1.0-trail*0.045*smoothstep(0.55,0.80,broad_patch(p*5.5+vec2(1.0,9.0)));
		}
		if (homebase_palette) {
			// Muted rust and dusty compacted soil share the existing rock family.
			// Saved surface weights still describe exactly the same cells.
			// The base uses built paths, not a paint map of road/sand tiles.
			// Gentle continuous sediment remains independent of tile boundaries.
			earth = mix(vec3(0.57,0.315,0.21),vec3(0.62,0.36,0.235),region);
			earth = mix(earth,vec3(0.25,0.45,0.50),weights.a);
			value = mix(0.95,1.045,smoothstep(0.10,0.88,patch));
		}
		// Several scales of world-space sand, broken crust and sparse gravel.
		// Anti-aliased grains stay quiet in overview, rather than stippling every hex.
		float gravel_zone=smoothstep(0.48,0.76,broad_patch(p*0.53+vec2(4.3,7.1)));
		vec2 grain_cell=floor(p*7.0);
		vec2 grain_local=fract(p*7.0)-0.5;
		vec2 grain_offset=(vec2(patch_hash(grain_cell),patch_hash(grain_cell+vec2(23.0,71.0)))-0.5)*0.42;
		float grain_distance=length(grain_local-grain_offset);
		float grain_footprint=max(length(dFdx(p*7.0)),length(dFdy(p*7.0)));
		float grain_edge=max(grain_footprint*0.65,0.035);
		// A grain's diameter is only 0.3 cells: stop drawing distinct grains
		// once that diameter no longer covers even one screen pixel.
		float grain_visibility=1.0-smoothstep(0.12,0.4,grain_footprint);
		float pebble=(1.0-smoothstep(0.15-grain_edge,0.15+grain_edge,grain_distance))*gravel_zone*grain_visibility;
		float crust_zone=smoothstep(0.45,0.72,broad_patch(p*0.85+vec2(6.7,2.1)))*(homebase_palette ? 1.0 : 1.0-road);
		float crack_field=abs(broad_patch(p*2.6+warp)-0.51);
		float crack_edge=max(fwidth(crack_field),0.009);
		float fissure=(1.0-smoothstep(0.018-crack_edge,0.045+crack_edge,crack_field))*crust_zone;
		float shoulder=homebase_palette ? 0.0 : (1.0-smoothstep(0.025,0.11,abs(weights.r-0.62)))*broad_patch(p*3.0);
		float detail_strength=quiet_tactical_surface ? 0.24 : 1.0;
		if (quiet_tactical_surface) {
			// Isolated crust and gravel fields; the wide ground between them stays plain.
			crust_zone*=smoothstep(0.58,0.80,broad_patch(p*0.19+vec2(2.4,11.3)));
			pebble*=smoothstep(0.55,0.78,broad_patch(p*0.23+vec2(9.9,4.2)));
			fissure=(1.0-smoothstep(0.018-crack_edge,0.045+crack_edge,crack_field))*crust_zone;
		}
		earth*=1.0-(fissure*(homebase_palette ? 0.055 : 0.14)+shoulder*0.09)*detail_strength;
		earth=mix(earth,earth*vec3(0.79,0.83,0.86),pebble*(homebase_palette ? 0.22 : 0.38)*detail_strength);
		tile_detail*=(1.0-(fissure*(homebase_palette ? 0.055 : 0.14)+shoulder*0.09)*detail_strength)*(1.0-pebble*(homebase_palette ? 0.22 : 0.38)*detail_strength*0.17);
		if (quiet_tactical_surface) { value=mix(0.975,1.025,patch); }
		// These authored palette literals are sRGB in every location. Only a
		// linear renderer needs decoding; double decoding made missions red/black.
		pigment = OUTPUT_IS_SRGB ? earth : pow(earth,vec3(2.2));
		float relief=(pebble*0.012-fissure*0.006+broad_patch(p*16.0)*0.003*detail_visibility(p*16.0))*detail_strength;
		vec3 surface_dx=dFdx(ground_world_position);
		vec3 surface_dy=dFdy(ground_world_position);
		vec3 cross_x=cross(surface_dy,ground_world_normal);
		vec3 cross_y=cross(ground_world_normal,surface_dx);
		float determinant=dot(surface_dx,cross_x);
		vec3 gradient=(dFdx(relief)*cross_x+dFdy(relief)*cross_y)/max(abs(determinant),0.000001)*sign(determinant);
		vec3 detailed_normal=normalize(ground_world_normal-gradient*0.65);
		NORMAL=normalize((VIEW_MATRIX*vec4(detailed_normal,0.0)).xyz);
	}
	if (quiet_tactical_surface && !rock_strata && !surface_blending && !marking_surface) {
		pigment=mix(pigment,base_color.rgb,0.85);
		value=mix(0.98,1.02,patch);
	}
	if (quiet_tactical_surface && !rock_strata && slope_normal_softening>0.0) {
		// Keep the actual incline readable after suppressing incidental noise.
		value*=1.0-0.18*smoothstep(0.05,0.32,ramp_incline);
	}
	if (!rock_strata && !marking_surface && drift_strength > 0.0) {
		float drift = wind_drift(ground_world_position.xz);
		float pale = smoothstep(0.05, 0.55, drift) * drift_strength * drift_mask;
		float pan = smoothstep(0.05, 0.55, -drift) * drift_strength * drift_mask;
		// The plain field sits a little deeper and redder, so blown sand can
		// read as lighter without bleaching the whole map.
		pigment = mix(pigment, pigment * pow(vec3(0.90, 0.865, 0.835), vec3(tint_gamma)), min(drift_strength, 1.0) * drift_mask);
		pigment = mix(pigment, pigment * pow(vec3(1.13, 1.19, 1.17), vec3(tint_gamma)), pale * 0.90);
		pigment = mix(pigment, pigment * pow(vec3(0.86, 0.78, 0.76), vec3(tint_gamma)), pan * 0.68);
		// Close range only: faint wind ripples across the drift direction. They
		// fade out before the tactical overview, where the broad bands carry.
		vec2 ripple_p = ground_world_position.xz;
		vec2 ripple_wind = vec2(ripple_p.x * 0.80 + ripple_p.y * 0.60, ripple_p.y * 0.80 - ripple_p.x * 0.60);
		float ripple = broad_patch(ripple_wind * vec2(0.55, 2.6) + vec2(drift * 1.5, 7.7)) - 0.5;
		float mottle = broad_patch(ripple_p * 0.9 + vec2(41.0, 3.0)) - 0.5;
		float near = detail_visibility(ripple_p * 4.0) * drift_strength * drift_mask;
		pigment *= pow(1.0 + (ripple * 0.085 + mottle * 0.07) * near, tint_gamma);
		tile_detail *= pow(1.0 + (ripple * 0.085 + mottle * 0.07) * near, tint_gamma);
	}
	vec3 old_albedo = pigment * value;
	vec3 final_albedo = old_albedo;
	if (ground_tiles_enabled && !marking_surface) {
		// World-space tiling: hex borders never become texture borders. Gradients
		// are taken once, so every lookup below may sit inside a branch.
		vec2 tile_uv = ground_world_position.xz / ground_tile_meters;
		vec2 tile_dx = dFdx(tile_uv);
		vec2 tile_dy = dFdy(tile_uv);
		vec3 tile_color;
		// Heimatbasis hat keine eigene Bodentextur mehr (Spielerwunsch 25.11.): Normalboden wie die Einsatzkarten.
		if (GROUND_BASE_OWN_TEXTURE && homebase_palette) {
			tile_color = textureGrad(ground_tex_base, tile_uv, tile_dx, tile_dy).rgb * ground_base_tile_gain;
		} else {
			tile_color = textureGrad(ground_tex_normal, tile_uv, tile_dx, tile_dy).rgb;
			// Fixed, slow world noise: patches over several fields, soft edges.
			vec2 pw = ground_world_position.xz * ground_patch_scale;
			float gravel_w = smoothstep(ground_patch_gravel, ground_patch_gravel + ground_patch_softness, broad_patch(pw + vec2(61.0, 23.0)));
			float clay_w = smoothstep(ground_patch_clay, ground_patch_clay + ground_patch_softness, broad_patch(pw * 1.3 + vec2(7.0, 91.0)));
			if (gravel_w > 0.001) {
				tile_color = mix(tile_color, textureGrad(ground_tex_gravel, tile_uv, tile_dx, tile_dy).rgb, gravel_w);
			}
			if (clay_w > 0.001) {
				tile_color = mix(tile_color, textureGrad(ground_tex_clay, tile_uv, tile_dx, tile_dy).rgb, clay_w);
			}
		}
		// Grafik 1: die neuen Kacheln gehoeren zur Einsatz-Stimmung (mission_variation > 0);
		// Heimatbasis und Editor behalten genau ihr bisheriges Bild.
		bool mission_tiles = mission_variation > 0.0;
		if (mission_tiles && tile_sand > 0.02) {
			tile_color = mix(tile_color, textureGrad(ground_tex_sand, tile_uv, tile_dx, tile_dy).rgb, clamp(tile_sand * 0.85, 0.0, 1.0));
		}
		float paving_w = (paved_surface && !surface_blending) ? 1.0 : clamp(tile_road, 0.0, 1.0);
		if (paving_w > 0.001) {
			vec3 paving_color = textureGrad(ground_tex_paving, tile_uv, tile_dx, tile_dy).rgb;
			// Staubiger Wegrand mit Grauplatten (10) nur im Uebergang Boden/Strasse.
			float road_edge = (mission_tiles && !(paved_surface && !surface_blending)) ? clamp(4.0 * paving_w * (1.0 - paving_w), 0.0, 1.0) : 0.0;
			if (road_edge > 0.03) {
				paving_color = mix(paving_color, textureGrad(ground_tex_paving_edge, tile_uv, tile_dx, tile_dy).rgb, road_edge * 0.8);
			}
			tile_color = mix(tile_color, paving_color, paving_w);
		}
		float rock_w = rock_strata ? smoothstep(0.40, 0.88, ground_world_normal.y) : clamp(tile_rock, 0.0, 1.0) * 0.85;
		if (rock_w > 0.001) {
			vec3 rock_color;
			if (mission_tiles) {
				// Erhoehungen: geschichteter Canyon-Fels, dazu helle Sandsteinflecken statt dunkler Platten.
				rock_color = textureGrad(ground_tex_rock_canyon, tile_uv, tile_dx, tile_dy).rgb;
				float light_w = smoothstep(ground_rock_light_threshold, ground_rock_light_threshold + 0.18, broad_patch(ground_world_position.xz * 0.085 + vec2(23.0, 47.0)));
				if (light_w > 0.01) {
					rock_color = mix(rock_color, textureGrad(ground_tex_rock_light, tile_uv, tile_dx, tile_dy).rgb, light_w);
				}
			} else {
				rock_color = textureGrad(ground_tex_rock, tile_uv, tile_dx, tile_dy).rgb;
			}
			tile_color = mix(tile_color, rock_color, rock_w);
		}
		float slope_keep = slope_normal_softening > 0.0 ? 1.0 - 0.18 * smoothstep(0.05, 0.32, ramp_incline) : 1.0;
		vec3 tiled_albedo = tile_color * ground_tile_brightness * slope_keep * mix(1.0, tile_detail, ground_detail_keep);
		// Cliff walls and water keep their old colour; only the flat tops take the texture.
		float tiled_amount = rock_strata ? rock_w : 1.0 - clamp(tile_water, 0.0, 1.0);
		final_albedo = mix(old_albedo, tiled_albedo, tiled_amount);
	}
	if (mission_variation > 0.0 && !marking_surface) {
		// Grossflaechiges Rauschen (Wellenlaenge ~20 bis 45 m, Weltkoordinaten, daher ohne
		// Kachel- oder Hexnaht): bricht das Kachelmuster in der Uebersicht. Nur Helligkeit
		// und ein leichter Farbstich; drei weiche Werte-Rauschen, keine Texturabfrage.
		vec2 vw = ground_world_position.xz;
		float vn_a = broad_patch(vw * 0.034 + vec2(71.3, 12.9));
		float vn_b = broad_patch(vw * 0.021 + vec2(5.7, 88.1));
		float vn_c = broad_patch(vw * 0.027 + vec2(40.2, 63.4));
		float vn = clamp(((vn_a * 0.62 + vn_b * 0.38) - 0.5) * 2.4, -1.0, 1.0);
		float vb = 1.0 + vn * 0.08 * mission_variation;
		vec3 vtint = mix(vec3(0.96, 0.985, 1.03), vec3(1.045, 1.0, 0.94), clamp((vn_c - 0.5) * 2.0 + 0.5, 0.0, 1.0));
		final_albedo *= vb * mix(vec3(1.0), vtint, clamp(mission_variation, 0.0, 1.0));
	}
	ALBEDO = final_albedo;
	if (rock_strata) {
		// Warm ground bounce keeps shaded cliff faces readable instead of
		// dropping to black; strongest near the foot, none on the crown.
		float shade_wall = 1.0 - smoothstep(0.40, 0.88, ground_world_normal.y);
		float averted = 1.0 - smoothstep(-0.30, 0.20, dot(normalize(ground_world_normal), normalize(sun_direction_world)));
		EMISSION = ALBEDO * vec3(1.0, 0.84, 0.74) * (0.12 + 0.62 * averted) * shade_wall * rock_facet_strength;
	}
	ROUGHNESS = 0.96;
	METALLIC = 0.0;
}
