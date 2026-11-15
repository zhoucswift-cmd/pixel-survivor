-- make_city.lua
-- 生成基地外围的城市背景：800x800（平台 480x480 居中，四周各外扩 160px）
-- 夜色氛围版：深蓝街道、亮窗、霓虹招牌、路灯光池、雾带、起火楼 + 火光、成群的僵尸
-- 运行: Aseprite.exe -b --script tools/make_city.lua

local OUT = "C:/game/test/assets/base/city_background.aseprite"
local W, H = 800, 800
local PLATFORM = { x = 160, y = 160, w = 480, h = 480 }

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

-- 夜色街道
local ASPHALT  = rgb(26, 28, 38)
local ASPHALT2 = rgb(32, 36, 47)
local SIDEWALK = rgb(44, 49, 63)
local LINE     = rgb(86, 82, 58)

-- 楼顶（都很暗，靠边缘高光提亮）
local ROOFS = {
	rgb(38, 42, 56), rgb(32, 36, 49), rgb(44, 48, 63),
	rgb(46, 42, 54), rgb(36, 40, 52), rgb(30, 34, 46),
	rgb(50, 46, 58), rgb(34, 39, 51),
}
local OUTLINE   = rgb(14, 16, 22)
local EDGE_LIT  = rgb(78, 88, 110)
local DETAIL    = rgb(22, 25, 33)
local TANK      = rgb(64, 62, 62)
local SOLAR     = rgb(26, 36, 54)
local GARDEN    = rgb(34, 52, 38)

-- 光
local LAMP      = rgb(255, 224, 168)
local LAMP_GLOW = rgb(255, 198, 120)
local WIN       = rgb(255, 210, 130)
local WIN2      = rgb(255, 176, 92)
local NEON_P    = rgb(255, 96, 158)
local NEON_C    = rgb(110, 236, 224)
local FIRE_HOT  = rgb(255, 240, 176)
local FIRE      = rgb(255, 148, 58)
local FIRE_D    = rgb(198, 68, 36)

-- 雾 / 阴天底色
local HAZE      = rgb(56, 64, 88)
local HAZE_H    = rgb(44, 50, 70)

local ZOMBIE    = rgb(92, 126, 88)
local ZOMBIE_D  = rgb(66, 92, 66)

local img = Image(W, H, ColorMode.RGB)
img:clear(ASPHALT)

local function put(x, y, c)
	if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end
local function getc(x, y)
	if x < 0 or y < 0 or x >= W or y >= H then return ASPHALT end
	return img:getPixel(x, y)
end
local function fill(x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(x, y, c) end end
end

local seed = 20241115
local function rnd()
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648.0
end
local function rndi(a, b)
	return a + math.floor(rnd() * (b - a + 1))
end

-- 把某点朝某个颜色混合（t = 0..1）
local function blend(x, y, c, t)
	if t <= 0 then return end
	if t > 1 then t = 1 end
	local p = getc(x, y)
	local function ch(a, b)
		local v = math.floor(a * (1 - t) + b * t + 0.5)
		if v < 0 then return 0 elseif v > 255 then return 255 end
		return v
	end
	put(x, y, rgb(ch(pc.rgbaR(p), pc.rgbaR(c)), ch(pc.rgbaG(p), pc.rgbaG(c)), ch(pc.rgbaB(p), pc.rgbaB(c))))
end

-- 圆形光晕（衰减平方，像路灯/火光打在地上）
local function glow(cx, cy, radius, c, strength)
	local r2 = radius * radius
	for y = math.floor(cy - radius), math.ceil(cy + radius) do
		for x = math.floor(cx - radius), math.ceil(cx + radius) do
			local dx, dy = x - cx, y - cy
			local d2 = dx * dx + dy * dy
			if d2 <= r2 then
				local f = 1 - math.sqrt(d2) / radius
				blend(x, y, c, f * f * strength)
			end
		end
	end
end

---------------------------------------------------------------
-- 1) 街道地面（湿漉漉的沥青）
---------------------------------------------------------------
for y = 0, H - 1 do
	for x = 0, W - 1 do
		local r = rnd()
		local c = ASPHALT
		if r < 0.12 then c = ASPHALT2
		elseif r < 0.145 then c = SIDEWALK end
		put(x, y, c)
	end
end
-- 路面裂缝 / 湿反光
for i = 1, 260 do
	local x, y = rndi(0, W - 1), rndi(0, H - 1)
	if rnd() < 0.5 then put(x, y, rgb(20, 22, 30)) else put(x, y, rgb(40, 46, 60)) end
end

---------------------------------------------------------------
-- 2) 楼群
---------------------------------------------------------------
local BLOCK = 72
local STREET = 14

local function antenna(cx, cy)
	fill(cx, cy, cx, cy + 4, DETAIL)
	put(cx, cy - 1, rgb(150, 60, 60))
	glow(cx, cy - 1, 5, rgb(255, 90, 80), 0.55)
end

local function neon_sign(bx, by, bw, bh)
	-- 屋顶霓虹招牌：一条亮色边 + 光晕
	local horiz = rnd() < 0.5
	local c = rnd() < 0.5 and NEON_P or NEON_C
	if horiz then
		local sx, sy = rndi(bx + 3, math.max(bx + 3, bx + bw - 12)), rndi(by + 3, math.max(by + 3, by + bh - 4))
		fill(sx, sy, sx + rndi(6, 10), sy, c)
		glow(sx + 4, sy, 9, c, 0.42)
	else
		local sx, sy = rndi(bx + 3, math.max(bx + 3, bx + bw - 4)), rndi(by + 3, math.max(by + 3, by + bh - 10))
		fill(sx, sy, sx, sy + rndi(6, 10), c)
		glow(sx, sy + 4, 9, c, 0.42)
	end
end

local function roof_props(bx, by, bw, bh)
	local kind = rndi(1, 8)
	if bw < 10 or bh < 10 then return end
	if kind == 1 then
		-- 空调外机
		for i = 1, rndi(1, 3) do
			local pw, ph = rndi(6, 9), rndi(4, 6)
			local px = rndi(bx + 3, math.max(bx + 3, bx + bw - pw - 3))
			local py = rndi(by + 3, math.max(by + 3, by + bh - ph - 3))
			fill(px, py, px + pw - 1, py + ph - 1, DETAIL)
			fill(px, py, px + pw - 1, py, rgb(70, 78, 96))
		end
	elseif kind == 2 then
		-- 水箱
		local pw, ph = rndi(9, 13), rndi(8, 11)
		local px = rndi(bx + 4, math.max(bx + 4, bx + bw - pw - 4))
		local py = rndi(by + 4, math.max(by + 4, by + bh - ph - 4))
		fill(px, py, px + pw - 1, py + ph - 1, OUTLINE)
		fill(px + 1, py + 1, px + pw - 2, py + ph - 2, TANK)
		fill(px + 1, py + 1, px + pw - 2, py + 1, rgb(92, 90, 88))
	elseif kind == 3 then
		-- 太阳能板（夜里反着冷光）
		for i = 1, rndi(2, 4) do
			local pw, ph = rndi(7, 10), rndi(5, 7)
			local px = rndi(bx + 3, math.max(bx + 3, bx + bw - pw - 3))
			local py = rndi(by + 3, math.max(by + 3, by + bh - ph - 3))
			fill(px, py, px + pw - 1, py + ph - 1, SOLAR)
			fill(px, py, px + pw - 1, py, rgb(52, 74, 108))
		end
	elseif kind == 4 then
		-- 屋顶花园
		local pw, ph = rndi(10, 18), rndi(8, 14)
		local px = rndi(bx + 3, math.max(bx + 3, bx + bw - pw - 3))
		local py = rndi(by + 3, math.max(by + 3, by + bh - ph - 3))
		fill(px, py, px + pw - 1, py + ph - 1, OUTLINE)
		fill(px + 1, py + 1, px + pw - 2, py + ph - 2, GARDEN)
		for i = 1, 6 do
			put(px + rndi(1, pw - 2), py + rndi(1, ph - 2), rgb(52, 78, 52))
		end
	elseif kind == 5 then
		-- 楼梯间
		local pw, ph = rndi(10, 16), rndi(9, 13)
		local px = rndi(bx + 3, math.max(bx + 3, bx + bw - pw - 3))
		local py = rndi(by + 3, math.max(by + 3, by + bh - ph - 3))
		fill(px, py, px + pw - 1, py + ph - 1, OUTLINE)
		fill(px + 1, py + 1, px + pw - 2, py + ph - 2, rgb(40, 45, 58))
		fill(px + 1, py + 1, px + pw - 2, py + 1, EDGE_LIT)
		-- 门口漏出来的一点灯光
		fill(px + pw - 4, py + ph - 4, px + pw - 3, py + ph - 2, WIN2)
		glow(px + pw - 3, py + ph - 3, 7, WIN2, 0.4)
	elseif kind == 6 then
		antenna(bx + rndi(4, math.max(4, bw - 4)), by + rndi(4, math.max(4, bh - 4)))
	elseif kind == 7 then
		neon_sign(bx, by, bw, bh)
	end
end

local function building(bx, by, bw, bh)
	local roof = ROOFS[rndi(1, #ROOFS)]
	fill(bx, by, bx + bw - 1, by + bh - 1, roof)

	for i = 1, math.floor(bw * bh / 30) do
		put(bx + rndi(1, bw - 2), by + rndi(1, bh - 2),
			rnd() < 0.5 and rgb(28, 32, 44) or rgb(52, 58, 74))
	end

	-- 轮廓 + 受光边（上边和左边亮一点，像被街道灯照到）
	for x = bx, bx + bw - 1 do
		put(x, by, OUTLINE)
		put(x, by + 1, EDGE_LIT)
		put(x, by + bh - 1, OUTLINE)
	end
	for y = by, by + bh - 1 do
		put(bx, y, OUTLINE)
		put(bx + 1, y, rgb(58, 66, 84))
		put(bx + bw - 1, y, OUTLINE)
	end

	roof_props(bx + 2, by + 2, bw - 4, bh - 4)
end

for by = 0, H, BLOCK do
	for bx = 0, W, BLOCK do
		local w = rndi(BLOCK - STREET - 12, BLOCK - STREET)
		local h = rndi(BLOCK - STREET - 12, BLOCK - STREET)
		building(bx + 2, by + 2, w, h)
	end
end

---------------------------------------------------------------
-- 3) 路灯 + 街上的光池
---------------------------------------------------------------
local lamps = {}
for by = 0, H, BLOCK do
	for bx = 0, W, BLOCK do
		-- 每个街口放一盏
		local lx = bx + BLOCK - STREET / 2
		local ly = by + BLOCK - STREET / 2
		-- 有的街口不亮（坏灯 / 背光），光池大小也不一样
		if rnd() < 0.72 then
			lamps[#lamps + 1] = { lx, ly }
			fill(lx - 1, ly, lx, ly, DETAIL)
			if rnd() < 0.12 then
				put(lx, ly, rgb(90, 78, 60))          -- 坏灯
			else
				put(lx, ly, LAMP)
				glow(lx, ly + 1, rndi(18, 32), LAMP_GLOW, rndi(42, 62) / 100.0)
			end
		end
	end
end

---------------------------------------------------------------
-- 3.5) 街上几辆车的车灯
---------------------------------------------------------------
for i = 1, 7 do
	local cx = rndi(10, W - 10)
	local cy = rndi(10, H - 10)
	local horiz = rnd() < 0.5
	local dirx = (rnd() < 0.5) and -1 or 1
	local diry = (rnd() < 0.5) and -1 or 1
	if horiz then
		local beam = 14
		for k = 1, beam do
			blend(cx + dirx * k, cy, rgb(255, 240, 200), 0.42 * (1 - k / beam))
			blend(cx + dirx * k, cy + 1, rgb(255, 236, 190), 0.22 * (1 - k / beam))
		end
		put(cx, cy, rgb(255, 246, 214))
		put(cx + 1, cy, rgb(255, 246, 214))
		put(cx - dirx, cy + 1, rgb(220, 60, 50))
	else
		local beam = 14
		for k = 1, beam do
			blend(cx, cy + diry * k, rgb(255, 240, 200), 0.42 * (1 - k / beam))
			blend(cx + 1, cy + diry * k, rgb(255, 236, 190), 0.22 * (1 - k / beam))
		end
		put(cx, cy, rgb(255, 246, 214))
		put(cx, cy + 1, rgb(255, 246, 214))
		put(cx + 1, cy - diry, rgb(220, 60, 50))
	end
end

---------------------------------------------------------------
-- 4) 路上成群的僵尸（一小撮一小撮）
---------------------------------------------------------------
local function zombie(cx, cy)
	put(cx, cy, ZOMBIE)
	put(cx + 1, cy, ZOMBIE)
	put(cx, cy + 1, ZOMBIE_D)
	put(cx + 1, cy + 1, ZOMBIE_D)
	put(cx + (rnd() < 0.5 and -1 or 2), cy + 1, ZOMBIE_D)
end

for i = 1, 26 do
	local cx = rndi(0, W - 1)
	local cy = rndi(0, H - 1)
	local n = rndi(2, 7)
	for j = 1, n do
		zombie(cx + rndi(-10, 10), cy + rndi(-8, 8))
	end
end

---------------------------------------------------------------
-- 5) 起火的楼 + 烟
---------------------------------------------------------------
local function fire(cx, cy)
	glow(cx, cy, 26, FIRE, 0.5)
	fill(cx - 2, cy, cx + 2, cy + 1, FIRE_D)
	fill(cx - 1, cy - 1, cx + 1, cy, FIRE)
	fill(cx, cy - 2, cx, cy - 1, FIRE_HOT)
	-- 烟柱（往上飘）
	for i = 1, rndi(10, 22) do
		local sy = cy - 4 - i
		local sx = cx + math.floor(math.sin(i * 0.5) * 4)
		blend(sx, sy, HAZE_H, 0.55)
		if i % 3 == 0 then blend(sx + 1, sy, HAZE, 0.4) end
	end
end

for i = 1, 5 do
	fire(rndi(30, W - 30), rndi(30, H - 30))
end

---------------------------------------------------------------
-- 6) 雾带（横着的几层，弱化整体对比）
---------------------------------------------------------------
for i = 1, 7 do
	local y0 = rndi(0, H - 1)
	local hgt = rndi(6, 18)
	for y = y0, y0 + hgt do
		if y >= 0 and y < H then
			for x = 0, W - 1 do
				local f = (1 - math.abs((y - y0) / (hgt + 1) - 0.5) * 2)
				blend(x, y, HAZE, 0.10 + f * 0.14)
			end
		end
	end
end

---------------------------------------------------------------
-- 7) 平台四周的阴影（让屋顶看起来是“高出街道”的）
---------------------------------------------------------------
local SHADOW = 34
for y = PLATFORM.y - SHADOW, PLATFORM.y + PLATFORM.h + SHADOW do
	for x = PLATFORM.x - SHADOW, PLATFORM.x + PLATFORM.w + SHADOW do
		if x >= 0 and y >= 0 and x < W and y < H then
			local dx = math.max(PLATFORM.x - x, x - (PLATFORM.x + PLATFORM.w), 0)
			local dy = math.max(PLATFORM.y - y, y - (PLATFORM.y + PLATFORM.h), 0)
			local d = math.max(dx, dy)
			local inside = x >= PLATFORM.x and x < PLATFORM.x + PLATFORM.w
				and y >= PLATFORM.y and y < PLATFORM.y + PLATFORM.h
			if not inside then
				blend(x, y, rgb(6, 8, 14), 0.55 * (1 - d / SHADOW))
			end
		end
	end
end

-- 平台区域留黑（平台本身会盖在上面）
fill(PLATFORM.x, PLATFORM.y, PLATFORM.x + PLATFORM.w - 1, PLATFORM.y + PLATFORM.h - 1, rgb(0, 0, 0))

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "city"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs(OUT)
print("saved city background")
