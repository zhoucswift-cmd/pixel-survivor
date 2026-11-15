-- make_furniture.lua
-- 生成基地家具/设备贴图：64x16（4 个 16x16 单元）
--  0 工作台  1 储物箱  2 发电机  3 盆栽
-- 运行: Aseprite.exe -b --script tools/make_furniture.lua

local OUT = "C:/game/test/assets/base/furniture.aseprite"
local W, H, CELL = 64, 16, 16

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE = rgb(44, 36, 34)
local WOOD    = rgb(150, 100, 58)
local WOOD_L  = rgb(184, 130, 78)
local WOOD_D  = rgb(104, 68, 40)
local METAL   = rgb(120, 126, 136)
local METAL_L = rgb(160, 166, 176)
local METAL_D = rgb(74, 78, 88)
local YELLOW  = rgb(224, 186, 70)
local LEAF    = rgb(88, 158, 78)
local LEAF_D  = rgb(58, 112, 54)
local POT     = rgb(176, 96, 70)

local img = Image(W, H, ColorMode.RGB)
img:clear(0)

local function put(x, y, c)
	if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end

local function fill(x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(x, y, c) end end
end

-- 单元 n 的局部坐标 → 全局坐标
local function cell(n) return n * CELL end

----------------------------------------------------------------
-- 0: 工作台（木桌 + 台钳 + 工具）
----------------------------------------------------------------
local ox = cell(0)
fill(ox + 1, 6, ox + 14, 13, OUTLINE)
fill(ox + 2, 7, ox + 13, 12, WOOD)
fill(ox + 2, 7, ox + 13, 7, WOOD_L)
fill(ox + 2, 12, ox + 13, 12, WOOD_D)
fill(ox + 3, 8, ox + 5, 9, METAL)
fill(ox + 3, 8, ox + 5, 8, METAL_L)
fill(ox + 8, 8, ox + 8, 11, METAL_D)
fill(ox + 9, 9, ox + 12, 9, METAL_D)
put(ox + 6, 10, YELLOW)

----------------------------------------------------------------
-- 1: 储物箱（木箱 + 铁角 + 锁扣）
----------------------------------------------------------------
ox = cell(1)
fill(ox + 2, 4, ox + 13, 14, OUTLINE)
fill(ox + 3, 5, ox + 12, 13, WOOD)
fill(ox + 3, 5, ox + 12, 6, WOOD_L)
fill(ox + 3, 12, ox + 12, 13, WOOD_D)
fill(ox + 3, 5, ox + 3, 13, METAL_D)
fill(ox + 12, 5, ox + 12, 13, METAL_D)
fill(ox + 7, 8, ox + 8, 10, YELLOW)

----------------------------------------------------------------
-- 2: 发电机（深色机器 + 黄色警示条 + 散热孔）
----------------------------------------------------------------
ox = cell(2)
fill(ox + 2, 3, ox + 13, 14, OUTLINE)
fill(ox + 3, 4, ox + 12, 13, METAL_D)
fill(ox + 3, 4, ox + 12, 5, METAL)
fill(ox + 4, 6, ox + 11, 8, METAL_L)
for x = ox + 4, ox + 11, 2 do put(x, 7, METAL_D) end
fill(ox + 3, 10, ox + 12, 11, YELLOW)
put(ox + 4, 12, METAL_L)
put(ox + 11, 12, METAL_L)

----------------------------------------------------------------
-- 3: 盆栽
----------------------------------------------------------------
ox = cell(3)
fill(ox + 5, 9, ox + 10, 14, OUTLINE)
fill(ox + 6, 10, ox + 9, 13, POT)
fill(ox + 6, 10, ox + 9, 10, rgb(206, 126, 96))
fill(ox + 6, 2, ox + 9, 8, LEAF_D)
fill(ox + 5, 4, ox + 10, 7, LEAF)
put(ox + 7, 1, LEAF)
put(ox + 4, 6, LEAF)
put(ox + 11, 6, LEAF)

----------------------------------------------------------------
-- 自动描边
----------------------------------------------------------------
local snapshot = {}
for y = 0, H - 1 do
	snapshot[y] = {}
	for x = 0, W - 1 do snapshot[y][x] = img:getPixel(x, y) end
end
for y = 0, H - 1 do
	for x = 0, W - 1 do
		if snapshot[y][x] == 0 then
			local near = false
			for dy = -1, 1 do
				for dx = -1, 1 do
					local nx, ny = x + dx, y + dy
					if nx >= 0 and ny >= 0 and nx < W and ny < H and snapshot[ny][nx] ~= 0 then
						near = true
					end
				end
			end
			if near then img:putPixel(x, y, OUTLINE) end
		end
	end
end

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "furniture"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs(OUT)
print(string.format("saved %s  %dx%d", OUT, W, H))
