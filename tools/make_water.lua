-- make_water.lua
-- 消防栓的水花（32x32，4 帧）和地面水洼（48x48，4 帧）
-- 运行: Aseprite.exe -b --script tools/make_water.lua

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

-- 水的配色
local WATER      = rgb(74, 154, 208, 205)
local WATER_D    = rgb(44, 110, 168, 215)
local WATER_L    = rgb(126, 200, 240, 200)
local FOAM       = rgb(236, 250, 255, 235)
local FOAM_D     = rgb(196, 234, 250, 225)

local seed = 12345
local function rnd()
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648
end

local function new_image(w, h)
	local img = Image(w, h, ColorMode.RGBA)
	img:clear(0)
	return img
end

local function put(img, x, y, c)
	local w, h = img.width, img.height
	if x >= 0 and y >= 0 and x < w and y < h then img:putPixel(x, y, c) end
end

local function fill(img, x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(img, x, y, c) end end
end

-- ================= 水花 =================
local SW, SH = 32, 32
local spray_frames = {}

-- 每帧：水柱 + 四散的水滴
local drops = {}
for i = 1, 26 do
	drops[i] = {
		ang = rnd() * math.pi * 2,
		spd = 0.6 + rnd() * 1.4,
		size = 1 + math.floor(rnd() * 2),
	}
end

for f = 1, 4 do
	local img = new_image(SW, SH)
	local cx, cy = SW / 2 - 0.5, SH - 6

	-- 中间的水柱：越高越窄，最后一帧散掉
	local plume_h = 10 + f * 3
	for y = cy, cy - plume_h, -1 do
		local t = (cy - y) / plume_h
		local half = math.floor(3 * (1 - t * 0.7))
		local c = (t < 0.35) and FOAM or WATER_L
		for x = cx - half, cx + half do
			put(img, x, y, c)
		end
	end
	-- 顶部水沫
	local tip_y = cy - plume_h
	fill(img, cx - 2, tip_y - 1, cx + 2, tip_y, FOAM)
	put(img, cx - 3, tip_y + 1, FOAM_D)
	put(img, cx + 3, tip_y + 1, FOAM_D)

	-- 四周飞溅的水滴
	for i, d in ipairs(drops) do
		local dist = d.spd * f * 4.5
		local dx = math.cos(d.ang) * dist
		local dy = math.sin(d.ang) * dist * 0.6 - 6    -- 往上抛
		local px = math.floor(cx + dx)
		local py = math.floor(cy + dy + f * f * 0.7)   -- 落回地面
		local c = d.size == 1 and WATER_L or FOAM_D
		put(img, px, py, c)
		if d.size > 1 then put(img, px + 1, py, WATER) end
		-- 早期的拖尾
		if f <= 2 then put(img, px, py + 2, WATER) end
	end
	table.insert(spray_frames, img)
end

-- ================= 地面水洼 =================
local PW, PH = 48, 48
local puddle_frames = {}
local pcx, pcy = PW / 2 - 0.5, PH / 2 - 0.5
local rx, ry = 22, 17

for f = 1, 4 do
	local img = new_image(PW, PH)

	-- 不规则的水面（边缘有点波动）
	for y = 0, PH - 1 do
		for x = 0, PW - 1 do
			local nx = (x - pcx) / rx
			local ny = (y - pcy) / ry
			local d = nx * nx + ny * ny
			local wob = 0.08 * math.sin(math.atan(y - pcy, x - pcx) * 5 + f)
			if d <= 1 + wob then
				local edge = d > 0.82
				local c = edge and WATER_D or WATER
				-- 内侧一点高光
				if not edge and d > 0.62 and d < 0.72 then c = WATER_L end
				put(img, x, y, c)
			end
		end
	end

	-- 涟漪：随帧向外扩的环
	local ring_r = 0.25 + f * 0.18
	for a = 0, 360, 3 do
		local rad = math.rad(a)
		local x = math.floor(pcx + math.cos(rad) * rx * ring_r)
		local y = math.floor(pcy + math.sin(rad) * ry * ring_r)
		put(img, x, y, WATER_L)
		put(img, x, y - 1, FOAM_D)
	end

	-- 几个溅起的小泡沫
	for i = 1, 6 do
		local a = i * 1.1 + f * 0.6
		local rr = 0.35 + (i % 3) * 0.18
		local x = math.floor(pcx + math.cos(a) * rx * rr)
		local y = math.floor(pcy + math.sin(a) * ry * rr)
		put(img, x, y, FOAM_D)
	end
	table.insert(puddle_frames, img)
end

-- ================= 存盘 =================
local function save_strip(frames, w, h, path)
	local spr = Sprite(w, h, ColorMode.RGBA)
	spr.layers[1].name = "water"
	for i, frame_img in ipairs(frames) do
		local fr = spr.frames[1]
		if i > 1 then fr = spr:newEmptyFrame(#spr.frames + 1) end
		spr:newCel(spr.layers[1], fr, frame_img, Point(0, 0))
	end
	spr:saveAs(path)
	print(string.format("saved %s  %dx%d  frames=%d", path, w, h, #frames))
end

save_strip(spray_frames, SW, SH, "C:/game/test/assets/base/water_spray.aseprite")
save_strip(puddle_frames, PW, PH, "C:/game/test/assets/base/water_puddle.aseprite")
