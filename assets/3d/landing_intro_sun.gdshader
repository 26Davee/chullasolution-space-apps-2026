shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

float streamer(float angle, float center, float sharpness) {
	return pow(max(cos(angle - center), 0.0), sharpness);
}

void fragment() {
	vec2 point = (UV - vec2(0.5)) * 2.0;
	float radius = length(point);
	float angle = atan(point.y, point.x + 0.00001);
	const float SURFACE_RADIUS = 0.23;
	float disc = 1.0 - smoothstep(SURFACE_RADIUS - 0.014, SURFACE_RADIUS + 0.008, radius);
	float center = sqrt(max(1.0 - pow(radius / SURFACE_RADIUS, 2.0), 0.0));
	float granules = sin(point.x * 91.0 + cos(point.y * 73.0))
		* sin(point.y * 52.0 - point.x * 36.0);
	float bands = sin(point.x * 19.0 + sin(point.y * 16.0) + granules * 0.4);
	vec3 rim = vec3(1.0, 0.48, 0.08);
	vec3 core = vec3(1.0, 0.98, 0.77);
	vec3 photosphere = mix(rim, core, clamp(center * 0.94 + bands * 0.077 + granules * 0.034, 0.0, 1.0));

	float distance_from_rim = max(radius - SURFACE_RADIUS, 0.0);
	float glow = 0.52 * exp(-distance_from_rim * 5.8);
	float twist = angle + distance_from_rim * 0.65;
	float rays = streamer(twist, 0.36, 14.0) + 0.7 * streamer(angle, 2.16, 19.0)
		+ 0.94 * streamer(angle, 3.44, 17.0) + 0.65 * streamer(angle, 5.02, 18.0);
	float corona = (glow + 0.62 * rays * exp(-distance_from_rim * 2.8))
		* (1.0 - smoothstep(0.78, 0.99, radius));
	float prominence = exp(-pow((radius - 0.285) / 0.022, 2.0))
		* (streamer(angle, 1.01, 95.0) + 0.78 * streamer(angle, 3.68, 110.0));

	ALBEDO = mix(mix(vec3(1.0, 0.22, 0.045), vec3(1.0, 0.83, 0.55), exp(-distance_from_rim * 4.0)), photosphere, disc);
	ALPHA = mix(corona + prominence * 0.52, 1.0, disc);
}
