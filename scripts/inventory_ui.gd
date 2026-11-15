extends Control
## 背包界面：按 B 打开 / 关闭。全屏大面板 + 物品格子 + 右侧详情。
## 用 GameState 里的资源数量显示。

const ITEMS := [
	{
		"id": "cloth", "name": "CLOTH", "type": "MATERIAL",
		"tex": "res://assets/base/cloth.png",
		"desc": ["Torn fabric.", "Used to craft clothes,", "beds and other things."],
	},
	{
		"id": "rope", "name": "ROPE", "type": "MATERIAL",
		"tex": "res://assets/base/rope.png",
		"desc": ["Coiled hemp rope.", "Used for crafting,", "traps and repairs."],
	},
]

const PANEL := Rect2(20, 12, 280, 156)
const TAB_H := 20.0
const TAB_W := 70.0
const SLOT := 26.0
const SLOT_GAP := 2.0
const GRID_COLS := 6
const GRID_ROWS := 4

var _open := false
var _selected := 0
var _textures: Array[Texture2D] = []
var _paused_by_me := false
var _gs: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_gs = get_node_or_null("/root/GameState")
	# 贴图在 _ready 里预加载，别在 _draw 里 load
	for data: Dictionary in ITEMS:
		_textures.append(load(data["tex"]))
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
	_paused_by_me = _open
	get_tree().paused = _open
	queue_redraw()


## 某个格子（背包格子）的矩形
func _slot_rect(index: int) -> Rect2:
	var gx := index % GRID_COLS
	var gy := index / GRID_COLS
	var origin := Vector2(PANEL.position.x + 10.0, PANEL.position.y + TAB_H + 14.0)
	return Rect2(origin + Vector2(gx, gy) * (SLOT + SLOT_GAP), Vector2(SLOT, SLOT))


func _count_of(index: int) -> int:
	if _gs == null or index < 0 or index >= ITEMS.size():
		return 0
	return int(_gs.get(ITEMS[index]["id"]))


func _input(event: InputEvent) -> void:
	if not _open:
		return
	# 鼠标移动 / 点击：选格子
	if event is InputEventMouseMotion:
		for i in ITEMS.size():
			if _slot_rect(i).has_point(event.position):
				if _selected != i:
					_selected = i
					queue_redraw()
				break
	elif event is InputEventMouseButton and event.pressed \
		and event.button_index == MOUSE_BUTTON_LEFT:
		for i in ITEMS.size():
			if _slot_rect(i).has_point(event.position):
				_selected = i
				queue_redraw()
				get_viewport().set_input_as_handled()
				return


func _draw() -> void:
	if not _open:
		return
	var font := ThemeDB.fallback_font
	var screen := get_viewport_rect().size

	# 压暗背景
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0, 0, 0, 0.55))

	# 主面板
	draw_rect(PANEL, Color(0.06, 0.065, 0.08, 0.98))
	draw_rect(PANEL, Color(1, 1, 1, 0.16), false, 1.0)

	# 标题栏
	draw_rect(Rect2(PANEL.position, Vector2(PANEL.size.x, TAB_H)), Color(0.12, 0.13, 0.16, 1.0))
	draw_line(Vector2(PANEL.position.x, PANEL.position.y + TAB_H - 1),
		Vector2(PANEL.position.x + PANEL.size.x, PANEL.position.y + TAB_H - 1),
		Color(1, 1, 1, 0.12), 1.0)
	# 三个页签（只有 BACKPACK 是亮的）
	var tabs := ["BACKPACK", "CHARACTER", "CRAFT"]
	for i in tabs.size():
		var r := Rect2(PANEL.position.x + 4.0 + float(i) * (TAB_W + 2.0),
			PANEL.position.y + 3.0, TAB_W, TAB_H - 3.0)
		var active := i == 0
		draw_rect(r, Color(0.20, 0.22, 0.26, 1.0) if active else Color(0.10, 0.11, 0.13, 1.0))
		draw_rect(r, Color(1, 1, 1, 0.20) if active else Color(1, 1, 1, 0.07), false, 1.0)
		if active:
			draw_line(Vector2(r.position.x, r.position.y + r.size.y - 1),
				Vector2(r.position.x + r.size.x, r.position.y + r.size.y - 1),
				Color(0.95, 0.78, 0.35, 1.0), 1.0)
		draw_string(font, Vector2(r.position.x + 6.0, r.position.y + 11.0), tabs[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 6,
			Color(0.98, 0.96, 0.9, 0.95) if active else Color(0.6, 0.64, 0.72, 0.8))

	# 右上角关闭提示
	draw_string(font, Vector2(PANEL.position.x + PANEL.size.x - 30.0, PANEL.position.y + 13.0),
		"B CLOSE", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.7, 0.75, 0.85, 0.85))

	# ===== 物品格子 =====
	var total_slots := GRID_COLS * GRID_ROWS
	for i in total_slots:
		var r := _slot_rect(i)
		var has_item := i < ITEMS.size() and _count_of(i) > 0
		var is_sel := i == _selected and has_item
		draw_rect(r, Color(0.12, 0.13, 0.16, 1.0))
		draw_rect(r, Color(0.95, 0.78, 0.35, 0.95) if is_sel else Color(1, 1, 1, 0.10),
			false, 1.0)
		if not has_item:
			continue
		var tex: Texture2D = _textures[i]
		var box := Vector2(SLOT - 6.0, SLOT - 6.0)
		var fit := minf(box.x / tex.get_width(), box.y / tex.get_height())
		var draw_size := Vector2(tex.get_width(), tex.get_height()) * fit
		draw_texture_rect(tex, Rect2(r.position + (Vector2(SLOT, SLOT) - draw_size) * 0.5 + Vector2(0, -1), draw_size), false)
		# 数量
		var cnt := str(_count_of(i))
		var cnt_size := font.get_string_size(cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 6)
		draw_string(font, Vector2(r.position.x + r.size.x - cnt_size.x - 2.0,
			r.position.y + r.size.y - 2.0), cnt,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.98, 0.96, 0.86, 0.95))

	# 格子数量提示
	var used := 0
	for i in ITEMS.size():
		if _count_of(i) > 0:
			used += 1
	draw_string(font, Vector2(PANEL.position.x + 10.0, PANEL.position.y + PANEL.size.y - 6.0),
		"%d / %d" % [used, total_slots], HORIZONTAL_ALIGNMENT_LEFT, -1, 6,
		Color(0.7, 0.75, 0.85, 0.85))

	# ===== 右侧详情 =====
	var detail := Rect2(PANEL.position.x + 186.0, PANEL.position.y + TAB_H + 4.0,
		88.0, PANEL.size.y - TAB_H - 10.0)
	draw_rect(detail, Color(0.09, 0.10, 0.125, 1.0))
	draw_rect(detail, Color(1, 1, 1, 0.10), false, 1.0)

	if _selected >= 0 and _selected < ITEMS.size() and _count_of(_selected) > 0:
		var data: Dictionary = ITEMS[_selected]
		# 大图标
		var tex: Texture2D = _textures[_selected]
		var big := Vector2(24, 24)
		draw_texture_rect(tex, Rect2(detail.position + Vector2(6, 5), big), false)
		draw_string(font, Vector2(detail.position.x + 34.0, detail.position.y + 14.0),
			data["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.98, 0.96, 0.9, 0.98))
		draw_string(font, Vector2(detail.position.x + 34.0, detail.position.y + 23.0),
			data["type"], HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(0.72, 0.76, 0.86, 0.85))
		# 分隔线
		draw_line(Vector2(detail.position.x + 5.0, detail.position.y + 32.0),
			Vector2(detail.position.x + detail.size.x - 5.0, detail.position.y + 32.0),
			Color(1, 1, 1, 0.10), 1.0)
		# 描述
		var lines: Array = data["desc"]
		for i in lines.size():
			draw_string(font, Vector2(detail.position.x + 6.0, detail.position.y + 42.0 + float(i) * 9.0),
				lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color(0.78, 0.82, 0.9, 0.9))
		# 数量
		draw_string(font, Vector2(detail.position.x + 6.0, detail.position.y + detail.size.y - 12.0),
			"QTY  %d" % _count_of(_selected), HORIZONTAL_ALIGNMENT_LEFT, -1, 7,
			Color(0.95, 0.9, 0.7, 0.95))
	else:
		draw_string(font, Vector2(detail.position.x + 6.0, detail.position.y + 14.0),
			"EMPTY", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.6, 0.64, 0.72, 0.8))
