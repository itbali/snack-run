shader_type spatial;
render_mode cull_front, unshaded, blend_mix, depth_draw_always;
// Инвертированный hull с «рваной» шириной: силуэт персонажа читается как пушистый (спек 2.8).
uniform vec4 color : source_color = vec4(0.224, 0.255, 0.318, 1.0);
uniform float width = 0.006;      // в единицах модели (Toon пересчитывает метры под масштаб узла)
uniform float jitter = 0.0;       // доля width: 0 — ровная обводка, 0.25 — шерсть
uniform float frequency = 40.0;   // не используется с хэшем по вершинам; оставлен для совместимости параметров
uniform float alpha = 1.0;

float hash1(float x) {
	return fract(sin(x * 127.1 + 311.7) * 43758.5453);
}

void vertex() {
	// Хэш по номеру вершины: стабилен в движении и не требует UV (у мешей из Blender-скриптов их нет).
	// При jitter = 0 шум не применяется, ширина ровно width.
	float n = jitter > 0.0 ? hash1(float(VERTEX_ID)) * 2.0 - 1.0 : 0.0;
	VERTEX += NORMAL * width * (1.0 + jitter * n);
}

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = alpha * color.a;
}
