shader_type spatial;
render_mode unshaded, fog_disabled;
// Tierra estilizada de Killawasi: océanos azules, las Américas hacia la cámara y nubes blancas.
// Es una ilustración procedural, no un mapa: no sale de ningún dato de NASA.

uniform vec3 sol_dir = vec3(-0.55, 0.35, 0.75);
varying vec3 n_obj;

float hash(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float ruido(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i), hash(i + vec3(1, 0, 0)), f.x), mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x), mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

float fbm(vec3 p) {
	return ruido(p) * 0.55 + ruido(p * 2.1) * 0.3 + ruido(p * 4.3) * 0.15;
}

float mancha(float lon, float lat, vec4 m) {
	float dl = lon - m.x;
	dl = dl - 6.2831853 * floor((dl + 3.14159265) / 6.2831853);
	float dy = lat - m.y;
	return exp(-(dl * dl) / (m.z * m.z) - (dy * dy) / (m.w * m.w));
}

void vertex() {
	n_obj = normalize(VERTEX);
}

void fragment() {
	vec3 n = normalize(n_obj);
	float lat = asin(clamp(n.y, -1.0, 1.0));
	float lon = atan(n.x, n.z);
	float t = 0.0;
	t = max(t, mancha(lon, lat, vec4(-0.28, 0.82, 0.42, 0.30)));
	t = max(t, mancha(lon, lat, vec4(-0.06, 0.58, 0.22, 0.20)));
	t = max(t, mancha(lon, lat, vec4(-0.50, 1.06, 0.36, 0.20)));
	t = max(t, mancha(lon, lat, vec4(-0.12, 0.30, 0.12, 0.15)));
	t = max(t, mancha(lon, lat, vec4(0.03, 0.14, 0.07, 0.09)));
	t = max(t, mancha(lon, lat, vec4(0.22, -0.12, 0.24, 0.25)));
	t = max(t, mancha(lon, lat, vec4(0.18, -0.50, 0.14, 0.28)));
	t = max(t, mancha(lon, lat, vec4(0.12, -0.86, 0.07, 0.15)));
	t = max(t, mancha(lon, lat, vec4(0.58, 1.18, 0.16, 0.13)));
	t = max(t, mancha(lon, lat, vec4(1.30, 0.20, 0.30, 0.50)));
	t = max(t, mancha(lon, lat, vec4(1.12, 0.85, 0.25, 0.15)));
	t += (fbm(n * 5.0) - 0.5) * 0.3;
	float tierra = smoothstep(0.40, 0.47, t);
	vec3 mar = mix(vec3(0.03, 0.17, 0.52), vec3(0.06, 0.36, 0.78), fbm(n * 2.5));
	vec3 suelo = mix(vec3(0.16, 0.52, 0.22), vec3(0.72, 0.60, 0.33), fbm(n * 6.0 + vec3(3.0)));
	vec3 col = mix(mar, suelo, tierra);
	col = mix(col, vec3(0.95), smoothstep(1.2, 1.32, abs(lat)));
	float nubes = smoothstep(0.56, 0.72, fbm(n * 3.4 + vec3(7.0, 1.0, 3.0)));
	col = mix(col, vec3(1.0), nubes * 0.85);
	float luz = clamp(dot(n, normalize(sol_dir)) * 0.75 + 0.6, 0.16, 1.0);
	float borde = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.4);
	ALBEDO = col * luz + vec3(0.18, 0.45, 1.0) * borde * 0.55;
}
