extends GutTest

func test_project_theme_uses_nunito_and_rounded_panels() -> void:
	assert_eq(ProjectSettings.get_setting("gui/theme/custom"), "res://assets/ui/theme.tres")
	var theme := load("res://assets/ui/theme.tres") as Theme
	assert_not_null(theme, "нет темы")
	if theme == null:
		return
	assert_not_null(theme.default_font, "шрифт по умолчанию задан")
	assert_eq(theme.default_font.resource_path, "res://assets/fonts/Nunito.ttf")
	var panel := theme.get_stylebox("panel", "PanelContainer") as StyleBoxFlat
	assert_not_null(panel, "плашка PanelContainer — StyleBoxFlat")
	if panel == null:
		return
	assert_gt(panel.corner_radius_top_left, 8, "округлые углы")
	assert_gt(panel.shadow_size, 0, "мягкая тень")
	assert_eq(theme.get_color("font_color", "Label").to_html(false), "394151", "графитовый текст")
