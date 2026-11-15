extends Node2D
## 枪口特效：3 帧爆闪序列（24x24）+ 一盏短暂的暖色 2D 光，播完自毁。

const SHEET_PATH := "res://assets/muzzle_flash.png"
const FRAME_SIZE := Vector2i(24, 24)
const FPS := 18.0


func _ready() -> void:
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = _build_frames()
	sprite.z_index = 0
	add_child(sprite)
	_add_glow()
	sprite.play("flash")
	sprite.animation_finished.connect(queue_free)


func _build_frames() -> SpriteFrames:
	var texture: Texture2D = load(SHEET_PATH)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("flash")
	frames.set_animation_speed("flash", FPS)
	frames.set_animation_loop("flash", false)
	for i in 3:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * FRAME_SIZE.x, 0, FRAME_SIZE.x, FRAME_SIZE.y)
		frames.add_frame("flash", atlas)
	return frames


func _add_glow() -> void:
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))

	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = 64
	texture.height = 64

	var light := PointLight2D.new()
	light.texture = texture
	light.color = Color(1.0, 0.78, 0.45)
	light.energy = 1.6
	light.texture_scale = 0.45
	light.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(light)

	# 光随爆闪一起衰减
	var tween := create_tween()
	tween.tween_property(light, "energy", 0.0, 0.18)
