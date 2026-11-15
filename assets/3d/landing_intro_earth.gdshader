shader_type spatial;
render_mode unshaded, shadows_disabled, fog_disabled;

uniform vec3 sun_direction = vec3(0.0, 0.0, -1.0);

varying vec3 globe_point;

void vertex() {
	globe_point = VERTEX;
}

float hash3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float noise3(vec3 p) {
	vec3 cell = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(hash3(cell), hash3(cell + vec3(1, 0, 0)), f.x);
	float b = mix(hash3(cell + vec3(0, 1, 0)), hash3(cell + vec3(1, 1, 0)), f.x);
	float c = mix(hash3(cell + vec3(0, 0, 1)), hash3(cell + vec3(1, 0, 1)), f.x);
	float d = mix(hash3(cell + vec3(0, 1, 1)), hash3(cell + vec3(1, 1, 1)), f.x);
	return mix(mix(a, b, f.y), mix(c, d, f.y), f.z);
}

float continent(vec2 point, vec2 center, vec2 radius, float angle) {
	vec2 offset = point - center;
	mat2 rotation = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
	return 1.0 - length(rotation * offset / radius);
}

void fragment() {
	vec3 sphere = normalize(globe_point);
	float longitude = atan(sphere.x, sphere.z) - 0.30;
	float latitude = asin(sphere.y);
	vec2 map = vec2(longitude, latitude + 0.14 * longitude);

	float land = continent(map, vec2(-0.57, 0.50), vec2(0.46, 0.27), -0.24);
	land = max(land, continent(map, vec2(-0.30, 0.24), vec2(0.21, 0.18), 0.62));
	land = max(land, continent(map, vec2(-0.25, -0.22), vec2(0.098, 0.29), 0.64));
	land = max(land, continent(map, vec2(-0.08, -0.31), vec2(0.20, 0.40), -0.31));
	land = max(land, continent(map, vec2(0.53, 0.12), vec2(0.27, 0.46), 0.29));
	land = max(land, continent(map, vec2(0.54, 0.55), vec2(0.27, 0.23), -0.2));
	land = max(land, continent(map, vec2(0.99, 0.63), vec2(0.51, 0.24), 0.10));
	land = max(land, continent(map, vec2(0.03, 0.87), vec2(0.14, 0.21), 0.15));

	float coast = 0.24 * (noise3(sphere * 12.0) - 0.5);
	float ground = smoothstep(-0.026, 0.04, land + coast);
	vec3 ocean = mix(vec3(0.10, 0.36, 0.52), vec3(0.16, 0.57, 0.68), noise3(sphere * 4.0));
	vec3 terrain = mix(vec3(0.29, 0.52, 0.41), vec3(0.63, 0.57, 0.39),
		smoothstep(0.02, 0.41, 0.28 - abs(latitude - 0.22) + noise3(sphere * 17.0) * 0.17));
	vec3 color = mix(ocean, terrain, ground);
	float polar = smoothstep(0.98, 1.23, abs(latitude) + coast * 0.4);
	color = mix(color, vec3(0.82, 0.91, 0.97), polar * 0.85);

	vec3 swirls = sphere * vec3(5.0, 12.0, 5.0) + vec3(4.2, 13.8, 0.5);
	float clouds = noise3(swirls) * 0.76 + noise3(swirls * 1.8) * 0.24;
	color = mix(color, vec3(0.87, 0.94, 1.0), smoothstep(0.56, 0.78, clouds) * 0.71);
	float daylight = smoothstep(-0.035, 0.12, dot(normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz), sun_direction));
	float limb = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = color * mix(0.22, 1.02, daylight)
		+ vec3(0.16, 0.46, 0.82) * limb * (0.22 + 0.57 * daylight);
}
