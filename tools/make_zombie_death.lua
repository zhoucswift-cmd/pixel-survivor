-- make_zombie_death.lua
-- 僵尸死亡爆血动画：48x48，5 帧（身体炸开 -> 血块飞散 -> 地面血泊）
-- 运行: Aseprite.exe -b --script tools/make_zombie_death.lua

local OUT = "C:/game/test/assets/zombie_death.aseprite"
local W, H = 48, 48

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local BLOOD   = rgb(150, 42, 38)
local BLOOD_L = rgb(190, 74, 62)
local BLOOD_D = rgb(104, 26, 26)
local BLOOD_DD = rgb(68, 16, 18)
local OUTLINE = rgb(30, 14, 16)

local function put(img, x, y, c)
  if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end

local function fill(img, x0, y0, x1, y1, c)
  for y = y0, y1 do for x = x0, x1 do put(img, x, y, c) end end
end

local function ellipse(img, cx, cy, rx, ry, c)
  for y = cy - ry, cy + ry do
    local t = (y - cy) / ry
    local w = math.floor(rx * math.sqrt(math.max(0, 1 - t * t)) + 0.5)
    fill(img, cx - w, y, cx + w, y, c)
  end
end

local function outline(img, color)
  local snap = {}
  for y = 0, H - 1 do
    snap[y] = {}
    for x = 0, W - 1 do snap[y][x] = img:getPixel(x, y) end
  end
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      if snap[y][x] == 0 then
        local near = false
        for dy = -1, 1 do
          for dx = -1, 1 do
            local nx, ny = x + dx, y + dy
            if nx >= 0 and ny >= 0 and nx < W and ny < H and snap[ny][nx] ~= 0 then near = true end
          end
        end
        if near then img:putPixel(x, y, color) end
      end
    end
  end
end

-- 固定种子 LCG
local function lcg(seed)
  local state = seed % 2147483647
  if state <= 0 then state = state + 2147483646 end
  return function()
    state = (state * 16807) % 2147483647
    return (state - 1) / 2147483646
  end
end

-- 一块血块（菱形，边缘更深）
local function chunk(img, cx, cy, r, base, edge)
  for y = cy - r, cy + r do
    for x = cx - r, cx + r do
      local d = math.abs(x - cx) + math.abs(y - cy)
      if d <= r then
        put(img, x, y, (d == r) and edge or base)
      end
    end
  end
end

----------------------------------------------------------------------
-- 第 1 帧：身体炸开（血液还在人形轮廓里）
----------------------------------------------------------------------
local function frame_burst(img)
  ellipse(img, 24, 16, 5, 5, BLOOD)
  fill(img, 17, 22, 31, 33, BLOOD)
  fill(img, 12, 25, 16, 28, BLOOD)
  fill(img, 32, 25, 36, 28, BLOOD)
  fill(img, 18, 33, 23, 37, BLOOD)
  fill(img, 25, 33, 30, 37, BLOOD)
  -- 高光 / 暗部
  fill(img, 19, 23, 22, 27, BLOOD_L)
  fill(img, 21, 13, 24, 15, BLOOD_L)
  fill(img, 26, 29, 31, 33, BLOOD_D)
  fill(img, 19, 34, 22, 37, BLOOD_D)
  -- 已经飞出去的血点
  put(img, 10, 18, BLOOD)
  put(img, 38, 20, BLOOD)
  put(img, 36, 34, BLOOD_D)
  put(img, 12, 33, BLOOD_D)
end

----------------------------------------------------------------------
-- 第 2~3 帧：血块飞散
----------------------------------------------------------------------
local function frame_scatter(img, seed, count, min_r, max_r, max_size)
  local rnd = lcg(seed)
  -- 放射状血丝，制造“炸出去”的方向感
  for i = 1, 6 do
    local ang = rnd() * math.pi * 2
    local len = 4 + math.floor(rnd() * 6)
    for d = 3, 3 + len do
      put(img, math.floor(24 + math.cos(ang) * d), math.floor(24 + math.sin(ang) * d * 0.8), BLOOD_D)
    end
  end
  for i = 1, count do
    local ang = rnd() * math.pi * 2
    -- 平方偏置：中间密、外围稀，更像炸开
    local bias = rnd() * rnd()
    local dist = min_r + (max_r - min_r) * bias
    local x = 24 + math.cos(ang) * dist
    local y = 24 + math.sin(ang) * dist * 0.8
    local size = 1 + math.floor(rnd() * max_size)
    chunk(img, math.floor(x), math.floor(y), size, BLOOD, BLOOD_D)
  end
end

-- 第 4 帧：血点落地 + 血泊开始
local function frame_land(img, seed)
  local rnd = lcg(seed)
  for i = 1, 26 do
    local ang = rnd() * math.pi * 2
    local dist = 8 + rnd() * 14
    local x = math.floor(24 + math.cos(ang) * dist)
    local y = math.floor(38 + math.sin(ang) * dist * 0.25)
    put(img, x, y, (rnd() < 0.5) and BLOOD or BLOOD_D)
  end
  ellipse(img, 24, 37, 9, 3, BLOOD_D)
  ellipse(img, 24, 37, 7, 2, BLOOD)
  put(img, 20, 37, BLOOD_L)
  -- 几块还没落下的碎肉
  chunk(img, 16, 30, 1, BLOOD, BLOOD_D)
  chunk(img, 31, 28, 1, BLOOD, BLOOD_D)
end

-- 第 5 帧：只剩地上的血泊（这一帧会被留成血迹）
local function frame_pool(img, seed)
  local rnd = lcg(seed)
  ellipse(img, 24, 37, 11, 4, BLOOD_D)
  ellipse(img, 24, 37, 9, 3, BLOOD)
  ellipse(img, 23, 36, 5, 1, BLOOD_L)
  for i = 1, 10 do
    local ang = rnd() * math.pi * 2
    local dist = 10 + rnd() * 8
    put(img, math.floor(24 + math.cos(ang) * dist), math.floor(37 + math.sin(ang) * dist * 0.3),
      (rnd() < 0.5) and BLOOD or BLOOD_D)
  end
end

----------------------------------------------------------------------
-- 生成
----------------------------------------------------------------------
local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "gore"

local FRAMES = {
  function(img) frame_burst(img) end,
  function(img) frame_scatter(img, 9101, 22, 6, 16, 2) end,
  function(img) frame_scatter(img, 9207, 30, 10, 22, 2) end,
  function(img) frame_land(img, 9311) end,
  function(img) frame_pool(img, 9413) end,
}

for i, fn in ipairs(FRAMES) do
  local frame = spr.frames[i] or spr:newEmptyFrame()
  local img = Image(W, H, ColorMode.RGB)
  img:clear(0)
  fn(img)
  outline(img, OUTLINE)
  spr:newCel(spr.layers[1], frame, img, Point(0, 0))
  spr.frames[i].duration = 0.1
end

spr:saveAs(OUT)
print(string.format("saved %s  %dx%d  frames=%d", OUT, W, H, #FRAMES))
