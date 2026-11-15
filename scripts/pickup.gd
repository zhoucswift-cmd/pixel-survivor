extends Area2D
## 地上的掉落物：玩家走过去自动捡起，加到 GameState 的背包里。

const TEXTURES := {
	"cloth": "res://assets/base/cloth.png",
	"rope": "res://assets/base/rope.png",
}

@export var item := "cloth"

var _t := 0.0
@onready var _sprite: Sprite2D = $Sprite


func _ready() -> void:
	if TEXTURES.has(item):
		_sprite.texture = load(TEXTURES[item])
	_t = randf() * TAU
	body_entered.connect(_on_body_entered)


## 上下轻浮，看着像掉在地上
func _process(delta: float) -> void:
	_t += delta
	_sprite.position.y = sin(_t * 3.5) * 1.2


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.add_item(item, 1)
	queue_free()
