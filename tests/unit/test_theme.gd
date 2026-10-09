extends GutTest

func test_project_theme_uses_nunito_and_rounded_panels() -> void:
	assert_eq(ProjectSettings.get_setting("gui/theme/custom"), "res://assets/ui/theme.tres")
	var theme := load("res://assets/ui/theme.tres") as Theme
	assert_not_null(theme, "нет темы")
	if theme == null:
		return
	assert_not_null(theme.default_font, "шрифт по умолчанию задан")
	# Nunito — вариативный шрифт, без явного веса берётся ExtraLight 200: тонкий и плохо читается.
	var fv := theme.default_font as FontVariation
	assert_not_null(fv, "шрифт темы — FontVariation с заданным весом")
	if fv:
		assert_eq(fv.base_font.resource_path, "res://assets/fonts/Nunito.ttf")
		assert_gte(int(fv.variation_opentype.get(TextServerManager.get_primary_interface().name_to_tag("wght"), 0)), 600, "вес не тоньше SemiBold")
	assert_gte(theme.default_font_size, 22, "базовый кегль читается на видео")
	var panel := theme.get_stylebox("panel", "PanelContainer") as StyleBoxFlat
	assert_not_null(panel, "плашка PanelContainer — StyleBoxFlat")
	if panel == null:
		return
	assert_gt(panel.corner_radius_top_left, 8, "округлые углы")
	assert_gt(panel.shadow_size, 0, "мягкая тень")
	assert_eq(theme.get_color("font_color", "Label").to_html(false), "394151", "графитовый текст")

func test_window_scales_with_screen() -> void:
	# Retina: окно 1280×720 физических пикселей выходило вдвое меньше; интерфейс должен масштабироваться вместе с окном.
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "canvas_items")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")
	assert_eq(int(ProjectSettings.get_setting("display/window/size/mode")), DisplayServer.WINDOW_MODE_MAXIMIZED)

func test_ui_uses_only_glyphs_the_font_has() -> void:
	# Символов ♥ ♡ ◎ ✓ в Nunito нет: подстановка из системного шрифта выглядит чужой.
	var font := load("res://assets/fonts/Nunito.ttf") as FontFile
	for path in ["res://scripts/ui/hud.gd", "res://scripts/ui/shop_menu.gd", "res://scenes/ui/hud.tscn", "res://scenes/ui/shop_menu.tscn"]:
		var text := FileAccess.get_file_as_string(path)
		for ch in ["♥", "♡", "◎", "✓"]:
			assert_false(text.contains(ch), "%s содержит «%s», которого нет в шрифте" % [path, ch])
	assert_false(font.has_char("♥".unicode_at(0)), "проверка выше осмысленна: ♥ в шрифте действительно нет")
