extends Node2D
## 放在基地里的一个家具：一个精灵 + 等级小方块。

const TILE := 16.0

var data: BaseFurniture = null
var level := 1
var cell := Vector2i.ZERO

var _sprite: Sprite2D


func setup(furniture: BaseFurniture, at_cell: Vector2i, start_level := 1) -> void:
	data = furniture
	cell = at_cell
	level = clampi(start_level, 1, furniture.max_level)

	position = Vector2(at_cell) * TILE + Vector2(TILE, TILE) * 0.5

	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.z_index = 1
		add_child(_sprite)
	_sprite.texture = furniture.texture

	queue_redraw()


## 升一级，满级返回 false
func upgrade() -> bool:
	if data == null or level >= data.max_level:
		return false
	level += 1
	# 升一级亮一点，直观一点
	modulate = Color(1.0, 1.0, 1.0).lerp(Color(1.25, 1.18, 0.9), float(level - 1) / 2.0)
	queue_redraw()
	return true


func _draw() -> void:
	if data == null:
		return
	# 等级标记：底部小方块
	for i in level:
		var x := -7.0 + float(i) * 4.0
		draw_rect(Rect2(x, 7.0, 3.0, 2.0), Color(0.95, 0.84, 0.42, 0.95))
