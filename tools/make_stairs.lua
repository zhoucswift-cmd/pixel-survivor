-- make_stairs.lua
-- 楼顶通往下层的楼梯：3x5 格 = 48x80 像素
-- 粗糙水泥 + 每级踏板磨损 + 栏杆螺栓/锈迹 + 底部一扇铁门
-- 运行: Aseprite.exe -b --script tools/make_stairs.lua

local OUT = "C:/game/test/assets/base/stairs.aseprite"
local W, H = 48, 80

local pc = app.pixelColor
local function rgb(r, g, b, a)
	return pc.rgba(math.floor(r), math.floor(g), math.floor(b), a or 255)
end

-- 水泥
local LIGHT   = rgb(170, 172, 178)
local MID     = rgb(146, 148, 156)
local DARK    = rgb(118, 120, 128)
local SHADE   = rgb(92, 94, 102)
local OUTLINE = rgb(58, 60, 66)
-- 金属
local METAL   = rgb(122, 126, 134)
local METAL_D = rgb(80, 84, 92)
local METAL_L = rgb(188, 194, 204)
local RUST    = rgb(126, 74, 44)
local RUST_L  = rgb(158, 96, 56)
-- 洞口 / 门
local HOLE    = rgb(24, 24, 30)
local HOLE2   = rgb(40, 42, 50)
local HOLE3   = rgb(58, 62, 74)
local DOOR    = rgb(96, 100, 110)
local DOOR_D  = rgb(66, 70, 80)
local DOOR_L  = rgb(128, 134, 146)
local LAMP    = rgb(226, 196, 120)
local LAMP_D  = rgb(160, 132, 74)

local img = Image(W, H, ColorMode.RGB)
img:clear(0)

-- 伪随机（固定种子，保证每次生成一样）
local seed = 20240117
local function rnd()
	seed = (seed * 1103515245 + 12345) % 2147483648
	return seed / 2147483648
end

local function put(x, y, c)
	if x >= 0 and y >= 0 and x < W and y < H then img:putPixel(x, y, c) end
end

local function fill(x0, y0, x1, y1, c)
	for y = y0, y1 do for x = x0, x1 do put(x, y, c) end end
end

-- 在矩形区域里撒噪点，让水泥看起来粗糙
local function speckle(x0, y0, x1, y1, colors, density)
	for y = y0, y1 do
		for x = x0, x1 do
			if rnd() < density then
				local c = colors[math.floor(rnd() * #colors) + 1]
				put(x, y, c)
			end
		end
	end
end

-- ============ 1. 水泥井口 ============
fill(0, 0, W - 1, H - 1, OUTLINE)

-- 井口外框（粗糙水泥）
fill(1, 1, W - 2, H - 2, DARK)
speckle(1, 1, W - 2, H - 2, { MID, SHADE, LIGHT }, 0.10)

-- 上/左受光，下/右压暗
fill(1, 1, W - 2, 2, MID)
speckle(1, 1, W - 2, 2, { LIGHT, DARK }, 0.12)
fill(1, 1, 2, H - 2, MID)
speckle(1, 1, 2, H - 2, { LIGHT, DARK }, 0.10)
fill(W - 3, 1, W - 2, H - 2, SHADE)
fill(1, H - 3, W - 2, H - 2, SHADE)

-- 裂纹
local cracks = {
	{ 5, 1, 6, 3 }, { 6, 3, 6, 5 }, { 40, 2, 41, 4 },
	{ 2, 30, 3, 33 }, { 44, 46, 45, 50 }, { 12, H - 4, 14, H - 5 },
}
for _, c in ipairs(cracks) do
	fill(c[1], c[2], c[3], c[4], OUTLINE)
end

-- ============ 2. 井口内壁 ============
fill(3, 3, W - 4, H - 4, SHADE)
speckle(3, 3, W - 4, H - 4, { OUTLINE, DARK }, 0.08)

-- ============ 3. 台阶（7 级，越往下越暗） ============
local steps = 8
local top = 6
local bottom = 66
local step_h = math.floor((bottom - top) / steps)
for i = 0, steps - 1 do
	local y0 = top + i * step_h
	local y1 = y0 + step_h - 1
	local t = i / (steps - 1)

	local tread = rgb(150 - 74 * t, 152 - 74 * t, 160 - 70 * t)
	local tread_d = rgb(126 - 60 * t, 128 - 60 * t, 136 - 56 * t)
	local riser = rgb(104 - 44 * t, 106 - 44 * t, 114 - 42 * t)
	local edge = rgb(192 - 62 * t, 196 - 60 * t, 206 - 58 * t)

	-- 踏面
	fill(4, y0, W - 5, y1 - 2, tread)
	speckle(4, y0, W - 5, y1 - 2, { tread_d, riser }, 0.06)   -- 磨损的颗粒
	-- 踏面前缘高光（有断点，显得磕碰过）
	for x = 4, W - 5 do
		if rnd() > 0.12 then put(x, y0, edge) end
	end
	-- 前缘崩边
	if rnd() > 0.5 then
		local cx = 6 + math.floor(rnd() * (W - 14))
		put(cx, y0, riser)
		put(cx + 1, y0 + 1, riser)
	end
	-- 右侧被墙挡住的部分
	fill(W - 7, y0, W - 5, y1 - 2, riser)
	-- 踢面阴影
	fill(4, y1 - 1, W - 5, y1, riser)
	-- 踢面上的脏污
	if rnd() > 0.4 then
		local sx = 6 + math.floor(rnd() * (W - 16))
		fill(sx, y1 - 1, sx + 2, y1 - 1, rgb(78 - 20 * t, 80 - 20 * t, 88 - 18 * t))
	end
end

-- ============ 4. 楼梯尽头：往下拐进暗处 ============
-- 2D 俯视看不到门，这里就画成楼梯尽头的一小段平台 + 黑
fill(4, bottom, W - 5, bottom + 2, DARK)
speckle(4, bottom, W - 5, bottom + 2, { MID, SHADE, LIGHT }, 0.10)
fill(4, bottom, W - 5, bottom, MID)

-- 洞口（越往下越黑）
fill(4, bottom + 3, W - 5, H - 5, HOLE3)
fill(5, bottom + 4, W - 6, H - 6, HOLE2)
fill(6, bottom + 6, W - 7, H - 7, HOLE)
fill(10, bottom + 8, W - 11, H - 8, rgb(16, 16, 20))

-- 洞口边缘的一点反光，显得是往下走
fill(6, bottom + 3, W - 7, bottom + 3, rgb(74, 78, 92))
fill(6, bottom + 4, 7, bottom + 8, rgb(60, 64, 78))
fill(W - 8, bottom + 4, W - 7, bottom + 7, rgb(56, 60, 74))

-- ============ 5. 两侧栏杆 + 螺栓 / 锈 ============
for y = 4, bottom + 1 do
	put(3, y, METAL_D)
	put(4, y, METAL)
	put(W - 6, y, METAL)
	put(W - 5, y, METAL_D)
end
-- 栏杆顶帽
fill(3, 4, 4, 4, METAL_L)
fill(W - 6, 4, W - 5, 4, METAL_L)
-- 螺栓（每 8 像素一颗）
for y = 8, bottom, 8 do
	put(4, y, METAL_L)
	put(W - 6, y, METAL_L)
	put(3, y + 1, METAL_D)
	put(W - 5, y + 1, METAL_D)
end
-- 锈斑
local rusts = { {4, 20}, {4, 44}, {W - 6, 30}, {W - 6, 52}, {4, 12} }
for _, p in ipairs(rusts) do
	put(p[1], p[2], RUST)
	put(p[1], p[2] + 1, RUST_L)
	put(p[1] + (p[1] < W / 2 and 1 or -1), p[2] + 2, RUST)
end

-- 顶部挂一盏小灯（照楼梯口）
fill(W - 12, 1, W - 8, 2, METAL_D)
put(W - 10, 2, LAMP)
put(W - 11, 2, LAMP_D)
put(W - 9, 2, LAMP_D)
put(W - 10, 3, rgb(255, 232, 170))

local spr = Sprite(W, H, ColorMode.RGB)
spr.layers[1].name = "stairs"
spr:newCel(spr.layers[1], spr.frames[1], img, Point(0, 0))
spr:saveAs(OUT)
print(string.format("saved %s  %dx%d", OUT, W, H))
