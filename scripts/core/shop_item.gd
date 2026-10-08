class_name ShopItem
extends Resource
## Товар магазина пряжи (спек 3.5). Файлы в data/shop/*.tres.

@export var id: StringName = &""
@export var display_name := ""
@export var price := 0
@export var kind := "refill"          # refill | max_heart | mouth | speed | quiet | skin
@export var value := 0                # новый max_hearts / mouth_capacity
@export var skin_id: StringName = &""
@export var requires: StringName = &""
@export var order := 0
