extends Node2D
## 消防栓：被子弹打中会喷水花，喷完地上留下 3x3 的水洼（涟漪动画）。

const SPRAY_TIME := 0.55          # 喷水持续多久
const SPRAY_FRAME := 0.12         # 水花每帧
const PUDDLE_DELAY := 0.35        # 喷完多久出现水洼
const PUDDLE_FRAME := 0.22        # 水洼每帧

@onready var _spray: Sprite2D = $Spray
@onready var _puddle: Sprite2D = $Puddle

var _spray_left := 0.0
var _spray_t := 0.0
var _puddle_delay := 0.0
var _puddle_t := 0.0


func _ready() -> void:
	add_to_group("hydrants")
	_spray.visible = false
	_puddle.visible = false


## 被打中
func hit() -> void:
	_spray_left = SPRAY_TIME
	_spray_t = 0.0
	_spray.visible = true
	_spray.frame = 0
	_puddle_delay = PUDDLE_DELAY


func _process(delta: float) -> void:
	if _spray_left > 0.0:
		_spray_left -= delta
		_spray_t += delta
		_spray.frame = int(_spray_t / SPRAY_FRAME) % maxi(1, _spray.hframes)
		if _spray_left <= 0.0:
			_spray.visible = false

	if _puddle_delay > 0.0:
		_puddle_delay -= delta
		if _puddle_delay <= 0.0:
			_puddle.visible = true
			_puddle_t = 0.0

	if _puddle.visible:
		_puddle_t += delta
		_puddle.frame = int(_puddle_t / PUDDLE_FRAME) % maxi(1, _puddle.hframes)
