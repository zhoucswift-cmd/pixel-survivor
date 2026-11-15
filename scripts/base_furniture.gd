class_name BaseFurniture
extends Resource
## 基地里可建造的家具 / 设备的数据（放在 assets/base/*.tres）。

@export var display_name := "家具"
## HUD 上显示的英文短名（默认字体没有中文）
@export var short_name := "FURNITURE"
@export var texture: Texture2D
## 这个工作台能做什么类别的配方（tools / clothing / carpentry）；空 = 不是工作台
@export var craft_category := ""
## 有人的时候换用的贴图（比如床躺了人），横向多帧就是呼吸动画；留空表示不能躺
@export var occupied_texture: Texture2D = null
## 有人贴图有几帧
@export var occupied_frames := 2
## 占几格（宽 x 高），比如床是 2x3
@export var footprint := Vector2i(1, 1)
## 最高等级（升级只影响外观和等级标记，数值系统以后再加）
@export var max_level := 3
## 每级做什么（可选说明，给以后接数值用）
@export var level_notes: PackedStringArray = PackedStringArray()
