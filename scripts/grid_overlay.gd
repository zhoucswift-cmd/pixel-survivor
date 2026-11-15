extends Node2D
## 调试用瓦片网格：在地图上画 16x16 的格子线，按 F1 开关（默认打开）。
## 每 5 格一条略深的线，方便数格子。

const TILE := 16
const MAP_SIZE := Vector2i(320, 320)
const MINOR_COLOR := Color(0, 0, 0, 0.16)
const MAJOR_COLOR := Color(0, 0, 0, 0.30)


func _ready() -> void:
	z_index = 5


func _draw() -> void:
	for x in range(0, MAP_SIZE.x + 1, TILE):
		var color := MAJOR_COLOR if (x / TILE) % 5 == 0 else MINOR_COLOR
		draw_line(Vector2(x, 0), Vector2(x, MAP_SIZE.y), color, 1.0)
	for y in range(0, MAP_SIZE.y + 1, TILE):
		var color := MAJOR_COLOR if (y / TILE) % 5 == 0 else MINOR_COLOR
		draw_line(Vector2(0, y), Vector2(MAP_SIZE.x, y), color, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		visible = not visible


## 调试/测试用
func toggle() -> void:
	visible = not visible
