-- make_workbench.lua
-- 基地工作台：32x16（2 格宽 × 1 格高）——俯视视角：桌面 + 桌上的工具
-- 运行: Aseprite.exe -b --script tools/make_workbench.lua

local OUT = "C:/game/test/assets/base/workbench.aseprite"
local W, H = 32, 16

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE = rgb(42, 30, 26)
local WOOD    = rgb(152, 102, 60)
local WOOD_L  = rgb(188, 132, 80)
local WOOD_D  = rgb(108, 68, 40)
local WOOD_DD = rgb(82, 50, 30)
local METAL   = rgb(156, 162, 174)
local METAL_D = rgb(100, 106, 118)
local METAL_L = rgb(214, 220, 230)
local STEEL   = rgb(128, 134, 148)
local PAPER   = rgb(228, 232, 240)
local PAPER_L = rgb(90, 130, 190)

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

-- ===== 桌面（俯视：一整块木板台面）=====
fill(1, 1, 30, 13, WOOD)
-- 左上受光
fill(1, 1, 30, 1, WOOD_L)
fill(1, 1, 1, 13, WOOD_L)
-- 右下压暗
fill(1, 13, 30, 13, WOOD_D)
fill(30, 1, 30, 13, WOOD_D)
-- 木板拼缝（横向）
fill(2, 5, 29, 5, WOOD_D)
fill(2, 9, 29, 9, WOOD_D)
put(7, 5, WOOD_L)
put(21, 9, WOOD_L)

-- 台面前沿（俯视能看到一点厚度）
fill(1, 14, 30, 14, WOOD_DD)

-- ===== 桌上的工具 =====
-- 台虎钳（左侧，夹在桌边）
fill(3, 2, 8, 7, METAL_D)
fill(4, 3, 7, 6, METAL)
fill(4, 3, 7, 3, METAL_L)
fill(3, 4, 3, 5, METAL_L)
put(5, 4, METAL_D)
put(6, 4, METAL_D)

-- 零件盒（中间偏左，里面几颗螺丝）
fill(11, 2, 17, 6, WOOD_DD)
fill(12, 3, 16, 5, rgb(58, 58, 66))
put(12, 3, METAL_L)
put(14, 4, METAL)
put(16, 3, METAL_L)
put(13, 5, STEEL)

-- 锤子（右上，斜着放）
fill(21, 3, 26, 4, WOOD_D)     -- 木柄
put(22, 3, WOOD_L)
fill(26, 2, 28, 5, METAL_D)    -- 锤头
fill(26, 3, 28, 4, METAL)
put(27, 3, METAL_L)

-- 扳手（右下）
fill(21, 9, 27, 10, METAL_D)
fill(21, 9, 26, 9, METAL)
put(20, 8, METAL_D)
put(20, 10, METAL_D)
put(28, 8, METAL_D)
put(28, 10, METAL_D)

-- 蓝图（左下，压着一角）
fill(4, 10, 12, 13, PAPER)
fill(4, 10, 12, 10, rgb(200, 214, 232))
fill(6, 11, 10, 11, PAPER_L)
fill(6, 12, 9, 12, PAPER_L)

-- 几颗散落的螺丝
put(18, 11, METAL_L)
put(19, 12, METAL)
put(24, 6, METAL_L)
put(9, 8, METAL)

-- ===== 自动描边 =====
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
