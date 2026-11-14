shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_back;

uniform int expresion = 0;
uniform float apertura : hint_range(0.1, 1.0) = 1.0;

float trazo(vec2 p, vec2 a, vec2 b, float grosor) {
	vec2 tramo = b - a;
	float t = clamp(dot(p - a, tramo) / dot(tramo, tramo), 0.0, 1.0);
	float distancia = length(p - a - t * tramo);
	return 1.0 - smoothstep(grosor - 0.007, grosor + 0.007, distancia);
}

float arco(vec2 p, float ancho, float base, float curva, float grosor) {
	float x = p.x / ancho;
	float distancia = abs(p.y - base - curva * x * x);
	float recorte = 1.0 - smoothstep(ancho - 0.012, ancho + 0.012, abs(p.x));
	return (1.0 - smoothstep(grosor - 0.007, grosor + 0.007, distancia)) * recorte;
}

void fragment() {
	vec2 p = (UV - 0.5) * vec2(2.0, -1.0);
	float fase = mod(TIME + 1.3, 4.6);
	float parpadeo = 1.0 - 0.88 * (1.0 - smoothstep(0.0, 0.105, abs(fase - 2.0)));
	vec2 ojos = vec2(abs(p.x - 0.02 * sin(TIME * 1.3)) - 0.34,
		(p.y - 0.105) / max(0.12, apertura * parpadeo));
	vec2 boca = vec2(p.x, (p.y + 0.175) / apertura);
	vec3 luz = vec3(0.22, 0.86, 0.94);
	float linea = trazo(ojos, vec2(0.0, -0.07), vec2(0.0, 0.13), 0.049);
	linea = max(linea, arco(boca, 0.16, -0.032, 0.067, 0.023));
	float iconos = 0.0;

	if (expresion == 1) {
		ojos.x += 0.055 * sin(TIME * 4.3);
		linea = trazo(ojos, vec2(-0.074, 0.017), vec2(0.074, 0.017), 0.038);
		linea = max(linea, trazo(boca, vec2(-0.106, 0.0), vec2(0.106, 0.0), 0.021));
		vec2 borde = vec2(abs(p.x), p.y);
		iconos = trazo(borde, vec2(0.73, -0.1), vec2(0.73, 0.25), 0.012);
		float radar = -0.1 + 0.35 * fract(TIME * 0.8);
		iconos += trazo(borde, vec2(0.65, radar), vec2(0.81, radar), 0.016);
	} else if (expresion == 2) {
		luz = vec3(1.0, 0.72, 0.28);
		linea = trazo(ojos, vec2(-0.074, 0.028), vec2(0.074, 0.080), 0.043);
		linea = max(linea, trazo(boca, vec2(-0.13, 0.0), vec2(0.13, 0.0), 0.022));
	} else if (expresion == 3) {
		luz = vec3(1.0, 0.39, 0.33) * (0.84 + 0.16 * sin(TIME * 7.0));
		float d = length(ojos * vec2(1.0, 0.78));
		linea = 1.0 - smoothstep(0.104, 0.119, d);
		d = length(boca * vec2(0.9, 1.1));
		linea = max(linea, 1.0 - smoothstep(0.059, 0.070, d));
	} else if (expresion == 4) {
		linea = arco(ojos, 0.115, 0.10, -0.10, 0.028);
		linea = max(linea, arco(boca, 0.19, -0.067, 0.101, 0.033));
		vec2 destello = vec2(abs(p.x) - 0.63, p.y + 0.034);
		float pulso = 0.78 + 0.22 * sin(TIME * 6.0);
		iconos = (trazo(destello, vec2(0.0, -0.05), vec2(0.0, 0.05), 0.013)
			+ trazo(destello, vec2(-0.048, 0.0), vec2(0.048, 0.0), 0.012)) * pulso;
	}

	ALBEDO = luz;
	ALPHA = clamp(max(linea, iconos), 0.0, 1.0);
}
