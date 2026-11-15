-- make_rifle_icon.lua
-- 生成突击步枪图标：20x20（深色枪身 + 长枪管 + 直弹匣），给武器轮盘用
-- 运行: Aseprite.exe -b --script tools/make_rifle_icon.lua

local OUT = "C:/game/test/assets/ui/rifle_icon.aseprite"
local W, H = 20, 20

local pc = app.pixelColor
local function rgb(r, g, b, a) return pc.rgba(r, g, b, a or 255) end

local OUTLINE = rgb(22, 24, 30)
local GUN     = rgb(62, 68, 80)
local GUN_L   = rgb(104, 112, 126)
local GUN_D   = rgb(36, 40, 48)

-- 文本地图：. 透明 / B 枪身 / L 高光 / D 暗部
local MAP = {
	"....................",
	"....................",
	"....................",
	"....................",
	".......LL...........",
	"....LLLLLLLL....LL..",
	"....BBBBBBBBBBBBBBBB",
	".BBBBBBBBBBBBBBBBBBB",
	".BBBBBBBBBBBBBBBB...",
	".BD..BBBB...BB......",
	".....BBBB...........",
	".....BBBB...........",
	"......BB............",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
	"....................",
}

local img = Image(W, H, ColorMode.RGB)
img:clear(0)

for y = 1, H do
	local row = MAP[y]
	if row then
		for x = 1, W do
			local ch = row:sub(x, x)
			local c = nil
			if ch == "B" then c = GUN
			elseif ch == "L" then c = GUN_L
			elseif ch == "D" then c = GUN_D end
			if c then img:putPixel(x - 1, y - 1, c) end
		end
	end
end

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
