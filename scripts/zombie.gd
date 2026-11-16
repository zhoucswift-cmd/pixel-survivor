extends CharacterBody2D
## 32x32 四方向僵尸。数值来自 ZombieType 资源（普通僵尸：移速 0.6、攻速 0.8、
## 攻击距离 0 格 = 同一 tile、伤害 12）。
##
## 精灵表：32 帧 32x32，每方向 8 帧（idle 1 / walk 4 / attack 3）
##   down: 0-7   up: 8-15   left: 16-23   right: 24-31

## 死亡时发出，刷怪器用来排下一只
signal died

const SHEET_PATH := "res://assets/zombie_sheet.png"
const FRAME_SIZE := Vector2i(32, 32)
const BASE_SPEED := 95.0
const TILE := 16.0
const WALK_FPS := 7.0
const ATTACK_FPS := 9.0
const DIRS := {"down": 0, "up": 8, "left": 16, "right": 24}
## 没指定类型时用普通僵尸
const DEFAULT_TYPE: ZombieType = preload("res://assets/zombie_types/normal_zombie.tres")

@export var type: ZombieType
@export var detect_range := 280.0

var health := 50.0
var max_health := 50.0
## 派生数值
var move_speed := 57.0
var attack_interval := 1.25
var damage := 12.0
var attack_range_tiles := 0

var _facing := "down"
var _attacking := false
var _attack_hit_done := false
var _cooldown := 0.0
var _dying := false
var _player: Node2D = null

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("zombies")

	var data: ZombieType = type if type != null else DEFAULT_TYPE
	move_speed = BASE_SPEED * data.move_speed
	attack_interval = 1.0 / maxf(data.attack_speed, 0.05)
	damage = data.damage
	attack_range_tiles = data.attack_range_tiles
	max_health = data.max_health
	health = max_health

	_sprite.sprite_frames = _build_sprite_frames()
	_sprite.play("idle_down")
	_sprite.animation_finished.connect(_on_animation_finished)

	_player = get_tree().get_first_node_in_group("player")


func _physics_process(delta: float) -> void:
	if _dying:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_cooldown = maxf(_cooldown - delta, 0.0)

	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return

	var to_player := _player.global_position - global_position
	var distance := to_player.length()

	if _attacking:
		# 抓击动画第 2 帧判定命中（再确认一次仍在攻击距离内）
		if not _attack_hit_done and _sprite.frame >= 1:
			_attack_hit_done = true
			if _in_attack_range(_player.global_position) and _player.has_method("take_damage"):
				_player.take_damage(damage)
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _in_attack_range(_player.global_position):
		# 站进同一格就停下：冷却好了抓一下，没好就站着等
		velocity = Vector2.ZERO
		if _cooldown <= 0.0:
			_start_attack()
		else:
			_face(to_player)
			_play("idle_" + _facing)
		move_and_slide()
		return

	if distance <= detect_range:
		_face(to_player)
		velocity = to_player.normalized() * move_speed
		_play("walk_" + _facing)
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		_play("idle_" + _facing)
		move_and_slide()


## 站在哪一格（16px 一格）
func _tile_of(world_position: Vector2) -> Vector2i:
	return Vector2i(floori(world_position.x / TILE), floori(world_position.y / TILE))


## 攻击距离按格算：0 格 = 必须同一格，1 格 = 相邻一圈
func _in_attack_range(target: Vector2) -> bool:
	var a := _tile_of(global_position)
	var b := _tile_of(target)
	return maxi(absi(a.x - b.x), absi(a.y - b.y)) <= attack_range_tiles


func _face(direction: Vector2) -> void:
	if absf(direction.x) > absf(direction.y):
		_facing = "right" if direction.x > 0.0 else "left"
	else:
		_facing = "down" if direction.y > 0.0 else "up"


func _play(anim: String) -> void:
	if _sprite.animation != anim:
		_sprite.play(anim)


func _start_attack() -> void:
	if _player != null:
		_face(_player.global_position - global_position)
	_attacking = true
	_attack_hit_done = false
	_cooldown = attack_interval
	_sprite.play("attack_" + _facing)


func _on_animation_finished() -> void:
	if _sprite.animation.begins_with("attack_"):
		_attacking = false
		_play("idle_" + _facing)


## —— 受击 / 死亡 ——

func take_damage(amount: float) -> void:
	if _dying:
		return
	health = maxf(health - amount, 0.0)

	# 受击闪白 + 轻微击退
	_sprite.modulate = Color(1.6, 1.6, 1.6)
	var tween := create_tween()
	tween.tween_property(_sprite, "modulate", Color.WHITE, 0.12)

	if health <= 0.0:
		_die()


func _die() -> void:
	_dying = true
	_attacking = false
	velocity = Vector2.ZERO
	remove_from_group("zombies")
	died.emit()
	$CollisionShape2D.set_deferred("disabled", true)

	# 爆血特效挂在父节点上（本节点马上要销毁），位置对齐
	var gore: Node2D = load("res://scenes/zombie_death.tscn").instantiate()
	gore.position = position
	get_parent().add_child(gore)

	# 掉落：普通僵尸 25% 布料、10% 绳子（各自独立判定）
	if randf() < 0.25:
		_spawn_drop("cloth")
	if randf() < 0.10:
		_spawn_drop("rope")
	if randf() < 0.20:
		_spawn_drop("wood")

	queue_free()


## 在地上扔一个掉落物
func _spawn_drop(item: String) -> void:
	var pickup: Node2D = load("res://scenes/pickup.tscn").instantiate()
	pickup.item = item
	pickup.position = position + Vector2(randf_range(-8.0, 8.0), randf_range(-4.0, 8.0))
	get_parent().add_child(pickup)


func _build_sprite_frames() -> SpriteFrames:
	var texture: Texture2D = load(SHEET_PATH)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")

	for dir_name: String in DIRS:
		var base: int = DIRS[dir_name]
		_add_animation(frames, texture, "idle_" + dir_name, [base], 1.0, true)
		_add_animation(frames, texture, "walk_" + dir_name, [base + 1, base + 2, base + 3, base + 4], WALK_FPS, true)
		_add_animation(frames, texture, "attack_" + dir_name, [base + 5, base + 6, base + 7], ATTACK_FPS, false)

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
