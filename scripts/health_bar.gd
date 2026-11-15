extends Control
## 血条：画外框，再按当前血量比例裁剪填充条（整数像素裁剪，不做拉伸，保持像素锐利）。
## 外框图 72x12（左侧 11x10 心形图标 + 56x12 血条框），填充图 156x8 = 3 帧 52x8
## （绿 / 黄 / 红），按血量百分比选帧：
##   > 50% 绿、20%~50% 黄、< 20% 红。

const FRAME_PATH := "res://assets/ui/health_frame.png"
const FILL_PATH := "res://assets/ui/health_fill.png"
const FILL_OFFSET := Vector2(18, 2)
const FILL_SIZE := Vector2i(52, 8)

## 颜色阈值
const GREEN_ABOVE := 0.5
const YELLOW_ABOVE := 0.2

var health := 100.0
var max_health := 100.0

var _frame: Texture2D
var _fills: Texture2D


func _ready() -> void:
	_frame = load(FRAME_PATH)
	_fills = load(FILL_PATH)
	queue_redraw()


func set_health(current: float, maximum: float) -> void:
	health = current
	max_health = maxf(maximum, 1.0)
	queue_redraw()


## 当前应该是哪一帧：0 = 绿，1 = 黄，2 = 红
func fill_index(ratio: float) -> int:
	if ratio > GREEN_ABOVE:
		return 0
	if ratio >= YELLOW_ABOVE:
		return 1
	return 2


func color_name(ratio: float) -> String:
	return ["green", "yellow", "red"][fill_index(clampf(ratio, 0.0, 1.0))]


func _draw() -> void:
	if _frame == null or _fills == null:
		return

	draw_texture(_frame, Vector2.ZERO)

	var ratio := clampf(health / max_health, 0.0, 1.0)
	var width := int(round(FILL_SIZE.x * ratio))
	if width <= 0:
		return

	# 从对应颜色的那一帧左侧裁一段，宽度随血量变化
	draw_texture_rect_region(
		_fills,
		Rect2(FILL_OFFSET, Vector2(width, FILL_SIZE.y)),
		Rect2(fill_index(ratio) * FILL_SIZE.x, 0, width, FILL_SIZE.y)
	)
