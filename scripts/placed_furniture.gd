extends Node2D
## 放在基地里的一个家具：精灵 + 等级标记 + 占地碰撞体。

const TILE := 16.0

var data: BaseFurniture = null
var level := 1
## 朝向：0-3，每档 90°
var steps := 0
var cell := Vector2i.ZERO

var _sprite: Sprite2D
var _sleep_sprite: Sprite2D
var _body: StaticBody2D
var _dragging := false
var _occupied := false
var _occ_time := 0.0


func setup(furniture: BaseFurniture, at_cell: Vector2i, start_level := 1, start_steps := 0) -> void:
	data = furniture
	cell = at_cell
	level = clampi(start_level, 1, furniture.max_level)
	steps = posmod(start_steps, 4)

	var fp := _footprint()
	position = Vector2(at_cell) * TILE + Vector2(fp) * TILE * 0.5

	# 家具画在人物下面（人物 z_index = 1），走过去不会被挡住
	z_index = 0

	if _sprite == null:
		_sprite = Sprite2D.new()
		_sprite.z_index = 0
		add_child(_sprite)
	_sprite.texture = furniture.texture
	_sprite.rotation = float(steps) * PI * 0.5

	# 有人时用的贴图（床就是躺上去的样子）
	if data.occupied_texture != null:
		if _sleep_sprite == null:
			_sleep_sprite = Sprite2D.new()
			_sleep_sprite.z_index = 0
			_sleep_sprite.hframes = maxi(1, data.occupied_frames)
			add_child(_sleep_sprite)
		_sleep_sprite.texture = data.occupied_texture
		_sleep_sprite.hframes = maxi(1, data.occupied_frames)
		_sleep_sprite.rotation = float(steps) * PI * 0.5
		_sleep_sprite.visible = _occupied
		_sleep_sprite.frame = 0

	if _sprite != null:
		_sprite.visible = not _occupied

	_add_collision(fp)
	_apply_tint()
	queue_redraw()


## 旋转后的占地（1x2 转 90° 就是 2x1）
func _footprint() -> Vector2i:
	if data == null:
		return Vector2i.ONE
	var fp := data.footprint
	return Vector2i(fp.y, fp.x) if steps % 2 == 1 else fp


## 躺人 / 起来
func set_occupied(value: bool) -> void:
	_occupied = value
	_occ_time = 0.0
	if _sprite != null:
		_sprite.visible = not value
	if _sleep_sprite != null:
		_sleep_sprite.visible = value
		_sleep_sprite.frame = 0


func is_occupied() -> bool:
	return _occupied


## 呼吸：两帧来回
func _process(delta: float) -> void:
	if not _occupied or _sleep_sprite == null or _sleep_sprite.hframes < 2:
		return
	_occ_time += delta
	_sleep_sprite.frame = int(_occ_time / 0.9) % _sleep_sprite.hframes


## 拖动中：半透明、亮一点，方便看落点
func set_dragging(value: bool) -> void:
	_dragging = value
	# 拖动时先关掉碰撞，松手再打开
	if _body != null:
		for child in _body.get_children():
			if child is CollisionShape2D:
				child.set_deferred("disabled", value)
	_apply_tint()


func _apply_tint() -> void:
	if data == null:
		return
	if _dragging:
		modulate = Color(0.85, 0.88, 0.95, 0.8)
		return
	# 升一级亮一点，直观一点
	modulate = Color(1.0, 1.0, 1.0).lerp(Color(1.25, 1.18, 0.9), float(level - 1) / 2.0)


## 占地的碰撞体：人物不能穿过家具
func _add_collision(fp: Vector2i) -> void:
	if _body != null:
		_body.queue_free()
	_body = StaticBody2D.new()
	_body.collision_layer = 1     # 和地形同一层，玩家/僵尸的 mask 是 1
	_body.collision_mask = 0

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	# 往里收 1px：一格宽的缝隙会更好走，不会贴着边缘卡住
	rect.size = Vector2(fp) * TILE - Vector2(2.0, 2.0)
	shape.shape = rect
	_body.add_child(shape)
	add_child(_body)


## 升一级，满级返回 false
func upgrade() -> bool:
	if data == null or level >= data.max_level:
		return false
	level += 1
	_apply_tint()
	queue_redraw()
	return true


func _draw() -> void:
	if data == null:
		return
	var fp := _footprint()
	# 等级标记：贴在这个家具占地的底部
	var bottom := float(fp.y) * TILE * 0.5 - 4.0
	var left := -float(fp.x) * TILE * 0.5 + 2.0
	for i in level:
		draw_rect(Rect2(left + float(i) * 4.0, bottom, 3.0, 2.0), Color(0.95, 0.84, 0.42, 0.95))
