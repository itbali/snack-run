shader_type spatial;
// Вода пруда и моря (спек порта, раздел 2): цвет палитры sea_light, рябь нормалью; непрозрачная — так её отражает SSR окружения
// (прозрачный проход Godot SSR не получает, ревью плана 12).
render_mode diffuse_toon, specular_toon, cull_disabled;

uniform vec4 tint : source_color = vec4(0.184, 0.612, 0.812, 1.0);
uniform vec4 deep : source_color = vec4(0.114, 0.498, 0.769, 1.0);
uniform float ripple = 0.08;
uniform float sparkle = 0.9;   // блики солнца на ряби (план 18)

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float a = sin(wpos.x * 1.7 + TIME * 1.3) + sin(wpos.z * 2.3 - TIME * 1.1);
	float b = cos(wpos.x * 2.1 - TIME * 0.9) + cos(wpos.z * 1.5 + TIME * 1.4);
	vec3 n = normalize(vec3(a * ripple, 1.0, b * ripple));
	NORMAL = normalize((VIEW_MATRIX * vec4(n, 0.0)).xyz);
	float f = 0.5 + 0.25 * (a + b) * 0.25;
	ALBEDO = mix(deep.rgb, tint.rgb, clamp(f, 0.0, 1.0));
	// блики: редкие яркие точки на гребнях ряби, мерцают со временем (ловит glow окружения)
	float s1 = sin(wpos.x * 7.3 + TIME * 2.1) * sin(wpos.z * 6.1 - TIME * 1.7);
	float s2 = sin((wpos.x + wpos.z) * 4.7 + TIME * 3.3);
	float g = smoothstep(0.86, 0.98, s1 * 0.5 + 0.5) * smoothstep(0.2, 1.0, s2);
	EMISSION = vec3(1.0, 0.98, 0.9) * g * sparkle * 2.5;
	ROUGHNESS = 0.05;
	METALLIC = 0.0;
	SPECULAR = 0.6;
}
