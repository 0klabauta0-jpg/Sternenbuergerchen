shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

uniform vec4 line_color : source_color = vec4(0.23, 0.14, 0.07, 0.27);
uniform float world_line_width = 0.04;
uniform float cell_size = 1.0;
uniform float minimum_pixel_width = 1.3;
uniform float distant_contrast_floor = 0.08;
varying float cell_pixels;

void vertex() {
	float world_per_pixel = abs(2.0 / PROJECTION_MATRIX[1][1]) / max(VIEWPORT_SIZE.y, 1.0);
	if (abs(PROJECTION_MATRIX[3][3]) < 0.5) {
		world_per_pixel *= max(abs((MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).z), 0.001);
	}
	float width = max(world_line_width, minimum_pixel_width * world_per_pixel);
	// NORMAL carries the horizontal side vector for this static edge quad.
	VERTEX += NORMAL * (UV.x * 2.0 - 1.0) * (width - world_line_width) * 0.5;
	cell_pixels = cell_size / max(world_per_pixel, 0.00001);
}

void fragment() {
	float edge_distance = min(UV.x, 1.0 - UV.x);
	float pixel_coverage = smoothstep(0.0, max(fwidth(UV.x), 0.00001), edge_distance);
	float distant_contrast = mix(distant_contrast_floor, 1.0, smoothstep(8.0, 26.0, cell_pixels));
	ALBEDO = line_color.rgb;
	ALPHA = line_color.a * pixel_coverage * distant_contrast;
}
