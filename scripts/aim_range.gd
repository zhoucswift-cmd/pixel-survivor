extends Node2D
## 瞄准提示（画在角色之下，z_index 0）：
## - 霰弹枪（show_cone）：以玩家为中心、朝鼠标的扇形，扇形里有目标时变红；
## - 步枪（aim_line）：从枪口拉一条瞄准辅助线，白色；扇形里有目标时变红并连到目标身上。
## 判定和命中共用 player 的同一套扇形逻辑，保证“看到红就是打得到”。

const SEGMENTS := 24
const IDLE_LINE := Color(1.0, 1.0, 1.0, 0.22)
const IDLE_FILL := Color(1.0, 1.0, 1.0, 0.06)
const TARGET_LINE := Color(1.0, 0.32, 0.28, 0.9)
const TARGET_FILL := Color(1.0, 0.32, 0.28, 0.09)
const AIM_LINE := Color(1.0, 1.0, 1.0, 0.45)
const AIM_LINE_HIT := Color(1.0, 0.32, 0.28, 0.9)

var _player: Node2D = null


func _process(_delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	queue_redraw()


func _draw() -> void:
	if _player == null:
		return
	if _player.show_cone():
		_draw_cone()
	if _player.show_aim_line():
		_draw_aim_line()


func _draw_cone() -> void:
	var center: Vector2 = _player.global_position
	var radius: float = _player.shot_range_px()
	var base: float = _player.aim_angle()
	var half: float = _player.cone_half_angle()
	var has_target: bool = _player.nearest_target_in_cone() != null

	var points := PackedVector2Array()
	points.append(center)
	for i in SEGMENTS + 1:
		var a := base - half + (2.0 * half) * float(i) / float(SEGMENTS)
		points.append(center + Vector2(cos(a), sin(a)) * radius)
	points.append(center)

	draw_colored_polygon(points, TARGET_FILL if has_target else IDLE_FILL)
	draw_polyline(points, TARGET_LINE if has_target else IDLE_LINE, 1.0)


func _draw_aim_line() -> void:
	var dir: Vector2 = _player.shot_direction()
	# 起点和弹道曳光完全一致（枪口），终点也一样，这样两条线重合
	var from: Vector2 = _player.muzzle_position(dir)
	var target: Node2D = _player.nearest_target_in_cone()

	if target != null:
		draw_line(from, target.global_position, AIM_LINE_HIT, 1.0)
	else:
		draw_line(from, _player.global_position + dir * _player.shot_range_px(), AIM_LINE, 1.0)
