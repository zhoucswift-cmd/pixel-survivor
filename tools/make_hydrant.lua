-- make_hydrant.lua
-- 红色消防栓：16x16（1 格）——先铺形状再自动描边，轮廓干净
-- 运行: Aseprite.exe -b --script tools/make_hydrant.lua

local OUT = "C:/game/test/assets/base/hydrant.aseprite"
local W, H = 16, 16

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE = rgb(48, 18, 18)
local RED     = rgb(204, 58, 48)
local RED_D   = rgb(152, 36, 32)
local RED_L   = rgb(242, 108, 88)
local METAL   = rgb(200, 202, 210)
local METAL_D = rgb(126, 130, 140)
local BOLT    = rgb(238, 240, 246)

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

-- ---- 1. 实心形状 ----
fill(3, 13, 12, 14, RED)     -- 底座
fill(4, 4, 11, 12, RED)      -- 主体
fill(5, 2, 10, 3, RED)       -- 盖子
fill(7, 0, 8, 1, RED)        -- 顶上小把手
fill(2, 8, 4, 8, RED)        -- 左出水口
fill(11, 8, 13, 8, RED)      -- 右出水口
fill(4, 6, 4, 11, RED)       -- 让主体更壮一点

-- ---- 2. 明暗 ----
fill(4, 4, 5, 12, RED_L)     -- 左侧受光
fill(10, 4, 11, 12, RED_D)   -- 右侧背光
fill(5, 2, 10, 2, RED_L)     -- 盖子顶
fill(7, 0, 8, 0, RED_L)
fill(3, 14, 12, 14, RED_D)   -- 底座阴影

-- 出水口金属盖
fill(1, 7, 1, 9, METAL_D)
fill(14, 7, 14, 9, METAL_D)
fill(1, 7, 1, 7, METAL)
fill(14, 7, 14, 7, METAL)
put(0, 8, METAL_D)
put(15, 8, METAL_D)

-- 中间阀门
fill(6, 7, 9, 9, RED_D)
fill(7, 7, 8, 7, BOLT)
fill(6, 9, 9, 9, rgb(96, 26, 24))

-- 底座螺栓 / 高光点
put(4, 12, BOLT)
put(11, 12, METAL_D)
put(6, 5, RED_L)

-- ---- 3. 自动描边：紧贴形状的空像素涂深色 ----
local to_outline = {}
for y = 0, H - 1 do
	for x = 0, W - 1 do
		if get(x, y) == 0 then
			local near = get(x - 1, y) ~= nil and get(x - 1, y) ~= 0
				or get(x + 1, y) ~= nil and get(x + 1, y) ~= 0
				or get(x, y - 1) ~= nil and get(x, y - 1) ~= 0
				or get(x, y + 1) ~= nil and get(x, y + 1) ~= 0
			if near then table.insert(to_outline, { x, y }) end
		end
	end
end
for _, p in ipairs(to_outline) do put(p[1], p[2], OUTLINE) end

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "hydrant"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs(OUT)
print(string.format("saved %s  %dx%d", OUT, W, H))
