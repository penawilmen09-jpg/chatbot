shader_type canvas_item;
// Trajes de Wilmen: solo se tiñe el verde de la camiseta (piel, pelo y bufanda no cambian).
uniform float hue_shift = 0.0;
uniform float sat_mul = 1.0;
uniform float val_mul = 1.0;

vec3 rgb2hsv(vec3 c) {
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
	float d = q.x - min(q.w, q.y);
	float e = 1.0e-10;
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	vec3 h = rgb2hsv(col.rgb);
	float green = step(0.28, h.x) * step(h.x, 0.52) * step(0.25, h.y);
	h.x = fract(h.x + hue_shift * green + 1.0);
	h.y = clamp(h.y * mix(1.0, sat_mul, green), 0.0, 1.0);
	h.z = clamp(h.z * mix(1.0, val_mul, green), 0.0, 1.0);
	COLOR = vec4(hsv2rgb(h), col.a);
}
