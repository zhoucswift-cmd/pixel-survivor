extends CharacterBody2D
## 32x32 四方向持枪像素角色：WASD / 方向键移动，鼠标左键朝鼠标方向开枪。
## 速度按比例算：speed_scale = 1.0 是基准速度（BASE_SPEED = 95 px/s）。
## 枪械数值来自 WeaponType 资源（霰弹枪：伤害 80、射速 0.8、弹匣 7、射程 3 格、换弹 3 秒）。
##
## 精灵表布局（横向 28 帧，每帧 32x32），每方向 7 帧：
##   idle 1 / walk 4 / shoot 2
##   down: 0-6   up: 7-13   left: 14-20   right: 21-27

signal shot_fired
## 血量变化时发出（当前值 / 最大值），HUD 用
signal health_changed(current: float, maximum: float)
## 弹量 / 换弹状态变化时发出
signal ammo_changed(current: int, maximum: int)
## 血量归零时发出一次
signal died

## 不带枪（横着瞄时用，枪单独旋转）
const SHEET_PATH := "res://assets/character_sheet.png"
## 带枪（上下瞄时用原始姿势，枪已经画在身体上）
const SHEET_BAKED_PATH := "res://assets/character_sheet_gun.png"
const FRAME_SIZE := Vector2i(32, 32)
const WALK_FPS := 10.0
const SHOOT_FPS := 12.0
const DIRS := {"down": 0, "up": 7, "left": 14, "right": 21}
## 持枪手相对角色原点的位置（枪以这个点为轴旋转）
const HAND_OFFSET := Vector2(0, 6)
## 原画姿势（上下瞄准）里，枪口相对角色原点的位置
const BAKED_MUZZLE := {
	"down": Vector2(1, 10),
	"up": Vector2(7, -8),
	"left": Vector2(-13, 2),
	"right": Vector2(13, 2),
}
## 四方向到单位向量的映射（动画朝向用）
const AIM_VECTORS := {
	"right": Vector2.RIGHT,
	"left": Vector2.LEFT,
	"up": Vector2.UP,
	"down": Vector2.DOWN,
}

## 基准移动速度（px/s）：玩家 1.0 倍、僵尸 0.6 倍都按这个算
const BASE_SPEED := 95.0
const TILE := 16.0
## 没指定武器时用霰弹枪
const DEFAULT_WEAPON: WeaponType = preload("res://assets/weapons/shotgun.tres")

@export var speed_scale: float = 1.0
@export var weapon: WeaponType
## 拥有的武器（武器轮盘显示这些）；留空就只用场景里配的那把
@export var weapons: Array[WeaponType] = []
## 角色可活动范围（脚底中心坐标），防止走出房间
@export var bounds: Rect2 = Rect2(20, 24, 280, 272)
## 是否装备武器（基地里设成 false：不能开枪、不跟鼠标瞄准，只播走路动画）
@export var armed := true
@export var max_health: float = 100.0
## 复活后的无敌时间（秒）
@export var respawn_invulnerable := 1.5

var speed: float = BASE_SPEED
var health: float = 100.0
## 当前弹量
var ammo: int = 7
## 截图/调试用：设成有效向量后瞄准方向固定（不跟鼠标）
var forced_aim := Vector2.ZERO

var _data: WeaponType
var _facing: String = "down"
var _shooting := false
var _dead := false
var _cooldown := 0.0
var _invulnerable := 0.0
var _frames_plain: SpriteFrames
var _frames_baked: SpriteFrames
var _using_baked := false
var _reloading := false
var _reload_left := 0.0
var _muzzle_scene: PackedScene = preload("res://scenes/muzzle_flash.tscn")
var _shell_texture: Texture2D

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _gun: Sprite2D = $Gun


func _ready() -> void:
	add_to_group("player")
	speed = BASE_SPEED * speed_scale
	health = max_health
	died.connect(_on_died)

	if weapons.is_empty():
		# 注意：weapons 是 Array[WeaponType]，得用 append 保持类型
		weapons.append(weapon if weapon != null else DEFAULT_WEAPON)
		var rifle: WeaponType = preload("res://assets/weapons/rifle.tres")
		if not weapons.has(rifle):
			weapons.append(rifle)
	equip(0)

	_frames_plain = _build_sprite_frames(SHEET_PATH)
	_frames_baked = _build_sprite_frames(SHEET_BAKED_PATH)
	_sprite.sprite_frames = _frames_plain
	_sprite.play("idle_down")
	_sprite.animation_finished.connect(_on_animation_finished)

	var shell := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	shell.fill(Color(0.86, 0.67, 0.28))
	_shell_texture = ImageTexture.create_from_image(shell)

	_gun.centered = false
	_gun.position = HAND_OFFSET
	_update_gun()

	health_changed.emit(health, max_health)
	ammo_changed.emit(ammo, _data.magazine)


func _physics_process(delta: float) -> void:
	if _dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_cooldown = maxf(_cooldown - delta, 0.0)
	_invulnerable = maxf(_invulnerable - delta, 0.0)
	_tick_reload(delta)

	if armed:
		var want_shoot := (Input.is_action_pressed("shoot") if _data.automatic
			else Input.is_action_just_pressed("shoot"))
		if want_shoot:
			_try_shoot()
		if Input.is_action_just_pressed("reload"):
			start_reload()

	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input * speed
	move_and_slide()

	position.x = clampf(position.x, bounds.position.x, bounds.end.x)
	position.y = clampf(position.y, bounds.position.y, bounds.end.y)

	_update_animation(input)
	_update_gun()


func _update_animation(input: Vector2) -> void:
	if _shooting:
		return

	var moving := input.length() > 0.01
	if armed:
		# 有武器：朝向永远跟着鼠标（像双摇杆射击）
		_facing = _dir_to_facing(shot_direction())
	elif moving:
		# 基地里没武器：朝向跟着移动方向，就是普通走路
		_facing = _dir_to_facing(input)

	var anim_name := ("walk_" if moving else "idle_") + _facing
	if _sprite.animation != anim_name:
		_sprite.play(anim_name)


## —— 射击 ——

func _try_shoot(forced_facing: String = "") -> void:
	if _dead or _reloading:
		return
	if _cooldown > 0.0 and forced_facing.is_empty():
		return
	if ammo <= 0:
		start_reload()
		return

	# 朝向用鼠标的连续方向；精灵只有 4 方向，所以动画取最近的那个
	var aim_dir: Vector2
	if forced_facing.is_empty():
		aim_dir = shot_direction()
		_facing = _dir_to_facing(aim_dir)
	else:
		_facing = forced_facing
		aim_dir = AIM_VECTORS.get(forced_facing, Vector2.DOWN)

	_shooting = true
	_cooldown = 1.0 / maxf(_data.fire_rate, 0.05)

	ammo -= 1
	ammo_changed.emit(ammo, _data.magazine)

	_sprite.play("shoot_" + _facing)
	_spawn_muzzle_flash(aim_dir)
	_spawn_shells()
	shot_fired.emit()
	var end_point := _apply_shot_hits(aim_dir)
	if _data.tracer:
		_spawn_tracer(muzzle_position(aim_dir), end_point)

	if ammo <= 0:
		start_reload()


## 命中判定：多目标武器打扇形内所有僵尸，单目标武器只打最近的一个。
## 返回弹道终点（画曳光用）。
func _apply_shot_hits(aim_dir: Vector2) -> Vector2:
	var best: Node2D = null
	var best_dist := INF
	var farthest := -1.0

	for zombie in get_tree().get_nodes_in_group("zombies"):
		if not _in_cone(zombie.global_position, aim_dir):
			continue
		var dist: float = (zombie.global_position - global_position).length()
		if _data.multi_hit:
			zombie.take_damage(_data.damage)
			if dist > farthest:
				farthest = dist
				best = zombie
		elif dist < best_dist:
			best_dist = dist
			best = zombie

	if not _data.multi_hit and best != null:
		best.take_damage(_data.damage)

	if best != null:
		return best.global_position
	return global_position + aim_dir * shot_range_px()


## 当前朝向的单位向量（四方向，动画用）
func aim_vector() -> Vector2:
	return AIM_VECTORS.get(_facing, Vector2.DOWN)


## 朝鼠标的连续方向（实时角度）；鼠标贴脸时退回当前朝向
func shot_direction() -> Vector2:
	if forced_aim != Vector2.ZERO:
		return forced_aim.normalized()
	# 从持枪手往鼠标算方向：枪口、瞄准线、弹道都从这点出发，准心正好落在线上
	var to_mouse := get_global_mouse_position() - muzzle_origin()
	if to_mouse.length() < 8.0:
		return aim_vector()
	return to_mouse.normalized()


## 持枪手的世界坐标（瞄准射线与旋转的起点）
func muzzle_origin() -> Vector2:
	return global_position + HAND_OFFSET


## 扇形指示用的角度（弧度），跟着鼠标实时转
func aim_angle() -> float:
	return shot_direction().angle()


## 射程（像素）：range_tiles * 16
func shot_range_px() -> float:
	return float(_data.range_tiles) * TILE


## 换枪时套用武器的手持贴图与握把点
func _apply_held_texture() -> void:
	_gun.texture = _data.held_texture
	_gun.visible = _gun.texture != null
	_gun.offset = -_data.held_pivot


## 切换身体用哪套帧（带枪 / 不带枪）
func _set_body_baked(baked: bool) -> void:
	if baked == _using_baked:
		return
	_using_baked = baked
	_sprite.sprite_frames = _frames_baked if baked else _frames_plain
	if _sprite.animation != "":
		_sprite.play(_sprite.animation)


## 开关武器：基地里关掉（不能开枪、不显示旋转枪、只播走路动画）
func set_armed(value: bool) -> void:
	armed = value
	if _gun != null:
		_gun.visible = armed and _gun.texture != null
	if not armed:
		# 用原画身体帧（枪和手都画在里面），旋转枪就不需要了
		_set_body_baked(true)


## 持枪那只手固定，枪身绕它转到鼠标方向。
## 朝左半边时水平镜像（flip_h）+ 角度减 180°，这样枪不会倒过来、手也还在枪下方。
func _update_gun() -> void:
	if _data == null:
		return
	var aim := shot_direction()
	var mirror := aim.x < 0.0
	_gun.flip_h = mirror
	_gun.flip_v = false
	_gun.rotation = aim.angle() - (PI if mirror else 0.0)

	# 镜像后握把在贴图里的 x 会翻到另一边，偏移要跟着换，枪才不会跳位
	var pivot: Vector2 = _data.held_pivot
	if mirror and _gun.texture != null:
		pivot.x = _gun.texture.get_width() - pivot.x
	_gun.offset = -pivot

	# 旋转枪永远画在身体前面，保证整把枪都看得见
	_gun.position = HAND_OFFSET
	_gun.z_index = 2

	# 上下瞄时换成“枪已经画在身体上”的那套帧，避免旋转的枪压在背上/肚子上
	var vertical := absf(aim.y) > absf(aim.x)
	_set_body_baked(vertical)

	# 竖向时隐藏旋转枪（身体帧里已经有枪和手了），横向才显示
	_gun.visible = not vertical and _gun.texture != null


## 枪口在世界坐标里的位置（火焰、曳光用）
func muzzle_position(aim_dir: Vector2) -> Vector2:
	return global_position + HAND_OFFSET + aim_dir * _data.muzzle_distance


## 是否显示扇形 / 瞄准辅助线（由武器决定）
func show_cone() -> bool:
	return _data.show_cone


func show_aim_line() -> bool:
	return _data.aim_line


## 扇形内最近的僵尸（瞄准线变红用），没有返回 null
func nearest_target_in_cone() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	var dir := shot_direction()
	for zombie in get_tree().get_nodes_in_group("zombies"):
		if not _in_cone(zombie.global_position, dir):
			continue
		var dist: float = (zombie.global_position - global_position).length()
		if dist < best_dist:
			best_dist = dist
			best = zombie
	return best


## 当前武器扇形的一半张角（弧度）
func cone_half_angle() -> float:
	return deg_to_rad(_data.cone_degrees) * 0.5


## 某个点是否在当前射程扇形内（张角 + 半径），实际命中和指示器共用
func is_in_shot_range(point: Vector2) -> bool:
	return _in_cone(point, shot_direction())


func _in_cone(point: Vector2, direction: Vector2) -> bool:
	var to_point := point - global_position
	var distance := to_point.length()
	if distance > shot_range_px():
		return false
	if distance < 0.001:
		return true
	return to_point.normalized().dot(direction) >= cos(cone_half_angle())


## 连续方向 → 最近的 4 方向（决定播放哪套动画）
func _dir_to_facing(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "right" if direction.x > 0.0 else "left"
	return "down" if direction.y > 0.0 else "up"


## —— 换弹 ——

func start_reload() -> void:
	if _dead or _reloading or ammo >= _data.magazine:
		return
	_reloading = true
	_reload_left = _data.reload_time


func is_reloading() -> bool:
	return _reloading


## HUD 用：换弹中显示倒计时，否则显示 当前弹量/弹匣
func ammo_display() -> String:
	if _reloading:
		return "RELOAD %0.1f" % maxf(_reload_left, 0.0)
	return "%d / %d" % [ammo, _data.magazine]


func _tick_reload(delta: float) -> void:
	if not _reloading:
		return
	_reload_left = maxf(_reload_left - delta, 0.0)
	if _reload_left <= 0.0:
		_reloading = false
		ammo = _data.magazine
		ammo_changed.emit(ammo, _data.magazine)


## 按鼠标位置取最近的四方向（动画朝向）；鼠标贴在角色身上时沿用当前朝向
func _aim_direction() -> String:
	var to_mouse := get_global_mouse_position() - global_position
	if to_mouse.length() < 8.0:
		return _facing
	return _dir_to_facing(to_mouse)


## 步枪曳光：一条快速淡出的线
func _spawn_tracer(from_world: Vector2, to_world: Vector2) -> void:
	var line := Line2D.new()
	line.width = 1.0
	line.default_color = Color(1.0, 0.92, 0.65, 0.9)
	line.z_index = 9
	line.add_point(to_local(from_world))
	line.add_point(to_local(to_world))
	add_child(line)

	var tween := create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.08)
	tween.tween_callback(line.queue_free)


func _spawn_muzzle_flash(aim_dir: Vector2) -> void:
	var flash: Node2D = _muzzle_scene.instantiate()
	if _using_baked:
		# 原画姿势：火焰放在那张帧里枪口的位置，画在最上层（枪口在身体轮廓外）
		flash.position = BAKED_MUZZLE.get(_facing, HAND_OFFSET + aim_dir * _data.muzzle_distance)
		flash.z_index = 10
	else:
		# 旋转枪：放在枪口，但要画在枪下面，不然会把枪管盖掉一截
		flash.position = HAND_OFFSET + aim_dir * _data.muzzle_distance
		flash.z_index = 1
	flash.rotation = aim_dir.angle()
	flash.scale = Vector2(0.85, 0.85)
	add_child(flash)


func _spawn_shells() -> void:
	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.amount = 4
	particles.lifetime = 0.7
	particles.explosiveness = 1.0
	particles.local_coords = false
	particles.texture = _shell_texture
	particles.direction = Vector2(0.35, -1.0)
	particles.spread = 32.0
	particles.initial_velocity_min = 45.0
	particles.initial_velocity_max = 80.0
	particles.gravity = Vector2(0, 300)
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 1.4
	particles.color = Color(0.98, 0.82, 0.42)
	particles.position = HAND_OFFSET + Vector2(2, 0)
	particles.z_index = 9
	add_child(particles)
	particles.emitting = true

	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(particles):
		particles.queue_free()


func _on_animation_finished() -> void:
	if _sprite.animation.begins_with("shoot_"):
		_shooting = false
		_update_animation(Input.get_vector("move_left", "move_right", "move_up", "move_down"))


## 换枪：切换后弹药重置为满匣（简单起见）
func equip(index: int) -> void:
	if weapons.is_empty():
		return
	index = clampi(index, 0, weapons.size() - 1)
	weapon = weapons[index]
	_data = weapon
	ammo = _data.magazine
	_reloading = false
	_apply_held_texture()
	ammo_changed.emit(ammo, _data.magazine)


## —— 血量 ——

func take_damage(amount: float) -> void:
	if _dead or _invulnerable > 0.0:
		return
	set_health(health - amount)


func heal(amount: float) -> void:
	set_health(health + amount)


func set_health(value: float) -> void:
	var clamped := clampf(value, 0.0, max_health)
	if is_equal_approx(clamped, health):
		return
	var was_alive := health > 0.0
	health = clamped

	# 回血到正数就当作复活，清掉死亡状态
	if health > 0.0 and _dead:
		_dead = false
		_sprite.modulate = Color.WHITE
	health_changed.emit(health, max_health)
	if was_alive and health <= 0.0:
		died.emit()


func _on_died() -> void:
	_dead = true
	_shooting = false
	_reloading = false
	velocity = Vector2.ZERO
	_sprite.modulate = Color(0.55, 0.55, 0.62)


## 复活：回满血、回满弹、回到指定位置（演示用）
func respawn(at: Vector2) -> void:
	global_position = at
	health = max_health
	_dead = false
	_reloading = false
	ammo = _data.magazine
	_sprite.modulate = Color.WHITE
	_sprite.play("idle_" + _facing)
	_invulnerable = respawn_invulnerable
	_blink()
	health_changed.emit(health, max_health)
	ammo_changed.emit(ammo, _data.magazine)


## 无敌期间闪烁提示
func _blink() -> void:
	var tween := create_tween()
	tween.set_loops(4)
	tween.tween_property(_sprite, "modulate:a", 0.35, 0.12)
	tween.tween_property(_sprite, "modulate:a", 1.0, 0.12)


## 把横向精灵表切成 12 个动画（4 方向 × idle/walk/shoot）
func _build_sprite_frames(path: String) -> SpriteFrames:
	var texture: Texture2D = load(path)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	for dir_name: String in DIRS:
		var base: int = DIRS[dir_name]
		_add_animation(frames, texture, "idle_" + dir_name, [base], 1.0, true)
		_add_animation(frames, texture, "walk_" + dir_name, [base + 1, base + 2, base + 3, base + 4], WALK_FPS, true)
		_add_animation(frames, texture, "shoot_" + dir_name, [base + 5, base + 6], SHOOT_FPS, false)

	return frames


func _add_animation(frames: SpriteFrames, texture: Texture2D, anim: String,
		indices: Array, fps: float, loop: bool) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	for index: int in indices:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(index * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame(anim, atlas)
