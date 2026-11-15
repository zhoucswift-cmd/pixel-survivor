-- make_character.lua
-- 用 Aseprite 批处理模式生成 32x32 四方向持枪角色（idle + 4 帧走路 + 2 帧射击）
-- 运行: Aseprite.exe -b --script tools/make_character.lua
--
-- 帧顺序(1..28)，每方向 7 帧:
--   idle 1 / walk 4 / shoot 2
--   down : 1-7    up : 8-14    left : 15-21    right : 22-28

local OUT = "C:/game/test/assets/character.aseprite"
local W, H = 32, 32

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

-- 调色板
local OUTLINE = rgb(26, 22, 38)
local SKIN    = rgb(242, 196, 158)
local SKIN_S  = rgb(214, 158, 118)
local HAIR    = rgb(92, 58, 38)
local HAIR_L  = rgb(126, 84, 56)
local HAIR_D  = rgb(62, 38, 26)
local EYE     = rgb(34, 26, 46)
local WHITE   = rgb(255, 255, 255)
local MOUTH   = rgb(150, 84, 78)
local BLUSH   = rgb(232, 148, 140)
local TUNIC   = rgb(63, 111, 181)
local TUNIC_L = rgb(104, 152, 220)
local TUNIC_S = rgb(40, 72, 128)
local BELT    = rgb(202, 162, 62)
local PANTS   = rgb(54, 62, 92)
local PANTS_D = rgb(40, 46, 70)
local BOOT    = rgb(92, 60, 38)
local BOOT_D  = rgb(68, 44, 28)
local SHADOW  = rgb(16, 14, 26, 96)
-- 霰弹枪
local METAL   = rgb(104, 110, 126)
local METAL_L = rgb(150, 158, 176)
local METAL_D = rgb(58, 62, 78)
local WOOD    = rgb(140, 90, 54)
local WOOD_D  = rgb(98, 60, 36)

----------------------------------------------------------------------
-- 基础绘制工具
----------------------------------------------------------------------
local function put(img, x, y, c)
  if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end

local function fill(img, x0, y0, x1, y1, c)
  for y = y0, y1 do
    for x = x0, x1 do put(img, x, y, c) end
  end
end

local function hline(img, x0, x1, y, c) fill(img, x0, y, x1, y, c) end
local function vline(img, x, y0, y1, c) fill(img, x, y0, x, y1, c) end

local function rrect(img, x0, y0, x1, y1, r, c)
  for y = y0, y1 do
    local dy = math.min(y - y0, y1 - y)
    local inset = 0
    if dy < r then inset = r - dy end
    fill(img, x0 + inset, y, x1 - inset, y, c)
  end
end

local function ellipse(img, cx, cy, rx, ry, c)
  for y = cy - ry, cy + ry do
    local t = (y - cy) / ry
    local w = math.floor(rx * math.sqrt(math.max(0, 1 - t * t)) + 0.5)
    fill(img, cx - w, y, cx + w, y, c)
  end
end

local function autoOutline(img, color)
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
            if not (dx == 0 and dy == 0) then
              local nx, ny = x + dx, y + dy
              if nx >= 0 and ny >= 0 and nx < W and ny < H
                 and snapshot[ny][nx] ~= 0 then
                near = true
              end
            end
          end
        end
        if near then img:putPixel(x, y, color) end
      end
    end
  end
end

local function mirror(img)
  local out = Image(W, H, ColorMode.RGB)
  out:clear(0)
  for y = 0, H - 1 do
    for x = 0, W - 1 do out:putPixel(W - 1 - x, y, img:getPixel(x, y)) end
  end
  return out
end

----------------------------------------------------------------------
-- 腿
----------------------------------------------------------------------
local function drawLegsFront(img, bob, phase)
  local lx, rx, llift, rlift = 0, 0, 0, 0
  if phase == 1 then
    lx = -1
  elseif phase == 2 then
    rlift = -1
  elseif phase == 3 then
    rx = 1
  else
    llift = -1
  end

  fill(img, 12 + lx, 24 + bob + llift, 14 + lx, 26 + bob + llift, PANTS)
  fill(img, 11 + lx, 26 + bob + llift, 14 + lx, 28 + bob + llift, BOOT)
  hline(img, 11 + lx, 14 + lx, 27 + bob + llift, BOOT_D)

  fill(img, 17 + rx, 24 + bob + rlift, 19 + rx, 26 + bob + rlift, PANTS_D)
  fill(img, 17 + rx, 26 + bob + rlift, 20 + rx, 28 + bob + rlift, BOOT_D)
  hline(img, 17 + rx, 20 + rx, 27 + bob + rlift, BOOT_D)
end

local function drawLegsSide(img, bob, phase)
  local fx, bx, fl, bl = 0, 0, 0, 0
  if phase == 1 then
    fx, bx = -1, 1
  elseif phase == 2 then
    fl = -1
  elseif phase == 3 then
    fx, bx = 1, -1
  else
    bl = -1
  end

  fill(img, 15 + bx, 24 + bob + bl, 17 + bx, 26 + bob + bl, PANTS_D)
  fill(img, 14 + bx, 26 + bob + bl, 18 + bx, 27 + bob + bl, BOOT_D)

  fill(img, 13 + fx, 24 + bob + fl, 15 + fx, 26 + bob + fl, PANTS)
  fill(img, 10 + fx, 26 + bob + fl, 16 + fx, 28 + bob + fl, BOOT)
  hline(img, 10 + fx, 16 + fx, 27 + bob + fl, BOOT_D)
end

----------------------------------------------------------------------
-- 身体（三个基准朝向，右 = 左镜像）
----------------------------------------------------------------------
local function drawDown(img, bob, phase)
  drawLegsFront(img, bob, phase)

  local ayL, ayR = 0, 0
  if phase == 1 then ayL, ayR = 1, -1 elseif phase == 3 then ayL, ayR = -1, 1 end

  fill(img, 14, 15 + bob, 17, 16 + bob, SKIN_S)

  rrect(img, 11, 16 + bob, 20, 23 + bob, 2, TUNIC)
  vline(img, 19, 17 + bob, 21 + bob, TUNIC_S)
  hline(img, 12, 13, 16 + bob, TUNIC_L)
  hline(img, 11, 20, 22 + bob, BELT)
  put(img, 15, 22 + bob, rgb(240, 210, 120))
  put(img, 16, 22 + bob, rgb(240, 210, 120))
  fill(img, 14, 16 + bob, 17, 17 + bob, TUNIC_S)

  fill(img, 9, 18 + bob + ayL, 10, 22 + bob + ayL, TUNIC)
  fill(img, 21, 18 + bob + ayR, 22, 22 + bob + ayR, TUNIC_S)
  fill(img, 9, 22 + bob + ayL, 10, 23 + bob + ayL, SKIN)
  fill(img, 21, 22 + bob + ayR, 22, 23 + bob + ayR, SKIN_S)

  rrect(img, 10, 6 + bob, 21, 15 + bob, 3, SKIN)
  rrect(img, 10, 5 + bob, 21, 10 + bob, 3, HAIR)
  hline(img, 12, 18, 6 + bob, HAIR_L)
  put(img, 11, 7 + bob, HAIR_L)
  fill(img, 12, 9 + bob, 19, 15 + bob, SKIN)
  fill(img, 10, 10 + bob, 11, 12 + bob, HAIR)
  fill(img, 20, 10 + bob, 21, 12 + bob, HAIR)
  fill(img, 13, 10 + bob, 14, 10 + bob, HAIR_D)
  fill(img, 17, 10 + bob, 18, 10 + bob, HAIR_D)
  fill(img, 13, 11 + bob, 14, 12 + bob, EYE)
  fill(img, 17, 11 + bob, 18, 12 + bob, EYE)
  put(img, 13, 11 + bob, WHITE)
  put(img, 17, 11 + bob, WHITE)
  hline(img, 15, 16, 14 + bob, MOUTH)
  put(img, 12, 13 + bob, BLUSH)
  put(img, 19, 13 + bob, BLUSH)
end

local function drawUp(img, bob, phase)
  drawLegsFront(img, bob, phase)

  local ayL, ayR = 0, 0
  if phase == 1 then ayL, ayR = 1, -1 elseif phase == 3 then ayL, ayR = -1, 1 end

  fill(img, 14, 14 + bob, 17, 16 + bob, SKIN_S)

  rrect(img, 11, 16 + bob, 20, 23 + bob, 2, TUNIC)
  vline(img, 19, 17 + bob, 21 + bob, TUNIC_S)
  hline(img, 12, 13, 16 + bob, TUNIC_L)
  hline(img, 11, 20, 22 + bob, BELT)
  fill(img, 12, 16 + bob, 19, 17 + bob, TUNIC_S)

  fill(img, 9, 18 + bob + ayL, 10, 22 + bob + ayL, TUNIC)
  fill(img, 21, 18 + bob + ayR, 22, 22 + bob + ayR, TUNIC_S)
  fill(img, 9, 22 + bob + ayL, 10, 23 + bob + ayL, SKIN)
  fill(img, 21, 22 + bob + ayR, 22, 23 + bob + ayR, SKIN_S)

  rrect(img, 10, 6 + bob, 21, 14 + bob, 3, HAIR_D)
  rrect(img, 11, 6 + bob, 20, 13 + bob, 3, HAIR)
  hline(img, 12, 18, 7 + bob, HAIR_L)
  hline(img, 11, 19, 6 + bob, HAIR_L)
  hline(img, 13, 17, 8 + bob, HAIR_L)
  vline(img, 15, 9 + bob, 12 + bob, HAIR_D)
  fill(img, 12, 13 + bob, 19, 14 + bob, HAIR_D)
  put(img, 14, 9 + bob, HAIR_L)
  put(img, 17, 10 + bob, HAIR_L)
  put(img, 12, 11 + bob, HAIR_L)
end

local function drawLeft(img, bob, phase)
  drawLegsSide(img, bob, phase)

  local ax = 0
  if phase == 1 then ax = -1 elseif phase == 3 then ax = 1 end

  fill(img, 14, 15 + bob, 16, 16 + bob, SKIN_S)

  rrect(img, 11, 16 + bob, 20, 23 + bob, 2, TUNIC)
  vline(img, 19, 17 + bob, 21 + bob, TUNIC_S)
  hline(img, 12, 14, 16 + bob, TUNIC_L)
  hline(img, 11, 20, 22 + bob, BELT)
  put(img, 13, 22 + bob, rgb(240, 210, 120))

  rrect(img, 10, 6 + bob, 20, 15 + bob, 3, SKIN)
  rrect(img, 12, 5 + bob, 21, 11 + bob, 3, HAIR)
  hline(img, 14, 19, 6 + bob, HAIR_L)
  put(img, 18, 7 + bob, HAIR_L)
  fill(img, 10, 9 + bob, 11, 15 + bob, HAIR)
  fill(img, 12, 9 + bob, 14, 11 + bob, HAIR)
  fill(img, 12, 10 + bob, 16, 15 + bob, SKIN)
  fill(img, 13, 10 + bob, 14, 10 + bob, HAIR_D)
  put(img, 10, 11 + bob, SKIN)
  put(img, 9, 11 + bob, SKIN_S)
  fill(img, 13, 11 + bob, 13, 12 + bob, EYE)
  put(img, 13, 11 + bob, WHITE)
  hline(img, 11, 12, 14 + bob, MOUTH)
  put(img, 16, 13 + bob, BLUSH)
end

----------------------------------------------------------------------
-- 霰弹枪（独立图层，recoil = 后坐位移像素）
----------------------------------------------------------------------
local function gunDown(img, bob, recoil)
  local oy = bob - recoil
  -- 枪托（右肩后侧）
  fill(img, 18, 17 + oy, 20, 19 + oy, WOOD_D)
  -- 机匣
  fill(img, 15, 19 + oy, 19, 21 + oy, METAL)
  hline(img, 15, 19, 19 + oy, METAL_L)
  -- 护木
  fill(img, 13, 22 + oy, 19, 23 + oy, WOOD)
  hline(img, 13, 19, 23 + oy, WOOD_D)
  -- 枪管
  fill(img, 16, 22 + oy, 17, 26 + oy, METAL_D)
  put(img, 16, 22 + oy, METAL)
  -- 枪口
  fill(img, 15, 26 + oy, 18, 26 + oy, METAL_D)
  -- 握持的手
  fill(img, 13, 20 + oy, 14, 21 + oy, SKIN)
  fill(img, 20, 20 + oy, 21, 21 + oy, SKIN)
end

local function gunUp(img, bob, recoil)
  local oy = bob + recoil
  -- 枪托
  fill(img, 22, 19 + oy, 24, 21 + oy, WOOD_D)
  -- 机匣
  fill(img, 21, 16 + oy, 24, 19 + oy, METAL)
  hline(img, 21, 24, 16 + oy, METAL_L)
  -- 护木
  fill(img, 21, 14 + oy, 24, 15 + oy, WOOD)
  hline(img, 21, 24, 15 + oy, WOOD_D)
  -- 枪管
  fill(img, 22, 8 + oy, 23, 14 + oy, METAL_D)
  put(img, 23, 14 + oy, METAL)
  -- 枪口
  fill(img, 21, 8 + oy, 24, 8 + oy, METAL_D)
  -- 手
  fill(img, 19, 17 + oy, 20, 18 + oy, SKIN)
  fill(img, 24, 15 + oy, 25, 16 + oy, SKIN)
end

local function gunLeft(img, bob, recoil)
  -- 朝左，枪口在左；recoil 让枪往右退
  local ox = recoil
  -- 枪托
  fill(img, 16 + ox, 18 + bob, 19 + ox, 20 + bob, WOOD)
  hline(img, 16 + ox, 19 + ox, 20 + bob, WOOD_D)
  -- 机匣
  fill(img, 12 + ox, 17 + bob, 16 + ox, 19 + bob, METAL)
  hline(img, 12 + ox, 16 + ox, 17 + bob, METAL_L)
  -- 护木
  fill(img, 6 + ox, 19 + bob, 10 + ox, 20 + bob, WOOD)
  hline(img, 6 + ox, 10 + ox, 20 + bob, WOOD_D)
  -- 枪管
  fill(img, 3 + ox, 17 + bob, 12 + ox, 18 + bob, METAL_D)
  hline(img, 3 + ox, 9 + ox, 17 + bob, METAL)
  -- 枪口
  fill(img, 3 + ox, 16 + bob, 3 + ox, 19 + bob, METAL_D)
  -- 手
  fill(img, 14 + ox, 19 + bob, 15 + ox, 21 + bob, SKIN)
  fill(img, 7 + ox, 19 + bob, 8 + ox, 21 + bob, SKIN_S)
end

----------------------------------------------------------------------
-- 生成 sprite
----------------------------------------------------------------------
local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "shadow"
local heroLayer = spr:newLayer()
heroLayer.name = "hero"
local gunLayer = spr:newLayer()
gunLayer.name = "gun"

local function addFrame(heroFn, gunFn)
  local frame = spr:newEmptyFrame()

  local simg = Image(W, H, ColorMode.RGB)
  simg:clear(0)
  ellipse(simg, 16, 29, 8, 2, SHADOW)
  ellipse(simg, 16, 29, 5, 1, SHADOW)
  spr:newCel(spr.layers[1], frame, simg, Point(0, 0))

  local himg = Image(W, H, ColorMode.RGB)
  himg:clear(0)
  heroFn(himg)
  autoOutline(himg, OUTLINE)
  spr:newCel(heroLayer, frame, himg, Point(0, 0))

  local gimg = Image(W, H, ColorMode.RGB)
  gimg:clear(0)
  gunFn(gimg)
  autoOutline(gimg, OUTLINE)
  spr:newCel(gunLayer, frame, gimg, Point(0, 0))
  return frame
end

local DIRS = {
  { name = "down",  hero = drawDown, gun = gunDown,  mirror = false },
  { name = "up",    hero = drawUp,   gun = gunUp,    mirror = false },
  { name = "left",  hero = drawLeft, gun = gunLeft,  mirror = false },
  { name = "right", hero = drawLeft, gun = gunLeft,  mirror = true },
}

local tags = {}
local frameIndex = 0

for _, def in ipairs(DIRS) do
  local function add(bob, phase, recoil)
    addFrame(
      function(img)
        if def.mirror then
          local tmp = Image(W, H, ColorMode.RGB)
          tmp:clear(0)
          def.hero(tmp, bob, phase)
          local m = mirror(tmp)
          for y = 0, H - 1 do for x = 0, W - 1 do img:putPixel(x, y, m:getPixel(x, y)) end end
        else
          def.hero(img, bob, phase)
        end
      end,
      function(img)
        if def.mirror then
          local tmp = Image(W, H, ColorMode.RGB)
          tmp:clear(0)
          def.gun(tmp, bob, recoil)
          local m = mirror(tmp)
          for y = 0, H - 1 do for x = 0, W - 1 do img:putPixel(x, y, m:getPixel(x, y)) end end
        else
          def.gun(img, bob, recoil)
        end
      end
    )
    frameIndex = frameIndex + 1
  end

  -- idle
  local idleStart = frameIndex + 1
  add(0, 1, 0)
  tags[#tags + 1] = { name = "idle_" .. def.name, from = idleStart, to = frameIndex }

  -- walk
  local walkStart = frameIndex + 1
  for phase = 1, 4 do
    add((phase == 2 or phase == 4) and -1 or 0, phase, 0)
  end
  tags[#tags + 1] = { name = "walk_" .. def.name, from = walkStart, to = frameIndex }

  -- shoot（第 1 帧强后坐，第 2 帧回收）
  local shootStart = frameIndex + 1
  add(0, 1, 2)
  add(0, 1, 1)
  tags[#tags + 1] = { name = "shoot_" .. def.name, from = shootStart, to = frameIndex }
end

-- 删掉 Sprite 自带的空白首帧
if #spr.frames > frameIndex then
  spr:deleteFrame(1)
end

for i = 1, #spr.frames do
  spr.frames[i].duration = 0.1
end

for _, t in ipairs(tags) do
  local tag = spr:newTag(t.from, t.to)
  tag.name = t.name
  if t.name:sub(1, 4) == "idle" then
    tag.color = Color(120, 180, 255)
  elseif t.name:sub(1, 5) == "walk" then
    tag.color = Color(255, 180, 90)
  else
    tag.color = Color(255, 96, 96)
  end
end

spr:saveAs(OUT)
print(string.format("saved %s  frames=%d tags=%d", OUT, #spr.frames, #tags))
