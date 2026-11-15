extends Node2D
## 基地建造：Tab 进建造模式。
##   1-4 选家具 · 左键放置 · 左键按住拖动已有家具 · 右键回收进仓库
##   滚轮旋转（鼠标指着家具就转它，指着空地就转下一件） · U 升级 · Delete 清空
## 布局和库存都存到 user://base_layout.json。

signal selection_changed(index: int)
signal layout_changed()
signal build_mode_changed(active: bool)

const TILE := 16.0
const SAVE_PATH := "user://base_layout.json"
const PLACED_SCENE := preload("res://scenes/placed_furniture.tscn")
## 这些瓦片是楼顶原有设备（舱口 #15 / 空调 #16 / 通风口 #17），不能往上摆东西
const BLOCKED_TILES := [Vector2i(7, 1), Vector2i(0, 2), Vector2i(1, 2)]

## 可建造的家具（留空就自动加载）
@export var types: Array[BaseFurniture] = []
## 每种家具的初始库存
@export var initial_stock := 8

## 当前选中的家具；-1 = 还没选（进建造模式时不预选）
var selected := -1
## 建造模式（Tab 开关）：关着的时候就是纯走路，不显示预览也不能摆东西
var build_mode := false

var _pieces: Dictionary = {}      # Vector2i -> PlacedFurniture
var _stock: Dictionary = {}       # 家具序号 -> 仓库里还剩几个
var _ghost: Sprite2D = null
var _map: Node2D = null
var _player: Node2D = null
var _board: Vector2i = Vector2i(30, 30)
## 新家具的朝向（0-3，每档 90°）
var _placing_steps := 0
var _dragging: Node2D = null
var _drag_origin := Vector2i.ZERO


func setup(map: Node2D, player: Node2D) -> void:
	_map = map
	_player = player
	_board = Vector2i(30, 30)

	if types.is_empty():
		_load_types()

	_ghost = Sprite2D.new()
	_ghost.name = "Ghost"
	_ghost.z_index = 6
	_ghost.modulate = Color(1, 1, 1, 0.55)
	add_child(_ghost)

	for i in types.size():
		_stock[i] = initial_stock

	_load_layout()
	_update_ghost()
	selection_changed.emit(selected)


func select(index: int) -> void:
	if types.is_empty():
		return
	selected = clampi(index, 0, types.size() - 1)
	_update_ghost()
	selection_changed.emit(selected)


func selected_type() -> BaseFurniture:
	if types.is_empty() or selected < 0 or selected >= types.size():
		return null
	return types[selected]


func piece_at(cell: Vector2i) -> Node2D:
	return _pieces.get(cell, null)


func piece_count() -> int:
	var seen := {}
	for cell: Vector2i in _pieces:
		var p: Node2D = _pieces[cell]
		seen[p.get_instance_id()] = true
	return seen.size()


## 仓库里某种家具还剩几个
func stock_of(index: int) -> int:
	return int(_stock.get(index, 0))


func is_dragging() -> bool:
	return _dragging != null


## HUD 用的鼠标所在格
func mouse_cell() -> Vector2i:
	return _mouse_cell()


## 转 90° 之后的占地
func rotated_footprint(data: BaseFurniture, steps: int) -> Vector2i:
	var fp := data.footprint
	return Vector2i(fp.y, fp.x) if steps % 2 == 1 else fp


## 一个家具从 cell 开始覆盖的所有格子
func cells_for(cell: Vector2i, data: BaseFurniture, steps := 0) -> Array[Vector2i]:
	var fp := rotated_footprint(data, steps)
	var cells: Array[Vector2i] = []
	for dy in fp.y:
		for dx in fp.x:
			cells.append(cell + Vector2i(dx, dy))
	return cells


## 这个位置能不能放（整块占地都要空着、可建）
func can_place(cell: Vector2i, type_index := -1, steps := -1) -> bool:
	if types.is_empty():
		return false
	if type_index < 0:
		type_index = selected
	if type_index < 0:
		return false
	if steps < 0:
		steps = _placing_steps
	var data: BaseFurniture = types[clampi(type_index, 0, types.size() - 1)]
	for c in cells_for(cell, data, steps):
		if not is_buildable(c) or _pieces.has(c):
			return false
	return true


## 在某格放一个家具（会扣库存）；返回是否成功
func place(cell: Vector2i, type_index := -1, start_level := 1, steps := -1) -> bool:
	if types.is_empty():
		return false
	if type_index < 0:
		type_index = selected
	if type_index < 0:
		return false
	type_index = clampi(type_index, 0, types.size() - 1)
	if steps < 0:
		steps = _placing_steps
	if not can_place(cell, type_index, steps):
		return false
	if stock_of(type_index) <= 0:
		return false

	_stock[type_index] = stock_of(type_index) - 1

	var data: BaseFurniture = types[type_index]
	var piece: Node2D = PLACED_SCENE.instantiate()
	add_child(piece)
	piece.setup(data, cell, start_level, steps)
	_register(piece, cell, steps, data)

	layout_changed.emit()
	_save_layout()

	# 放完就取消选中：要再按数字键才会继续拿一件出来
	selected = -1
	_update_ghost()
	selection_changed.emit(selected)
	return true


## 回收某格上的家具：拆下来放回仓库
func recycle(cell: Vector2i) -> bool:
	var piece: Node2D = _pieces.get(cell, null)
	if piece == null:
		return false
	var index: int = types.find(piece.data)
	_unregister(piece)
	piece.queue_free()
	if index >= 0:
		_stock[index] = stock_of(index) + 1

	layout_changed.emit()
	_save_layout()
	return true


## 升级某格，满级返回 false
func upgrade(cell: Vector2i) -> bool:
	var piece: Node2D = _pieces.get(cell, null)
	if piece == null or not piece.upgrade():
		return false
	layout_changed.emit()
	_save_layout()
	return true


## 旋转：鼠标指着家具就转它，指着空地就转“下一件”的朝向
func rotate_at(cell: Vector2i, direction: int) -> void:
	var piece: Node2D = _pieces.get(cell, null)
	if piece == null:
		if selected_type() == null:
			return
		_placing_steps = posmod(_placing_steps + direction, 4)
		return

	var origin: Vector2i = piece.cell
	var data: BaseFurniture = piece.data
	var steps := posmod(int(piece.steps) + direction, 4)
	var level: int = piece.level

	_unregister(piece)
	piece.queue_free()

	if can_place(origin, types.find(data), steps):
		var fresh: Node2D = PLACED_SCENE.instantiate()
		add_child(fresh)
		fresh.setup(data, origin, level, steps)
		_register(fresh, origin, steps, data)
	else:
		# 转不开就放回原位
		var back: Node2D = PLACED_SCENE.instantiate()
		add_child(back)
		back.setup(data, origin, level, steps - direction if direction != 0 else 0)
		_register(back, origin, int(back.steps), data)

	layout_changed.emit()
	_save_layout()


## 这格能不能建：在地图内、不在设备瓦片上
func is_buildable(cell: Vector2i) -> bool:
	if cell.x < 1 or cell.y < 1 or cell.x > _board.x - 2 or cell.y > _board.y - 2:
		return false
	var ground := _map.get_node_or_null("Ground") as TileMapLayer
	if ground != null and BLOCKED_TILES.has(ground.get_cell_atlas_coords(cell)):
		return false
	return true


# —— 拖动 ——

func _start_drag(piece: Node2D, cell: Vector2i) -> void:
	_dragging = piece
	_drag_origin = Vector2i(piece.cell)
	_unregister(piece)
	piece.set_dragging(true)


func _finish_drag() -> void:
	if _dragging == null:
		return
	var piece := _dragging
	_dragging = null
	piece.set_dragging(false)

	var cell := _mouse_cell()
	if can_place(cell, types.find(piece.data), int(piece.steps)):
		piece.setup(piece.data, cell, piece.level, int(piece.steps))
		_register(piece, cell, int(piece.steps), piece.data)
	else:
		# 放不下就回原位
		piece.setup(piece.data, _drag_origin, piece.level, int(piece.steps))
		_register(piece, _drag_origin, int(piece.steps), piece.data)

	layout_changed.emit()
	_save_layout()


func _register(piece: Node2D, cell: Vector2i, steps: int, data: BaseFurniture) -> void:
	for c in cells_for(cell, data, steps):
		_pieces[c] = piece


func _unregister(piece: Node2D) -> void:
	for c: Vector2i in _pieces.keys():
		if _pieces[c] == piece:
			_pieces.erase(c)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_mode"):
		toggle_build_mode()
		return

	if not build_mode:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode
		if key >= KEY_1 and key <= KEY_9:
			select(key - KEY_1)
		elif key == KEY_U:
			upgrade(_mouse_cell())
		elif key == KEY_DELETE:
			clear_all()
		return

	if event is InputEventMouseButton:
		var cell := _mouse_cell()
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					var piece: Node2D = _pieces.get(cell, null)
					if piece != null:
						_start_drag(piece, cell)
					else:
						place(cell)
				else:
					_finish_drag()
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					recycle(cell)
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					rotate_at(cell, 1)
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					rotate_at(cell, -1)


## Tab：进 / 出建造模式
func toggle_build_mode() -> void:
	build_mode = not build_mode
	# 刚进建造模式时不预选，按了数字键才出现要放的家具
	selected = -1
	if _ghost != null:
		_ghost.visible = false
	if not build_mode and _dragging != null:
		_finish_drag()
	_update_ghost()
	selection_changed.emit(selected)
	layout_changed.emit()
	build_mode_changed.emit(build_mode)


func _process(_delta: float) -> void:
	if _ghost == null:
		return

	if not build_mode or selected_type() == null:
		_ghost.visible = false
		if _dragging != null:
			return
		return

	var cell := _mouse_cell()

	if _dragging != null:
		# 拖着家具走：家具自己跟着鼠标，预览藏起来
		_ghost.visible = false
		var fp := rotated_footprint(_dragging.data, int(_dragging.steps))
		_dragging.position = Vector2(cell) * TILE + Vector2(fp) * TILE * 0.5
		_dragging.modulate = Color(1, 1, 1, 0.75) if can_place(cell, types.find(_dragging.data), int(_dragging.steps)) \
			else Color(1, 0.5, 0.48, 0.6)
		return

	var data := selected_type()

	# 整块占地都要在平台范围内，否则不显示预览
	var inside := true
	for c in cells_for(cell, data, _placing_steps):
		if c.x < 0 or c.y < 0 or c.x >= _board.x or c.y >= _board.y:
			inside = false
	_ghost.visible = inside
	if not inside:
		return

	var fp := rotated_footprint(data, _placing_steps)
	_ghost.position = Vector2(cell) * TILE + Vector2(fp) * TILE * 0.5
	_ghost.rotation = _placing_steps * PI * 0.5
	var free := can_place(cell) and stock_of(selected) > 0
	_ghost.modulate = Color(1, 1, 1, 0.55) if free else Color(1, 0.45, 0.42, 0.5)


func _mouse_cell() -> Vector2i:
	var world := get_global_mouse_position()
	return Vector2i(floori(world.x / TILE), floori(world.y / TILE))


## 清空整个基地的家具（DELETE 键）
func clear_all() -> void:
	for cell: Vector2i in _pieces.keys():
		var piece: Node2D = _pieces[cell]
		if is_instance_valid(piece):
			piece.queue_free()
	_pieces.clear()
	layout_changed.emit()
	_save_layout()


func _update_ghost() -> void:
	if _ghost == null:
		return
	var data := selected_type()
	_ghost.visible = data != null and data.texture != null
	if data != null:
		_ghost.texture = data.texture


func _load_types() -> void:
	# 固定顺序，保证 1-4 对应家具
	for file in ["bed"]:
		var res: BaseFurniture = load("res://assets/base/%s.tres" % file)
		if res != null:
			types.append(res)


func _save_layout() -> void:
	var arr: Array = []
	for cell: Vector2i in _pieces:
		var piece: Node2D = _pieces[cell]
		arr.append({
			"x": cell.x, "y": cell.y,
			"type": types.find(piece.data),
			"level": piece.level,
			"steps": int(piece.steps),
		})
	var stock: Array = []
	for i in types.size():
		stock.append(stock_of(i))

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"pieces": arr, "stock": stock}))


func _load_layout() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var stock: Array = parsed.get("stock", [])
	for i in mini(stock.size(), types.size()):
		_stock[i] = int(stock[i])

	for item: Dictionary in parsed.get("pieces", []):
		var cell := Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
		var type_index := int(item.get("type", 0))
		var level := int(item.get("level", 1))
		var steps := int(item.get("steps", 0))
		if type_index < 0 or type_index >= types.size():
			continue
		if not can_place(cell, type_index, steps):
			continue
		var piece: Node2D = PLACED_SCENE.instantiate()
		add_child(piece)
		piece.setup(types[type_index], cell, level, steps)
		_register(piece, cell, steps, types[type_index])
