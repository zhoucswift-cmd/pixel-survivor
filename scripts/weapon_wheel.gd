extends Control
## 武器轮盘：按住 Tab 暂停游戏并弹出，鼠标指向某个槽位，松开 Tab 装备它。
## 目前只有霰弹枪，所以是一个槽位的轮盘；以后 weapons 数组里加枪就会自动多出槽位。

const RADIUS := 46.0
const SLOT_RADIUS := 17.0
const DEADZONE := 12.0
const SLOT_LABEL_SIZE := 7
const CENTER_LABEL_SIZE := 10
const HINT_SIZE := 8

var _player: Node2D = null
var _open := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func is_open() -> bool:
	return _open


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("weapon_wheel"):
		open_wheel()
	elif event.is_action_released("weapon_wheel"):
		close_wheel()


func _process(_delta: float) -> void:
	if _open:
		queue_redraw()


func open_wheel() -> void:
	if _open:
		return
	_player = get_tree().get_first_node_in_group("player")
	if _player == null or _player.weapons.is_empty():
		return
	_open = true
	visible = true
	get_tree().paused = true
	# 轮盘时要能看到鼠标指针
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	queue_redraw()


func close_wheel() -> void:
	if not _open:
		return
	var index := highlighted()
	_open = false
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	if index >= 0:
		_player.equip(index)


## 槽位在圆周上的角度：1 个在正上，2 个在左右，其余均分
func _slot_angle(index: int, count: int) -> float:
	if count == 2:
		return PI if index == 0 else 0.0
	return -PI / 2.0 + TAU * float(index) / float(count)


## 鼠标指向哪个槽位（取角度最接近的）；鼠标在中间死区时返回 -1
func highlighted() -> int:
	if _player == null or _player.weapons.is_empty():
		return -1
	var center := get_viewport_rect().size * 0.5
	var to := get_viewport().get_mouse_position() - center
	if to.length() < DEADZONE:
		return -1
	var count: int = _player.weapons.size()
	var mouse_angle := to.angle()
	var best := 0
	var best_diff := INF
	for i in count:
		var diff := absf(angle_difference(mouse_angle, _slot_angle(i, count)))
		if diff < best_diff:
			best_diff = diff
			best = i
	return best


func _draw() -> void:
	if not _open or _player == null:
		return

	var center := get_viewport_rect().size * 0.5
	var screen := get_viewport_rect().size
	var font := ThemeDB.fallback_font

	# 背景压暗
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0, 0, 0, 0.55))

	var count: int = _player.weapons.size()
	var selected := highlighted()

	for i in count:
		var angle := _slot_angle(i, count)
		var pos := center + Vector2(cos(angle), sin(angle)) * RADIUS
		var is_selected := i == selected

		draw_circle(pos, SLOT_RADIUS + 3.0, Color(0, 0, 0, 0.55))
		draw_circle(pos, SLOT_RADIUS,
			Color(0.86, 0.33, 0.26) if is_selected else Color(0.18, 0.20, 0.24))
		draw_arc(pos, SLOT_RADIUS, 0.0, TAU, 24,
			Color(1, 1, 1, 0.8) if is_selected else Color(1, 1, 1, 0.4), 1.0)

		# 槽位里画武器图标
		var icon: Texture2D = _player.weapons[i].icon
		if icon != null:
			var icon_size := icon.get_size()
			draw_texture_rect(icon, Rect2(pos - icon_size * 0.5, icon_size), false)

		# 名字放在圆下方，避免挤在圆里
		var label: String = _player.weapons[i].short_name
		var label_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, SLOT_LABEL_SIZE)
		draw_string(font, pos + Vector2(-label_size.x * 0.5, SLOT_RADIUS + 11.0), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, SLOT_LABEL_SIZE,
			Color(1, 1, 1, 0.95) if is_selected else Color(0.85, 0.87, 0.92, 0.75))

	# 底部提示
	var hint := "HOLD TAB - RELEASE TO EQUIP"
	var hint_size := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, HINT_SIZE)
	draw_string(font, Vector2(center.x - hint_size.x * 0.5, screen.y - 18.0), hint,
		HORIZONTAL_ALIGNMENT_LEFT, -1, HINT_SIZE, Color(0.85, 0.9, 1.0, 0.85))
