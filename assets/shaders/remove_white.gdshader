shader_type canvas_item;

void fragment() {
	vec4 col = texture(TEXTURE, UV);

	float cmax = max(col.r, max(col.g, col.b));
	float cmin = min(col.r, min(col.g, col.b));
	float sat = (cmax > 0.001) ? (cmax - cmin) / cmax : 0.0;
	float bri = dot(col.rgb, vec3(0.299, 0.587, 0.114));

	// White/grey/light areas: bright AND low saturation
	if (bri > 0.45 && sat < 0.35) {
		// How strongly to replace: 0 = original, 1 = full dark shadow
		float strength = smoothstep(0.45, 0.80, bri) * smoothstep(0.35, 0.05, sat);
		// Replace with black → dark grey gradient based on original brightness
		float dark = mix(0.08, 0.18, bri);
		col.rgb = mix(col.rgb, vec3(dark), strength);
		// Keep alpha — shadow stays opaque
	}

	COLOR = col;
}
