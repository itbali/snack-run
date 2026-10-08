class_name FoodDef
extends Resource
## Описание вкусняшки (данные, не код). Файлы в data/food/*.tres.

@export var id: StringName = &""
@export var display_name := ""
@export var tier: Rarity.Tier = Rarity.Tier.COMMON
@export var model_path := ""     # res://assets/models/food_<id>.glb; пусто = сфера-заглушка
@export var sweet := false       # вокруг сладкого кружит оса


func satiety() -> int:
	return Rarity.SATIETY[tier]
