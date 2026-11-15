extends Node2D
## 僵尸死亡特效：5 帧爆血动画 + 血块粒子，播完在脚下留一滩血。

const SHEET_PATH := "res://assets/zombie_death.png"
const FRAME_SIZE := Vector2i(48, 48)
const FRAME_COUNT := 5
const FPS := 12.0

var _sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("gore")

	_sprite = AnimatedSprite2D.new()
	_sprite.name = "Sprite"
	_sprite.sprite_frames = _build_frames()
	add_child(_sprite)
	_sprite.play("burst")
	_sprite.animation_finished.connect(_on_finished)

	_spawn_chunks()


func _build_frames() -> SpriteFrames:
	var texture: Texture2D = load(SHEET_PATH)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("burst")
	frames.set_animation_speed("burst", FPS)
	frames.set_animation_loop("burst", false)
	for i in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame("burst", atlas)
	return frames


## 血块粒子：往四周炸开，受重力落地
func _spawn_chunks() -> void:
	var chunk := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	chunk.fill(Color(0.62, 0.13, 0.12))

	var particles := CPUParticles2D.new()
	particles.one_shot = true
	particles.amount = 16
	particles.lifetime = 0.7
	particles.explosiveness = 1.0
	particles.local_coords = false
	particles.texture = ImageTexture.create_from_image(chunk)
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 55.0
	particles.initial_velocity_max = 130.0
	particles.gravity = Vector2(0, 340)
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.z_index = 2
	add_child(particles)
	particles.emitting = true


## 动画播完：把最后一帧（血泊）留成地面血迹
func _on_finished() -> void:
	var stain := Sprite2D.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = load(SHEET_PATH)
	atlas.region = Rect2((FRAME_COUNT - 1) * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
	stain.texture = atlas
	stain.position = position
	stain.z_index = 0
	get_parent().add_child(stain)

	queue_free()
