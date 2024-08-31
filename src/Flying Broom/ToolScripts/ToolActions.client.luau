--!strict
-- Client Tool Actions Script

---------- Validate container ----------

if not (script:FindFirstAncestorWhichIsA("Workspace") or script:FindFirstAncestorWhichIsA("Backpack")) then
	return
end

---------- Imports ----------

local Packages = script.Parent.Parent:WaitForChild("ToolPackages")
local CFrameUtility = require(Packages:WaitForChild("CFrameUtility"))

local ToolScripts = script.Parent
local PlayerMotion = require(ToolScripts:WaitForChild("PlayerMotion"))
local User = require(ToolScripts:WaitForChild("User"))

---------- Services ----------

local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

---------- Instances ----------

local Tool = script.Parent.Parent
local Handle = Tool:WaitForChild("Handle")

local ToolEvents = Tool:WaitForChild("ToolEvents")
local ActionsEvent = ToolEvents:WaitForChild("ActionsEvent")
local ActionsRemoteEvent = ToolEvents:WaitForChild("ActionsRemoteEvent")
local ActionsUnreliableRemoteEvent = ToolEvents:WaitForChild("ActionsUnreliableRemoteEvent")
local ToolRemoteFunction = ToolEvents:WaitForChild("ToolRemoteFunction")

local Broom = ToolRemoteFunction:InvokeServer("Get Broom")
local BroomAlignPart = Broom:WaitForChild("BroomAlignPart")
local BroomJointAttachment = Broom:WaitForChild("BroomJointAttachment")
local BroomAlignOrientation = Broom:WaitForChild("AlignOrientation")
local BroomAntiGravity = Broom:WaitForChild("AntiGravity")

---------- Variables ----------

local _time = os.clock

local toolUser: User.UserInfo = {}

local random = Random.new()

local handleTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local handleTweens = {
	Show = TweenService:Create(Handle, handleTweenInfo, {Transparency = 0}),
	Hide = TweenService:Create(Handle, handleTweenInfo, {Transparency = 1}),
}

local mountTweens = {
	Show = TweenService:Create(Broom, handleTweenInfo, {Transparency = 0}),
	Hide = TweenService:Create(Broom, handleTweenInfo, {Transparency = 1}),
}

local ridingConnections: {RBXScriptConnection} = {}
local previousJointCFrame: CFrame?
local broomVelocity = Vector3.new()
local moveVector = Vector3.new()

local antigravityThrottle = false

local isAscending, isDescending = false, false

local isRiding = false
local lastMountTime = 0
local mountThrottle = false

local isStored = false
local lastStoreTime = 0
local storeThrottle = false

local lastThrustTime = 0
local activatedThrottle = false

---------- Local functions ----------

local function lerp(a: number, b: number, alpha: number)
	return a + (b - a) * alpha
end

local function broomRidingRotation()
	-- Initialize
	local willTurnBroom = true
	local hasShiftLock = User.isShiftLock()

	-- Check moving
	local flatVector = Vector3.new(broomVelocity.X, 0, broomVelocity.Z)
	if flatVector:Dot(flatVector) < 1 or moveVector:Dot(moveVector) < 0.5 then
		willTurnBroom = false
	end

	-- Rotate broom
	if willTurnBroom then
		-- Calculate CFrame
		local goalVector = -flatVector.Unit
		local goalCFrame = CFrame.lookAlong(Broom.Position, goalVector)
		local finalCFrame = CFrameUtility.getStandUpright(goalCFrame)
		finalCFrame = finalCFrame:Lerp(CFrameUtility.getTiltUpright(Broom.CFrame), 0.8)

		-- Check shift lock
		if hasShiftLock then
			-- Rotate joint
			previousJointCFrame = CFrameUtility.getMonaxialJoint(finalCFrame, BroomAlignPart.CFrame)
		end

		-- Rotate broom
		BroomAlignOrientation.CFrame = finalCFrame
	else
		-- Check shift lock
		if hasShiftLock then
			-- Keep the broom at the local orientation, but align orientation CFrame is modified
			local standUprightCFrame = CFrameUtility.getStandUpright(BroomAlignPart.CFrame)
			local finalCFrame = standUprightCFrame:ToWorldSpace(previousJointCFrame:Inverse())
			BroomAlignOrientation.CFrame = finalCFrame
		end
	end

	-- Rotate joint
	if previousJointCFrame then
		BroomJointAttachment.CFrame = previousJointCFrame
		ActionsUnreliableRemoteEvent:FireServer("Set Broom Joint CFrame", previousJointCFrame)
	end
end

local function getUserInputMotion(): Vector3
	-- Initialize
	local inputMotion = Vector3.new()
	local ascendVelocitySize = Tool:GetAttribute("AscendRideVelocitySize")

	-- Ascending
	if isAscending then
		inputMotion += Vector3.yAxis * ascendVelocitySize
	end

	-- Descending
	if isDescending then
		inputMotion -= Vector3.yAxis * ascendVelocitySize
	end

	-- Return motion
	return inputMotion
end

local function setBroomVelocity(velocity: Vector3)
	-- Set velocity
	broomVelocity = velocity

	-- Get real velocity
	local realVelocity = Broom.AssemblyLinearVelocity

	-- Final velocity
	local finalVelocity = broomVelocity:Lerp(realVelocity, 0.9)

	-- Extra input motion
	local inputMotion = getUserInputMotion()
	local limitY = math.max(math.abs(finalVelocity.Y), math.abs(inputMotion.Y))
	local finalY = math.clamp(lerp(finalVelocity.Y, finalVelocity.Y + inputMotion.Y, 0.2), -limitY, limitY)
	finalVelocity = Vector3.new(finalVelocity.X, finalY, finalVelocity.Z)

	-- Apply velocity
	Broom.AssemblyLinearVelocity = finalVelocity
end

local function broomRidingMovement()
	-- Validate control module
	if not PlayerMotion.isControlModuleReady then
		return
	end

	-- Validate move vector
	moveVector = PlayerMotion.getRawMoveVector()
	if not moveVector then
		return
	end

	-- Get information
	local maxVelocitySize = Tool:GetAttribute("MaxRideVelocitySize")
	local moveVelocity = moveVector * maxVelocitySize

	-- Get initial velocity
	local originalVelocity = broomVelocity or Vector3.new()

	-- Calculate goal velocity
	local moveAccelerationFactor = Tool:GetAttribute("MoveAccelerationFactor")
	local goalVelocity = originalVelocity:Lerp(moveVelocity, moveAccelerationFactor)

	-- Scale velocity
	local scale = maxVelocitySize / math.max(maxVelocitySize, goalVelocity.Magnitude)
	goalVelocity *= scale

	setBroomVelocity(goalVelocity)
end

local function onRiding()
	if isRiding then
		if #ridingConnections == 0 then
			broomVelocity = Vector3.new()
			previousJointCFrame = CFrame.new()
			moveVector = Vector3.new()

			local goalVector = Vector3.new(BroomAlignPart.CFrame.LookVector.X, 0, BroomAlignPart.CFrame.LookVector.Z)
			local goalCFrame = CFrame.lookAt(Vector3.new(), goalVector)
			BroomAlignOrientation.CFrame = goalCFrame
			BroomAlignOrientation.Enabled = true
			BroomAntiGravity.Force = Vector3.new(0, Broom.AssemblyMass * workspace.Gravity, 0)

			table.insert(ridingConnections, RunService.PreSimulation:Connect(function()
				broomRidingRotation()
			end))
			table.insert(ridingConnections, RunService.Heartbeat:Connect(function()
				broomRidingMovement()
			end))
		end
	else
		if #ridingConnections >= 1 then
			BroomAlignOrientation.Enabled = false
			BroomAntiGravity.Force = Vector3.new()

			for _, connection in ridingConnections do
				connection:Disconnect()
			end
			ridingConnections = {}
		end
	end
end

local function setRiding(riding: boolean)
	-- Get humanoid
	local humanoid = toolUser.Humanoid
	if not humanoid then
		warn("No humanoid or root part found!")
		return
	end

	-- Set humanoid states
	if riding then
		humanoid.PlatformStand = true
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, false)
	else
		humanoid.PlatformStand = false
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
	end
	isRiding = riding
	ActionsRemoteEvent:FireServer("Set Broom Riding", riding)
	onRiding()
end

local function setBroomMounted(mounted: boolean, ignoreCooldown: boolean)
	if not ignoreCooldown then
		-- Validate mount cooldown
		local mountCooldown = Tool:GetAttribute("MountCooldown")
		if not (_time() - lastMountTime >= mountCooldown) then
			return
		end
	end
	lastMountTime = _time()

	-- Mount or dismount
	if mounted then
		handleTweens.Hide:Play()
		mountTweens.Show:Play()
	else
		handleTweens.Show:Play()
		mountTweens.Hide:Play()
	end
	setRiding(mounted)
	ActionsRemoteEvent:FireServer("Set Broom Mounted", mounted)
end

local function setBroomStored(stored: boolean, ignoreCooldown: boolean)
	if not ignoreCooldown then
		-- Validate store cooldown
		local storeCooldown = Tool:GetAttribute("StoreCooldown")
		if not (_time() - lastStoreTime >= storeCooldown) then
			return
		end
	end
	lastStoreTime = _time()

	-- Force dismount
	setRiding(false)

	-- Store or unstore
	if stored then
		handleTweens.Hide:Play()
		mountTweens.Hide:Play()
	else
		handleTweens.Show:Play()
	end
	isStored = stored
	ActionsRemoteEvent:FireServer("Set Broom Stored", stored)
end

local function getMotion(): Vector3
	-- Get mouse position
	local mousePosition = User.getMousePosition()

	-- Get direction (position relative to handle)
	local motionDirection = mousePosition - Handle.Position

	-- Return
	return motionDirection
end

local function thrustRideFor(duration: number)
	-- Get motion
	local motionDirection = getMotion()

	-- Get thrust velocity
	local thrustVelocity = motionDirection.Unit * Tool:GetAttribute("MaxRideVelocitySize")
	thrustVelocity *= 2

	-- Modify cooldown
	lastThrustTime = _time() + duration

	-- Thrust ride
	local thrustRideStart = _time()
	local thrustConnection: RBXScriptConnection
	thrustConnection = RunService.Heartbeat:Connect(function()
		if _time() - thrustRideStart < duration then
			-- Calculate velocity
			local finalVelocity = thrustVelocity:Lerp(Broom.AssemblyLinearVelocity, 0.5)

			-- Set velocity
			Broom.AssemblyLinearVelocity = finalVelocity
		else
			-- Clean up connection
			thrustConnection:Disconnect()
			thrustConnection = nil
		end
	end)
end

local function onAntigravity()
	-- Validate throttle
	if antigravityThrottle then
		return
	end
	antigravityThrottle = true
	task.defer(function()
		task.wait(0.05)
		antigravityThrottle = false
	end)

	-- Validate mounted
	if not isRiding then
		return
	end

	-- Enable or disable antigravity
	BroomAntiGravity.Enabled = not BroomAntiGravity.Enabled
end

local function onAscendBroom(state: string)
	if state == "Start" then
		isAscending = true
	elseif state == "End" then
		isAscending = false
	end
end

local function onDescendBroom(state: string)
	if state == "Start" then
		isDescending = true
	elseif state == "End" then
		isDescending = false
	end
end

local function onMountBroom()
	-- Validate throttle
	if mountThrottle then
		return
	end
	mountThrottle = true
	task.defer(function()
		task.wait(0.05)
		mountThrottle = false
	end)

	-- Validate mounted or not stored
	if not (isRiding or not isStored) then
		return
	end

	-- Mount or dismount
	if isRiding then
		setBroomMounted(false)
	else
		setBroomMounted(true)
	end
end

local function onStoreBroom()
	-- Validate throttle
	if storeThrottle then
		return
	end
	storeThrottle = true
	task.defer(function()
		task.wait(0.05)
		storeThrottle = false
	end)

	-- Store or unstore
	if isStored then
		setBroomStored(false)
	else
		setBroomStored(true)
	end
end

local function onThrust()
	-- Validate throttle
	if activatedThrottle then
		return
	end
	activatedThrottle = true
	task.defer(function()
		task.wait(0.05)
		activatedThrottle = false
	end)

	-- Validate not stored
	if isStored then
		return
	end

	-- Validate thrust cooldown
	local thrustCooldown = Tool:GetAttribute("ThrustCooldown")
	if not (_time() - lastThrustTime >= thrustCooldown) then
		return
	end
	lastThrustTime = _time()

	-- Check riding
	if isRiding then
		-- Thrust ride
		task.defer(function()
			thrustRideFor(0.3)
		end)

		-- Thurst effect on server
		ActionsRemoteEvent:FireServer("Thrust Ride")
	else
		-- Get motion
		local motionDirection = getMotion()

		-- Get thrust
		local thurstVelocity = motionDirection.Unit * Tool:GetAttribute("ThrustVelocitySize")

		-- Thrust
		Handle.AssemblyLinearVelocity = thurstVelocity

		-- Thrust effect on server
		ActionsRemoteEvent:FireServer("Thrust")
	end
end

---------- Event functions ----------

local function onActionsEvent(mode: string, ...)
	-- Validate equipped
	if not Tool.Equipped then
		return
	end

	-- Actions
	if mode == "Broom Antigravity" then
		onAntigravity(...)
	elseif mode == "Ascend Broom" then
		onAscendBroom(...)
	elseif mode == "Descend Broom" then
		onDescendBroom(...)
	elseif mode == "Mount Broom" then
		onMountBroom(...)
	elseif mode == "Store Broom" then
		onStoreBroom(...)
	elseif mode == "Thrust Broom" then
		onThrust(...)
	end
end

local function onUserLoaded(currentUser: User.UserInfo)
	toolUser = currentUser

	setBroomStored(isStored)
end

local function onUserUnloaded(currentUser: User.UserInfo)
	toolUser = currentUser

	-- Dismount
	setBroomMounted(false, true)

	-- Dropped tool
	if Tool.Parent == workspace then
		task.delay(0.05, function()
			setBroomStored(false, true)
		end)
	end
end

---------- Calling / connecting functions ----------

ActionsEvent.Event:Connect(onActionsEvent)
User.UserLoaded.Event:Connect(onUserLoaded)
User.UserUnloaded.Event:Connect(onUserUnloaded)
