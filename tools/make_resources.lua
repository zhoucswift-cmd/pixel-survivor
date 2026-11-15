-- make_resources.lua
-- 掉落资源：布料（叠好的布，带缝线）16x16、绳子（盘好的绳卷）16x16
-- 运行: Aseprite.exe -b --script tools/make_resources.lua

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE = rgb(48, 40, 34)

-- 布料（亚麻布）
local CLOTH   = rgb(228, 216, 190)
local CLOTH_L = rgb(248, 242, 222)
local CLOTH_D = rgb(196, 182, 152)
local CLOTH_DD = rgb(158, 144, 114)

-- 绳子（麻绳）
local ROPE    = rgb(196, 152, 88)
local ROPE_L  = rgb(228, 190, 126)
local ROPE_D  = rgb(150, 108, 58)

local function new_image()
	local img = Image(16, 16, ColorMode.RGB)
	img:clear(0)
	return img
end

local function put(img, x, y, c)
	if x >= 0 and y >= 0 and x < 16 and y < 16 then img:putPixel(x, y, c) end
end
local function get(img, x, y)
	if x < 0 or y < 0 or x >= 16 or y >= 16 then return nil end
	return img:getPixel(x, y)
end
local function fill(img, x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(img, x, y, c) end end
end

local function outline(img)
	local list = {}
	for y = 0, 15 do
		for x = 0, 15 do
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
	local spr = Sprite(16, 16, ColorMode.RGB)
	spr.layers[1].name = "res"
	spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
	spr:saveAs(path)
	print("saved " .. path)
end

-- ================= 布料 =================
-- 一块摊开的布：边缘有点波浪（用角度扰动），左上受光、右下压暗，中间两道折痕
local cloth = new_image()
local cx, cy = 7.5, 7.5
local rx, ry = 5.2, 4.6

for y = 0, 15 do
	for x = 0, 15 do
		local nx = (x - cx) / rx
		local ny = (y - cy) / ry
		local ang = math.atan(ny, nx)
		-- 波浪边界：让布边不是死板的方形
		local edge = 1.0 + 0.10 * math.sin(ang * 3.0 + 0.6) + 0.05 * math.sin(ang * 5.0 + 2.1)
		local d = math.sqrt(nx * nx + ny * ny)
		if d <= edge then
			local c = CLOTH
			local lit = -(nx * 0.7 + ny * 0.7)          -- 左上亮
			if lit > 0.35 then c = CLOTH_L
			elseif lit < -0.30 then c = CLOTH_D
			elseif lit < -0.62 then c = CLOTH_DD end
			put(cloth, x, y, c)
		end
	end
end

-- 两道折痕（斜线，旁边带一点高光）
local fx, fy = 4, 6
while fx <= 7 do
	put(cloth, fx, fy, CLOTH_D)
	put(cloth, fx, fy + 1, CLOTH_L)
	fx = fx + 1
	fy = fy + 1
end
local gx, gy = 9, 4
while gx <= 11 do
	put(cloth, gx, gy, CLOTH_D)
	put(cloth, gx, gy + 1, CLOTH_L)
	gx = gx + 1
	gy = gy + 1
end

-- 底部卷边（布的一层褶）
for x = 4, 10 do
	put(cloth, x, 11, CLOTH_DD)
end
for x = 5, 11 do
	put(cloth, x, 12, CLOTH_D)
end

outline(cloth)
save(cloth, "C:/game/test/assets/base/cloth.aseprite")

-- ================= 绳子 =================
-- 盘绳：两圈错开的环叠在一起（像随手盘的一坨），圈上有扭股暗纹，右下甩绳头
local rope = new_image()

local function ring(cx, cy, rx, ry, thick)
	for y = 0, 15 do
		for x = 0, 15 do
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

-- 后面一圈（偏右上），前面一圈（偏左下）
ring(7.5, 7.0, 4.6, 3.4, 0.30)
ring(6.0, 8.6, 4.8, 3.6, 0.30)

-- 扭股暗纹：在环上撒几段短斜线
local marks = {
	{ 8, 3 }, { 11, 6 }, { 9, 11 }, { 4, 10 }, { 2, 7 }, { 5, 4 },
}
for _, m in ipairs(marks) do
	if get(rope, m[1], m[2]) ~= 0 then
		put(rope, m[1], m[2], ROPE_D)
	end
end

-- 绳头（右下，从盘里抽出来）
put(rope, 10, 11, ROPE_L)
put(rope, 11, 12, ROPE)
put(rope, 12, 12, ROPE_L)
put(rope, 13, 13, ROPE_D)

outline(rope)
save(rope, "C:/game/test/assets/base/rope.aseprite")
