-- make_zombie.lua
-- 生成 32x32 四方向僵尸：idle 1 帧 + walk 4 帧 + 抓取攻击 3 帧，每方向 8 帧
-- 运行: Aseprite.exe -b --script tools/make_zombie.lua
--
-- 帧顺序 (1..32)：
--   down : 1 / 2-5 / 6-8
--   up   : 9 / 10-13 / 14-16
--   left : 17 / 18-21 / 22-24
--   right: 25 / 26-29 / 30-32

local OUT = "C:/game/test/assets/zombie.aseprite"
local W, H = 32, 32

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

-- 僵尸配色
local OUTLINE  = rgb(24, 22, 26)
local SKIN     = rgb(138, 168, 98)
local SKIN_D   = rgb(109, 138, 73)
local SKIN_DD  = rgb(82, 105, 58)
local HAIR     = rgb(63, 74, 52)
local HAIR_D   = rgb(45, 52, 38)
local EYE      = rgb(232, 224, 106)
local EYE_D    = rgb(42, 42, 32)
local SHIRT    = rgb(90, 95, 107)
local SHIRT_D  = rgb(67, 71, 79)
local PANTS    = rgb(60, 65, 82)
local PANTS_D  = rgb(45, 49, 64)
local BOOT     = rgb(74, 58, 42)
local BOOT_D   = rgb(56, 44, 32)
local BLOOD    = rgb(142, 43, 40)
local SHADOW   = rgb(16, 14, 26, 96)

local function put(img, x, y, c)
  if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end

local function fill(img, x0, y0, x1, y1, c)
  for y = y0, y1 do for x = x0, x1 do put(img, x, y, c) end end
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
              if nx >= 0 and ny >= 0 and nx < W and ny < H and snapshot[ny][nx] ~= 0 then
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
-- 腿：拖沓的小碎步
----------------------------------------------------------------------
local function legsFront(img, bob, phase)
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

local function legsSide(img, bob, phase, dx)
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
-- 正面（down）：手臂朝镜头伸
----------------------------------------------------------------------
local function drawDown(img, bob, arm, phase)
  legsFront(img, bob, phase)

  local handY = 22
  if arm == 1 then handY = 20 elseif arm == 2 then handY = 24 end

  -- 躯干（破衣服）
  rrect(img, 11, 16 + bob, 20, 23 + bob, 2, SHIRT)
  vline(img, 19, 17 + bob, 21 + bob, SHIRT_D)
  hline(img, 11, 20, 23 + bob, SHIRT_D)
  -- 破口露出皮肤
  fill(img, 12, 22 + bob, 13, 23 + bob, SKIN_D)
  fill(img, 17, 20 + bob, 18, 21 + bob, BLOOD)

  -- 手臂：向外伸
  fill(img, 8, 17 + bob, 9, 20 + bob, SHIRT)
  fill(img, 22, 17 + bob, 23, 20 + bob, SHIRT_D)
  fill(img, 8, handY + bob, 9, handY + 3 + bob, SKIN)
  fill(img, 22, handY + bob, 23, handY + 3 + bob, SKIN_D)
  if arm == 2 then
    -- 指爪
    put(img, 8, handY + 4 + bob, SKIN_D)
    put(img, 10, handY + 4 + bob, SKIN_D)
    put(img, 22, handY + 4 + bob, SKIN_DD)
    put(img, 24, handY + 4 + bob, SKIN_DD)
  end

  -- 头
  rrect(img, 10, 6 + bob, 21, 15 + bob, 3, SKIN)
  -- 稀疏头发
  fill(img, 11, 6 + bob, 20, 7 + bob, HAIR)
  put(img, 10, 8 + bob, HAIR)
  put(img, 20, 8 + bob, HAIR_D)
  put(img, 15, 5 + bob, HAIR)
  -- 凹陷眼窝 + 黄眼
  fill(img, 12, 10 + bob, 14, 12 + bob, EYE_D)
  fill(img, 17, 10 + bob, 19, 12 + bob, EYE_D)
  put(img, 13, 11 + bob, EYE)
  put(img, 18, 11 + bob, EYE)
  -- 缝合的嘴
  hline(img, 14, 17, 14 + bob, EYE_D)
  put(img, 15, 13 + bob, SKIN_D)
  put(img, 16, 14 + bob, SKIN_D)
  -- 伤口
  put(img, 11, 12 + bob, BLOOD)
  put(img, 12, 13 + bob, BLOOD)
end

----------------------------------------------------------------------
-- 背面（up）
----------------------------------------------------------------------
local function drawUp(img, bob, arm, phase)
  legsFront(img, bob, phase)

  local handY = 18
  if arm == 1 then handY = 17 elseif arm == 2 then handY = 15 end

  rrect(img, 11, 16 + bob, 20, 23 + bob, 2, SHIRT)
  vline(img, 19, 17 + bob, 21 + bob, SHIRT_D)
  hline(img, 11, 20, 23 + bob, SHIRT_D)
  fill(img, 12, 21 + bob, 13, 23 + bob, SHIRT_D)

  -- 手臂（背面，向前伸所以只在两侧露一点）
  fill(img, 8, 17 + bob, 9, handY + 2 + bob, SHIRT)
  fill(img, 22, 17 + bob, 23, handY + 2 + bob, SHIRT_D)
  fill(img, 8, handY + 3 + bob, 9, handY + 5 + bob, SKIN)
  fill(img, 22, handY + 3 + bob, 23, handY + 5 + bob, SKIN_D)
  if arm == 2 then
    put(img, 8, handY + 1 + bob, SKIN_D)
    put(img, 10, handY + 1 + bob, SKIN_D)
    put(img, 22, handY + 1 + bob, SKIN_DD)
    put(img, 24, handY + 1 + bob, SKIN_DD)
  end

  -- 后脑：斑驳的头发
  rrect(img, 10, 6 + bob, 21, 15 + bob, 3, HAIR_D)
  rrect(img, 11, 7 + bob, 20, 14 + bob, 3, HAIR)
  put(img, 13, 8 + bob, SKIN_D)
  put(img, 17, 10 + bob, SKIN_D)
  put(img, 15, 9 + bob, HAIR_D)
  fill(img, 12, 14 + bob, 19, 15 + bob, HAIR_D)
end

----------------------------------------------------------------------
-- 侧面（left）：双手前伸
----------------------------------------------------------------------
local function drawLeft(img, bob, arm, phase)
  legsSide(img, bob, phase)

  local reach = 0
  if arm == 1 then reach = -2 elseif arm == 2 then reach = 3 end

  -- 躯干
  rrect(img, 11, 16 + bob, 20, 23 + bob, 2, SHIRT)
  vline(img, 19, 17 + bob, 21 + bob, SHIRT_D)
  hline(img, 11, 20, 23 + bob, SHIRT_D)
  fill(img, 12, 22 + bob, 14, 23 + bob, SKIN_D)

  -- 手臂：上臂 + 前臂 + 手，向前伸
  fill(img, 12 - reach, 17 + bob, 15, 18 + bob, SHIRT)
  fill(img, 10 - reach, 18 + bob, 12 - reach, 19 + bob, SKIN_D)
  fill(img, 12 - reach, 19 + bob, 15, 20 + bob, SHIRT_D)
  fill(img, 9 - reach, 20 + bob, 12 - reach, 21 + bob, SKIN_D)
  -- 手
  fill(img, 7 - reach, 18 + bob, 9 - reach, 20 + bob, SKIN)
  fill(img, 6 - reach, 20 + bob, 9 - reach, 21 + bob, SKIN_D)
  put(img, 6 - reach, 19 + bob, SKIN_DD)
  if arm == 2 then
    -- 指爪
    put(img, 5 - reach, 18 + bob, SKIN_D)
    put(img, 4 - reach, 19 + bob, SKIN_D)
    put(img, 5 - reach, 21 + bob, SKIN_DD)
    put(img, 4 - reach, 20 + bob, SKIN_DD)
  end

  -- 头（侧脸）
  rrect(img, 10, 6 + bob, 20, 15 + bob, 3, SKIN)
  rrect(img, 12, 5 + bob, 21, 11 + bob, 3, HAIR)
  fill(img, 12, 9 + bob, 14, 11 + bob, HAIR)
  fill(img, 12, 10 + bob, 16, 15 + bob, SKIN)
  -- 眼窝
  fill(img, 13, 10 + bob, 14, 12 + bob, EYE_D)
  put(img, 13, 11 + bob, EYE)
  -- 下颌 / 嘴
  hline(img, 11, 13, 14 + bob, EYE_D)
  put(img, 10, 12 + bob, SKIN_D)
  -- 伤口
  put(img, 17, 9 + bob, BLOOD)
  put(img, 18, 10 + bob, BLOOD)
end

----------------------------------------------------------------------
-- 生成 sprite
----------------------------------------------------------------------
local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "shadow"
local bodyLayer = spr:newLayer()
bodyLayer.name = "zombie"

local function addFrame(drawFn, mirrored)
  local frame = spr:newEmptyFrame()

  local simg = Image(W, H, ColorMode.RGB)
  simg:clear(0)
  ellipse(simg, 16, 29, 8, 2, SHADOW)
  ellipse(simg, 16, 29, 5, 1, SHADOW)
  spr:newCel(spr.layers[1], frame, simg, Point(0, 0))

  local bimg = Image(W, H, ColorMode.RGB)
  bimg:clear(0)
  drawFn(bimg)
  if mirrored then
    local m = mirror(bimg)
    for y = 0, H - 1 do for x = 0, W - 1 do bimg:putPixel(x, y, m:getPixel(x, y)) end end
  end
  autoOutline(bimg, OUTLINE)
  spr:newCel(bodyLayer, frame, bimg, Point(0, 0))
  return frame
end

local DIRS = {
  { name = "down",  fn = drawDown, mirror = false },
  { name = "up",    fn = drawUp,   mirror = false },
  { name = "left",  fn = drawLeft, mirror = false },
  { name = "right", fn = drawLeft, mirror = true },
}

local tags = {}
local frameIndex = 0

for _, def in ipairs(DIRS) do
  local function add(bob, arm, phase)
    addFrame(function(img)
      if def.mirror then
        local tmp = Image(W, H, ColorMode.RGB)
        tmp:clear(0)
        def.fn(tmp, bob, arm, phase)
        for y = 0, H - 1 do for x = 0, W - 1 do img:putPixel(x, y, tmp:getPixel(W - 1 - x, y)) end end
      else
        def.fn(img, bob, arm, phase)
      end
    end, false)
    frameIndex = frameIndex + 1
  end

  local idleStart = frameIndex + 1
  add(0, 0, 1)
  tags[#tags + 1] = { name = "idle_" .. def.name, from = idleStart, to = frameIndex }

  local walkStart = frameIndex + 1
  for phase = 1, 4 do
    add((phase == 2 or phase == 4) and -1 or 0, 0, phase)
  end
  tags[#tags + 1] = { name = "walk_" .. def.name, from = walkStart, to = frameIndex }

  local attackStart = frameIndex + 1
  add(0, 1, 1)   -- 蓄力
  add(1, 2, 2)   -- 扑抓
  add(0, 2, 3)   -- 收手
  tags[#tags + 1] = { name = "attack_" .. def.name, from = attackStart, to = frameIndex }
end

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
    tag.color = Color(200, 60, 60)
  end
end

spr:saveAs(OUT)
print(string.format("saved %s  frames=%d tags=%d", OUT, #spr.frames, #tags))
