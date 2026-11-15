-- make_hud.lua
-- 生成血条 UI：外框（含心形图标）+ 填充条
-- 运行: Aseprite.exe -b --script tools/make_hud.lua

local OUT_DIR = "C:/game/test/assets/ui"

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE     = rgb(36, 26, 38)
local FRAME_BODY  = rgb(90, 94, 107)
local FRAME_LIGHT = rgb(125, 131, 144)
local FRAME_DARK  = rgb(60, 63, 74)
local TRACK       = rgb(58, 20, 20)
local FILL        = rgb(207, 63, 48)
local FILL_L      = rgb(239, 106, 74)
local FILL_D      = rgb(156, 40, 32)
local HEART       = rgb(216, 66, 58)
local HEART_L     = rgb(240, 118, 106)

-- 心形：隐函数 (x^2+y^2-1)^3 - x^2 y^3 <= 0
local HEART_W, HEART_H = 11, 10

local function build_heart()
  local inside = {}
  for y = 0, HEART_H - 1 do
    inside[y] = {}
    for x = 0, HEART_W - 1 do
      local nx = (x - 5.0) / 4.3
      local ny = (4.3 - y) / 3.9
      local a = nx * nx + ny * ny - 1
      inside[y][x] = (a * a * a - nx * nx * ny * ny * ny) <= 0
    end
  end
  return inside
end

----------------------------------------------------------------------
-- 外框：11x10 心形 + 56x12 血条框（内槽 52x8）
----------------------------------------------------------------------
local BAR_X, BAR_Y, BAR_W, BAR_H = 16, 0, 56, 12
local frameSprite = Sprite(BAR_X + BAR_W, BAR_H, ColorMode.RGB)
frameSprite.layers[1].name = "frame"
local frameImg = Image(BAR_X + BAR_W, BAR_H, ColorMode.RGB)
frameImg:clear(0)

local function put(img, x, y, c)
  if x >= 0 and y >= 0 and x < img.width and y < img.height then img:putPixel(x, y, c) end
end

-- 心形（先描边再填色）
local heart = build_heart()
for y = 0, HEART_H - 1 do
  for x = 0, HEART_W - 1 do
    if not heart[y][x] then
      local near = false
      for dy = -1, 1 do
        for dx = -1, 1 do
          local nx, ny = x + dx, y + dy
          if nx >= 0 and ny >= 0 and nx < HEART_W and ny < HEART_H and heart[ny][nx] then
            near = true
          end
        end
      end
      if near then put(frameImg, x + 1, y + 1, OUTLINE) end
    end
  end
end
for y = 0, HEART_H - 1 do
  for x = 0, HEART_W - 1 do
    if heart[y][x] then
      put(frameImg, x + 1, y + 1, (x + y < 6) and HEART_L or HEART)
    end
  end
end

-- 血条外框
local function fill(img, x0, y0, x1, y1, c)
  for y = y0, y1 do
    for x = x0, x1 do put(img, x, y, c) end
  end
end
local function hline(img, x0, x1, y, c) fill(img, x0, y, x1, y, c) end

fill(frameImg, BAR_X, BAR_Y, BAR_X + BAR_W - 1, BAR_Y + BAR_H - 1, OUTLINE)
fill(frameImg, BAR_X + 1, BAR_Y + 1, BAR_X + BAR_W - 2, BAR_Y + BAR_H - 2, FRAME_BODY)
hline(frameImg, BAR_X + 1, BAR_X + BAR_W - 2, BAR_Y + 1, FRAME_LIGHT)
hline(frameImg, BAR_X + 1, BAR_X + BAR_W - 2, BAR_Y + BAR_H - 2, FRAME_DARK)
fill(frameImg, BAR_X + 2, BAR_Y + 2, BAR_X + BAR_W - 3, BAR_Y + BAR_H - 3, TRACK)

frameSprite:newCel(frameSprite.layers[1], frameSprite.frames[1], frameImg, Point(0, 0))
frameSprite:saveAs(OUT_DIR .. "/health_frame.aseprite")

----------------------------------------------------------------------
-- 填充条：52x8，三色（绿 / 黄 / 红）同一形状只换颜色，按帧排列
--   帧 1 绿 = 血量 > 50%、帧 2 黄 = 20%~50%、帧 3 红 = < 20%
----------------------------------------------------------------------
local FILL_W, FILL_H = 52, 8
local fillSprite = Sprite(FILL_W, FILL_H, ColorMode.RGB)
fillSprite.layers[1].name = "fill"

local STATES = {
  { name = "green",  base = rgb(76, 168, 63),  light = rgb(122, 208, 102), dark = rgb(48, 112, 40) },
  { name = "yellow", base = rgb(216, 166, 44), light = rgb(243, 208, 92),  dark = rgb(158, 112, 24) },
  { name = "red",    base = rgb(207, 63, 48),  light = rgb(239, 106, 74),  dark = rgb(156, 40, 32) },
}

for i, st in ipairs(STATES) do
  local frame = fillSprite.frames[i] or fillSprite:newEmptyFrame()
  local img = Image(FILL_W, FILL_H, ColorMode.RGB)
  img:clear(0)
  fill(img, 0, 0, FILL_W - 1, FILL_H - 1, st.base)
  hline(img, 0, FILL_W - 1, 0, st.light)
  hline(img, 0, FILL_W - 1, FILL_H - 1, st.dark)
  -- 左侧竖向高光，填充条短的时候也好看
  fill(img, 0, 1, 1, FILL_H - 2, st.light)
  fillSprite:newCel(fillSprite.layers[1], frame, img, Point(0, 0))
  fillSprite.frames[i].duration = 0.1
end

fillSprite:saveAs(OUT_DIR .. "/health_fill.aseprite")

print(string.format("saved health_frame (%dx%d) + health_fill (%dx%d, %d frames)",
  frameImg.width, frameImg.height, FILL_W, FILL_H, #STATES))
