shader_type spatial;

varying vec3 suit_position;

void vertex() {
	suit_position = VERTEX;
}

void fragment() {
	vec3 p = suit_position;
	float side = abs(p.x);
	vec3 fabric = vec3(0.045, 0.51, 0.53);
	vec3 binding = vec3(0.035, 0.19, 0.24);
	vec3 ivory = vec3(0.85, 0.83, 0.71);
	vec3 amber = vec3(0.86, 0.44, 0.105);

	float belly = 1.0 - smoothstep(-0.149, -0.135, p.y);
	float chest_edge = -0.33 - side * 0.37 + p.y * 0.14;
	float chest = 1.0 - smoothstep(chest_edge - 0.011, chest_edge + 0.011, p.z);
	float chest_trim = 1.0 - smoothstep(0.011, 0.020, abs(p.z - chest_edge));
	vec3 color = mix(fabric, ivory, chest);
	color = mix(color, binding, max(belly, chest_trim));

	float harness_center = 0.30 - p.y * 0.52;
	float strap_distance = abs(p.z - harness_center);
	float strap = 1.0 - smoothstep(0.035, 0.043, strap_distance);
	float piping = (1.0 - smoothstep(0.003, 0.008, abs(strap_distance - 0.028)));
	color = mix(color, binding, strap);
	color = mix(color, amber, piping * smoothstep(-0.12, -0.095, p.y));

	float panel = (1.0 - smoothstep(0.091, 0.10, abs(p.z - 0.036)))
		* (1.0 - smoothstep(0.044, 0.053, abs(p.y - 0.031)))
		* smoothstep(0.234, 0.261, side);
	color = mix(color, binding, panel);
	vec2 badge = vec2((p.z - 0.036) * sign(p.x), p.y - 0.031);
	float disc = 1.0 - smoothstep(0.027, 0.030, length(badge));
	float cutout = smoothstep(0.024, 0.027, length(badge - vec2(0.012, 0.011)));
	color = mix(color, amber, panel * disc * cutout);

	ALBEDO = color;
	ROUGHNESS = 0.87;
}
