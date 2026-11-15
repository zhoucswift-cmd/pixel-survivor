extends CanvasLayer
## 像素准心：隐藏系统鼠标，用两帧精灵跟随鼠标；开火时短暂变成张开的准心。
## 截图模式下可用 forced_position 固定准心位置。

const SHEET_PATH := "res://assets/crosshair.png"
const FRAME_SIZE := Vector2i(13, 13)
const KICK_TIME := 0.12

## 截图/调试用：设成有限值时准心固定在这个视口坐标
var forced_position := Vector2.INF

var _sprite: AnimatedSprite2D
var _kick_timer := 0.0


func _ready() -> void:
	layer = 10
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Sprite"
	_sprite.sprite_frames = _build_frames()
	_sprite.centered = false  # 用左上角定位，保证像素对齐
	_sprite.frame = 0
	add_child(_sprite)


func _process(delta: float) -> void:
	var mouse := get_viewport().get_mouse_position()
	if forced_position.is_finite():
		mouse = forced_position
	else:
		var player := get_tree().get_first_node_in_group("player")
		if player != null:
			if player.weapon.aim_line:
				# 步枪：准心沿瞄准线滑动
				mouse = _clamp_to_aim_line(player, mouse)
			elif player.weapon.show_cone:
				# 霰弹枪：准心钉在扇形圆弧的正中间
				mouse = _arc_midpoint(player)
	# 13x13 的中心像素是 (6,6)，减掉偏移让准心正对鼠标
	_sprite.position = (mouse - Vector2(6, 6)).round()

	if _kick_timer > 0.0:
		_kick_timer -= delta
		if _kick_timer <= 0.0:
			_sprite.frame = 0


## 霰弹枪：准心放在扇形圆弧的正中间（射程处、正对瞄准方向）
func _arc_midpoint(player: Node2D) -> Vector2:
	var world: Vector2 = player.global_position + player.shot_direction() * player.shot_range_px()
	return get_viewport().get_canvas_transform() * world


## 步枪：把准心压到瞄准线上（沿线滑动，最远到线的末端，不会跑到线外）
func _clamp_to_aim_line(player: Node2D, screen_mouse: Vector2) -> Vector2:
	var origin: Vector2 = player.muzzle_origin()
	var dir: Vector2 = player.shot_direction()
	var end_point: Vector2 = player.global_position + dir * player.shot_range_px()
	var target: Node2D = player.nearest_target_in_cone()
	if target != null:
		end_point = target.global_position

	var seg: Vector2 = end_point - origin
	var seg_len: float = seg.length()
	if seg_len < 0.01:
		return screen_mouse

	var to_world := get_viewport().get_canvas_transform().affine_inverse()
	var mouse_world: Vector2 = to_world * screen_mouse
	var along: float = clampf((mouse_world - origin).dot(seg / seg_len), 0.0, seg_len)
	var point_world: Vector2 = origin + seg / seg_len * along
	return get_viewport().get_canvas_transform() * point_world


## 开火时调用：准心张开一下
func kick() -> void:
	_kick_timer = KICK_TIME
	_sprite.frame = 1


## 当前帧（0 = 常态，1 = 张开），调试/测试用
func current_frame() -> int:
	return _sprite.frame if _sprite != null else -1


## 窗口失焦时把系统光标还回去，回来再隐藏
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _build_frames() -> SpriteFrames:
	var texture: Texture2D = load(SHEET_PATH)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("crosshair")
	frames.set_animation_loop("crosshair", false)
	frames.set_animation_speed("crosshair", 1.0)
	for i in 2:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame("crosshair", atlas)
	return frames
