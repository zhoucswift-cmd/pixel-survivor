-- export_nogun.lua
-- 导出不含 gun 图层的角色精灵表（枪改成独立旋转的精灵，避免人物身上还画着一把）
-- 运行: Aseprite.exe -b assets/character.aseprite --script tools/export_nogun.lua

local spr = app.activeSprite
local gun = spr.layers["gun"]
if gun == nil then
	print("gun layer not found")
	return
end

gun.isVisible = false

app.command.ExportSpriteSheet({
	ui = false,
	askOverwrite = false,
	type = SpriteSheetType.HORIZONTAL,
	textureFilename = "C:/game/test/assets/character_sheet.png",
	trim = false,
})

gun.isVisible = true
print("exported character_sheet.png without gun layer")
