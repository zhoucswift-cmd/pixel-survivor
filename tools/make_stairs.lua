-- make_stairs.lua
-- 楼顶通往下层的楼梯：3x5 格 = 48x80 像素
-- 运行: Aseprite.exe -b --script tools/make_stairs.lua

local OUT = "C:/game/test/assets/base/stairs.aseprite"
local W, H = 48, 80

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local LIGHT   = rgb(168, 170, 176)
local MID     = rgb(140, 142, 150)
local DARK    = rgb(112, 114, 120)
local SHADE   = rgb(88, 90, 96)
local OUTLINE = rgb(62, 64, 70)
local METAL   = rgb(120, 124, 132)
local METAL_D = rgb(78, 82, 90)
local METAL_L = rgb(186, 192, 202)
local HOLE    = rgb(28, 28, 34)
local HOLE2   = rgb(44, 46, 54)
local HOLE3   = rgb(62, 66, 78)

local img = Image(W, H, ColorMode.RGB)
img:clear(0)

local function put(x, y, c)
	if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end

local function fill(x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(x, y, c) end end
end

-- 外圈：水泥井口（和楼顶女儿墙一个色系）
fill(0, 0, W - 1, H - 1, OUTLINE)
fill(1, 1, W - 2, H - 2, DARK)
fill(1, 1, W - 2, 1, MID)
fill(1, 1, 1, H - 2, MID)
fill(1, H - 2, W - 2, H - 2, SHADE)
fill(W - 2, 1, W - 2, H - 2, SHADE)

-- 井口内壁（往下看的一圈阴影）
fill(3, 3, W - 4, H - 4, SHADE)

-- 楼梯：从上往下 8 级，越往下越暗（往下走）
local steps = 9
local top = 5
local bottom = 62          -- 楼梯到这里结束，下面是更深的黑
local step_h = math.floor((bottom - top) / steps)
for i = 0, steps - 1 do
	local y0 = top + i * step_h
	local y1 = y0 + step_h - 1
	-- 越往下越暗，并且左右各收进一点，做出“往深处走”的透视
	local t = i / (steps - 1)
	local inset = 0          -- 不做收边，保持干净的直边
	local x0 = 4 + inset
	local x1 = W - 5 - inset
	local tread = rgb(
		math.floor(152 - 70 * t),
		math.floor(154 - 70 * t),
		math.floor(162 - 66 * t))
	local riser = rgb(
		math.floor(110 - 46 * t),
		math.floor(112 - 46 * t),
		math.floor(120 - 44 * t))
	-- 踏面
	fill(x0, y0, x1, y1 - 3, tread)
	-- 踏面前缘高光
	fill(x0, y0, x1, y0, rgb(
		math.min(255, math.floor(190 - 60 * t)),
		math.min(255, math.floor(194 - 60 * t)),
		math.min(255, math.floor(204 - 56 * t))))
	-- 右侧压暗，像有侧墙挡光
	fill(x1 - 3, y0, x1, y1 - 3, riser)
	-- 踢面（阴影带）
	fill(x0, y1 - 2, x1, y1, riser)
end

-- 楼梯下面的深洞（通往下层）
fill(4, bottom, W - 5, H - 5, HOLE3)
fill(5, bottom + 2, W - 6, bottom + 6, HOLE2)
fill(7, bottom + 5, W - 8, H - 7, HOLE)
fill(9, bottom + 8, W - 10, H - 9, rgb(18, 18, 22))
-- 洞里一点点反光
fill(6, bottom + 2, 8, bottom + 7, rgb(56, 62, 78))
fill(W - 9, bottom + 3, W - 7, bottom + 6, rgb(50, 56, 70))

-- 两侧扶手（金属栏杆）
local rail = 4
for y = 4, bottom - 2 do
	-- 左
	put(rail - 1, y, METAL_D)
	put(rail, y, METAL)
	-- 右
	put(W - rail, y, METAL)
	put(W - rail + 1, y, METAL_D)
end
-- 栏杆立柱 / 顶帽
fill(2, 3, W - 3, 4, METAL_D)
fill(2, 3, W - 3, 3, METAL)
put(2, 3, METAL_L)
put(W - 3, 3, METAL_L)
fill(2, bottom - 1, W - 3, bottom, METAL_D)
fill(2, bottom - 1, W - 3, bottom - 1, METAL)

-- 顶部地面接缝（和楼顶融为一体）
fill(2, 2, W - 3, 2, MID)
put(2, 2, LIGHT)
put(W - 3, 2, LIGHT)

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "stairs"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs(OUT)
print(string.format("saved %s  %dx%d", OUT, W, H))
