extends Node
## Сохранение прогресса в JSON. Пишет только по явному вызову save_now() (из Main).

const VERSION := 1

var path := "user://save.json"


func save_now() -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("не удалось открыть %s для записи" % path)
		return false
	f.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	f.close()
	return true


func load_now() -> bool:
	if not FileAccess.file_exists(path):
		GameState.reset()
		return false
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()   # parse() возвращает код ошибки и не печатает ERROR в консоль, в отличие от parse_string
	var parsed = json.data if json.parse(text) == OK else null
	if not (parsed is Dictionary):
		push_warning("сохранение повреждено, начинаем заново: " + path)
		GameState.reset()
		return false
	GameState.from_dict(parsed)
	return true


func clear() -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
