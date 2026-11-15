-- make_equip_icons.lua
-- 装备图标：衣服 / 裤子 / 靴子，16x16 白色底（游戏里用 modulate 染色）
-- 运行: Aseprite.exe -b --script tools/make_equip_icons.lua

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE = rgb(38, 34, 40)
local WHITE   = rgb(255, 255, 255)
local SHADE   = rgb(198, 198, 204)
local SHADE2  = rgb(160, 160, 168)

local W, H = 16, 16

local function new_image()
	local img = Image(W, H, ColorMode.RGB)
	img:clear(0)
	return img
end

local function put(img, x, y, c)
	if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end
local function fill(img, x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(img, x, y, c) end end
end

local function outline(img)
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
	for _, p in ipairs(list) do put(img, p[1], p[2], OUTLINE) end
end

local function save(img, path)
	local spr = Sprite(W, H, ColorMode.RGB)
	spr.layers[1].name = "icon"
	spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
	spr:saveAs(path)
	print("saved " .. path)
end

-- ===== 上衣 =====
local shirt = new_image()
fill(shirt, 4, 4, 11, 13, WHITE)
fill(shirt, 2, 4, 4, 7, WHITE)
fill(shirt, 11, 4, 13, 7, WHITE)
fill(shirt, 6, 4, 9, 5, SHADE)
fill(shirt, 7, 4, 8, 4, SHADE2)
fill(shirt, 10, 5, 11, 13, SHADE)
fill(shirt, 4, 12, 11, 13, SHADE)
fill(shirt, 12, 6, 13, 7, SHADE2)
fill(shirt, 7, 7, 7, 11, SHADE)
outline(shirt)
save(shirt, "C:/game/test/assets/base/icon_shirt.aseprite")

-- ===== 裤子 =====
local pants = new_image()
fill(pants, 3, 3, 12, 5, WHITE)      -- 腰
fill(pants, 3, 5, 7, 13, WHITE)      -- 左腿
fill(pants, 8, 5, 12, 13, WHITE)     -- 右腿
fill(pants, 3, 3, 12, 3, SHADE)
fill(pants, 3, 5, 3, 13, SHADE)
fill(pants, 7, 5, 7, 13, SHADE2)
fill(pants, 12, 5, 12, 13, SHADE2)
fill(pants, 4, 12, 7, 13, SHADE)
fill(pants, 9, 12, 12, 13, SHADE)
outline(pants)
save(pants, "C:/game/test/assets/base/icon_pants.aseprite")

-- ===== 靴子 =====
local boots = new_image()
fill(boots, 4, 2, 8, 10, WHITE)      -- 靴筒
fill(boots, 4, 9, 12, 13, WHITE)     -- 靴面
fill(boots, 4, 2, 8, 2, SHADE)
fill(boots, 4, 2, 4, 13, SHADE)
fill(boots, 8, 3, 8, 9, SHADE2)
fill(boots, 4, 13, 12, 13, SHADE2)
fill(boots, 10, 10, 12, 12, SHADE)
outline(boots)
save(boots, "C:/game/test/assets/base/icon_boots.aseprite")
