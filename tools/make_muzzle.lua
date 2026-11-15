-- make_muzzle.lua
-- 生成 24x24 的霰弹枪枪口火焰序列（3 帧：爆闪 / 收缩 / 硝烟）
-- 运行: Aseprite.exe -b --script tools/make_muzzle.lua

local OUT = "C:/game/test/assets/muzzle_flash.aseprite"
local W, H = 24, 24
local CX, CY = 12, 12

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local CORE  = rgb(255, 252, 232)
local HOT   = rgb(255, 224, 122)
local MID   = rgb(255, 162, 58)
local OUTER = rgb(226, 88, 40)
local SMOKE_A = rgb(120, 120, 128, 120)
local SMOKE_B = rgb(92, 92, 100, 80)

local function put(img, x, y, c)
  if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end

local function fill(img, x0, y0, x1, y1, c)
  for y = y0, y1 do for x = x0, x1 do put(img, x, y, c) end end
end

local RAYS = {
  { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
  { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 },
}

-- 星芒：8 根射线 + 亮核
local function star(img, length, thickness, hot_len)
  for _, r in ipairs(RAYS) do
    local diagonal = (r[1] ~= 0 and r[2] ~= 0)
    local len = diagonal and math.floor(length * 0.66) or length
    for d = 1, len do
      local color = OUTER
      if d <= hot_len then
        color = HOT
      elseif d <= len * 0.7 then
        color = MID
      end
      put(img, CX + r[1] * d, CY + r[2] * d, color)
      if thickness > 1 and not diagonal then
        put(img, CX + r[1] * d + (r[2] ~= 0 and 1 or 0), CY + r[2] * d + (r[1] ~= 0 and 1 or 0), color)
      end
    end
  end
  -- 亮核
  fill(img, CX - 2, CY - 1, CX + 1, CY + 2, HOT)
  fill(img, CX - 1, CY - 1, CX + 1, CY + 1, CORE)
end

local sparkle = { { 5, 3 }, { -6, 2 }, { 3, -5 }, { -3, -6 }, { 7, -1 }, { -7, -2 } }

local function frame_flash(img)
  star(img, 10, 2, 4)
  -- 几粒飞散的火星
  for _, s in ipairs(sparkle) do put(img, CX + s[1], CY + s[2], HOT) end
end

local function frame_flash2(img)
  star(img, 7, 1, 3)
  put(img, CX + 6, CY + 3, MID)
  put(img, CX - 5, CY - 4, MID)
end

local function frame_smoke(img)
  fill(img, CX - 3, CY - 3, CX + 2, CY + 2, SMOKE_B)
  fill(img, CX - 2, CY - 2, CX + 1, CY + 1, SMOKE_A)
  fill(img, CX - 1, CY - 1, CX, CY, SMOKE_A)
  put(img, CX + 4, CY - 3, SMOKE_B)
  put(img, CX + 5, CY - 2, SMOKE_B)
  put(img, CX - 5, CY + 2, SMOKE_B)
  put(img, CX - 6, CY + 3, SMOKE_B)
  put(img, CX + 3, CY + 5, SMOKE_B)
  put(img, CX - 2, CY + 6, SMOKE_B)
  put(img, CX - 4, CY - 5, SMOKE_B)
  put(img, CX + 1, CY - 6, SMOKE_B)
end

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "flash"

local frames = { frame_flash, frame_flash2, frame_smoke }
-- 第一帧用 Sprite 自带帧，其余新建
for i, fn in ipairs(frames) do
  local frame = spr.frames[i] or spr:newEmptyFrame()
  local img = Image(W, H, ColorMode.RGB)
  img:clear(0)
  fn(img)
  spr:newCel(spr.layers[1], frame, img, Point(0, 0))
  spr.frames[i].duration = i == 1 and 0.05 or (i == 2 and 0.06 or 0.08)
end

spr:saveAs(OUT)
print(string.format("saved %s frames=%d", OUT, #spr.frames))
