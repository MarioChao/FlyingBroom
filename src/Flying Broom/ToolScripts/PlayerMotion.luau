--!strict
-- Player Motion Utility Module

---------- Module ----------
local PlayerMotion = {}

---------- Imports ----------

local ToolScripts = script.Parent
local User = require(ToolScripts:WaitForChild("User"))

local ControlModule

---------- Variables ----------

local userLoaded = false

---------- Event functions ----------

local function onUserLoaded(currentUser: User.UserInfo)
	userLoaded = true

	-- Get information
	local Player = currentUser.Player
	local PlayerScripts = Player:WaitForChild("PlayerScripts", 1)
	local PlayerModuleScript = PlayerScripts:WaitForChild("PlayerModule", 1)

	-- Validate player
	if not (userLoaded and Player == User.Player) then
		return
	end
	local PlayerModule = require(PlayerModuleScript)
	ControlModule = PlayerModule:GetControls()
end

local function onUserUnloaded(currentUser: User.UserInfo)
	userLoaded = false
	ControlModule = nil
end

---------- Module functions ----------

function PlayerMotion.isControlModuleReady(): boolean
	return (ControlModule ~= nil)
end

function PlayerMotion.getMoveVector(): Vector3?
	if not PlayerMotion.isControlModuleReady then
		return nil
	end
	return ControlModule:GetMoveVector()
end

function PlayerMotion.getRawMoveVector(): Vector3?
	if not PlayerMotion.isControlModuleReady then
		return nil
	end
	if ControlModule["calculateRawMoveVector"] then
		return ControlModule:calculateRawMoveVector(ControlModule.humanoid, ControlModule:GetMoveVector())
	else
		local camera = workspace.CurrentCamera
		if not camera then
			return nil
		end
		return camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector())
	end
end

---------- Calling / connecting functions ----------

User.UserLoaded.Event:Connect(onUserLoaded)
User.UserUnloaded.Event:Connect(onUserUnloaded)

---------- Return module ----------
return PlayerMotion
