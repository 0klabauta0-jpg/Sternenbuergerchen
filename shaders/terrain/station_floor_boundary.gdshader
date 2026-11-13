shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform vec4 inside_color : source_color = vec4(1.0);
uniform vec4 outside_color : source_color = vec4(0.65, 0.36, 0.25, 1.0);
uniform sampler2D floor_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool has_floor_texture = false;
uniform vec4 floor_bounds = vec4(0.0, 0.0, 1.0, 1.0);
uniform float floor_metallic = 0.16;
uniform float floor_roughness = 0.9;
varying vec2 floor_world_xz;

void vertex() {
	floor_world_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec3 interior = inside_color.rgb;
	if (has_floor_texture) {
		interior *= texture(floor_texture, UV).rgb;
	}
	// Material boundary only: no displacement, discarded fragments, extra
	// geometry or change to the existing floor/foot/grid support height.
	vec2 distance_inside = min(floor_world_xz - floor_bounds.xy, floor_bounds.zw - floor_world_xz);
	float edge = min(distance_inside.x, distance_inside.y);
	float width = max(fwidth(edge), 0.0001);
	float inside = smoothstep(-width * 0.5, width * 0.5, edge);
	ALBEDO = mix(outside_color.rgb, interior, inside);
	METALLIC = floor_metallic * inside;
	ROUGHNESS = mix(0.95, floor_roughness, inside);
}
