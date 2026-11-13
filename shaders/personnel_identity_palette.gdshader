shader_type spatial;
render_mode diffuse_burley, specular_disabled;
// Same stock UV/geometry. Read-only palettes follow the canonical portrait atlas.
uniform sampler2D skin_texture : source_color, filter_linear_mipmap;
uniform vec4 skin_color : source_color = vec4(0.545, 0.337, 0.212, 1.0);
uniform vec4 hair_color : source_color = vec4(0.100, 0.067, 0.051, 1.0);
uniform vec4 cloth_color : source_color = vec4(0.180, 0.285, 0.290, 1.0);
uniform vec4 plate_color : source_color = vec4(0.820, 0.788, 0.682, 1.0);

void fragment() {
	vec3 source = texture(skin_texture, UV).rgb;
	float value = max(source.r, max(source.g, source.b));
	bool face_region = UV.x < 0.628 && UV.y < 0.420;
	// Printed eyes/brows keep dark ink even for silver hair or a shaved scalp.
	bool face_ink = UV.x > 0.255 && UV.x < 0.385 && UV.y > 0.180 && UV.y < 0.285
		&& source.r < (OUTPUT_IS_SRGB ? 0.16 : 0.025);
	if (face_region && !face_ink && source.r > source.g * 1.40) {
		// Source dark red skin, dark hair and printed features stay distinct.
		float skin = smoothstep(OUTPUT_IS_SRGB ? 0.16 : 0.025, OUTPUT_IS_SRGB ? 0.36 : 0.10, source.r);
		vec3 color = mix(hair_color.rgb, skin_color.rgb, skin);
		ALBEDO = color * mix(0.72, 1.0, smoothstep(0.0, OUTPUT_IS_SRGB ? 0.50 : 0.22, value));
	} else if (!face_region && abs(source.r - source.g) < 0.22 && source.b >= source.r) {
		float plate = smoothstep(OUTPUT_IS_SRGB ? 0.45 : 0.17, OUTPUT_IS_SRGB ? 0.85 : 0.70, value);
		ALBEDO = mix(cloth_color.rgb, plate_color.rgb, plate) * mix(0.45, 1.0, value);
	} else {
		ALBEDO = source;
	}
	ROUGHNESS = 0.86;
}
