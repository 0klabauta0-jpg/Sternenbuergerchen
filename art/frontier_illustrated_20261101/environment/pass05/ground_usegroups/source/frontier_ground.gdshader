shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform vec4 base_color : source_color = vec4(0.76, 0.49, 0.30, 1.0);
uniform bool rock_strata = false;
uniform bool paved_surface = false;
varying vec3 ground_world_position;

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

void vertex() {
	ground_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Continuous world coordinates keep the same broad paint patches across tile seams.
	float patch = broad_patch(ground_world_position.xz * 0.40);
	float region = broad_patch(ground_world_position.xz * 0.13 + vec2(12.1, 4.8));
	float grit = broad_patch(ground_world_position.xz * 8.0);
	float sediment = broad_patch(ground_world_position.xz * 1.6 + vec2(region * 3.0, patch));
	float value = mix(0.87, 1.12, smoothstep(0.10, 0.88, patch));
	vec3 pigment = mix(base_color.rgb * vec3(0.91, 0.89, 0.91), base_color.rgb * vec3(1.14, 1.10, 1.0), region);
	value *= mix(0.955, 1.035, grit);
	// Soft sediment fields break up the flat paint without drawing a square/hex grid.
	value *= mix(0.94, 1.035, smoothstep(0.20, 0.80, sediment));
	if (rock_strata) {
		// Broken broad pigment beds support the mesh, without regular ring stripes.
		float layer = broad_patch(vec2(ground_world_position.y * 2.1 + region * 0.7,
			ground_world_position.x * 0.17 + ground_world_position.z * 0.13));
		value *= mix(0.90, 1.045, layer);
	}
	if (paved_surface) {
		float wheels=max(wheel_mark(ground_world_position.xz,vec2(12.5,7.0),vec2(13.1,10.3)),wheel_mark(ground_world_position.xz,vec2(13.1,7.0),vec2(13.7,10.3)));
		value*=1.0-wheels*0.18;
	}
	ALBEDO = pigment * value;
	ROUGHNESS = 0.96;
	METALLIC = 0.0;
}
