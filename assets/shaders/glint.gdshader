shader_type canvas_item;
// A glinting Trailomon: its colours turned round the colour wheel, and a slow sparkle
// sweeping across it.

uniform float hue_shift = 0.42;
uniform float sparkle = 0.6;

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
	vec3 hsv = rgb2hsv(col.rgb);
	hsv.x = fract(hsv.x + hue_shift);
	hsv.y = min(1.0, hsv.y * 1.15);
	vec3 rgb = hsv2rgb(hsv);
	// A diagonal band of light that sweeps across every few seconds.
	float band = fract((UV.x + UV.y) * 0.7 - TIME * 0.35);
	float glow = smoothstep(0.0, 0.04, band) * (1.0 - smoothstep(0.04, 0.09, band));
	rgb += vec3(1.0, 0.95, 0.75) * glow * sparkle;
	COLOR = vec4(rgb, col.a) * COLOR;
}
