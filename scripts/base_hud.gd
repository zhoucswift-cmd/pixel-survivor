extends Control
## 基地建造 HUD：按 Tab 在右侧弹出黑色建造面板（标题 + 物品列表 + 底部操作提示）。

const PANEL_W := 100.0
const PANEL_MARGIN := 3.0
const HEADER_H := 15.0
const ROW_H := 26.0
const ROW_GAP := 3.0
const ROW_PAD := 4.0
const FOOTER_H := 26.0

var _builder: Node2D = null
var _selected := -1


func setup(builder: Node2D) -> void:
	_builder = builder
	builder.selection_changed.connect(_on_selection_changed)
	builder.layout_changed.connect(_on_layout_changed)
	_selected = builder.selected
	queue_redraw()


func _process(_delta: float) -> void:
	# 鼠标移到别的家具上时刷新悬停信息
	queue_redraw()


## 面板外框
func _panel_rect() -> Rect2:
	var screen := get_viewport_rect().size
	return Rect2(screen.x - PANEL_W - PANEL_MARGIN, PANEL_MARGIN,
		PANEL_W, screen.y - PANEL_MARGIN * 2.0)


## 列表里第 index 行的矩形（画和点都用它）
func _slot_rect(index: int) -> Rect2:
	var panel := _panel_rect()
	return Rect2(panel.position.x + ROW_PAD,
		panel.position.y + HEADER_H + ROW_PAD + float(index) * (ROW_H + ROW_GAP),
		PANEL_W - ROW_PAD * 2.0, ROW_H)


## 鼠标左键点某一行选家具（点到面板外就不吃事件，交给世界里的放置/拖动）
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

	# ===== 面板底板（黑色）=====
	var panel := _panel_rect()
	draw_rect(panel, Color(0.02, 0.02, 0.03, 0.94))
	draw_rect(panel, Color(1, 1, 1, 0.14), false, 1.0)

	# 标题栏
	var header := Rect2(panel.position, Vector2(panel.size.x, HEADER_H))
	draw_rect(header, Color(0.11, 0.12, 0.15, 1.0))
	draw_line(Vector2(header.position.x, header.position.y + HEADER_H - 1),
		Vector2(header.position.x + header.size.x, header.position.y + HEADER_H - 1),
		Color(1, 1, 1, 0.12), 1.0)
	draw_string(font, Vector2(panel.position.x + 5.0, panel.position.y + 10.0), "BUILD",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.95, 0.93, 0.85, 0.95))

	# ===== 物品列表 =====
	var types: Array = _builder.types
	for i in types.size():
		var row := _slot_rect(i)
		var is_selected: bool = i == _selected
		var data: BaseFurniture = types[i]

		# 行底色
		draw_rect(row, Color(0.72, 0.24, 0.20, 0.95) if is_selected else Color(0.13, 0.14, 0.17, 1.0))
		draw_rect(row, Color(1, 1, 1, 0.55) if is_selected else Color(1, 1, 1, 0.10), false, 1.0)
		# 左边一条色带，像商店条目的图标底
		draw_rect(Rect2(row.position, Vector2(3.0, row.size.y)),
			Color(0.95, 0.78, 0.35, 1.0) if is_selected else Color(0.35, 0.38, 0.45, 1.0))

		# 图标
		if data != null and data.texture != null:
			var tex: Texture2D = data.texture
			var box := Vector2(row.size.y - 8.0, row.size.y - 8.0)
			var tex_size := tex.get_size()
			var fit := minf(box.x / tex_size.x, box.y / tex_size.y)
			var draw_size := tex_size * fit
			var pos := row.position + Vector2(6.0, 4.0) + (box - draw_size) * 0.5
			draw_texture_rect(tex, Rect2(pos, draw_size), false)

		# 名字 + 数量
		var name_text: String = "-" if data == null else data.short_name
		draw_string(font, Vector2(row.position.x + 26.0, row.position.y + 11.0), name_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.96, 0.96, 0.92, 0.95))
		var stock_text := "x%d" % _builder.stock_of(i)
		var stock_size := font.get_string_size(stock_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7)
		draw_string(font, Vector2(row.position.x + row.size.x - stock_size.x - 4.0,
			row.position.y + 11.0), stock_text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.86, 0.9, 1.0, 0.95))

		# 第二行：占地尺寸
		if data != null:
			var fp := data.footprint
			var size_text := "%dx%d" % [fp.x, fp.y]
			draw_string(font, Vector2(row.position.x + 26.0, row.position.y + 21.0), size_text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.7, 0.74, 0.82, 0.85))

	# 悬停到已放置家具时，在行下面标等级
	var hovered: Node2D = _builder.piece_at(_builder.mouse_cell())
	if hovered != null and _selected >= 0:
		var row := _slot_rect(_selected)
		var lv := "LV%d/%d" % [hovered.level, hovered.data.max_level]
		draw_string(font, Vector2(row.position.x + row.size.x - 30.0, row.position.y + 21.0), lv,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1.0, 0.9, 0.55, 0.95))

	# ===== 操作提示：放在左下角的空白处 =====
	var lines := [
		"LMB BUILD / DRAG",
		"RMB CANCEL / RECYCLE",
		"R ROTATE   U UPGRADE   DEL CLEAR",
	]
	for i in lines.size():
		draw_string(font, Vector2(6.0, screen.y - 22.0 + float(i) * 8.0), lines[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.78, 0.84, 0.95, 0.9))
