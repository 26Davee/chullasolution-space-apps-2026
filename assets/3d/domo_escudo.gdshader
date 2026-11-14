shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
// Escudo del domo de Killawasi: burbuja turquesa con borde luminoso.
// `presencia` baja con el escudo (1 = 100 %, 0 = apagado). `pulso` hace parpadear el escudo bajo.

uniform vec4 color : source_color = vec4(0.36, 0.86, 0.95, 1.0);
uniform float presencia : hint_range(0.0, 1.0) = 1.0;
uniform float pulso : hint_range(0.0, 1.0) = 0.0;

varying vec3 pos;

void vertex() {
	pos = VERTEX;
}

void fragment() {
	float f = 1.0 - abs(dot(normalize(NORMAL), normalize(VIEW)));
	float borde = pow(f, 2.4);
	float lon = atan(pos.z, pos.x) / 6.2831853;
	float lat = asin(clamp(pos.y / length(pos), 0.0, 1.0)) / 1.5707963;
	vec2 celda = abs(fract(vec2(lon * 24.0, lat * 6.0)) - 0.5);
	float linea = smoothstep(0.47, 0.5, max(celda.x, celda.y));
	float suelo = 1.0 - smoothstep(0.0, 0.07, lat);
	float latido = mix(1.0, 0.55 + 0.45 * sin(TIME * 5.0), pulso);
	ALBEDO = color.rgb * (1.0 + borde * 0.7 + suelo * 0.5);
	ALPHA = clamp((0.06 + borde * 0.5 + linea * 0.05 + suelo * 0.22) * presencia * latido, 0.0, 1.0);
}
