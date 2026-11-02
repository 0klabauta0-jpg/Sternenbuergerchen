shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform vec4 base_color : source_color = vec4(0.76, 0.49, 0.30, 1.0);
uniform bool rock_strata = false;
uniform bool paved_surface = false;
uniform bool authored_paving_wear = false;
uniform vec4 wear_service_span = vec4(11.2,10.45,15.0,10.45);
uniform vec4 wear_hall_span = vec4(13.2,8.48,13.2,10.45);
uniform vec4 wear_utility_span = vec4(15.15,10.25,16.1,9.15);
uniform bool marking_surface = false;
uniform vec4 sediment_color : source_color = vec4(0.73, 0.51, 0.33, 1.0);
varying vec3 ground_world_position;
varying vec3 ground_world_normal;

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
	ground_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	ground_world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	if (marking_surface) {
		float wear_area = broad_patch(ground_world_position.xz * 5.5 + vec2(3.1, 8.7));
		float chip = broad_patch(ground_world_position.xz * 95.0);
		if (wear_area > 0.45 && chip > mix(0.82, 0.45, wear_area)) { discard; }
	}
	// Continuous world coordinates keep the same broad paint patches across tile seams.
	float patch = broad_patch(ground_world_position.xz * 0.40);
	float region = broad_patch(ground_world_position.xz * 0.13 + vec2(12.1, 4.8));
	float grit = broad_patch(ground_world_position.xz * 18.0);
	float sediment = broad_patch(ground_world_position.xz * 1.6 + vec2(region * 3.0, patch));
	float value = mix(0.87, 1.12, smoothstep(0.10, 0.88, patch));
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
	} else {
		// Broad brush-like silt fans with a consistent wind direction. Wide quiet
		// fields remain; only selected deposits receive small dark crust fragments.
		vec2 p = ground_world_position.xz;
		vec2 flow = vec2(p.x * 0.90 + p.y * 0.43, p.y * 0.90 - p.x * 0.43);
		float stroke = broad_patch(flow * vec2(0.85, 1.6) + vec2(region * 1.2, patch * 1.4));
		float deposit = smoothstep(0.48, 0.78, broad_patch(p * 0.80 + vec2(7.2, 1.4)));
		float crust = smoothstep(0.55, 0.82, broad_patch(p * 9.0 + vec2(stroke * 0.45, 0.0)));
		float silt = deposit * smoothstep(0.28, 0.70, stroke);
		pigment = mix(pigment, base_color.rgb * vec3(1.40, 1.29, 1.12), silt * 0.50);
		value *= 1.0 - deposit * crust * (paved_surface ? 0.025 : 0.06);
		value *= mix(0.94, 1.04, stroke);
	}
	if (paved_surface) {
		if (authored_paving_wear) {
			float wheels=max(wheel_mark(ground_world_position.xz,wear_hall_span.xy+vec2(-0.28,0.0),wear_hall_span.zw+vec2(-0.28,0.0)),wheel_mark(ground_world_position.xz,wear_hall_span.xy+vec2(0.28,0.0),wear_hall_span.zw+vec2(0.28,0.0)));
			value*=1.0-wheels*0.18;
		}
		// Scuffed aggregate and dusty, broad paint loss. No regular tile lattice.
		float scuff = smoothstep(0.46, 0.72, broad_patch(ground_world_position.xz * 3.7));
		float worn = smoothstep(0.42, 0.75, sediment) * scuff;
		pigment = mix(pigment, base_color.rgb * vec3(1.24, 1.18, 1.04), worn * 0.58);
		value *= mix(0.90, 1.045, broad_patch(ground_world_position.xz * 11.0));
		// Local deposits on quiet straight approach spans soften selected road
		// shoulders without a second coplanar overlay or a universal orange border.
		vec2 p=ground_world_position.xz;
		float shoulder=authored_paving_wear?dusty_shoulder(p,wear_service_span.xy,wear_service_span.zw,1.04):0.0;
		shoulder=max(shoulder,authored_paving_wear?dusty_shoulder(p,wear_hall_span.xy,wear_hall_span.zw,0.84):0.0);
		shoulder=max(shoulder,authored_paving_wear?dusty_shoulder(p,wear_utility_span.xy,wear_utility_span.zw,0.64):0.0);
		float broken_deposit=shoulder*smoothstep(0.40,0.80,broad_patch(p*7.0+vec2(patch,region)));
		pigment=mix(pigment,sediment_color.rgb,broken_deposit*0.30);
	}
	ALBEDO = pigment * value;
	ROUGHNESS = 0.96;
	METALLIC = 0.0;
}
