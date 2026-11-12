shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 surface_color : source_color = vec4(0.7, 0.45, 0.23, 1.0);
uniform float seed = 0.0;
uniform bool star = false;
varying vec3 local_normal;

void vertex() {
	local_normal = normalize(VERTEX);
}

float hash_cell(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7)) + seed) * 43758.5453);
}

float noise3(vec3 p) {
	vec3 c = floor(p);
	vec3 t = fract(p);
	t = t * t * (3.0 - 2.0 * t);
	return mix(mix(mix(hash_cell(c), hash_cell(c + vec3(1,0,0)), t.x),
		mix(hash_cell(c + vec3(0,1,0)), hash_cell(c + vec3(1,1,0)), t.x), t.y),
		mix(mix(hash_cell(c + vec3(0,0,1)), hash_cell(c + vec3(1,0,1)), t.x),
		mix(hash_cell(c + vec3(0,1,1)), hash_cell(c + vec3(1,1,1)), t.x), t.y), t.z);
}

void fragment() {
	vec3 n = normalize(local_normal);
	float terrain = 0.58 * noise3(n * 6.5) + 0.29 * noise3(n * 21.0) + 0.13 * noise3(n * 52.0);
	float rim = pow(1.0 - max(dot(normalize(NORMAL), normalize(VIEW)), 0.0), 3.2);
	ALBEDO = surface_color.rgb * mix(0.44, 1.52, terrain);
	ROUGHNESS = 0.92;
	EMISSION = ALBEDO * (star ? mix(0.8, 3.8, terrain) : 0.07) + surface_color.rgb * rim * (star ? 0.7 : 0.20);
}
