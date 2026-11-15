extends Node2D
## 基地建造系统：数字键 1-4 选家具，左键放置，右键拆除，U 升级。
## 全部按 16px 格子对齐，改完自动存到 user://base_layout.json，下次进来还原。

signal selection_changed(index: int)
signal layout_changed()
signal build_mode_changed(active: bool)

const TILE := 16.0
const SAVE_PATH := "user://base_layout.json"
const PLACED_SCENE := preload("res://scenes/placed_furniture.tscn")
## 这些瓦片是楼顶原有设备（舱口 #15 / 空调 #16 / 通风口 #17），不能往上摆东西
const BLOCKED_TILES := [Vector2i(7, 1), Vector2i(0, 2), Vector2i(1, 2)]

## 可建造的家具（留空就自动加载 assets/base/*.tres）
@export var types: Array[BaseFurniture] = []

var selected := 0
## 建造模式（Tab 开关）：关着的时候就是纯走路，不显示预览也不能摆东西
var build_mode := false
var _pieces: Dictionary = {}          # Vector2i -> PlacedFurniture
var _ghost: Sprite2D = null
var _map: Node2D = null
var _player: Node2D = null
var _board: Vector2i = Vector2i(30, 30)


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
	if types.is_empty():
		return null
	return types[selected]


func piece_at(cell: Vector2i) -> Node2D:
	return _pieces.get(cell, null)


func piece_count() -> int:
	return _pieces.size()


## 一个家具从 cell 开始覆盖的所有格子
func cells_for(cell: Vector2i, data: BaseFurniture) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dy in data.footprint.y:
		for dx in data.footprint.x:
			cells.append(cell + Vector2i(dx, dy))
	return cells


## 这个位置能不能放（整块占地都要空着、可建）
func can_place(cell: Vector2i, type_index := -1) -> bool:
	if types.is_empty():
		return false
	if type_index < 0:
		type_index = selected
	var data: BaseFurniture = types[clampi(type_index, 0, types.size() - 1)]
	for c in cells_for(cell, data):
		if not is_buildable(c) or _pieces.has(c):
			return false
	return true


## 在某格放一个家具；返回是否成功
func place(cell: Vector2i, type_index := -1, start_level := 1) -> bool:
	if types.is_empty():
		return false
	if type_index < 0:
		type_index = selected
	type_index = clampi(type_index, 0, types.size() - 1)
	if not can_place(cell, type_index):
		return false

	var data: BaseFurniture = types[type_index]
	var piece: Node2D = PLACED_SCENE.instantiate()
	add_child(piece)
	piece.setup(data, cell, start_level)
	for c in cells_for(cell, data):
		_pieces[c] = piece
	layout_changed.emit()
	_save_layout()
	return true


## 拆除某格
func remove(cell: Vector2i) -> bool:
	var piece: Node2D = _pieces.get(cell, null)
	if piece == null:
		return false
	for c: Vector2i in _pieces.keys():
		if _pieces[c] == piece:
			_pieces.erase(c)
	piece.queue_free()
	layout_changed.emit()
	_save_layout()
	return true


## 清空整个基地的家具（DELETE 键）
func clear_all() -> void:
	for cell: Vector2i in _pieces.keys():
		var piece: Node2D = _pieces[cell]
		if is_instance_valid(piece):
			piece.queue_free()
	_pieces.clear()
	layout_changed.emit()
	_save_layout()


## 升级某格，满级返回 false
func upgrade(cell: Vector2i) -> bool:
	var piece: Node2D = _pieces.get(cell, null)
	if piece == null or not piece.upgrade():
		return false
	layout_changed.emit()
	_save_layout()
	return true


## 这格能不能建：在地图内、不在设备瓦片上
func is_buildable(cell: Vector2i) -> bool:
	if cell.x < 1 or cell.y < 1 or cell.x > _board.x - 2 or cell.y > _board.y - 2:
		return false
	var ground := _map.get_node_or_null("Ground") as TileMapLayer
	if ground != null and BLOCKED_TILES.has(ground.get_cell_atlas_coords(cell)):
		return false
	return true


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

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			place(_mouse_cell())
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			remove(_mouse_cell())


## Tab：进 / 出建造模式
func toggle_build_mode() -> void:
	build_mode = not build_mode
	if not build_mode and _ghost != null:
		_ghost.visible = false
	layout_changed.emit()
	build_mode_changed.emit(build_mode)


func _process(_delta: float) -> void:
	if _ghost == null or selected_type() == null:
		return

	if not build_mode:
		_ghost.visible = false
		return

	var cell := _mouse_cell()
	var data := selected_type()

	# 整块占地都要在平台范围内，否则不显示预览
	var inside := true
	for c in cells_for(cell, data):
		if c.x < 0 or c.y < 0 or c.x >= _board.x or c.y >= _board.y:
			inside = false
	_ghost.visible = inside
	if not inside:
		return

	_ghost.position = Vector2(cell) * TILE + Vector2(data.footprint) * TILE * 0.5
	_ghost.modulate = Color(1, 1, 1, 0.55) if can_place(cell) else Color(1, 0.45, 0.42, 0.5)


## 是不是在 30x30 平台范围内
func _in_board(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _board.x and cell.y < _board.y


## HUD 用的鼠标所在格
func mouse_cell() -> Vector2i:
	return _mouse_cell()


func _mouse_cell() -> Vector2i:
	var world := get_global_mouse_position()
	return Vector2i(floori(world.x / TILE), floori(world.y / TILE))


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE + Vector2(TILE, TILE) * 0.5


func _update_ghost() -> void:
	if _ghost == null:
		return
	var data := selected_type()
	_ghost.visible = data != null and data.texture != null
	if data != null:
		_ghost.texture = data.texture


func _load_types() -> void:
	# 固定顺序，保证 1-4 对应工作台 / 储物箱 / 发电机 / 盆栽
	for file in ["workbench", "storage", "generator", "plant", "bed"]:
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
		})
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({"pieces": arr}))


func _load_layout() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var text := FileAccess.get_file_as_string(SAVE_PATH)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for item: Dictionary in parsed.get("pieces", []):
		var cell := Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
		var type_index := int(item.get("type", 0))
		var level := int(item.get("level", 1))
		if type_index < 0 or type_index >= types.size():
			continue
		place(cell, type_index, level)
