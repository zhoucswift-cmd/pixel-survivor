-- make_concrete.lua
-- 生成楼顶基地的水泥瓦片：16x16 × 16 块（8 列 × 2 行）
--  0-3 水泥地面（4 种斑驳变化）  4 裂缝  5 排水格栅  6 暗一点的地面
--  7  女儿墙（横向）  8 女儿墙（竖向）  9-12 四角  13 楼梯口  14 空调外机  15 通风口
-- 运行: Aseprite.exe -b --script tools/make_concrete.lua

local OUT = "C:/game/test/assets/tiles/concrete_tiles.aseprite"
local T, COLS, ROWS = 16, 8, 2

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local BASE   = rgb(138, 140, 146)
local LIGHT  = rgb(168, 170, 176)
local DARK   = rgb(112, 114, 120)
local SHADE  = rgb(88, 90, 96)
local OUTLINE = rgb(62, 64, 70)
local METAL  = rgb(120, 124, 132)
local METAL_D = rgb(78, 82, 90)
local GRATE  = rgb(70, 72, 78)

local img = Image(COLS * T, ROWS * T, ColorMode.RGB)
img:clear(0)

local function put(x, y, c)
	if x >= 0 and y >= 0 and x < img.width and y < img.height then img:putPixel(x, y, c) end
end

local function fill(x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(x, y, c) end end
end

local function tile_origin(i)
	local col = i % COLS
	local row = math.floor(i / COLS)
	return col * T, row * T
end

-- 简单确定性噪声
local seed = 1337
local function rnd()
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648.0
end

-- 水泥地面：底色 + 随机深浅点
local function concrete(ox, oy, tone)
	local base = tone
	for y = 0, T - 1 do
		for x = 0, T - 1 do
			local r = rnd()
			local c = base
			if r < 0.10 then c = LIGHT
			elseif r < 0.22 then c = DARK end
			put(ox + x, oy + y, c)
		end
	end
	-- 四边压一点暗，让瓦片之间有缝
	for i = 0, T - 1 do
		put(ox + i, oy, DARK)
		put(ox, oy + i, DARK)
	end
end

-- 女儿墙：横向（顶部一道墙）
local function parapet_h(ox, oy)
	concrete(ox, oy, BASE)
	fill(ox, oy, ox + T - 1, oy + 4, LIGHT)
	fill(ox, oy + 5, ox + T - 1, oy + 5, SHADE)
	fill(ox, oy + 6, ox + T - 1, oy + 7, DARK)
	fill(ox, oy + 8, ox + T - 1, oy + T - 1, BASE)
	for x = ox, ox + T - 1 do put(x, oy + 8, SHADE) end
end

-- 女儿墙：竖向（左侧一道墙）
local function parapet_v(ox, oy)
	concrete(ox, oy, BASE)
	fill(ox, oy, ox + 4, oy + T - 1, LIGHT)
	fill(ox + 5, oy, ox + 5, oy + T - 1, SHADE)
	fill(ox + 6, oy, ox + 7, oy + T - 1, DARK)
	fill(ox + 8, oy, ox + T - 1, oy + T - 1, BASE)
end

-- 角落：左上
local function corner_tl(ox, oy)
	parapet_h(ox, oy)
	fill(ox, oy, ox + 4, oy + T - 1, LIGHT)
	fill(ox + 5, oy, ox + 5, oy + T - 1, SHADE)
	fill(ox + 6, oy, ox + 7, oy + T - 1, DARK)
	fill(ox + 8, oy, ox + T - 1, oy + 4, LIGHT)
	fill(ox + 8, oy + 5, ox + T - 1, oy + 5, SHADE)
	fill(ox + 8, oy + 6, ox + T - 1, oy + 7, DARK)
end

-- 楼梯口（通向下层的舱口）
local function hatch(ox, oy)
	concrete(ox, oy, BASE)
	fill(ox + 2, oy + 2, ox + 13, oy + 13, OUTLINE)
	fill(ox + 3, oy + 3, ox + 12, oy + 12, METAL_D)
	fill(ox + 4, oy + 4, ox + 11, oy + 11, METAL)
	for i = 0, 6 do put(ox + 5 + i, oy + 6, METAL_D) end
	for i = 0, 6 do put(ox + 5 + i, oy + 9, METAL_D) end
	fill(ox + 7, oy + 13, ox + 8, oy + 14, rgb(190, 190, 196))
end

-- 空调外机
local function ac_unit(ox, oy)
	concrete(ox, oy, BASE)
	fill(ox + 1, oy + 2, ox + 14, oy + 13, OUTLINE)
	fill(ox + 2, oy + 3, ox + 13, oy + 12, METAL)
	fill(ox + 2, oy + 3, ox + 13, oy + 4, rgb(150, 154, 162))
	for y = oy + 6, oy + 11, 2 do
		for x = ox + 4, ox + 11 do put(x, y, METAL_D) end
	end
	fill(ox + 3, oy + 3, ox + 3, oy + 12, METAL_D)
end

-- 通风口
local function vent(ox, oy)
	concrete(ox, oy, BASE)
	fill(ox + 1, oy + 3, ox + 14, oy + 12, OUTLINE)
	fill(ox + 2, oy + 4, ox + 13, oy + 11, GRATE)
	for y = oy + 5, oy + 10, 2 do
		for x = ox + 3, ox + 12 do put(x, y, METAL_D) end
	end
end

-- 0-3: 地面变化
concrete(0, 0, BASE)
concrete(T, 0, BASE)
-- 2: 带裂缝
local ox, oy = tile_origin(2)
concrete(ox, oy, BASE)
local cx, cy = ox + 3, oy + 1
for i = 0, 11 do
	put(cx, cy, SHADE)
	cx = cx + 1
	cy = cy + ((i % 3 == 0) and 1 or 0)
	if cx > ox + 13 then cx = ox + 4; cy = cy + 2 end
end
-- 3: 带污渍
ox, oy = tile_origin(3)
concrete(ox, oy, BASE)
for y = oy + 4, oy + 11 do
	for x = ox + 4, ox + 11 do
		if (x - ox - 4) * (x - ox - 4) + (y - oy - 4) * (y - oy - 4) < 22 then put(x, y, DARK) end
	end
end

-- 4: 排水格栅
ox, oy = tile_origin(4)
concrete(ox, oy, BASE)
fill(ox + 3, oy + 3, ox + 12, oy + 12, GRATE)
for y = oy + 4, oy + 11, 2 do
	for x = ox + 4, ox + 11 do put(x, y, OUTLINE) end
end

-- 5: 暗色地面
concrete(ox, oy, BASE)
-- 覆盖成 5 号瓦片（第二行第 5 格）
ox, oy = tile_origin(5)
concrete(ox, oy, DARK)

-- 6
ox, oy = tile_origin(6)
concrete(ox, oy, BASE)
for i = 0, T - 1 do
	put(ox + i, oy + 1, LIGHT)
	put(ox + i, oy + 2, LIGHT)
end

-- 7 横向女儿墙, 8 竖向女儿墙
ox, oy = tile_origin(7)
parapet_h(ox, oy)
ox, oy = tile_origin(8)
parapet_v(ox, oy)

-- 9-12 四角（左上 / 右上 / 左下 / 右下）
ox, oy = tile_origin(9)
corner_tl(ox, oy)
-- 右上：横向 + 右侧墙
ox, oy = tile_origin(10)
parapet_h(ox, oy)
fill(ox + T - 5, oy, ox + T - 1, oy + T - 1, LIGHT)
fill(ox + T - 7, oy, ox + T - 6, oy + T - 1, DARK)
-- 左下：竖向 + 底部墙
ox, oy = tile_origin(11)
parapet_v(ox, oy)
fill(ox, oy + T - 5, ox + T - 1, oy + T - 1, LIGHT)
fill(ox, oy + T - 7, ox + T - 1, oy + T - 6, DARK)
-- 右下
ox, oy = tile_origin(12)
parapet_h(ox, oy)
fill(ox + T - 5, oy, ox + T - 1, oy + T - 1, LIGHT)
fill(ox + T - 7, oy, ox + T - 6, oy + T - 1, DARK)
fill(ox, oy + T - 5, ox + T - 1, oy + T - 1, LIGHT)

-- 13 楼梯口
ox, oy = tile_origin(13)
hatch(ox, oy)

-- 14 空调外机
ox, oy = tile_origin(14)
ac_unit(ox, oy)

-- 15 通风口
ox, oy = tile_origin(15)
vent(ox, oy)

local spr = Sprite(img.width, img.height, ColorMode.RGB)
spr.layers[1].name = "tiles"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs(OUT)
print(string.format("saved %s  %dx%d (%d tiles)", OUT, img.width, img.height, COLS * ROWS))
