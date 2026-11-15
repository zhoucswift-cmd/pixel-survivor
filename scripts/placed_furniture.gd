extends Node2D
## 放在基地里的一个家具：一个精灵 + 等级小方块。

const TILE := 16.0

var data: BaseFurniture = null
var level := 1
var cell := Vector2i.ZERO

var _sprite: Sprite2D
var _body: StaticBody2D


func setup(furniture: BaseFurniture, at_cell: Vector2i, start_level := 1) -> void:
	data = furniture
	cell = at_cell
	level = clampi(start_level, 1, furniture.max_level)

	position = Vector2(at_cell) * TILE + Vector2(furniture.footprint) * TILE * 0.5

	# 家具画在人物下面（人物 z_index = 1），走过去不会被挡住
	z_index = 0

	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.z_index = 0
		add_child(_sprite)
	_sprite.texture = furniture.texture

	_add_collision(furniture)
	queue_redraw()


## 占地的碰撞体：人物不能穿过家具
func _add_collision(furniture: BaseFurniture) -> void:
	if _body != null:
		_body.queue_free()
	_body = StaticBody2D.new()
	_body.collision_layer = 1     # 和地形同一层，玩家/僵尸的 mask 是 1
	_body.collision_mask = 0

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(furniture.footprint) * TILE
	shape.shape = rect
	_body.add_child(shape)
	add_child(_body)


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
	# 等级标记：贴在这个家具占地的底部
	var bottom := float(data.footprint.y) * TILE * 0.5 - 4.0
	var left := -float(data.footprint.x) * TILE * 0.5 + 2.0
	for i in level:
		draw_rect(Rect2(left + float(i) * 4.0, bottom, 3.0, 2.0), Color(0.95, 0.84, 0.42, 0.95))
