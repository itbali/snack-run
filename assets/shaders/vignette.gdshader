shader_type canvas_item;
// Мягкое затемнение краёв кадра (план 4). strength — плотность, radius — где начинается.
uniform float strength : hint_range(0.0, 1.0) = 0.35;
uniform float radius : hint_range(0.0, 1.5) = 0.72;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float d = length(uv) * 1.4142;
	float v = smoothstep(radius, 1.25, d);
	COLOR = vec4(0.0, 0.0, 0.0, v * strength);
}
