-- make_bed_occupied.lua
-- 床 + 睡着的人：32x48，两帧（呼吸）
-- 运行: Aseprite.exe -b --script tools/make_bed_occupied.lua

local OUT = "C:/game/test/assets/base/bed_occupied.aseprite"
local W, H = 32, 48

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE  = rgb(44, 32, 30)
local WOOD     = rgb(140, 94, 56)
local WOOD_L   = rgb(176, 124, 74)
local WOOD_D   = rgb(98, 64, 38)
local SHEET    = rgb(238, 234, 224)
local SHEET_D  = rgb(200, 196, 186)
local BLANKET  = rgb(96, 132, 186)
local BLANKET_D = rgb(66, 96, 144)
local BLANKET_L = rgb(126, 160, 208)
local PILLOW   = rgb(248, 246, 238)
local PILLOW_D = rgb(212, 210, 200)
-- 人物
local HAIR     = rgb(110, 68, 40)
local HAIR_L   = rgb(150, 98, 58)
local SKIN     = rgb(242, 196, 158)
local SKIN_D   = rgb(214, 158, 118)
local EYE      = rgb(60, 40, 34)

local function draw_frame(breath)
	local img = Image(W, H, ColorMode.RGB)
	img:clear(0)

	local function put(x, y, c)
		if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
	end
	local function fill(x0, y0, x1, y1, c)
		for y = y0, y1 do for x = x0, x1 do put(x, y, c) end end
	end

	-- 床（和 bed.png 一致）
	fill(0, 0, W - 1, H - 1, OUTLINE)
	fill(1, 1, W - 2, H - 2, WOOD)
	fill(1, 1, W - 2, 5, WOOD_L)
	fill(1, H - 5, W - 2, H - 2, WOOD_D)
	fill(1, 1, 2, H - 2, WOOD_L)
	fill(W - 3, 1, W - 2, H - 2, WOOD_D)
	fill(3, 6, W - 4, H - 6, SHEET)
	fill(3, 6, W - 4, 6, SHEET_D)

	-- 枕头
	fill(4, 7, W - 5, 19, PILLOW)
	fill(4, 19, W - 5, 19, PILLOW_D)

	-- 头（枕头上）
	fill(10, 6, 21, 19, SKIN)      -- 脸
	fill(9, 8, 9, 17, SKIN_D)      -- 左脸颊阴影
	fill(22, 8, 22, 17, SKIN_D)
	fill(10, 6, 21, 11, HAIR)      -- 头发
	fill(10, 6, 21, 7, HAIR_L)     -- 发顶高光
	fill(9, 8, 9, 15, HAIR)        -- 两侧鬓发
	fill(22, 8, 22, 15, HAIR)
	fill(13, 14, 15, 14, EYE)      -- 闭眼
	fill(17, 14, 19, 14, EYE)
	put(15, 17, SKIN_D)            -- 嘴
	put(16, 17, SKIN_D)
	fill(11, 18, 20, 18, SKIN_D)   -- 下巴阴影

	-- 被子（从胸口盖到脚），呼吸时上沿会动
	local by = breath and 18 or 19
	for x = 4, W - 5 do
		put(x, by, BLANKET_L)
	end
	fill(4, by + 1, W - 5, H - 7, BLANKET)
	fill(4, by + 2, W - 5, by + 2, BLANKET_D)
	fill(4, H - 8, W - 5, H - 7, BLANKET_D)
	-- 被子褶皱
	fill(W / 2 - 1, by + 4, W / 2, H - 9, BLANKET_D)
	fill(7, by + 7, 7, H - 10, BLANKET_D)
	fill(W - 8, by + 6, W - 8, H - 10, BLANKET_D)
	fill(5, by + 11, W - 6, by + 11, BLANKET_D)
	-- 被子边缘压在肩膀上的亮边
	fill(8, by, 23, by, BLANKET_L)
	return img
end

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "bed_occupied"
for f = 1, 2 do
	local frame = spr.frames[1]
	if f > 1 then frame = spr:newEmptyFrame(#spr.frames + 1) end
	local cel = spr:newCel(spr.layers[1], frame, draw_frame(f == 2), Point(0, 0))
	cel.image = Image(W, H, ColorMode.RGB)
	cel.image = draw_frame(f == 2)
end
spr:saveAs(OUT)
print(string.format("saved %s  %dx%d  frames=%d", OUT, W, H, #spr.frames))
