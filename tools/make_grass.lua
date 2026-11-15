-- make_grass.lua
-- 生成 16x16 草皮瓦片集（8 列 x 2 行 = 16 块），供 Tiled 使用
-- 运行: Aseprite.exe -b --script tools/make_grass.lua

local OUT = "C:/game/test/assets/tiles/grass_tiles.aseprite"
local TILE = 16
local COLS, ROWS = 8, 3
local W, H = TILE * COLS, TILE * ROWS

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

-- 草地配色（偏星露谷的中绿）
local GRASS    = rgb(104, 158, 66)
local GRASS_L  = rgb(126, 181, 80)
local GRASS_D  = rgb(84, 132, 52)
local GRASS_DD = rgb(66, 107, 42)
local FLOWER_W = rgb(245, 246, 236)
local FLOWER_WL = rgb(210, 214, 200)
local FLOWER_Y = rgb(247, 214, 94)
local CENTER   = rgb(214, 158, 52)
local STONE    = rgb(160, 160, 152)
local STONE_D  = rgb(112, 112, 108)

local function put(img, x, y, c)
  if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end

local function fill(img, x0, y0, x1, y1, c)
  for y = y0, y1 do
    for x = x0, x1 do put(img, x, y, c) end
  end
end

-- 固定种子 LCG，保证每次生成结果一致
local function lcg(seed)
  local state = seed % 2147483647
  if state <= 0 then state = state + 2147483646 end
  return function()
    state = (state * 16807) % 2147483647
    return (state - 1) / 2147483646
  end
end

local function ix(rnd, n) return math.floor(rnd() * n) end

----------------------------------------------------------------------
-- 细节元素（坐标都相对瓦片左上角）
----------------------------------------------------------------------
local function speckles(img, x0, y0, rnd, count)
  for _ = 1, count do
    local x = x0 + ix(rnd, TILE)
    local y = y0 + 1 + ix(rnd, TILE - 3)
    local r = rnd()
    if r < 0.6 then
      -- 竖着的一小片草叶
      put(img, x, y, GRASS_D)
      put(img, x, y + 1, GRASS_D)
      if rnd() < 0.35 then put(img, x, y - 1, GRASS_L) end
    elseif r < 0.9 then
      -- 横向亮点
      put(img, x, y, GRASS_L)
      if rnd() < 0.45 then put(img, x + 1, y, GRASS_L) end
    else
      put(img, x, y, GRASS_DD)
    end
  end
end

-- 一丛草：3~4 片斜向草叶
local function tuft(img, x0, y0, rnd, blades)
  for _ = 1, blades do
    local x = x0 + 2 + ix(rnd, 11)
    local y = y0 + 4 + ix(rnd, 8)
    put(img, x, y, GRASS_D)
    put(img, x + 1, y - 1, GRASS_D)
    put(img, x + 1, y - 2, GRASS_L)
    put(img, x + 2, y - 2, GRASS_L)
  end
end

-- 小花：2x2 花瓣 + 花心
local function flower(img, x0, y0, rnd, petal, petal_l)
  local x = x0 + 2 + ix(rnd, 11)
  local y = y0 + 2 + ix(rnd, 11)
  put(img, x, y, petal)
  put(img, x + 1, y, petal_l)
  put(img, x, y + 1, petal_l)
  put(img, x + 1, y + 1, CENTER)
end

-- 小石子
local function pebble(img, x0, y0, rnd)
  local x = x0 + 2 + ix(rnd, 11)
  local y = y0 + 3 + ix(rnd, 10)
  fill(img, x, y, x + 1, y + 1, STONE)
  put(img, x + 1, y + 1, STONE_D)
  put(img, x, y + 2, STONE_D)
end

-- 深色草块：5x4 的软边色斑
local function dark_patch(img, x0, y0, rnd)
  local x = x0 + 4 + ix(rnd, 5)
  local y = y0 + 4 + ix(rnd, 5)
  fill(img, x, y, x + 3, y + 2, GRASS_DD)
  -- 用 GRASS_D 做一圈抖动边缘，避免生硬方块
  for dy = -1, 3 do
    for dx = -1, 4 do
      local edge_x = (dx == -1 or dx == 4)
      local edge_y = (dy == -1 or dy == 3)
      if (edge_x or edge_y) and (dx >= 0 and dx <= 3) and (dy >= 0 and dy <= 2) then
        put(img, x + dx, y + dy, GRASS_D)
      end
    end
  end
  for dx = 0, 3 do
    put(img, x + dx, y - 1, (dx % 2 == 0) and GRASS_D or GRASS)
    put(img, x + dx, y + 3, (dx % 2 == 1) and GRASS_D or GRASS)
  end
end

----------------------------------------------------------------------
-- 16 块瓦片：0 = 纯草底，1~15 = 各种变化
----------------------------------------------------------------------
local TILES = {
  { name = "grass",             speck = 10 },
  { name = "grass_tuft_a",      speck = 9, tuft = 3 },
  { name = "grass_tuft_b",      speck = 9, tuft = 4 },
  { name = "grass_tuft_c",      speck = 8, tuft = 2, flower = "w" },
  { name = "grass_flower_w",    speck = 8, flower = "w" },
  { name = "grass_flower_y",    speck = 8, flower = "y" },
  { name = "grass_flowers",     speck = 8, flower = "w", flower2 = "y" },
  { name = "grass_pebble",      speck = 8, pebble = true },
  { name = "grass_dense",       speck = 16 },
  { name = "grass_tuft_flow",   speck = 8, tuft = 2, flower = "y" },
  { name = "grass_dark",        speck = 7, dark = true },
  { name = "grass_pebble_tuft", speck = 7, pebble = true, tuft = 2 },
  { name = "grass_flower_w2",   speck = 8, flower = "w", tuft = 1 },
  { name = "grass_dark_tuft",   speck = 7, dark = true, tuft = 2 },
  { name = "grass_b",           speck = 11, seed_off = 991 },
  { name = "grass_pebbles",     speck = 8, pebble = true, pebble2 = true },
}

----------------------------------------------------------------------
-- 井盖 / 井口（第 3 行，索引 16、17）
----------------------------------------------------------------------
local STONE     = rgb(172, 164, 148)
local STONE_L   = rgb(200, 192, 174)
local STONE_D   = rgb(126, 118, 104)
local STONE_DD  = rgb(92, 86, 76)
local WELL_EDGE = rgb(38, 36, 30, 110)
local HOLE      = rgb(20, 17, 24)
local HOLE_DEEP = rgb(11, 9, 14)
local WATER     = rgb(32, 50, 60)
local WATER_L   = rgb(62, 88, 100)
local IRON      = rgb(88, 94, 104)
local IRON_L    = rgb(150, 158, 172)
local IRON_D    = rgb(50, 54, 64)

local function disc(img, x0, y0, cx, cy, r2, c)
  for y = 0, TILE - 1 do
    for x = 0, TILE - 1 do
      local dx, dy = x - cx, y - cy
      if dx * dx + dy * dy <= r2 then put(img, x0 + x, y0 + y, c) end
    end
  end
end

-- 石砌井沿 + 外侧一圈软阴影
local function well_rim(img, x0, y0)
  for y = 0, TILE - 1 do
    for x = 0, TILE - 1 do
      local dx, dy = x - 7.5, y - 7.5
      local d2 = dx * dx + dy * dy
      if d2 > 7.6 * 7.6 and d2 <= 8.6 * 8.6 then
        put(img, x0 + x, y0 + y, WELL_EDGE)
      elseif d2 <= 7.6 * 7.6 then
        local c = STONE
        if d2 > 6.5 * 6.5 then
          c = (dx + dy < -4) and STONE_L or STONE_D
        elseif d2 > 5.9 * 5.9 then
          c = STONE_DD
        end
        put(img, x0 + x, y0 + y, c)
      end
    end
  end
end

-- 盖着铁盖的井口
local function well_cover(img, x0, y0)
  well_rim(img, x0, y0)
  disc(img, x0, y0, 7.5, 7.5, 5.7 * 5.7, IRON)
  -- 盖面左上高光弧
  for y = 0, TILE - 1 do
    for x = 0, TILE - 1 do
      local dx, dy = x - 7.5, y - 7.5
      local d2 = dx * dx + dy * dy
      if d2 > 4.4 * 4.4 and d2 <= 5.4 * 5.4 and dx + dy < -3 then
        put(img, x0 + x, y0 + y, IRON_L)
      end
    end
  end
  -- 提环
  fill(img, x0 + 6, y0 + 6, x0 + 9, y0 + 8, IRON_D)
  fill(img, x0 + 7, y0 + 7, x0 + 8, y0 + 7, IRON_L)
  -- 四颗螺栓
  put(img, x0 + 4, y0 + 4, IRON_D)
  put(img, x0 + 11, y0 + 4, IRON_D)
  put(img, x0 + 4, y0 + 11, IRON_D)
  put(img, x0 + 11, y0 + 11, IRON_D)
end

-- 掀开盖的井口（以后僵尸从这里出来时切换成这块）
local function well_open(img, x0, y0)
  well_rim(img, x0, y0)
  disc(img, x0, y0, 7.5, 7.5, 5.7 * 5.7, HOLE)
  disc(img, x0, y0, 7.5, 7.5, 4.4 * 4.4, HOLE_DEEP)
  -- 井底的水光
  fill(img, x0 + 5, y0 + 9, x0 + 10, y0 + 10, WATER)
  put(img, x0 + 6, y0 + 9, WATER_L)
  put(img, x0 + 9, y0 + 10, WATER_L)
end

local PROPS = { well_cover, well_open }

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "base"
local detailLayer = spr:newLayer()
detailLayer.name = "details"

local baseImg = Image(W, H, ColorMode.RGB)
baseImg:clear(0)
local detailImg = Image(W, H, ColorMode.RGB)
detailImg:clear(0)

for i, t in ipairs(TILES) do
  local idx = i - 1
  local col = idx % COLS
  local row = math.floor(idx / COLS)
  local x0 = col * TILE
  local y0 = row * TILE

  local base = lcg(2024 + idx * 37 + (t.seed_off or 0))
  fill(baseImg, x0, y0, x0 + TILE - 1, y0 + TILE - 1, GRASS)
  speckles(baseImg, x0, y0, base, t.speck)

  local det = lcg(777 + idx * 131 + (t.seed_off or 0))
  if t.dark then dark_patch(detailImg, x0, y0, det) end
  if t.tuft then tuft(detailImg, x0, y0, det, t.tuft) end
  if t.flower == "w" then flower(detailImg, x0, y0, det, FLOWER_W, FLOWER_WL) end
  if t.flower == "y" then flower(detailImg, x0, y0, det, FLOWER_Y, CENTER) end
  if t.flower2 == "w" then flower(detailImg, x0, y0, det, FLOWER_W, FLOWER_WL) end
  if t.flower2 == "y" then flower(detailImg, x0, y0, det, FLOWER_Y, CENTER) end
  if t.pebble then pebble(detailImg, x0, y0, det) end
  if t.pebble2 then pebble(detailImg, x0, y0, det) end
end

-- 井盖瓦片：自带草地底，这样单独放进地图也不会透出空洞
for i, fn in ipairs(PROPS) do
  local idx = #TILES + (i - 1)
  local x0 = (idx % COLS) * TILE
  local y0 = math.floor(idx / COLS) * TILE

  local base = lcg(3033 + idx * 53)
  fill(baseImg, x0, y0, x0 + TILE - 1, y0 + TILE - 1, GRASS)
  speckles(baseImg, x0, y0, base, 6)

  fn(detailImg, x0, y0)
end

local frame = spr.frames[1]
spr:newCel(spr.layers[1], frame, baseImg, Point(0, 0))
spr:newCel(detailLayer, frame, detailImg, Point(0, 0))

spr:saveAs(OUT)
print(string.format("saved %s  %dx%d  tiles=%d (+%d props)", OUT, W, H, #TILES, #PROPS))
