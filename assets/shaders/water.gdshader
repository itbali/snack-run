shader_type spatial;
// Вода пруда и моря (спек порта, раздел 2): цвет палитры sea_light, прозрачность, рябь нормалью; отражения — SSR окружения.
render_mode diffuse_toon, specular_toon, cull_disabled;

uniform vec4 tint : source_color = vec4(0.184, 0.612, 0.812, 0.85);
uniform vec4 deep : source_color = vec4(0.114, 0.498, 0.769, 1.0);
uniform float ripple = 0.08;

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
	ALPHA = tint.a;
	ROUGHNESS = 0.05;
	METALLIC = 0.0;
	SPECULAR = 0.6;
}
