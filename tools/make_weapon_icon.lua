-- make_weapon_icon.lua
-- 生成武器图标：20x20 的霰弹枪（和角色手里那把同配色），给武器轮盘用
-- 运行: Aseprite.exe -b --script tools/make_weapon_icon.lua

local OUT = "C:/game/test/assets/ui/shotgun_icon.aseprite"
local W, H = 20, 20

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE = rgb(26, 22, 38)
local METAL   = rgb(112, 118, 130)
local METAL_L = rgb(158, 166, 180)
local METAL_D = rgb(64, 68, 82)
local WOOD    = rgb(146, 96, 56)
local WOOD_D  = rgb(102, 64, 38)

local function put(img, x, y, c)
  if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end

local function fill(img, x0, y0, x1, y1, c)
  for y = y0, y1 do for x = x0, x1 do put(img, x, y, c) end end
end

local function hline(img, x0, x1, y, c) fill(img, x0, y, x1, y, c) end

local img = Image(W, H, ColorMode.RGB)
img:clear(0)

-- 枪托（左，带一点斜角）
fill(img, 2, 9, 5, 11, WOOD)
fill(img, 1, 10, 2, 12, WOOD_D)
put(img, 3, 9, WOOD_D)

-- 机匣
fill(img, 5, 8, 9, 10, METAL)
hline(img, 5, 9, 8, METAL_L)
hline(img, 5, 9, 10, METAL_D)

-- 枪管
fill(img, 9, 8, 18, 9, METAL_D)
hline(img, 9, 18, 8, METAL)
-- 枪口
fill(img, 17, 7, 18, 10, METAL_D)
hline(img, 17, 18, 7, METAL_L)

-- 护木
fill(img, 11, 10, 15, 11, WOOD)
hline(img, 11, 15, 11, WOOD_D)

-- 扳机护圈
put(img, 7, 11, METAL_D)
put(img, 8, 11, METAL_D)
put(img, 7, 12, METAL_D)

-- 自动描边
local snapshot = {}
for y = 0, H - 1 do
  snapshot[y] = {}
  for x = 0, W - 1 do snapshot[y][x] = img:getPixel(x, y) end
end
for y = 0, H - 1 do
  for x = 0, W - 1 do
    if snapshot[y][x] == 0 then
      local near = false
      for dy = -1, 1 do
        for dx = -1, 1 do
          local nx, ny = x + dx, y + dy
          if nx >= 0 and ny >= 0 and nx < W and ny < H and snapshot[ny][nx] ~= 0 then
            near = true
          end
        end
      end
      if near then img:putPixel(x, y, OUTLINE) end
    end
  end
end

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "icon"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs(OUT)
print(string.format("saved %s  %dx%d", OUT, W, H))
