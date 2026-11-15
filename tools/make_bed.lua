-- make_bed.lua
-- 生成基地的床：32x48（2 格宽 × 3 格高，双人床）
-- 运行: Aseprite.exe -b --script tools/make_bed.lua

local OUT = "C:/game/test/assets/base/bed.aseprite"
local W, H = 32, 48

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
fill(1, 1, W - 2, 5, WOOD_L)          -- 床头板
fill(1, H - 5, W - 2, H - 2, WOOD_D)  -- 床尾板
fill(1, 1, 2, H - 2, WOOD_L)          -- 左侧木边
fill(W - 3, 1, W - 2, H - 2, WOOD_D)  -- 右侧木边

-- 床垫（白）
fill(3, 6, W - 4, H - 6, SHEET)
fill(3, 6, W - 4, 6, SHEET_D)

-- 两个枕头（上方并排）
local pw = 12
local py0, py1 = 8, 16
fill(4, py0, 4 + pw - 1, py1, PILLOW)
fill(W - 4 - pw, py0, W - 5, py1, PILLOW)
fill(4, py1, 4 + pw - 1, py1, PILLOW_D)
fill(W - 4 - pw, py1, W - 5, py1, PILLOW_D)
-- 两个枕头之间的缝
fill(W / 2 - 1, py0, W / 2, py1, PILLOW_D)
-- 枕头缝线
put(4, py0, PILLOW_D)
put(4 + pw - 1, py0, PILLOW_D)
put(W - 4 - pw, py0, PILLOW_D)
put(W - 5, py0, PILLOW_D)

-- 被子（下半段）
local by0 = 19
fill(3, by0, W - 4, H - 7, BLANKET)
fill(3, by0, W - 4, by0 + 1, BLANKET_L)
fill(3, by0 + 2, W - 4, by0 + 2, BLANKET_D)
fill(3, H - 8, W - 4, H - 7, BLANKET_D)
-- 被子褶皱
fill(W / 2 - 1, by0 + 4, W / 2 - 1, H - 9, BLANKET_D)
fill(W / 2, by0 + 4, W / 2, H - 9, BLANKET_D)
fill(6, by0 + 9, 6, H - 10, BLANKET_D)
fill(W - 7, by0 + 7, W - 7, H - 10, BLANKET_D)
fill(4, by0 + 14, W - 5, by0 + 14, BLANKET_D)

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "bed"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs(OUT)
print(string.format("saved %s  %dx%d", OUT, W, H))
