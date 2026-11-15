extends Control
## 基地建造 HUD：按 Tab 在右侧弹出黑色建造面板（标题 + 物品列表 + 底部操作提示）。

const PANEL_W := 100.0
const PANEL_MARGIN := 3.0
const HEADER_H := 15.0
const ROW_H := 22.0
const ROW_GAP := 3.0
const ROW_PAD := 4.0
const FOOTER_H := 26.0

## 三个工作台的配方（out 是产物 id，bed 会进仓库，其它是装备）
const RECIPES := {
	"tools": [],
	"clothing": [
		{"out": "casual_hat", "name": "CASUAL HAT", "tex": "res://assets/base/icon_hat.png", "tint": Color8(198, 176, 128), "cost": {"cloth": 2, "rope": 1}},
		{"out": "casual_top", "name": "CASUAL TOP", "tex": "res://assets/base/icon_shirt.png", "tint": Color8(110, 160, 210), "cost": {"cloth": 7, "rope": 2}},
		{"out": "casual_pants", "name": "CASUAL PANTS", "tex": "res://assets/base/icon_pants.png", "tint": Color8(84, 92, 116), "cost": {"cloth": 4, "rope": 1}},
		{"out": "casual_shoes", "name": "CASUAL SHOES", "tex": "res://assets/base/icon_boots.png", "tint": Color8(126, 84, 52), "cost": {"cloth": 5, "rope": 3}},
	],
	"carpentry": [
		{"out": "bed", "name": "BED", "tex": "res://assets/base/bed.png", "cost": {"cloth": 2, "rope": 1}},
	],
}

## 制造面板里点了某个配方
signal craft_requested(out_id: String)

var _builder: Node2D = null
var _selected := -1
## 当前制造面板属于哪个工作台
var _craft_category := ""
var _recipe_tex: Array[Texture2D] = []
var _hover_recipe := -1
## 面板模式："build" 建造 / "craft" 工作台制造
var _mode := "build"


func setup(builder: Node2D) -> void:
	_builder = builder
	builder.selection_changed.connect(_on_selection_changed)
	builder.layout_changed.connect(_on_layout_changed)
	_selected = builder.selected
	queue_redraw()


## 切换面板模式（建造 / 制造）
func set_mode(mode: String) -> void:
	_mode = mode
	queue_redraw()


func is_craft_open() -> bool:
	return _mode == "craft"


## 打开制造面板时告诉它现在是哪个工作台
func set_craft_category(cat: String) -> void:
	_craft_category = cat
	_hover_recipe = -1
	_recipe_tex.clear()
	for r: Dictionary in recipes():
		_recipe_tex.append(load(r["tex"]) if r.has("tex") else null)
	queue_redraw()


func recipes() -> Array:
	return RECIPES.get(_craft_category, [])


## 制造面板里第 i 个配方那一行
func _recipe_rect(index: int) -> Rect2:
	var panel := _panel_rect()
	return Rect2(panel.position.x + ROW_PAD, panel.position.y + HEADER_H + ROW_PAD + float(index) * (ROW_H + ROW_GAP),
		PANEL_W - ROW_PAD * 2.0, ROW_H)


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
	if _mode == "craft":
		var list: Array = recipes()
		for i in list.size():
			if _recipe_rect(i).has_point(event.position):
				craft_requested.emit(list[i]["out"])
				accept_event()
				return
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

	# 制造面板和建造面板共用一个面板，只是标题和底部提示不一样
	var crafting := _mode == "craft"

	# 既不在建造、也不在制造：只留一条 Tab 提示（睡着等锁住的情况下不显示）
	if not crafting and not _builder.build_mode:
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
	draw_string(font, Vector2(panel.position.x + 5.0, panel.position.y + 10.0),
		"CRAFT" if crafting else "BUILD",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.95, 0.93, 0.85, 0.95))

	# ===== 面板内容 =====
	if crafting:
		var list: Array = recipes()
		if list.is_empty():
			var tip := "NO RECIPES YET"
			var tip_size := font.get_string_size(tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 6)
			draw_string(font, Vector2(panel.position.x + (panel.size.x - tip_size.x) * 0.5,
				panel.position.y + HEADER_H + 30.0), tip,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.62, 0.66, 0.74, 0.9))
		else:
			var gs := get_node_or_null("/root/GameState")
			for i in list.size():
				var r := _recipe_rect(i)
				var recipe: Dictionary = list[i]
				var afford: bool = gs == null or gs.can_afford(recipe["cost"])
				var hot := i == _hover_recipe
				draw_rect(r, Color(0.72, 0.24, 0.20, 0.95) if hot else Color(0.13, 0.14, 0.17, 1.0))
				draw_rect(r, Color(1, 1, 1, 0.5) if hot else Color(1, 1, 1, 0.10), false, 1.0)
				if i < _recipe_tex.size() and _recipe_tex[i] != null:
					var box := Vector2(r.size.y - 8.0, r.size.y - 8.0)
					draw_texture_rect(_recipe_tex[i], Rect2(r.position + Vector2(6.0, 4.0), box),
						false, recipe.get("tint", Color(1, 1, 1)))
				# 名字
				draw_string(font, Vector2(r.position.x + 26.0, r.position.y + 10.0), recipe["name"],
					HORIZONTAL_ALIGNMENT_LEFT, -1, 6,
					Color(0.96, 0.96, 0.92, 0.95) if afford else Color(0.62, 0.64, 0.7, 0.9))
				# 材料
				var parts: Array[String] = []
				for k: String in recipe["cost"]:
					parts.append("%d %s" % [int(recipe["cost"][k]), k.to_upper()])
				var cost_text := " ".join(parts)
				draw_string(font, Vector2(r.position.x + 26.0, r.position.y + 19.0), cost_text,
					HORIZONTAL_ALIGNMENT_LEFT, -1, 5,
					Color(0.78, 0.84, 0.95, 0.9) if afford else Color(0.9, 0.5, 0.45, 0.9))
	else:
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
			# 名字太长就缩小一号，别和右边的数量撞上
			var name_size := 7 if name_text.length() <= 12 else 5
			draw_string(font, Vector2(row.position.x + 26.0, row.position.y + 13.0), name_text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, name_size, Color(0.96, 0.96, 0.92, 0.95))
			var stock_text := "x%d" % _builder.stock_of(i)
			var stock_size := font.get_string_size(stock_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7)
			draw_string(font, Vector2(row.position.x + row.size.x - stock_size.x - 4.0,
				row.position.y + 13.0), stock_text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color(0.86, 0.9, 1.0, 0.95))

	# ===== 操作提示：放在左下角的空白处 =====
	var lines := [
		"LMB BUILD / DRAG",
		"RMB CANCEL / RECYCLE",
		"R ROTATE   U UPGRADE   DEL CLEAR",
	]
	if crafting:
		lines = ["LMB CRAFT", "E / TAB CLOSE"]
	for i in lines.size():
		draw_string(font, Vector2(6.0, screen.y - 22.0 + float(i) * 8.0), lines[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(0.78, 0.84, 0.95, 0.9))
