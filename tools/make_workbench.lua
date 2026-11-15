-- make_workbench.lua
-- 基地工作台：32x16（2 格宽 × 1 格高）
-- 运行: Aseprite.exe -b --script tools/make_workbench.lua

local OUT = "C:/game/test/assets/base/workbench.aseprite"
local W, H = 32, 16

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE = rgb(40, 28, 24)
local WOOD    = rgb(146, 96, 56)
local WOOD_L  = rgb(184, 128, 76)
local WOOD_D  = rgb(102, 64, 38)
local METAL   = rgb(150, 156, 168)
local METAL_D = rgb(96, 102, 114)
local METAL_L = rgb(206, 212, 222)
local STEEL   = rgb(120, 126, 140)

local img = Image(W, H, ColorMode.RGB)
img:clear(0)

local function put(x, y, c)
	if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end
local function get(x, y)
	if x < 0 or y < 0 or x >= W or y >= H then return nil end
	return img:getPixel(x, y)
end
local function fill(x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(x, y, c) end end
end

-- 桌面
fill(1, 4, 30, 8, WOOD)
fill(1, 4, 30, 4, WOOD_L)     -- 台面高光
fill(1, 8, 30, 8, WOOD_D)     -- 台面下方阴影
fill(1, 5, 30, 7, WOOD)
-- 木纹
put(6, 6, WOOD_D)
put(7, 6, WOOD_D)
put(19, 5, WOOD_D)
put(24, 7, WOOD_D)

-- 桌腿
fill(2, 9, 4, 14, WOOD)
fill(27, 9, 29, 14, WOOD)
fill(2, 9, 2, 14, WOOD_L)
fill(27, 9, 27, 14, WOOD_L)
fill(2, 14, 4, 14, WOOD_D)
fill(27, 14, 29, 14, WOOD_D)

-- 中间的横撑
fill(4, 12, 27, 12, WOOD_D)
fill(4, 11, 27, 11, WOOD)

-- 台面上的台虎钳（左边）
fill(4, 1, 8, 3, METAL)
fill(4, 1, 8, 1, METAL_L)
fill(4, 3, 8, 3, METAL_D)
put(9, 2, METAL_D)
put(3, 2, METAL_D)

-- 台面上的锤子（右边）
fill(20, 0, 24, 2, METAL_D)
fill(20, 0, 23, 1, METAL)
fill(25, 1, 28, 2, WOOD_D)
put(25, 1, WOOD)
put(28, 2, WOOD)

-- 台面上的零件盒
fill(12, 1, 17, 3, WOOD_D)
fill(12, 1, 17, 1, WOOD_L)
put(13, 2, METAL_L)
put(15, 2, METAL_L)

-- 桌腿上的螺栓
put(2, 10, METAL_L)
put(29, 10, METAL_L)

-- 自动描边
local outline = {}
for y = 0, H - 1 do
	for x = 0, W - 1 do
		if get(x, y) == 0 then
			local near = (get(x - 1, y) or 0) ~= 0 or (get(x + 1, y) or 0) ~= 0
				or (get(x, y - 1) or 0) ~= 0 or (get(x, y + 1) or 0) ~= 0
			if near then table.insert(outline, { x, y }) end
		end
	end
end
for _, p in ipairs(outline) do put(p[1], p[2], OUTLINE) end

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "workbench"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs(OUT)
print(string.format("saved %s  %dx%d", OUT, W, H))
