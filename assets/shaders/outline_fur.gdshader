shader_type spatial;
render_mode cull_front, unshaded, blend_mix, depth_draw_always;
// Инвертированный hull с «рваной» шириной: силуэт персонажа читается как пушистый (спек 2.8).
uniform vec4 color : source_color = vec4(0.224, 0.255, 0.318, 1.0);
uniform float width = 0.006;      // в единицах модели (Toon пересчитывает метры под масштаб узла)
uniform float jitter = 0.0;       // доля width: 0 — ровная обводка, 0.25 — шерсть
uniform float frequency = 40.0;   // частота шума по UV
uniform float alpha = 1.0;

float hash2(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	float n = hash2(floor(UV * frequency)) * 2.0 - 1.0;   // UV стабильны по вершинам, обводка не «кипит» в движении
	VERTEX += NORMAL * width * (1.0 + jitter * n);
}

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = alpha * color.a;
}
