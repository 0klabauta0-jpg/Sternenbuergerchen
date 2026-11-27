shader_type sky;
// Einsatzkarten (Grafik 1, 27.11.): Farbverlauf statt einfarbigem Hintergrund und
// zugleich die Umgebungsfarbe der Schattenseiten.
//  - Bildpunkte (kein Cubemap-Durchgang): senkrechter Verlauf ueber den Bildschirm,
//    oben gedaempftes Blaugrau, unten staubiges Pfirsich. Die Kamera ist orthogonal;
//    eine Blickrichtung ergaebe darum keinen Verlauf, SCREEN_UV schon.
//  - Cubemap-Durchgang (Quelle fuer das Umgebungslicht): oben kuehles Violett,
//    am Horizont warmes Pfirsich, unten Rostorange. Flaechen, die von der Sonne
//    abgewandt sind, bekommen so einen warmen statt grauen Ton.

// Bjoerns Himmelsbild (27.11.): oben #74828e, Mitte #b4a088, unten (Horizont) #e89a6c.
uniform vec3 screen_top_color : source_color = vec3(0.455, 0.510, 0.557);
uniform vec3 screen_mid_color : source_color = vec3(0.706, 0.627, 0.533);
uniform vec3 screen_bottom_color : source_color = vec3(0.910, 0.604, 0.424);
// Bildpunkte hinter der Karte: false = einfarbiger Staubton (Vorgabe), true = Verlauf oben.
uniform bool screen_gradient = false;
uniform vec3 offmap_color : source_color = vec3(0.690, 0.416, 0.322);
uniform vec3 ambient_top_color : source_color = vec3(0.490, 0.478, 0.639);
uniform vec3 ambient_horizon_color : source_color = vec3(0.851, 0.627, 0.486);
uniform vec3 ambient_bottom_color : source_color = vec3(0.690, 0.380, 0.227);

void sky() {
	if (AT_CUBEMAP_PASS) {
		float h = EYEDIR.y;
		vec3 upper = mix(ambient_horizon_color, ambient_top_color, smoothstep(0.0, 0.85, h));
		vec3 lower = mix(ambient_horizon_color, ambient_bottom_color, smoothstep(0.0, 0.85, -h));
		COLOR = h >= 0.0 ? upper : lower;
	} else if (screen_gradient) {
		float v = clamp(SCREEN_UV.y, 0.0, 1.0);
		COLOR = v < 0.5 ? mix(screen_top_color, screen_mid_color, v * 2.0) : mix(screen_mid_color, screen_bottom_color, (v - 0.5) * 2.0);
	} else {
		// Nachbesserung 27.11.: einfarbiger Staubton hinter der Karte, sonst schwebt sie im Himmel.
		COLOR = offmap_color;
	}
}
