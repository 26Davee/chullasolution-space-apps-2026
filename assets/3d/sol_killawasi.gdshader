shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never, fog_disabled;
// Disco solar lejano con halo cálido. Es decorativo: la luz la da el DirectionalLight3D.

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float disco = smoothstep(0.2, 0.17, r);
	float halo = exp(-r * r * 7.0) * 0.9 + exp(-r * 3.2) * 0.22;
	ALBEDO = mix(vec3(1.0, 0.45, 0.1), vec3(1.0, 0.88, 0.5), disco) * (0.7 + disco * 0.9);
	ALPHA = clamp(disco + halo, 0.0, 1.0) * smoothstep(1.0, 0.65, r);
}
