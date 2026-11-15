-- make_benches.lua
-- 三个工作台（俯视 32x16）：工具与武器台 / 服装台 / 木工台
-- 运行: Aseprite.exe -b --script tools/make_benches.lua

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE = rgb(40, 30, 26)
local WOOD    = rgb(150, 100, 58)
local WOOD_L  = rgb(186, 132, 82)
local WOOD_D  = rgb(110, 70, 40)
local WOOD_DD = rgb(84, 52, 30)
local METAL   = rgb(156, 162, 174)
local METAL_D = rgb(100, 106, 118)
local METAL_L = rgb(214, 220, 230)
local STEEL   = rgb(126, 132, 146)
local CLOTH_C = rgb(196, 96, 96)
local CLOTH_B = rgb(96, 132, 196)
local CLOTH_G = rgb(96, 156, 110)
local PAPER   = rgb(228, 224, 206)
local BLACK   = rgb(48, 46, 54)

local W, H = 32, 16

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
local function fill(img, x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(img, x, y, c) end end
end

-- 桌面（三张台子共用）
local function table_top(img, tone)
	local base = tone or WOOD
	fill(img, 1, 1, 30, 13, base)
	fill(img, 1, 1, 30, 1, WOOD_L)
	fill(img, 1, 1, 1, 13, WOOD_L)
	fill(img, 1, 13, 30, 13, WOOD_D)
	fill(img, 30, 1, 30, 13, WOOD_D)
	-- 板缝
	fill(img, 2, 5, 29, 5, WOOD_D)
	fill(img, 2, 9, 29, 9, WOOD_D)
	put(img, 8, 5, WOOD_L)
	put(img, 20, 9, WOOD_L)
	-- 前沿厚度
	fill(img, 1, 14, 30, 14, WOOD_DD)
end

local function outline(img)
	local list = {}
	for y = 0, H - 1 do
		for x = 0, W - 1 do
			if get(img, x, y) == 0 then
				local function nz(nx, ny)
					if nx < 0 or ny < 0 or nx >= W or ny >= H then return false end
					return get(img, nx, ny) ~= 0
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
	spr.layers[1].name = "bench"
	spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
	spr:saveAs(path)
	print("saved " .. path)
end

-- ============ 1. 工具与武器台 ============
local tool = new_image()
table_top(tool)
-- 台虎钳（左）
fill(tool, 3, 2, 8, 6, METAL_D)
fill(tool, 4, 3, 7, 5, METAL)
fill(tool, 4, 3, 7, 3, METAL_L)
put(tool, 5, 4, METAL_D)
put(tool, 6, 4, METAL_D)
-- 锤子（中上）
fill(tool, 12, 3, 16, 4, WOOD_D)
put(tool, 13, 3, WOOD_L)
fill(tool, 17, 2, 19, 5, METAL_D)
fill(tool, 17, 3, 19, 4, METAL)
put(tool, 18, 3, METAL_L)
-- 扳手（右上）
fill(tool, 22, 3, 27, 4, METAL_D)
fill(tool, 22, 3, 26, 3, METAL)
put(tool, 21, 2, METAL_D)
put(tool, 21, 5, METAL_D)
put(tool, 28, 2, METAL_D)
put(tool, 28, 5, METAL_D)
-- 锯子（下方）
fill(tool, 4, 10, 14, 10, METAL)
fill(tool, 4, 11, 14, 11, METAL_D)
fill(tool, 15, 10, 18, 11, WOOD_D)
put(tool, 16, 10, WOOD_L)
-- 几颗钉子
put(tool, 21, 10, METAL_L)
put(tool, 23, 11, METAL)
put(tool, 25, 9, METAL_L)
outline(tool)
save(tool, "C:/game/test/assets/base/toolbench.aseprite")

-- ============ 2. 服装台 ============
local cloth = new_image()
table_top(cloth)
-- 缝纫机（左）
fill(cloth, 3, 2, 10, 6, BLACK)
fill(cloth, 4, 3, 9, 4, rgb(72, 70, 82))
fill(cloth, 4, 5, 6, 6, METAL_D)
fill(cloth, 8, 5, 9, 6, METAL_L)
put(cloth, 9, 6, METAL_L)
-- 布卷（右上，三色）
fill(cloth, 20, 2, 28, 5, CLOTH_B)
fill(cloth, 20, 2, 28, 2, rgb(126, 160, 220))
fill(cloth, 20, 6, 28, 7, CLOTH_C)
fill(cloth, 20, 6, 28, 6, rgb(220, 130, 130))
fill(cloth, 20, 8, 26, 9, CLOTH_G)
fill(cloth, 20, 8, 26, 8, rgb(126, 186, 140))
-- 剪刀（下中）
fill(cloth, 7, 11, 12, 11, METAL_L)
put(cloth, 6, 10, METAL_D)
put(cloth, 13, 10, METAL_D)
put(cloth, 6, 12, METAL_D)
put(cloth, 13, 12, METAL_D)
-- 线轴
fill(cloth, 15, 10, 16, 12, WOOD_D)
fill(cloth, 15, 11, 16, 11, CLOTH_C)
-- 图纸
fill(cloth, 3, 10, 5, 12, PAPER)
outline(cloth)
save(cloth, "C:/game/test/assets/base/clothingbench.aseprite")

-- ============ 3. 木工台 ============
local wood = new_image()
table_top(wood)
-- 木料堆（左上，板条）
fill(wood, 3, 2, 14, 3, WOOD_L)
fill(wood, 3, 4, 13, 5, WOOD)
fill(wood, 4, 6, 12, 7, WOOD_D)
put(wood, 5, 2, WOOD)
put(wood, 9, 4, WOOD_L)
-- 锯子（右）
fill(wood, 19, 3, 28, 3, METAL)
fill(wood, 19, 4, 28, 4, METAL_D)
fill(wood, 17, 2, 19, 4, WOOD_D)
put(wood, 18, 2, WOOD_L)
-- 卷尺 / 铅笔
fill(wood, 4, 10, 12, 11, rgb(220, 196, 90))
fill(wood, 4, 10, 12, 10, rgb(238, 220, 130))
put(wood, 11, 10, BLACK)
fill(wood, 20, 10, 26, 10, rgb(212, 160, 60))
put(wood, 21, 10, BLACK)
-- 木屑
put(wood, 16, 8, WOOD_L)
put(wood, 18, 9, WOOD_L)
put(wood, 15, 12, WOOD)
outline(wood)
save(wood, "C:/game/test/assets/base/carpentrybench.aseprite")
