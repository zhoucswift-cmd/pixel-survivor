extends Control
## 背包界面：按 B 打开 / 关闭。
## 布局模仿生存游戏：左侧人物 + 装备栏 + 属性，中间物品格子，右侧物品详情。

const ITEMS := [
	{
		"id": "cloth", "name": "CLOTH", "type": "MATERIAL",
		"tex": "res://assets/base/cloth.png",
		"desc": ["Torn fabric.", "Used to craft", "clothes and beds."],
	},
	{
		"id": "rope", "name": "ROPE", "type": "MATERIAL",
		"tex": "res://assets/base/rope.png",
		"desc": ["Coiled hemp rope.", "Used for crafting", "and repairs."],
	},
	{
		"id": "shirt_blue", "name": "BLUE SHIRT", "type": "EQUIP",
		"tex": "res://assets/base/shirt.png", "tint": Color8(63, 111, 181),
		"equip": "blue", "own": true,
		"desc": ["A worn blue shirt.", "Click to wear it."],
	},
	{
		"id": "shirt_red", "name": "RED SHIRT", "type": "EQUIP",
		"tex": "res://assets/base/shirt.png", "tint": Color8(181, 63, 63),
		"equip": "red", "own": true,
		"desc": ["A faded red shirt.", "Click to wear it."],
	},
	{
		"id": "shirt_green", "name": "GREEN SHIRT", "type": "EQUIP",
		"tex": "res://assets/base/shirt.png", "tint": Color8(74, 150, 88),
		"equip": "green", "own": true,
		"desc": ["A grass-stained shirt.", "Click to wear it."],
	},
]

const PANEL := Rect2(4, 5, 312, 170)
const TAB_H := 15.0
const TAB_W := 66.0

## 左侧人物 / 装备 / 属性
const CHAR_BOX := Rect2(33, 34, 38, 62)
const EQUIP := 16.0
## 中间物品格子
const GRID_ORIGIN := Vector2(106, 34)
const SLOT := 26.0
const SLOT_GAP := 2.0
const GRID_COLS := 5
const GRID_ROWS := 4
## 右侧详情
const DETAIL := Rect2(248, 28, 64, 142)

var _open := false
var _selected := 0
var _textures: Array[Texture2D] = []
var _sheet: Texture2D = null
var _gs: Node = null
var _player: Node = null
var _atk := 0
var _def := 0
var _speed := 100
## 打开背包前系统鼠标是什么状态（关掉时还原）
var _prev_mouse_mode := Input.MOUSE_MODE_VISIBLE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_gs = get_node_or_null("/root/GameState")
	for data: Dictionary in ITEMS:
		_textures.append(load(data["tex"]))
	_sheet = load("res://assets/character_sheet.png")
	visible = false
	set_process_input(true)


func is_open() -> bool:
	return _open


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.physical_keycode != KEY_B:
		return
	toggle()
	get_viewport().set_input_as_handled()


func toggle() -> void:
	_open = not _open
	visible = _open
	if _open:
		_selected = -1
		# 背包要用鼠标点格子：先把系统光标放出来
		_prev_mouse_mode = Input.mouse_mode
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_refresh_stats()
	else:
		# 关掉时恢复（草地是隐藏光标 + 自绘准心）
		Input.set_mouse_mode(_prev_mouse_mode)
	get_tree().paused = _open
	queue_redraw()


## 从当前场景的玩家身上取属性
func _refresh_stats() -> void:
	_player = null
	var scene := get_tree().current_scene
	if scene != null:
		_player = scene.get_node_or_null("Player")
	_atk = 0
	_def = 0
	_speed = 100
	if _player != null:
		var weapon = _player.weapon
		if weapon != null and _player.armed:
			_atk = int(round(weapon.damage))
		_def = 0
		if _player is CharacterBody2D:
			_speed = 100


func _slot_rect(index: int) -> Rect2:
	var gx := index % GRID_COLS
	var gy := index / GRID_COLS
	return Rect2(GRID_ORIGIN + Vector2(gx, gy) * (SLOT + SLOT_GAP), Vector2(SLOT, SLOT))


## 装备栏格子（0-3 左列，4-6 右列）
func _equip_rect(index: int) -> Rect2:
	if index < 4:
		return Rect2(10, 36 + float(index) * (EQUIP + 3.0), EQUIP, EQUIP)
	return Rect2(78, 36 + float(index - 4) * (EQUIP + 3.0), EQUIP, EQUIP)


## 背包格子里应该显示的物品（穿在身上的衣服不显示，可穿戴物不显示数量）
func _visible_indices() -> Array:
	var out := []
	for i in ITEMS.size():
		var data: Dictionary = ITEMS[i]
		if data.has("equip"):
			# 可穿戴：没穿在身上才在包里
			var worn: bool = _gs != null and _gs.equipped_jacket == data["equip"]
			if not worn:
				out.append(i)
		elif _count_of(i) > 0:
			out.append(i)
	return out


## 点物品：能穿的直接穿上，角色外观立刻变
func _try_equip(index: int) -> void:
	if index < 0 or index >= ITEMS.size():
		return
	var data: Dictionary = ITEMS[index]
	if not data.has("equip"):
		return
	if _gs != null:
		_gs.equipped_jacket = data["equip"]
	var p = get_tree().current_scene.get_node_or_null("Player") if get_tree().current_scene != null else null
	if p != null and p.has_method("apply_look"):
		p.apply_look(_gs.jacket_color() if _gs != null else Color(0, 0, 0, 0))
	_refresh_stats()


func _count_of(index: int) -> int:
	if index < 0 or index >= ITEMS.size():
		return 0
	var data: Dictionary = ITEMS[index]
	if data.has("own"):
		return 1
	if _gs == null:
		return 0
	return int(_gs.get(data["id"]))


func _input(event: InputEvent) -> void:
	if not _open:
		return
	var vis := _visible_indices()
	if event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT:
		for slot in vis.size():
			if _slot_rect(slot).has_point(event.position):
				_selected = vis[slot]
				_try_equip(_selected)
				queue_redraw()
				get_viewport().set_input_as_handled()
				return


## 每帧看鼠标压在哪个格子上：移开就没有黄圈
func _process(_delta: float) -> void:
	if not _open:
		return
	var vis := _visible_indices()
	var hovered := -1
	var mouse := get_local_mouse_position()
	for slot in vis.size():
		if _slot_rect(slot).has_point(mouse):
			hovered = vis[slot]
			break
	if hovered != _selected:
		_selected = hovered
		queue_redraw()


func _draw() -> void:
	if not _open:
		return
	var font := ThemeDB.fallback_font
	var screen := get_viewport_rect().size

	draw_rect(Rect2(Vector2.ZERO, screen), Color(0, 0, 0, 0.6))

	# 主面板
	draw_rect(PANEL, Color(0.055, 0.06, 0.075, 0.98))
	draw_rect(PANEL, Color(1, 1, 1, 0.16), false, 1.0)

	# ===== 标题页签 =====
	draw_rect(Rect2(PANEL.position, Vector2(PANEL.size.x, TAB_H)), Color(0.11, 0.12, 0.15, 1.0))
	draw_line(Vector2(PANEL.position.x, PANEL.position.y + TAB_H - 1),
		Vector2(PANEL.position.x + PANEL.size.x, PANEL.position.y + TAB_H - 1),
		Color(1, 1, 1, 0.12), 1.0)
	var tabs := ["BACKPACK", "CHARACTER", "CRAFT"]
	for i in tabs.size():
		var r := Rect2(PANEL.position.x + 2.0 + float(i) * (TAB_W + 1.0),
			PANEL.position.y + 2.0, TAB_W, TAB_H - 2.0)
		var active := i == 0
		draw_rect(r, Color(0.20, 0.22, 0.26, 1.0) if active else Color(0.09, 0.10, 0.12, 1.0))
		draw_rect(r, Color(1, 1, 1, 0.18) if active else Color(1, 1, 1, 0.06), false, 1.0)
		if active:
			draw_line(Vector2(r.position.x, r.position.y + r.size.y - 1),
				Vector2(r.position.x + r.size.x, r.position.y + r.size.y - 1),
				Color(0.95, 0.78, 0.35, 1.0), 1.0)
		draw_string(font, Vector2(r.position.x + 5.0, r.position.y + 10.0), tabs[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 5,
			Color(0.98, 0.96, 0.9, 0.95) if active else Color(0.58, 0.62, 0.7, 0.8))
	draw_string(font, Vector2(PANEL.position.x + PANEL.size.x - 30.0, PANEL.position.y + 11.0),
		"B CLOSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(0.68, 0.73, 0.84, 0.85))

	# ===== 左侧：人物 + 装备 + 属性 =====
	var left := Rect2(6, 24, 94, 148)
	draw_rect(left, Color(0.08, 0.09, 0.11, 1.0))
	draw_rect(left, Color(1, 1, 1, 0.08), false, 1.0)

	# 人物框
	draw_rect(CHAR_BOX, Color(0.14, 0.15, 0.18, 1.0))
	draw_rect(CHAR_BOX, Color(1, 1, 1, 0.10), false, 1.0)
	var preview_sheet: Texture2D = _sheet
	if _player != null and _player.get("look_sheet") != null:
		preview_sheet = _player.look_sheet
	if preview_sheet != null:
		draw_texture_rect_region(preview_sheet, Rect2(CHAR_BOX.position + Vector2(3, 4), Vector2(32, 32)),
			Rect2(0, 0, 32, 32))

	# 装备格（左 4：帽子/外套/裤子/鞋；右 3：武器/背包/饰品）
	var shirt_tex: Texture2D = _textures[3]     # ITEMS 里第一件 shirt
	for i in 7:
		var r := _equip_rect(i)
		draw_rect(r, Color(0.16, 0.17, 0.21, 1.0))
		draw_rect(r, Color(1, 1, 1, 0.10), false, 1.0)
		if i == 1 and _gs != null and shirt_tex != null:
			# 外套格：画出当前穿的衣服颜色
			draw_texture_rect(shirt_tex, Rect2(r.position + Vector2(1, 1), Vector2(EQUIP - 2, EQUIP - 2)),
				false, _gs.jacket_color())
			continue
		# 空格子中间一个小横线，表示没装备
		draw_line(r.position + Vector2(6, EQUIP * 0.5), r.position + Vector2(EQUIP - 6, EQUIP * 0.5),
			Color(1, 1, 1, 0.14), 1.0)

	# 属性
	var stats := Rect2(9, 116, 88, 52)
	draw_rect(stats, Color(0.10, 0.11, 0.135, 1.0))
	draw_rect(stats, Color(1, 1, 1, 0.08), false, 1.0)
	var rows := [
		["ATTACK", str(_atk)],
		["DEFENSE", str(_def)],
		["SPEED", "%d%%" % _speed],
	]
	for i in rows.size():
		var y := stats.position.y + 10.0 + float(i) * 15.0
		draw_string(font, Vector2(stats.position.x + 5.0, y), rows[i][0],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.8, 0.84, 0.92, 0.9))
		var v: String = rows[i][1]
		var vs := font.get_string_size(v, HORIZONTAL_ALIGNMENT_LEFT, -1, 7)
		draw_string(font, Vector2(stats.position.x + stats.size.x - vs.x - 5.0, y), v,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.97, 0.95, 0.86, 0.95))
		if i < rows.size() - 1:
			draw_line(Vector2(stats.position.x + 4.0, y + 5.0),
				Vector2(stats.position.x + stats.size.x - 4.0, y + 5.0),
				Color(1, 1, 1, 0.06), 1.0)

	# ===== 中间：物品格子 =====
	var grid_box := Rect2(104, 24, 140, 148)
	draw_rect(grid_box, Color(0.08, 0.09, 0.11, 1.0))
	draw_rect(grid_box, Color(1, 1, 1, 0.08), false, 1.0)

	var total := GRID_COLS * GRID_ROWS
	var vis := _visible_indices()
	for slot in total:
		var r := _slot_rect(slot)
		var index: int = vis[slot] if slot < vis.size() else -1
		var is_sel := index >= 0 and index == _selected
		draw_rect(r, Color(0.12, 0.13, 0.16, 1.0))
		draw_rect(r, Color(0.95, 0.78, 0.35, 0.95) if is_sel else Color(1, 1, 1, 0.09), false, 1.0)
		if index < 0:
			continue
		var data_item: Dictionary = ITEMS[index]
		var tex: Texture2D = _textures[index]
		var box := Vector2(SLOT - 6.0, SLOT - 6.0)
		var fit := minf(box.x / tex.get_width(), box.y / tex.get_height())
		var draw_size := Vector2(tex.get_width(), tex.get_height()) * fit
		var tint: Color = data_item.get("tint", Color(1, 1, 1))
		draw_texture_rect(tex, Rect2(r.position + (Vector2(SLOT, SLOT) - draw_size) * 0.5 + Vector2(0, -1), draw_size), false, tint)
		# 可穿戴物不显示数量
		if data_item.has("equip"):
			continue
		var cnt := str(_count_of(index))
		var cs := font.get_string_size(cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 6)
		draw_string(font, Vector2(r.position.x + r.size.x - cs.x - 2.0, r.position.y + r.size.y - 2.0),
			cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.98, 0.96, 0.86, 0.95))

	var used := vis.size()
	draw_string(font, Vector2(grid_box.position.x + 6.0, grid_box.position.y + grid_box.size.y - 5.0),
		"%d / %d" % [used, total], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.7, 0.75, 0.85, 0.85))

	# ===== 右侧：物品详情 =====
	draw_rect(DETAIL, Color(0.09, 0.10, 0.125, 1.0))
	draw_rect(DETAIL, Color(1, 1, 1, 0.10), false, 1.0)
	if _selected >= 0 and _selected < ITEMS.size() and _count_of(_selected) > 0:
		var data: Dictionary = ITEMS[_selected]
		var tex: Texture2D = _textures[_selected]
		var tint2: Color = data.get("tint", Color(1, 1, 1))
		draw_texture_rect(tex, Rect2(DETAIL.position + Vector2(4, 4), Vector2(22, 22)), false, tint2)
		draw_string(font, Vector2(DETAIL.position.x + 28.0, DETAIL.position.y + 13.0),
			data["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.98, 0.96, 0.9, 0.98))
		draw_string(font, Vector2(DETAIL.position.x + 28.0, DETAIL.position.y + 22.0),
			data["type"], HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(0.7, 0.75, 0.86, 0.85))
		draw_line(Vector2(DETAIL.position.x + 4.0, DETAIL.position.y + 30.0),
			Vector2(DETAIL.position.x + DETAIL.size.x - 4.0, DETAIL.position.y + 30.0),
			Color(1, 1, 1, 0.10), 1.0)
		var lines: Array = data["desc"]
		for i in lines.size():
			draw_string(font, Vector2(DETAIL.position.x + 4.0, DETAIL.position.y + 40.0 + float(i) * 9.0),
				lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(0.78, 0.82, 0.9, 0.9))
		# 可穿戴物不显示数量，改成显示是否穿着
		if data.has("equip"):
			var worn_now: bool = _gs != null and _gs.equipped_jacket == data["equip"]
			draw_string(font, Vector2(DETAIL.position.x + 4.0, DETAIL.position.y + DETAIL.size.y - 24.0),
				"EQUIPPED" if worn_now else "NOT WORN", HORIZONTAL_ALIGNMENT_LEFT, -1, 6,
				Color(0.95, 0.9, 0.7, 0.95) if worn_now else Color(0.7, 0.74, 0.84, 0.9))
		else:
			draw_string(font, Vector2(DETAIL.position.x + 4.0, DETAIL.position.y + DETAIL.size.y - 24.0),
				"QTY  %d" % _count_of(_selected), HORIZONTAL_ALIGNMENT_LEFT, -1, 6,
				Color(0.95, 0.9, 0.7, 0.95))
	else:
		draw_string(font, Vector2(DETAIL.position.x + 4.0, DETAIL.position.y + 12.0),
			"EMPTY", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(0.58, 0.62, 0.7, 0.8))
