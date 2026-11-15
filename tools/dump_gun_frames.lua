-- dump_gun_frames.lua
-- 把 gun 图层每一帧的 cel 图导出（32x32，和角色帧一一对应），用来定位“手”的位置。
-- 运行: Aseprite.exe -b assets/character.aseprite --script tools/dump_gun_frames.lua

local spr = app.activeSprite
local gun = spr.layers["gun"]
if gun == nil then print("no gun layer"); return end
for i, frame in ipairs(spr.frames) do
	local cel = gun:cel(frame)
	if cel ~= nil then
		cel.image:saveAs(string.format("C:/game/test/docs/_gunframe_%02d.png", i))
	end
end
print("dumped " .. #spr.frames .. " frames")
