shader_type spatial;
render_mode unshaded, cull_front, fog_disabled;
// Bóveda del cielo: azul marino con un horizonte apenas más claro.

uniform vec3 arriba : source_color = vec3(0.016, 0.071, 0.18);
uniform vec3 horizonte : source_color = vec3(0.05, 0.13, 0.33);
uniform float oscuro = 1.0;
varying float altura;

void vertex() {
	altura = normalize(VERTEX).y;
}

void fragment() {
	ALBEDO = mix(horizonte, arriba, smoothstep(-0.02, 0.55, altura)) * oscuro;
}
