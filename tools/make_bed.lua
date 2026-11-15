-- make_bed.lua
-- 生成基地的床：16x32（1 格宽 × 2 格高）——俯视：床垫 + 枕头 + 被子
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
fill(1, 1, W - 2, 3, WOOD_L)          -- 床头板
fill(1, H - 3, W - 2, H - 2, WOOD_D)  -- 床尾板
fill(1, 1, 1, H - 2, WOOD_L)          -- 左侧木边
fill(W - 2, 1, W - 2, H - 2, WOOD_D)  -- 右侧木边

-- 床垫（白）
fill(2, 4, W - 3, H - 4, SHEET)
fill(2, 4, W - 3, 4, SHEET_D)

-- 枕头
fill(3, 6, W - 4, 10, PILLOW)
fill(3, 10, W - 4, 10, PILLOW_D)
put(3, 6, PILLOW_D)
put(W - 4, 6, PILLOW_D)

-- 被子（下半段）
local by = 12
fill(2, by, W - 3, H - 5, BLANKET)
fill(2, by, W - 3, by, BLANKET_L)
fill(2, by + 1, W - 3, by + 1, BLANKET_D)
fill(2, H - 6, W - 3, H - 5, BLANKET_D)
-- 被子褶皱
fill(W / 2 - 1, by + 3, W / 2, H - 7, BLANKET_D)
fill(4, by + 6, 4, H - 8, BLANKET_D)
fill(W - 5, by + 5, W - 5, H - 8, BLANKET_D)
fill(3, by + 10, W - 4, by + 10, BLANKET_D)

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "bed"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs(OUT)
print(string.format("saved %s  %dx%d", OUT, W, H))
