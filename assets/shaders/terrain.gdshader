shader_type spatial;
render_mode diffuse_toon, specular_toon;
// Пол района (спек «Масштаб и рельеф», раздел 3): 4 покрытия по карте весов (RGBA), камень на крутых гранях.
// Покрытия — проекция сверху по мировым xz, камень — трипланарно по бокам.
uniform sampler2D splat : filter_linear, repeat_disable;
uniform sampler2D tex_r : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_g : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_b : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_cliff : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 tile_sizes = vec4(4.0, 1.2, 2.0, 0.8);   // метров на один повтор текстуры R, G, B, A
uniform float cliff_tile = 3.0;
uniform vec2 origin = vec2(0.0);
uniform vec2 size = vec2(40.0);
uniform vec2 texels = vec2(41.0);

varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec2 suv = ((wpos.xz - origin) / size) * ((texels - 1.0) / texels) + 0.5 / texels;   // центры текселей = вершины сетки
	vec4 w = texture(splat, suv);
	w /= max(w.r + w.g + w.b + w.a, 0.001);
	vec3 ground = texture(tex_r, wpos.xz / tile_sizes.x).rgb * w.r
		+ texture(tex_g, wpos.xz / tile_sizes.y).rgb * w.g
		+ texture(tex_b, wpos.xz / tile_sizes.z).rgb * w.b
		+ texture(tex_a, wpos.xz / tile_sizes.w).rgb * w.a;
	vec3 an = abs(wnorm);
	vec3 cliff = (texture(tex_cliff, wpos.zy / cliff_tile).rgb * an.x + texture(tex_cliff, wpos.xy / cliff_tile).rgb * an.z) / max(an.x + an.z, 0.001);
	float steep = smoothstep(0.80, 0.62, wnorm.y);
	ALBEDO = mix(ground, cliff, steep);
	ROUGHNESS = 0.9;
}
