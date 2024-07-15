--!strict
-- Mouse Icon Script

---------- Validate container ----------

if script:FindFirstAncestorWhichIsA("StarterPack") then
	return
end

---------- Services ----------

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

---------- Instances ----------

local Tool = script.Parent.Parent

---------- Variables ----------

local activatedIcon = "rbxasset://textures/GunCursor.png"

---------- Local functions ----------

local function setCursor(icon: string)
	if not (icon == "" or Players:GetPlayerFromCharacter(Tool.Parent) == Players.LocalPlayer) then
		return
	end
	UserInputService.MouseIcon = icon
end

---------- Event functions ----------

local function onEquipped(mouse: Mouse)
	mouse.Icon = activatedIcon
	setCursor(activatedIcon)
end

local function onUnequipped()
	setCursor("")
end

---------- Calling / connecting functions ----------

Tool.Equipped:Connect(onEquipped)
Tool.Unequipped:Connect(onUnequipped)
