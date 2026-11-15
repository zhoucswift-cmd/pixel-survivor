-- make_shirt_icon.lua
-- 衣服图标：16x16，白色底（游戏里用 modulate 染成各种颜色）
-- 运行: Aseprite.exe -b --script tools/make_shirt_icon.lua

local OUT = "C:/game/test/assets/base/shirt.aseprite"
local W, H = 16, 16

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE = rgb(38, 34, 40)
local WHITE   = rgb(255, 255, 255)
local SHADE   = rgb(196, 196, 200)
local SHADE2  = rgb(160, 160, 166)

local img = Image(W, H, ColorMode.RGB)
img:clear(0)

local function put(x, y, c)
	if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end
local function fill(x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(x, y, c) end end
end

-- 衣身
fill(4, 4, 11, 13, WHITE)
-- 袖子（左右）
fill(2, 4, 4, 7, WHITE)
fill(11, 4, 13, 7, WHITE)
-- 领口
fill(6, 4, 9, 5, SHADE)
fill(7, 4, 8, 4, SHADE2)
-- 阴影（右下）
fill(10, 5, 11, 13, SHADE)
fill(4, 12, 11, 13, SHADE)
fill(12, 6, 13, 7, SHADE2)
-- 中间一道折痕
fill(7, 7, 7, 11, SHADE)

-- 描边
local list = {}
for y = 0, H - 1 do
	for x = 0, W - 1 do
		if img:getPixel(x, y) == 0 then
			local function nz(nx, ny)
				if nx < 0 or ny < 0 or nx >= W or ny >= H then return false end
				return img:getPixel(nx, ny) ~= 0
			end
			if nz(x - 1, y) or nz(x + 1, y) or nz(x, y - 1) or nz(x, y + 1) then
				table.insert(list, { x, y })
			end
		end
	end
end
for _, p in ipairs(list) do put(p[1], p[2], OUTLINE) end

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "shirt"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs(OUT)
print(string.format("saved %s  %dx%d", OUT, W, H))
