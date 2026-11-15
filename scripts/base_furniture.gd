class_name BaseFurniture
extends Resource
## 基地里可建造的家具 / 设备的数据（放在 assets/base/*.tres）。

@export var display_name := "家具"
## HUD 上显示的英文短名（默认字体没有中文）
@export var short_name := "FURNITURE"
@export var texture: Texture2D
## 最高等级（升级只影响外观和等级标记，数值系统以后再加）
@export var max_level := 3
## 每级做什么（可选说明，给以后接数值用）
@export var level_notes: PackedStringArray = PackedStringArray()
