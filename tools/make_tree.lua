-- make_tree.lua
-- 小街道绿化树：1×3 格（16x48），俯视/微侧视角，树冠 + 树干
-- 运行: Aseprite.exe -b --script tools/make_tree.lua

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE = rgb(34, 40, 28)
local LEAF_D  = rgb(46, 84, 46)
local LEAF    = rgb(62, 108, 58)
local LEAF_M  = rgb(84, 134, 70)
local LEAF_L  = rgb(112, 164, 84)
local LEAF_H  = rgb(146, 192, 106)
local TRUNK   = rgb(96, 66, 40)
local TRUNK_L = rgb(128, 92, 56)
local TRUNK_D = rgb(70, 46, 28)
local SOIL    = rgb(88, 66, 44)

local W, H = 16, 48

local img = Image(W, H, ColorMode.RGB)
img:clear(0)

local function put(x, y, c)
	if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end
local function get(x, y)
	if x < 0 or y < 0 or x >= W or y >= H then return nil end
	return img:getPixel(x, y)
end

-- 树干（下部）
for y = 30, 44 do
	for x = 6, 9 do
		local c = TRUNK
		if x == 6 then c = TRUNK_D elseif x == 9 then c = TRUNK_L end
		put(x, y, c)
	end
end
-- 树干上的纹路
put(7, 34, TRUNK_D)
put(8, 38, TRUNK_D)
put(7, 41, TRUNK_D)

-- 树根处的一小块土
for y = 43, 45 do
	for x = 4, 11 do
		if get(x, y) == 0 then put(x, y, SOIL) end
	end
end

-- 树冠：几个椭圆叠在一起
local function blob(cx, cy, rx, ry)
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			local nx = (x - cx) / rx
			local ny = (y - cy) / ry
			if nx * nx + ny * ny <= 1.0 and get(x, y) == 0 then
				-- 左上是亮面，右下是暗面
				local light = -nx * 0.7 - ny * 0.7
				local c = LEAF
				if light > 0.55 then c = LEAF_H
				elseif light > 0.2 then c = LEAF_L
				elseif light > -0.1 then c = LEAF_M
				elseif light > -0.5 then c = LEAF
				else c = LEAF_D end
				put(x, y, c)
			end
		end
	end
end

blob(7.5, 12.0, 7.0, 8.0)
blob(4.5, 18.0, 4.2, 5.0)
blob(11.5, 17.0, 4.2, 5.5)
blob(7.5, 22.0, 6.6, 6.0)
blob(5.0, 26.0, 4.0, 4.0)
blob(10.5, 26.5, 4.0, 4.0)

-- 树冠上的小亮点 / 深色缝隙
local spots = { { 5, 8 }, { 9, 6 }, { 11, 11 }, { 4, 14 }, { 8, 16 }, { 12, 15 }, { 6, 20 }, { 9, 24 } }
for _, s in ipairs(spots) do
	if get(s[1], s[2]) ~= 0 then put(s[1], s[2], LEAF_H) end
end
local dark = { { 7, 10 }, { 10, 9 }, { 5, 17 }, { 12, 19 }, { 8, 23 }, { 11, 25 }, { 6, 29 } }
for _, s in ipairs(dark) do
	if get(s[1], s[2]) ~= 0 then put(s[1], s[2], LEAF_D) end
end

-- 描边
local list = {}
for y = 0, H - 1 do
	for x = 0, W - 1 do
		if get(x, y) == 0 then
			local near = (get(x - 1, y) or 0) ~= 0 or (get(x + 1, y) or 0) ~= 0
				or (get(x, y - 1) or 0) ~= 0 or (get(x, y + 1) or 0) ~= 0
			if near then table.insert(list, { x, y }) end
		end
	end
end
for _, p in ipairs(list) do put(p[1], p[2], OUTLINE) end

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "tree"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs("C:/game/test/assets/base/tree.aseprite")
print("saved tree")
