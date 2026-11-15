-- make_resources.lua
-- 掉落资源：布料（3/4 视角的布堆：顶面 + 两个侧面 + 折层线）、绳子（盘绳）
-- 运行: Aseprite.exe -b --script tools/make_resources.lua

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE = rgb(40, 36, 32)
-- 布（顶面很亮，侧面逐层变暗）
local C_TOP  = rgb(246, 242, 230)
local C_TOP2 = rgb(226, 220, 204)
local C_R    = rgb(196, 190, 170)   -- 右侧面
local C_R2   = rgb(172, 165, 145)
local C_L    = rgb(178, 171, 150)   -- 左侧面
local C_L2   = rgb(150, 143, 122)
local C_LINE = rgb(126, 119, 100)   -- 折层分界
-- 绳子
local ROPE   = rgb(196, 152, 88)
local ROPE_L = rgb(228, 190, 126)
local ROPE_D = rgb(150, 108, 58)

local W, H = 16, 16

local function new_image()
	local img = Image(W, H, ColorMode.RGB)
	img:clear(0)
	return img
end

local function put(img, x, y, c)
	if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end
local function get(img, x, y)
	if x < 0 or y < 0 or x >= W or y >= H then return nil end
	return img:getPixel(x, y)
end

-- 凸多边形填充（扫描线）
local function poly(img, pts, color, shade_fn)
	local miny, maxy = 1e9, -1e9
	for _, p in ipairs(pts) do
		if p[2] < miny then miny = p[2] end
		if p[2] > maxy then maxy = p[2] end
	end
	for y = math.floor(miny), math.ceil(maxy) do
		local xs = {}
		for i = 1, #pts do
			local a = pts[i]
			local b = pts[i % #pts + 1]
			if (a[2] <= y and b[2] > y) or (b[2] <= y and a[2] > y) then
				local t = (y - a[2]) / (b[2] - a[2])
				table.insert(xs, a[1] + (b[1] - a[1]) * t)
			end
		end
		table.sort(xs)
		for i = 1, #xs - 1, 2 do
			for x = math.floor(xs[i] + 0.5), math.floor(xs[i + 1] + 0.5) do
				local c = color
				if shade_fn then c = shade_fn(x, y) or color end
				put(img, x, y, c)
			end
		end
	end
end

local function outline(img)
	local list = {}
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			if get(img, x, y) == 0 then
				local near = (get(img, x - 1, y) or 0) ~= 0 or (get(img, x + 1, y) or 0) ~= 0
					or (get(img, x, y - 1) or 0) ~= 0 or (get(img, x, y + 1) or 0) ~= 0
				if near then table.insert(list, { x, y }) end
			end
		end
	end
	for _, p in ipairs(list) do put(img, p[1], p[2], OUTLINE) end
end

local function save(img, path)
	local spr = Sprite(W, H, ColorMode.RGB)
	spr.layers[1].name = "res"
	spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
	spr:saveAs(path)
	print("saved " .. path)
end

-- ================= 布料 =================
-- 一个扁扁的布堆：顶面（平行四边形）+ 左前面 + 右前面
local cloth = new_image()

local A = { 1.5, 5.5 }    -- 左
local B = { 8.0, 2.0 }    -- 上
local C = { 14.0, 5.5 }   -- 右
local D = { 7.5, 9.0 }    -- 下（靠近观察者）
local DH = 3.0             -- 厚度

-- 右前面（A-C 那侧的下面）
local Cr = { C[1], C[2] + DH }
local Dr = { D[1], D[2] + DH }
-- 左前面
local Dl = { D[1], D[2] + DH }
local Al = { A[1], A[2] + DH }

-- 侧面
poly(cloth, { D, C, Cr, Dr }, C_R, function(x, y)
	-- 一层层往里，越靠下越暗
	local band = math.floor((y - D[2]) / 1.4) % 2
	return band == 0 and C_R or C_R2
end)
poly(cloth, { A, D, Dl, Al }, C_L, function(x, y)
	local band = math.floor((y - D[2]) / 1.4) % 2
	return band == 0 and C_L or C_L2
end)

-- 顶面
poly(cloth, { A, B, C, D }, C_TOP)

-- 顶面上的一点明暗：靠右下压暗
for y = 0, H - 1 do
	for x = 0, W - 1 do
		if get(cloth, x, y) == C_TOP then
			if (x + y) > 17 then put(cloth, x, y, C_TOP2) end
		end
	end
end

-- 顶面的折痕：从中线往下的一道暗线
local fx = A[1] + (B[1] - A[1]) * 0.5
local fy = A[2] + (B[2] - A[2]) * 0.5
local gx = D[1] + (C[1] - D[1]) * 0.35
local gy = D[2] + (C[2] - D[2]) * 0.35
for i = 0, 5 do
	local t = i / 5.0
	put(cloth, math.floor(fx + (gx - fx) * t + 0.5), math.floor(fy + (gy - fy) * t + 0.5), C_TOP2)
end

-- 侧面的折层分界线（横着两条）
for x = 2, 14 do
	put(cloth, x, math.floor(D[2] + 1.0), C_LINE)
	put(cloth, x, math.floor(D[2] + 2.0), C_LINE)
end

outline(cloth)
save(cloth, "C:/game/test/assets/base/cloth.aseprite")

-- ================= 绳子 =================
local rope = new_image()

local function ring(cx, cy, rx, ry, thick)
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local nx = (x - cx) / rx
			local ny = (y - cy) / ry
			local d = math.sqrt(nx * nx + ny * ny)
			if d > 1.0 - thick and d <= 1.0 then
				local c = ROPE
				if nx + ny < -0.25 then c = ROPE_L elseif nx + ny > 0.45 then c = ROPE_D end
				put(rope, x, y, c)
			end
		end
	end
end

ring(7.5, 7.0, 4.6, 3.4, 0.30)
ring(6.0, 8.6, 4.8, 3.6, 0.30)

local marks = { { 8, 3 }, { 11, 6 }, { 9, 11 }, { 4, 10 }, { 2, 7 }, { 5, 4 } }
for _, m in ipairs(marks) do
	if get(rope, m[1], m[2]) ~= 0 then put(rope, m[1], m[2], ROPE_D) end
end

put(rope, 10, 11, ROPE_L)
put(rope, 11, 12, ROPE)
put(rope, 12, 12, ROPE_L)
put(rope, 13, 13, ROPE_D)

outline(rope)
save(rope, "C:/game/test/assets/base/rope.aseprite")


-- ================= 石头 =================
local ROCK_L = rgb(186, 188, 194)
local ROCK   = rgb(146, 148, 156)
local ROCK_D = rgb(108, 110, 118)
local ROCK_DD= rgb(80, 82, 90)

local function ellipse(img, cx, cy, rx, ry, color, shade)
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local nx = (x - cx) / rx
			local ny = (y - cy) / ry
			if nx * nx + ny * ny <= 1.0 then
				local c = color
				if shade then c = shade(x, y, nx, ny) or color end
				if get(img, x, y) == 0 then put(img, x, y, c) end
			end
		end
	end
end

local stone = new_image()
-- 大石头
ellipse(stone, 7.0, 9.5, 5.2, 4.2, ROCK, function(x, y, nx, ny)
	if nx + ny < -0.5 then return ROCK_L end
	if nx + ny > 0.55 then return ROCK_D end
	return ROCK
end)
-- 小石头
ellipse(stone, 12.0, 10.5, 3.0, 2.4, ROCK, function(x, y, nx, ny)
	if nx + ny < -0.3 then return ROCK_L end
	if nx + ny > 0.5 then return ROCK_D end
	return ROCK
end)
-- 石头上的一点裂纹/高光
put(stone, 5, 7, ROCK_L)
put(stone, 6, 6, ROCK_L)
put(stone, 9, 11, ROCK_DD)
put(stone, 11, 10, ROCK_DD)
put(stone, 12, 9, ROCK_L)
-- 地上的碎渣
put(stone, 2, 13, ROCK_D)
put(stone, 14, 13, ROCK_D)
outline(stone)
save(stone, "C:/game/test/assets/base/stone.aseprite")

-- ================= 木头 =================
local WOOD_L  = rgb(198, 146, 92)
local WOOD    = rgb(160, 112, 64)
local WOOD_D  = rgb(122, 82, 44)
local BARK    = rgb(96, 62, 34)
local RING    = rgb(206, 168, 118)

local wood = new_image()
-- 下面那根（横躺）
for y = 8, 12 do
	for x = 1, 12 do
		local c = WOOD
		if y == 8 then c = WOOD_L elseif y == 12 then c = WOOD_D end
		put(wood, x, y, c)
	end
end
-- 左端断面
for y = 8, 12 do
	for x = 1, 3 do
		put(wood, x, y, BARK)
	end
end
put(wood, 2, 10, RING)
put(wood, 3, 9, RING)
put(wood, 3, 11, RING)
-- 树皮纹理
for x = 4, 12 do
	put(wood, x, 10, WOOD_D)
end
-- 上面那根（斜着叠）
for y = 3, 7 do
	for x = 4, 14 do
		local c = WOOD
		if y == 3 then c = WOOD_L elseif y == 7 then c = WOOD_D end
		put(wood, x, y, c)
	end
end
for y = 3, 7 do
	for x = 12, 14 do
		put(wood, x, y, BARK)
	end
end
put(wood, 13, 5, RING)
put(wood, 12, 4, RING)
put(wood, 12, 6, RING)
for x = 5, 11 do
	put(wood, x, 5, WOOD_D)
end
outline(wood)
save(wood, "C:/game/test/assets/base/wood.aseprite")
