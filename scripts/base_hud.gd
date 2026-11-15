extends Control
## 基地建造 HUD：底部一排家具槽位 + 操作提示。

const SLOT := 24.0
const SLOT_GAP := 3.0
const ICON := 16.0

var _builder: Node2D = null
var _selected := 0


func setup(builder: Node2D) -> void:
	_builder = builder
	builder.selection_changed.connect(_on_selection_changed)
	builder.layout_changed.connect(_on_layout_changed)
	_selected = builder.selected
	queue_redraw()


func _process(_delta: float) -> void:
	# 鼠标移动到别的家具上时刷新一下悬停信息
	queue_redraw()


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

	# 非建造模式：只留一条 Tab 提示
	if not _builder.build_mode:
		var hint := "TAB - BUILD"
		var size := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 8)
		draw_string(font, Vector2((screen.x - size.x) * 0.5, screen.y - 6.0), hint,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.9, 0.93, 1.0, 0.75))
		return

	# 底部底板
	var bar_h := 40.0
	var bar_y := screen.y - bar_h
	draw_rect(Rect2(0, bar_y, screen.x, bar_h), Color(0.06, 0.07, 0.09, 0.82))
	draw_line(Vector2(0, bar_y), Vector2(screen.x, bar_y), Color(1, 1, 1, 0.12), 1.0)

	# 槽位
	var types: Array = _builder.types
	var x := 8.0
	var y := bar_y + 4.0
	for i in types.size():
		var rect := Rect2(x, y, SLOT, SLOT)
		var is_selected: bool = i == _selected
		draw_rect(rect, Color(0.86, 0.33, 0.26, 0.9) if is_selected else Color(0.16, 0.18, 0.22, 0.95))
		draw_rect(rect, Color(1, 1, 1, 0.75) if is_selected else Color(1, 1, 1, 0.25), false, 1.0)

		var data: BaseFurniture = types[i]
		if data != null and data.texture != null:
			var tex: Texture2D = data.texture
			# 图标按槽位等比缩放（床这种 1x2 的也能塞进来）
			var tex_size := tex.get_size()
			var fit := minf((SLOT - 4.0) / tex_size.x, (SLOT - 4.0) / tex_size.y)
			var draw_size := tex_size * fit
			var pos := rect.position + (Vector2(SLOT, SLOT) - draw_size) * 0.5
			draw_texture_rect(tex, Rect2(pos, draw_size), false)

		var num := str(i + 1)
		draw_string(font, rect.position + Vector2(1, 7), num,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(1, 1, 1, 0.85))
		x += SLOT + SLOT_GAP

	# 当前选中 + 操作提示
	var data_sel: BaseFurniture = _builder.selected_type()
	var name_text: String = "PRESS 1 TO BUILD" if data_sel == null \
		else "%s  x%d" % [data_sel.short_name, _builder.stock_of(_selected)]
	var level_text := ""
	var hovered: Node2D = _builder.piece_at(_builder.mouse_cell())
	if hovered != null:
		level_text = "  LV%d/%d" % [hovered.level, hovered.data.max_level]
	draw_string(font, Vector2(x + 6.0, y + 9.0), name_text + level_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.95, 0.95, 0.9, 0.95))
	var hint := "LMB BUILD/DRAG   RMB RECYCLE   WHEEL ROTATE   U UPGRADE   DEL CLEAR"
	if types.size() > 1:
		hint = "1-%d SELECT   " % types.size() + hint
	draw_string(font, Vector2(8.0, y + 33.0), hint,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.8, 0.85, 0.95, 0.8))

	# 放置数量
	var count_text := "%d PLACED" % _builder.piece_count()
	var size := font.get_string_size(count_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7)
	draw_string(font, Vector2(screen.x - size.x - 6.0, bar_y + 12.0), count_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.85, 0.9, 1, 0.8))
