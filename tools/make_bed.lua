-- make_bed.lua
-- 生成基地的床：16x32（1 格宽 × 2 格高）
-- 运行: Aseprite.exe -b --script tools/make_bed.lua

local OUT = "C:/game/test/assets/base/bed.aseprite"
local W, H = 16, 32

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE = rgb(44, 32, 30)
local WOOD    = rgb(140, 94, 56)
local WOOD_L  = rgb(176, 124, 74)
local WOOD_D  = rgb(98, 64, 38)
local SHEET   = rgb(238, 234, 224)
local SHEET_D = rgb(200, 196, 186)
local BLANKET = rgb(96, 132, 186)
local BLANKET_D = rgb(66, 96, 144)
local BLANKET_L = rgb(126, 160, 208)
local PILLOW  = rgb(248, 246, 238)
local PILLOW_D = rgb(212, 210, 200)

local img = Image(W, H, ColorMode.RGB)
img:clear(0)

local function put(x, y, c)
	if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end

local function fill(x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(x, y, c) end end
end

-- 外框（深色描边）
fill(0, 0, W - 1, H - 1, OUTLINE)

-- 木质床架
fill(1, 1, W - 2, H - 2, WOOD)
fill(1, 1, W - 2, 3, WOOD_L)      -- 床头
fill(1, H - 4, W - 2, H - 2, WOOD_D)  -- 床尾

-- 床垫（白）
fill(2, 4, W - 3, H - 5, SHEET)
fill(2, 4, W - 3, 4, SHEET_D)

-- 枕头（上方）
fill(3, 6, W - 4, 11, PILLOW)
fill(3, 11, W - 4, 11, PILLOW_D)
put(3, 7, PILLOW_D)
put(W - 4, 7, PILLOW_D)

-- 被子（下半段）
fill(2, 13, W - 3, H - 5, BLANKET)
fill(2, 13, W - 3, 14, BLANKET_L)
fill(2, 15, W - 3, 15, BLANKET_D)
fill(2, H - 6, W - 3, H - 5, BLANKET_D)
-- 被子的褶皱
fill(5, 17, 5, H - 7, BLANKET_D)
fill(10, 19, 10, H - 7, BLANKET_D)
fill(3, 22, W - 4, 22, BLANKET_D)

-- 四角木纹高光
put(1, 4, WOOD_L)
put(W - 2, 4, WOOD_L)
put(1, H - 5, WOOD_D)
put(W - 2, H - 5, WOOD_D)

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "bed"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs(OUT)
print(string.format("saved %s  %dx%d", OUT, W, H))
