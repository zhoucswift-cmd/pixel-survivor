-- make_city.lua
-- 生成基地外围的城市背景：800x800（平台 480x480 居中，四周各外扩 160px）
--  小体量的低矮楼房群 / 起火冒烟的楼 / 街上成群的僵尸 / 路灯 / 平台投影
-- 运行: Aseprite.exe -b --script tools/make_city.lua

local OUT = "C:/game/test/assets/base/city_background.aseprite"
local W, H = 800, 800
local PLATFORM = { x = 160, y = 160, w = 480, h = 480 }

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local ROAD     = rgb(46, 48, 56)
local ROAD_D   = rgb(38, 40, 47)
local SIDEWALK = rgb(62, 65, 74)
local LINE     = rgb(104, 98, 70)

local ROOFS = {
	rgb(78, 82, 94), rgb(90, 94, 106), rgb(66, 70, 80),
	rgb(98, 86, 74), rgb(82, 88, 100), rgb(72, 76, 88),
	rgb(104, 96, 82), rgb(62, 66, 76),
}
local OUTLINE   = rgb(18, 19, 24)
local ROOF_LIT  = rgb(120, 124, 138)
local DETAIL    = rgb(30, 33, 39)
local TANK      = rgb(104, 96, 84)
local SOLAR     = rgb(38, 52, 74)
local GARDEN    = rgb(58, 84, 54)

local FIRE_HOT  = rgb(255, 238, 160)
local FIRE      = rgb(255, 152, 62)
local FIRE_D    = rgb(206, 74, 40)
local SMOKE     = rgb(86, 88, 98)
local SMOKE_L   = rgb(116, 118, 128)

local ZOMBIE    = rgb(148, 186, 116)
local ZOMBIE_D  = rgb(104, 136, 84)

local LAMP      = rgb(255, 210, 142)

local img = Image(W, H, ColorMode.RGB)
img:clear(ROAD)

local function put(x, y, c)
	if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end

local function getc(x, y)
	if x < 0 or y < 0 or x >= W or y >= H then return ROAD end
	return img:getPixel(x, y)
end

local function fill(x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(x, y, c) end end
end

local seed = 424242
local function rnd()
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648.0
end

local function rndi(a, b)
	return a + math.floor(rnd() * (b - a + 1))
end

---------------------------------------------------------------
-- 1) 街道地面
---------------------------------------------------------------
for y = 0, H - 1 do
	for x = 0, W - 1 do
		local r = rnd()
		local c = ROAD
		if r < 0.10 then c = ROAD_D
		elseif r < 0.13 then c = SIDEWALK end
		put(x, y, c)
	end
end

---------------------------------------------------------------
-- 2) 楼群
---------------------------------------------------------------
local BLOCK = 72
local STREET = 14

local function roof_props(bx, by, bw, bh)
	local kind = rndi(1, 7)
	if kind == 1 then
		-- 空调外机
		for i = 1, rndi(1, 3) do
			local pw, ph = rndi(6, 9), rndi(4, 6)
			local px = rndi(bx + 3, math.max(bx + 3, bx + bw - pw - 3))
			local py = rndi(by + 3, math.max(by + 3, by + bh - ph - 3))
			fill(px, py, px + pw - 1, py + ph - 1, DETAIL)
			fill(px, py, px + pw - 1, py, rgb(120, 124, 134))
		end
	elseif kind == 2 then
		-- 水箱
		local pw, ph = rndi(9, 13), rndi(8, 11)
		local px = rndi(bx + 4, math.max(bx + 4, bx + bw - pw - 4))
		local py = rndi(by + 4, math.max(by + 4, by + bh - ph - 4))
		fill(px, py, px + pw - 1, py + ph - 1, OUTLINE)
		fill(px + 1, py + 1, px + pw - 2, py + ph - 2, TANK)
		fill(px + 1, py + 1, px + pw - 2, py + 1, rgb(134, 124, 108))
	elseif kind == 3 then
		-- 太阳能板
		for i = 1, rndi(2, 4) do
			local pw, ph = rndi(7, 10), rndi(5, 7)
			local px = rndi(bx + 3, math.max(bx + 3, bx + bw - pw - 3))
			local py = rndi(by + 3, math.max(by + 3, by + bh - ph - 3))
			fill(px, py, px + pw - 1, py + ph - 1, SOLAR)
			fill(px, py, px + pw - 1, py, rgb(70, 92, 124))
		end
	elseif kind == 4 then
		-- 屋顶小花园
		local pw, ph = rndi(10, 18), rndi(8, 14)
		local px = rndi(bx + 3, math.max(bx + 3, bx + bw - pw - 3))
		local py = rndi(by + 3, math.max(by + 3, by + bh - ph - 3))
		fill(px, py, px + pw - 1, py + ph - 1, OUTLINE)
		fill(px + 1, py + 1, px + pw - 2, py + ph - 2, GARDEN)
		for i = 1, 6 do
			put(px + rndi(1, pw - 2), py + rndi(1, ph - 2), rgb(84, 118, 72))
		end
	elseif kind == 5 then
		-- 楼梯间 / 机房
		local pw, ph = rndi(10, 16), rndi(9, 13)
		local px = rndi(bx + 3, math.max(bx + 3, bx + bw - pw - 3))
		local py = rndi(by + 3, math.max(by + 3, by + bh - ph - 3))
		fill(px, py, px + pw - 1, py + ph - 1, OUTLINE)
		fill(px + 1, py + 1, px + pw - 2, py + ph - 2, rgb(78, 82, 92))
		fill(px + 1, py + 1, px + pw - 2, py + 1, ROOF_LIT)
		fill(px + pw - 4, py + ph - 4, px + pw - 3, py + ph - 2, DETAIL)
	end
end

local function building(bx, by, bw, bh)
	local roof = ROOFS[rndi(1, #ROOFS)]
	fill(bx, by, bx + bw - 1, by + bh - 1, roof)

	-- 轻微斑驳
	for i = 1, math.floor(bw * bh / 26) do
		put(bx + rndi(1, bw - 2), by + rndi(1, bh - 2),
			rnd() < 0.5 and rgb(64, 68, 78) or rgb(104, 108, 120))
	end

	-- 轮廓 + 受光边
	for x = bx, bx + bw - 1 do
		put(x, by, OUTLINE)
		put(x, by + 1, ROOF_LIT)
		put(x, by + bh - 1, OUTLINE)
	end
	for y = by, by + bh - 1 do
		put(bx, y, OUTLINE)
		put(bx + bw - 1, y, OUTLINE)
	end

	roof_props(bx + 2, by + 2, bw - 4, bh - 4)
end

for by = 0, H, BLOCK do
	for bx = 0, W, BLOCK do
		local count = (rnd() < 0.45) and 1 or 2
		local x = bx + rndi(1, 3)
		local y = by + rndi(1, 3)
		for i = 1, count do
			local w = math.floor((BLOCK - STREET - (count - 1) * 6) / count) - rndi(0, 4)
			local h = BLOCK - STREET - rndi(0, 16)
			building(x, y, math.max(w, 12), math.max(h, 12))
			x = x + w + 6
		end
	end
end

-- 街区之间的人行道边
for by = 0, H, BLOCK do
	for bx = 0, W, BLOCK do
		fill(bx, by + BLOCK - STREET, bx + BLOCK - 1, by + BLOCK - STREET + 1, SIDEWALK)
		fill(bx + BLOCK - STREET, by, bx + BLOCK - STREET + 1, by + BLOCK - 1, SIDEWALK)
	end
end

-- 路中线
for by = 0, H, BLOCK do
	local y = by + BLOCK - STREET + 6
	for x = 0, W - 1, 8 do put(x, y, LINE) end
end
for bx = 0, W, BLOCK do
	local x = bx + BLOCK - STREET + 6
	for y = 0, H - 1, 8 do put(x, y, LINE) end
end

---------------------------------------------------------------
-- 3) 起火冒烟（3 处）
---------------------------------------------------------------
-- 位置要落在平台外的四条边里（图片坐标 = 世界坐标 + 160）
local fires = {
	{ x = 74, y = 330 },    -- 左侧
	{ x = 726, y = 380 },   -- 右侧
	{ x = 300, y = 706 },   -- 下侧
	{ x = 420, y = 96 },    -- 上侧
}

for _, f in ipairs(fires) do
	for i = 1, 60 do
		local fx = f.x + rndi(-14, 14)
		local fy = f.y + rndi(-10, 10)
		local h = rndi(2, 6)
		for k = 0, h do
			local c = FIRE
			if k == 0 then c = FIRE_HOT elseif k >= h - 1 then c = FIRE_D end
			put(fx, fy - k, c)
			if rnd() < 0.4 then put(fx + 1, fy - k, c) end
		end
	end
	-- 烟柱
	local sx = f.x + rndi(-3, 3)
	for i = 0, 52 do
		local t = i / 52.0
		local cx = sx + math.floor(math.sin(t * 7.0) * 12.0)
		local cy = f.y - 16 - i * 2
		local r = 2 + math.floor(t * 8)
		for dy = -r, r do
			for dx = -r, r do
				if dx * dx + dy * dy <= r * r then
					local c = SMOKE
					if (dx + dy) % 3 == 0 then c = SMOKE_L end
					put(cx + dx, cy + dy, c)
				end
			end
		end
	end
end

-- 火光把周围照亮一点
for _, f in ipairs(fires) do
	for dy = -34, 34 do
		for dx = -34, 34 do
			local d = math.sqrt(dx * dx + dy * dy)
			if d <= 34 then
				local x, y = f.x + dx, f.y + dy
				local c = getc(x, y)
				if c ~= FIRE and c ~= FIRE_HOT and c ~= FIRE_D and c ~= SMOKE and c ~= SMOKE_L then
					local k = (1.0 - d / 34.0) * 0.42
					local cr, cg, cb = pc.rgbaR(c), pc.rgbaG(c), pc.rgbaB(c)
					local r = cr + (255 - cr) * k * 0.35
					local g = cg + (150 - cg) * k * 0.55
					local b = cb + (80 - cb) * k * 0.35
					put(x, y, rgb(math.floor(r), math.floor(g), math.floor(b)))
				end
			end
		end
	end
end

---------------------------------------------------------------
-- 4) 街上成群的僵尸
---------------------------------------------------------------
local function zombie(x, y)
	put(x, y, ZOMBIE)
	put(x, y + 1, ZOMBIE_D)
	if rnd() < 0.5 then put(x + 1, y, ZOMBIE_D) end
end

for i = 1, 70 do
	local gx = rndi(8, W - 8)
	local gy = rndi(8, H - 8)
	local n = rndi(8, 22)
	for k = 1, n do
		local zx = gx + rndi(-11, 11)
		local zy = gy + rndi(-9, 9)
		local base = getc(zx, zy)
		if base == ROAD or base == ROAD_D or base == SIDEWALK or base == LINE then
			zombie(zx, zy)
		end
	end
end

---------------------------------------------------------------
-- 5) 路灯
---------------------------------------------------------------
for i = 1, 22 do
	local lx = rndi(6, W - 6)
	local ly = rndi(6, H - 6)
	if getc(lx, ly) == ROAD or getc(lx, ly) == ROAD_D then
		put(lx, ly, LAMP)
		for dy = -5, 5 do
			for dx = -5, 5 do
				local d = dx * dx + dy * dy
				if d <= 25 and d > 3 then
					local c = getc(lx + dx, ly + dy)
					if c == ROAD or c == ROAD_D then put(lx + dx, ly + dy, rgb(58, 56, 54)) end
				end
			end
		end
	end
end

---------------------------------------------------------------
-- 6) 平台投影
---------------------------------------------------------------
for ring = 0, 4 do
	local prob = 1.0 - ring / 5.0
	local x0 = PLATFORM.x - ring * 2
	local y0 = PLATFORM.y - ring * 2
	local x1 = PLATFORM.x + PLATFORM.w + ring * 2
	local y1 = PLATFORM.y + PLATFORM.h + ring * 2
	for x = x0, x1 do
		if rnd() < prob then put(x, y0, rgb(16, 17, 21)) end
		if rnd() < prob then put(x, y1, rgb(16, 17, 21)) end
	end
	for y = y0, y1 do
		if rnd() < prob then put(x0, y, rgb(16, 17, 21)) end
		if rnd() < prob then put(x1, y, rgb(16, 17, 21)) end
	end
end
fill(PLATFORM.x, PLATFORM.y, PLATFORM.x + PLATFORM.w - 1, PLATFORM.y + PLATFORM.h - 1, rgb(14, 15, 19))

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "city"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs(OUT)
print(string.format("saved %s  %dx%d", OUT, W, H))
