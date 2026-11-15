-- make_concrete.lua
-- 生成楼顶基地的水泥瓦片：16x16 × 24 块（8 列 × 3 行）
--  0-5 水泥地面（斑驳 / 裂缝 / 污渍 / 格栅 / 暗色 / 浅色）
--  6 备用地面
--  7 女儿墙-上  8 女儿墙-下  9 女儿墙-左  10 女儿墙-右
--  11 角-左上  12 角-右上  13 角-左下  14 角-右下
--  15 楼梯舱口  16 空调外机  17 通风口
--  18-23 备用
-- 运行: Aseprite.exe -b --script tools/make_concrete.lua

local OUT = "C:/game/test/assets/tiles/concrete_tiles.aseprite"
local T, COLS, ROWS = 16, 8, 3

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local BASE    = rgb(138, 140, 146)
local LIGHT   = rgb(168, 170, 176)
local DARK    = rgb(112, 114, 120)
local SHADE   = rgb(88, 90, 96)
local OUTLINE = rgb(62, 64, 70)
local METAL   = rgb(120, 124, 132)
local METAL_D = rgb(78, 82, 90)
local GRATE   = rgb(70, 72, 78)

-- 女儿墙配色：外墙皮 / 压顶（受光）/ 压顶阴影 / 地面投影
local OUTER   = rgb(74, 76, 84)
local CAP     = rgb(196, 198, 202)
local CAP_D   = rgb(150, 152, 158)
local SHADOW  = rgb(112, 114, 121)
local SHADOW2 = rgb(124, 126, 132)

local img = Image(COLS * T, ROWS * T, ColorMode.RGB)
img:clear(0)

local function put(x, y, c)
	if x >= 0 and y >= 0 and x < img.width and y < img.height then img:putPixel(x, y, c) end
end

local function fill(x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(x, y, c) end end
end

local function tile_origin(i)
	return (i % COLS) * T, math.floor(i / COLS) * T
end

local seed = 1337
local function rnd()
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648.0
end

-- 水泥地面：底色 + 随机深浅点
local function concrete(ox, oy, tone)
	for y = 0, T - 1 do
		for x = 0, T - 1 do
			local r = rnd()
			local c = tone
			if r < 0.10 then c = LIGHT
			elseif r < 0.22 then c = DARK end
			put(ox + x, oy + y, c)
		end
	end
	for i = 0, T - 1 do
		put(ox + i, oy, DARK)
		put(ox, oy + i, DARK)
	end
end

-- 女儿墙的四条边（画满整条，保证相邻瓦片接得上）
-- side: "top" / "bottom" / "left" / "right"
local function rim(ox, oy, side)
	if side == "top" then
		fill(ox, oy, ox + T - 1, oy + 0, OUTER)
		fill(ox, oy + 1, ox + T - 1, oy + 3, CAP)
		fill(ox, oy + 4, ox + T - 1, oy + 4, CAP_D)
		fill(ox, oy + 5, ox + T - 1, oy + 6, SHADOW)
		fill(ox, oy + 7, ox + T - 1, oy + 7, SHADOW2)
	elseif side == "bottom" then
		fill(ox, oy + T - 1, ox + T - 1, oy + T - 1, OUTER)
		fill(ox, oy + T - 4, ox + T - 1, oy + T - 2, CAP)
		fill(ox, oy + T - 5, ox + T - 1, oy + T - 5, CAP_D)
		fill(ox, oy + T - 7, ox + T - 1, oy + T - 6, SHADOW)
		fill(ox, oy + T - 8, ox + T - 1, oy + T - 8, SHADOW2)
	elseif side == "left" then
		fill(ox, oy, ox + 0, oy + T - 1, OUTER)
		fill(ox + 1, oy, ox + 3, oy + T - 1, CAP)
		fill(ox + 4, oy, ox + 4, oy + T - 1, CAP_D)
		fill(ox + 5, oy, ox + 6, oy + T - 1, SHADOW)
		fill(ox + 7, oy, ox + 7, oy + T - 1, SHADOW2)
	else -- right
		fill(ox + T - 1, oy, ox + T - 1, oy + T - 1, OUTER)
		fill(ox + T - 4, oy, ox + T - 2, oy + T - 1, CAP)
		fill(ox + T - 5, oy, ox + T - 5, oy + T - 1, CAP_D)
		fill(ox + T - 7, oy, ox + T - 6, oy + T - 1, SHADOW)
		fill(ox + T - 8, oy, ox + T - 8, oy + T - 1, SHADOW2)
	end
end

---------------------------------------------------------------
-- 0-5 地面
---------------------------------------------------------------
concrete(0, 0, BASE)
concrete(T, 0, BASE)

-- 2 裂缝
local ox, oy = tile_origin(2)
concrete(ox, oy, BASE)
local cx, cy = ox + 3, oy + 1
for i = 0, 11 do
	put(cx, cy, SHADE)
	cx = cx + 1
	cy = cy + ((i % 3 == 0) and 1 or 0)
	if cx > ox + 13 then cx = ox + 4; cy = cy + 2 end
end

-- 3 污渍
ox, oy = tile_origin(3)
concrete(ox, oy, BASE)
for y = oy + 4, oy + 11 do
	for x = ox + 4, ox + 11 do
		if (x - ox - 4) * (x - ox - 4) + (y - oy - 4) * (y - oy - 4) < 22 then put(x, y, DARK) end
	end
end

-- 4 格栅
ox, oy = tile_origin(4)
concrete(ox, oy, BASE)
fill(ox + 3, oy + 3, ox + 12, oy + 12, GRATE)
for y = oy + 4, oy + 11, 2 do
	for x = ox + 4, ox + 11 do put(x, y, OUTLINE) end
end

-- 5 暗色地面 / 6 普通水泥（多一种斑驳）
ox, oy = tile_origin(5)
concrete(ox, oy, DARK)
ox, oy = tile_origin(6)
concrete(ox, oy, BASE)

---------------------------------------------------------------
-- 7-10 四边女儿墙
---------------------------------------------------------------
ox, oy = tile_origin(7); concrete(ox, oy, BASE); rim(ox, oy, "top")
ox, oy = tile_origin(8); concrete(ox, oy, BASE); rim(ox, oy, "bottom")
ox, oy = tile_origin(9); concrete(ox, oy, BASE); rim(ox, oy, "left")
ox, oy = tile_origin(10); concrete(ox, oy, BASE); rim(ox, oy, "right")

---------------------------------------------------------------
-- 11-14 四角
---------------------------------------------------------------
ox, oy = tile_origin(11); concrete(ox, oy, BASE); rim(ox, oy, "top"); rim(ox, oy, "left")
ox, oy = tile_origin(12); concrete(ox, oy, BASE); rim(ox, oy, "top"); rim(ox, oy, "right")
ox, oy = tile_origin(13); concrete(ox, oy, BASE); rim(ox, oy, "bottom"); rim(ox, oy, "left")
ox, oy = tile_origin(14); concrete(ox, oy, BASE); rim(ox, oy, "bottom"); rim(ox, oy, "right")

---------------------------------------------------------------
-- 15 楼梯舱口
---------------------------------------------------------------
ox, oy = tile_origin(15)
concrete(ox, oy, BASE)
fill(ox + 2, oy + 2, ox + 13, oy + 13, OUTLINE)
fill(ox + 3, oy + 3, ox + 12, oy + 12, METAL_D)
fill(ox + 4, oy + 4, ox + 11, oy + 11, METAL)
for i = 0, 6 do put(ox + 5 + i, oy + 6, METAL_D) end
for i = 0, 6 do put(ox + 5 + i, oy + 9, METAL_D) end
fill(ox + 7, oy + 13, ox + 8, oy + 14, rgb(190, 190, 196))

---------------------------------------------------------------
-- 16 空调外机
---------------------------------------------------------------
ox, oy = tile_origin(16)
concrete(ox, oy, BASE)
fill(ox + 1, oy + 2, ox + 14, oy + 13, OUTLINE)
fill(ox + 2, oy + 3, ox + 13, oy + 12, METAL)
fill(ox + 2, oy + 3, ox + 13, oy + 4, rgb(150, 154, 162))
for y = oy + 6, oy + 11, 2 do
	for x = ox + 4, ox + 11 do put(x, y, METAL_D) end
end
fill(ox + 3, oy + 3, ox + 3, oy + 12, METAL_D)

---------------------------------------------------------------
-- 17 通风口
---------------------------------------------------------------
ox, oy = tile_origin(17)
concrete(ox, oy, BASE)
fill(ox + 1, oy + 3, ox + 14, oy + 12, OUTLINE)
fill(ox + 2, oy + 4, ox + 13, oy + 11, GRATE)
for y = oy + 5, oy + 10, 2 do
	for x = ox + 3, ox + 12 do put(x, y, METAL_D) end
end

---------------------------------------------------------------
-- 18-23 备用地面（简单变化，避免大片重复）
---------------------------------------------------------------
for i = 18, 23 do
	ox, oy = tile_origin(i)
	concrete(ox, oy, BASE)
	-- 轻微斑驳：几粒浅色/深色小点，保持地面整体均匀
	for k = 0, 8 do
		local px = ox + 2 + math.floor(rnd() * 12)
		local py = oy + 2 + math.floor(rnd() * 12)
		put(px, py, LIGHT)
	end
	for k = 0, 5 do
		local px = ox + 2 + math.floor(rnd() * 12)
		local py = oy + 2 + math.floor(rnd() * 12)
		put(px, py, DARK)
	end
end

local spr = Sprite(img.width, img.height, ColorMode.RGB)
spr.layers[1].name = "tiles"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs(OUT)
print(string.format("saved %s  %dx%d (%d tiles)", OUT, img.width, img.height, COLS * ROWS))
