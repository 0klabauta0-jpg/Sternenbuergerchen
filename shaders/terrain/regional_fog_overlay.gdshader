shader_type spatial;
render_mode unshaded, cull_disabled, blend_mix, shadows_disabled;

uniform float height_step = 0.75;
varying vec4 fog_color;

void vertex() {
	int sample_index = int(UV.x);
	if (sample_index < 12) {
		int values = int(round(INSTANCE_CUSTOM[sample_index / 3] * 728.0));
		int component = sample_index % 3;
		int place = component == 0 ? 1 : (component == 1 ? 9 : 81);
		VERTEX.y += height_step * 0.25 * float((values / place) % 9 - 4);
	}
	fog_color = COLOR;
}

void fragment() {
	ALBEDO = fog_color.rgb;
	ALPHA = fog_color.a;
}
