// Material de holograma para la previsualización de piezas.
// El color (y la transparencia) se controla desde PlacementSystem con el uniform `tint`.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix, shadows_disabled;

uniform vec4 tint : source_color = vec4(0.2, 0.95, 0.85, 0.45);
uniform float fresnel_power = 2.5;
uniform float scan_density = 6.0;   // líneas por metro
uniform float scan_speed = 1.5;
uniform float pulse_speed = 3.0;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), fresnel_power);
	float scan = smoothstep(0.45, 0.5, fract(world_pos.y * scan_density - TIME * scan_speed)) * 0.2;
	float pulse = 0.85 + 0.15 * sin(TIME * pulse_speed);

	ALBEDO = tint.rgb * (1.0 + fres * 1.5);
	ALPHA = clamp((tint.a + fres * 0.5 + scan) * pulse, 0.0, 1.0);
}
