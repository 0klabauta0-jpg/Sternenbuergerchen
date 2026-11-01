shader_type spatial;
render_mode diffuse_burley, specular_disabled;

uniform vec4 base_color : source_color = vec4(0.76, 0.49, 0.30, 1.0);
uniform bool rock_strata = false;
varying vec3 ground_world_position;

float patch_hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float broad_patch(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(patch_hash(i), patch_hash(i + vec2(1.0, 0.0)), u.x),
		mix(patch_hash(i + vec2(0.0, 1.0)), patch_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void vertex() {
	ground_world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Continuous world coordinates keep the same broad paint patches across tile seams.
	float patch = broad_patch(ground_world_position.xz * 0.40);
	float region = broad_patch(ground_world_position.xz * 0.13 + vec2(12.1, 4.8));
	float grit = broad_patch(ground_world_position.xz * 8.0);
	float value = mix(0.87, 1.12, smoothstep(0.10, 0.88, patch));
	vec3 pigment = mix(base_color.rgb * vec3(0.95, 0.94, 0.95), base_color.rgb * vec3(1.10, 1.08, 1.0), region);
	value *= mix(0.97, 1.03, grit);
	if (rock_strata) {
		float layer = sin(ground_world_position.y * 10.0 + patch * 1.5);
		value *= mix(0.88, 1.05, smoothstep(-0.15, 0.2, layer));
	}
	ALBEDO = pigment * value;
	ROUGHNESS = 0.96;
	METALLIC = 0.0;
}
