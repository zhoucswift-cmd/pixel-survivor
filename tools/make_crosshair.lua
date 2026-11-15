-- make_crosshair.lua
-- 生成 13x13 像素准心（2 帧：常态准心 / 开火时张开的准心）
-- 运行: Aseprite.exe -b --script tools/make_crosshair.lua

local OUT = "C:/game/test/assets/crosshair.aseprite"
local W, H = 13, 13
local CX, CY = 6, 6

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local WHITE  = rgb(242, 247, 255)
local OUTLINE = rgb(16, 16, 26, 210)

local function put(img, x, y, c)
  if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end

-- gap: 中心留空的距离；len: 每条臂的长度；dot: 是否画中心点
local function draw_cross(img, gap, len, dot)
  local pts = {}
  for d = gap + 1, gap + len do
    pts[#pts + 1] = { CX + d, CY }
    pts[#pts + 1] = { CX - d, CY }
    pts[#pts + 1] = { CX, CY + d }
    pts[#pts + 1] = { CX, CY - d }
  end
  if dot then pts[#pts + 1] = { CX, CY } end

  -- 先铺一圈 1px 深色描边，保证在亮/暗背景上都看得清
  local set = {}
  for _, p in ipairs(pts) do set[p[1] .. "," .. p[2]] = true end
  for _, p in ipairs(pts) do
    for dy = -1, 1 do
      for dx = -1, 1 do
        local x, y = p[1] + dx, p[2] + dy
        if not set[x .. "," .. y] then put(img, x, y, OUTLINE) end
      end
    end
  end
  for _, p in ipairs(pts) do put(img, p[1], p[2], WHITE) end
end

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "crosshair"

local variants = {
  { gap = 1, len = 3, dot = true },   -- 常态：紧凑准心 + 中心点
  { gap = 2, len = 3, dot = false },  -- 开火：向外张开、中心留空
}

for i, v in ipairs(variants) do
  local frame = spr.frames[i] or spr:newEmptyFrame()
  local img = Image(W, H, ColorMode.RGB)
  img:clear(0)
  draw_cross(img, v.gap, v.len, v.dot)
  spr:newCel(spr.layers[1], frame, img, Point(0, 0))
  spr.frames[i].duration = 0.1
end

spr:saveAs(OUT)
print(string.format("saved %s frames=%d", OUT, #spr.frames))
