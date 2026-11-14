shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, shadows_disabled;

void fragment() {
	float facing = clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0);
	float rim = pow(1.0 - facing, 3.0);
	ALBEDO = mix(vec3(0.22, 0.52, 0.72), vec3(0.58, 0.82, 1.0), rim);
	ALPHA = 0.045 + rim * 0.34;
}
