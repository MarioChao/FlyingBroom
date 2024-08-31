--!strict
-- Context Actions Script

---------- Validate container ----------

if not (script:FindFirstAncestorWhichIsA("Workspace") or script:FindFirstAncestorWhichIsA("Backpack")) then
	return
end

---------- Services ----------

local ContextActionService = game:GetService("ContextActionService")

---------- Instances ----------

local Tool = script.Parent.Parent
local ToolEvents = Tool:WaitForChild("ToolEvents")
local ActionsEvent = ToolEvents:WaitForChild("ActionsEvent")

---------- Local functions ----------

local function handleAction(actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
	local isBeginState = (inputState == Enum.UserInputState.Begin)
	local isCancelOrEndState = (inputState == Enum.UserInputState.Cancel) or (inputState == Enum.UserInputState.End)

	if actionName == "Broom Antigravity" then
		if isBeginState then
			ActionsEvent:Fire("Broom Antigravity")
		end
	elseif actionName == "Broom Ascend" then
		if isBeginState then
			ActionsEvent:Fire("Ascend Broom", "Start")
		elseif isCancelOrEndState then
			ActionsEvent:Fire("Ascend Broom", "End")
		end
	elseif actionName == "Broom Descend" then
		if isBeginState then
			ActionsEvent:Fire("Descend Broom", "Start")
		elseif isCancelOrEndState then
			ActionsEvent:Fire("Descend Broom", "End")
		end
	elseif actionName == "Broom Mount Broom" then
		if isBeginState then
			ActionsEvent:Fire("Mount Broom")
		end
	elseif actionName == "Broom Store Broom" then
		if isBeginState then
			ActionsEvent:Fire("Store Broom")
		end
	end
end

---------- Event functions ----------

local function onActivated()
	ActionsEvent:Fire("Thrust Broom")
end

local function onEquipped()
	ContextActionService:BindAction("Broom Antigravity", handleAction, true, Enum.KeyCode.F)
	ContextActionService:BindAction("Broom Ascend", handleAction, true, Enum.KeyCode.E)
	ContextActionService:BindAction("Broom Descend", handleAction, true, Enum.KeyCode.Q)
	ContextActionService:BindAction("Broom Mount Broom", handleAction, true, Enum.KeyCode.R)
	ContextActionService:BindAction("Broom Store Broom", handleAction, true, Enum.KeyCode.X)
end

local function onUnequipped()
	ContextActionService:UnbindAction("Broom Antigravity")
	ContextActionService:UnbindAction("Broom Ascend")
	ContextActionService:UnbindAction("Broom Descend")
	ContextActionService:UnbindAction("Broom Mount Broom")
	ContextActionService:UnbindAction("Broom Store Broom")
end

---------- Calling / connecting functions ----------

Tool.Equipped:Connect(onEquipped)
Tool.Unequipped:Connect(onUnequipped)
Tool.Activated:Connect(onActivated)
