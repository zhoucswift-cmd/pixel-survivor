extends Control
## 基地建造 HUD：按 Tab 后左侧弹出竖着的家具面板（图标竖排），底部只有一条操作提示。

const PANEL_W := 40.0
const PANEL_X := 4.0
const SLOT := 28.0
const SLOT_GAP := 4.0
const PANEL_PAD := 6.0

var _builder: Node2D = null
var _selected := -1


func setup(builder: Node2D) -> void:
	_builder = builder
	builder.selection_changed.connect(_on_selection_changed)
	builder.layout_changed.connect(_on_layout_changed)
	_selected = builder.selected
	queue_redraw()


func _process(_delta: float) -> void:
	# 鼠标移动到别的家具上时刷新一下悬停信息
	queue_redraw()


## 面板外框
func _panel_rect() -> Rect2:
	var screen := get_viewport_rect().size
	var n: int = 0 if _builder == null else _builder.types.size()
	var h := PANEL_PAD * 2.0 + float(n) * (SLOT + SLOT_GAP) - SLOT_GAP
	return Rect2(PANEL_X, (screen.y - h) * 0.5, PANEL_W, h)


## 某个家具槽位的矩形（画和点都用它）
func _slot_rect(index: int) -> Rect2:
	var panel := _panel_rect()
	return Rect2(panel.position.x + (PANEL_W - SLOT) * 0.5,
		panel.position.y + PANEL_PAD + float(index) * (SLOT + SLOT_GAP), SLOT, SLOT)


## 鼠标左键点槽位选家具（点到槽位外就不吃事件，交给世界里的放置/拖动）
func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	if event.button_index != MOUSE_BUTTON_LEFT or _builder == null:
		return
	for i in _builder.types.size():
		if _slot_rect(i).has_point(event.position):
			_builder.select(i)
			accept_event()
			return


func _on_selection_changed(index: int) -> void:
	_selected = index
	queue_redraw()


func _on_layout_changed() -> void:
	queue_redraw()


func _draw() -> void:
	if _builder == null:
		return
	var font := ThemeDB.fallback_font
	var screen := get_viewport_rect().size

	# 非建造模式：只留一条 Tab 提示（睡着等锁住的情况下不显示）
	if not _builder.build_mode:
		if _builder.build_locked:
			return
		var hint := "TAB - BUILD"
		var hint_size := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		draw_string(font, Vector2((screen.x - hint_size.x) * 0.5, screen.y - 6.0), hint,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.9, 0.93, 1.0, 0.75))
		return

	# ===== 左侧竖面板 =====
	var panel := _panel_rect()
	draw_rect(panel, Color(0.06, 0.07, 0.09, 0.86))
	draw_rect(panel, Color(1, 1, 1, 0.16), false, 1.0)
	# 面板左上角一点高光，做出“浮起来”的感觉
	draw_line(panel.position + Vector2(1, 1), panel.position + Vector2(panel.size.x - 1, 1),
		Color(1, 1, 1, 0.22), 1.0)

	var types: Array = _builder.types
	for i in types.size():
		var rect := _slot_rect(i)
		var is_selected: bool = i == _selected
		draw_rect(rect, Color(0.86, 0.33, 0.26, 0.95) if is_selected else Color(0.16, 0.18, 0.22, 0.96))
		draw_rect(rect, Color(1, 1, 1, 0.8) if is_selected else Color(1, 1, 1, 0.22), false, 1.0)

		var data: BaseFurniture = types[i]
		if data != null and data.texture != null:
			var tex: Texture2D = data.texture
			var tex_size := tex.get_size()
			var fit := minf((SLOT - 6.0) / tex_size.x, (SLOT - 6.0) / tex_size.y)
			var draw_size := tex_size * fit
			var pos := rect.position + (Vector2(SLOT, SLOT) - draw_size) * 0.5
			draw_texture_rect(tex, Rect2(pos, draw_size), false)

	# 选中信息（面板正下方）
	var data_sel: BaseFurniture = _builder.selected_type()
	var info := "CLICK AN ITEM" if data_sel == null \
		else "%s x%d" % [data_sel.short_name, _builder.stock_of(_selected)]
	var hovered: Node2D = _builder.piece_at(_builder.mouse_cell())
	if hovered != null:
		info += "  LV%d/%d" % [hovered.level, hovered.data.max_level]
	draw_string(font, Vector2(panel.position.x + 2.0, panel.position.y + panel.size.y + 10.0),
		info, HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.95, 0.95, 0.9, 0.95))

	# ===== 底部：操作提示 + 已放置数量 =====
	var hint := "LMB SELECT / BUILD / DRAG    RMB CANCEL / RECYCLE    R ROTATE    U UPGRADE    DEL CLEAR"
	draw_string(font, Vector2(8.0, screen.y - 5.0), hint,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.8, 0.85, 0.95, 0.8))

	var count_text := "%d PLACED" % _builder.piece_count()
	var count_size := font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6)
	draw_string(font, Vector2(screen.x - count_size.x - 6.0, screen.y - 5.0), count_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.85, 0.9, 1, 0.8))
