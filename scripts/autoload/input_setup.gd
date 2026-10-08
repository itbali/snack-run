extends Node
## Регистрирует действия InputMap (клавиатура + геймпад), спек 3.1.

const ACTIONS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_forward": [KEY_W, KEY_UP],
	"move_back": [KEY_S, KEY_DOWN],
	"run": [KEY_SHIFT],
	"jump": [KEY_SPACE],
	"hide": [KEY_CTRL],
	"eat": [KEY_E],
	"cam_left": [KEY_Q],
	"cam_right": [KEY_R],
	"album": [KEY_TAB],
	"pause": [KEY_ESCAPE],
}
const PAD_BUTTONS := {
	"jump": JOY_BUTTON_A,
	"hide": JOY_BUTTON_B,
	"eat": JOY_BUTTON_X,
	"album": JOY_BUTTON_Y,
	"pause": JOY_BUTTON_START,
}
const PAD_AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_forward": [JOY_AXIS_LEFT_Y, -1.0],
	"move_back": [JOY_AXIS_LEFT_Y, 1.0],
	"run": [JOY_AXIS_TRIGGER_RIGHT, 1.0],
	"cam_left": [JOY_AXIS_RIGHT_X, -1.0],
	"cam_right": [JOY_AXIS_RIGHT_X, 1.0],
}


func _ready() -> void:
	register()


static func register() -> void:
	for action in ACTIONS:
		if InputMap.has_action(action):
			continue   # повторная регистрация не должна дублировать события
		InputMap.add_action(action, 0.2)
		for key in ACTIONS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		if PAD_BUTTONS.has(action):
			var b := InputEventJoypadButton.new()
			b.button_index = PAD_BUTTONS[action]
			InputMap.action_add_event(action, b)
		if PAD_AXES.has(action):
			var m := InputEventJoypadMotion.new()
			m.axis = PAD_AXES[action][0]
			m.axis_value = PAD_AXES[action][1]
			InputMap.action_add_event(action, m)
