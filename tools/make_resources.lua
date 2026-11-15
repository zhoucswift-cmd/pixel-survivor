-- make_resources.lua
-- 掉落资源：布料 16x16、绳子 16x16
-- 运行: Aseprite.exe -b --script tools/make_resources.lua

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE = rgb(48, 40, 34)
-- 布料
local CLOTH   = rgb(232, 226, 208)
local CLOTH_L = rgb(250, 246, 234)
local CLOTH_D = rgb(188, 180, 160)
local CLOTH_DD = rgb(150, 142, 124)
-- 绳子
local ROPE    = rgb(186, 140, 78)
local ROPE_L  = rgb(214, 172, 108)
local ROPE_D  = rgb(136, 98, 50)

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

-- 自动描边
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

-- ===== 布料：叠起来的布 =====
local cloth = new_image()
-- 下层布（大一点，被压着）
fill(cloth, 3, 8, 13, 13, CLOTH_D)
fill(cloth, 3, 8, 13, 9, CLOTH)
-- 上层布（叠角）
fill(cloth, 4, 4, 12, 11, CLOTH)
fill(cloth, 4, 4, 12, 4, CLOTH_L)
fill(cloth, 4, 11, 12, 11, CLOTH_D)
-- 折痕
fill(cloth, 6, 5, 6, 10, CLOTH_D)
fill(cloth, 9, 5, 9, 10, CLOTH_D)
put(cloth, 10, 6, CLOTH_L)
-- 布角翻起来一点
fill(cloth, 11, 4, 12, 6, CLOTH_L)
put(cloth, 12, 5, CLOTH_DD)
outline(cloth)
save(cloth, "C:/game/test/assets/base/cloth.aseprite")

-- ===== 绳子：盘起来的一卷 =====
local rope = new_image()
-- 外圈
for a = 0, 359 do
	local rad = math.rad(a)
	local x = 3 + math.cos(rad) * 5.0
	local y = 8 + math.sin(rad) * 4.2
	put(rope, math.floor(x + 0.5), math.floor(y + 0.5), ROPE)
end
-- 里圈
for a = 0, 359 do
	local rad = math.rad(a)
	local x = 3 + math.cos(rad) * 3.0
	local y = 8 + math.sin(rad) * 2.4
	put(rope, math.floor(x + 0.5), math.floor(y + 0.5), ROPE_D)
end
-- 绳股高光（右上）
for a = 200, 340 do
	local rad = math.rad(a)
	local x = 3 + math.cos(rad) * 5.0
	local y = 8 + math.sin(rad) * 4.2
	put(rope, math.floor(x + 0.5), math.floor(y + 0.5), ROPE_L)
end
-- 绳头（往右下甩出去）
fill(rope, 8, 11, 11, 12, ROPE)
put(rope, 11, 12, ROPE_L)
put(rope, 12, 13, ROPE_D)
outline(rope)
save(rope, "C:/game/test/assets/base/rope.aseprite")
