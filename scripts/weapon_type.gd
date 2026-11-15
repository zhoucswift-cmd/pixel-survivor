class_name WeaponType
extends Resource
## 武器类型数据：一个 .tres 就是一把枪，玩家读取它决定射击参数。
## 目前只有「霰弹枪」，之后加手枪/步枪就再建一个 .tres。

@export var display_name: String = "武器"
## 轮盘上显示的短名（默认字体没有中文，用英文）
@export var short_name: String = "WEAPON"
## 武器图标（轮盘槽位里显示）
@export var icon: Texture2D

## 单发伤害
@export var damage := 80.0

## 射速：每秒开火次数，射击冷却 = 1 / fire_rate
@export_range(0.1, 10.0, 0.05) var fire_rate := 0.8

## 弹匣容量
@export var magazine := 7

## 射程：按 tile 算（1 格 = 16px）
@export_range(1, 20, 1) var range_tiles := 3

## 换弹时间（秒）
@export var reload_time := 3.0

## 是否按住左键连续开火（步枪 true，霰弹枪 false）
@export var automatic := false

## 命中方式：true = 扇形内所有敌人；false = 只打最近的一个
@export var multi_hit := true

## 命中扇形的张角（度）：霰弹 90，步枪 20
@export_range(5.0, 180.0, 1.0) var cone_degrees := 90.0

## 是否画一条弹道（步枪用）
@export var tracer := false

## 拿在手里的枪贴图（会跟着鼠标转）；留空则不显示
@export var held_texture: Texture2D

## 贴图里的握把点（像素坐标），旋转以它为轴
@export var held_pivot := Vector2(16, 20)

## 枪口到握把的距离（像素），枪口火焰用
@export var muzzle_distance := 13.0

## 是否显示扇形射程提示（霰弹枪 true）
@export var show_cone := true

## 是否显示瞄准辅助线（步枪 true：白线，能打中变红）
@export var aim_line := false

## 用这把枪时是否显示准心（霰弹枪靠扇形指示，就不显示鼠标了）
@export var show_crosshair := true
