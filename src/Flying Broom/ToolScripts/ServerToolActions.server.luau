--!strict
-- Server Tool Actions Script

---------- Validate container ----------
if script:FindFirstAncestorWhichIsA("StarterPack") then
	return
end

---------- Services ----------
local TweenService = game:GetService("TweenService")

---------- Imports ----------
local ToolScripts = script.Parent
local User = require(ToolScripts:WaitForChild("User"))

---------- Instances ----------
local Tool = script.Parent.Parent
local Handle = Tool:WaitForChild("Handle")
local HandleSparkles = Handle:WaitForChild("Sparkles")

local ToolEvents = Tool:WaitForChild("ToolEvents")
local ActionsRemoteEvent = ToolEvents:WaitForChild("ActionsRemoteEvent")
local ActionsUnreliableRemoteEvent = ToolEvents:WaitForChild("ActionsUnreliableRemoteEvent")

local ToolAssets = Tool:WaitForChild("ToolAssets")
local RavenWitchHat = ToolAssets:WaitForChild("RavenWitchHat")

local Broom = ToolAssets:WaitForChild("Broom")
local BroomAlignPart = Broom:WaitForChild("BroomAlignPart")
local AlignPartRigidConstraint = BroomAlignPart:WaitForChild("RigidConstraint")

local ThrustSound = Broom:WaitForChild("ThrustSound")

local BroomJointAttachment = Broom:WaitForChild("BroomJointAttachment")
local BroomRigidConstraint = Broom:WaitForChild("RigidConstraint")
local BroomAlignOrientation = Broom:WaitForChild("AlignOrientation")
local BroomAntiGravity = Broom:WaitForChild("AntiGravity")

local BroomSparkles = Broom:WaitForChild("Sparkles")
local BroomTrail = Broom:WaitForChild("Trail")

---------- Variables ----------
local storedAccessory: Accessory?
local accessoryName: string = ""

local _time = os.clock

local toolUser: User.UserInfo = {}

local handleTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local handleTweens = {
    Show = TweenService:Create(Handle, handleTweenInfo, {Transparency = 0}),
    Hide = TweenService:Create(Handle, handleTweenInfo, {Transparency = 1}),
}

local mountTweens = {
    Show = TweenService:Create(Broom, handleTweenInfo, {Transparency = 0}),
    Hide = TweenService:Create(Broom, handleTweenInfo, {Transparency = 1}),
}

local isRiding = false
local lastMountTime = 0

local isStored = false
local lastStoreTime = 0

local lastThrustTime = 0

---------- Local functions ----------
local function thrustEffectAt(part: Part)
    -- Get sparkles
    local sparkles: Sparkles = part:FindFirstChild("Sparkles")
    if not sparkles then
        return
    end

    -- Validate not enabled
    if sparkles.Enabled then
        return
    end

    -- Enable sparkles
    sparkles.Enabled = true
    task.delay(0.5, function()
        sparkles.Enabled = false
    end)

    -- Play sound
    ThrustSound:Play()
end

local function setBroomCollision(collision: boolean)
    Broom.CanCollide = collision
    Broom.CanQuery = collision
    Broom.CanTouch = collision
end

local function onSetBroomJointCFrame(jointCFrame: CFrame)
    -- Validate riding
    if not isRiding then
        return
    end

    -- Set CFrame
    BroomJointAttachment.CFrame = jointCFrame
end

local function onSetRiding(riding: boolean)
    -- Validate humanoid
    local humanoid = toolUser.Humanoid
    if not humanoid then
        return
    end

    -- Set broom states
    isRiding = riding
    setBroomCollision(isRiding)

    -- Set broom trail
    BroomTrail.Enabled = isRiding
end

local function onSetBroomMounted(mounted: boolean, ignoreCooldown: boolean)
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
    onSetRiding(mounted)
end

local function onSetBroomStored(stored: boolean, ignoreCooldown: boolean)
    if not ignoreCooldown then
        -- Validate store cooldown
        local storeCooldown = Tool:GetAttribute("StoreCooldown")
        if not (_time() - lastStoreTime >= storeCooldown) then
            return
        end
    end
    lastStoreTime = _time()

    -- Force dismount
    onSetRiding(false)
    
    -- Store or unstore
    if stored then
        handleTweens.Hide:Play()
        mountTweens.Hide:Play()
    else
        handleTweens.Show:Play()
    end
    isStored = stored
end

local function onThrustRide()
    -- Validate not stored and riding
    if not (not isStored and isRiding) then
        return
    end

    -- Validate thrust cooldown
    local thrustCooldown = Tool:GetAttribute("ThrustCooldown")
    if not (_time() - lastThrustTime >= thrustCooldown) then
        return
    end
    lastThrustTime = _time()

    -- Thrust effect
    thrustEffectAt(Broom)
end

local function onThrust()
    -- Validate not stored and dismounted
    if not (not isStored and not isRiding) then
        return
    end

    -- Validate thrust cooldown
    local thrustCooldown = Tool:GetAttribute("ThrustCooldown")
    if not (_time() - lastThrustTime >= thrustCooldown) then
        return
    end
    lastThrustTime = _time()

    -- Thrust effect
    thrustEffectAt(Handle)
end

local function initSetUp()
    -- Sparkles
    HandleSparkles.Enabled = false
    BroomSparkles.Enabled = false

    -- Trail
    BroomTrail.Enabled = false
    BroomTrail.Attachment0 = Broom:WaitForChild("TrailAttachment0")
    BroomTrail.Attachment1 = Broom:WaitForChild("TrailAttachment1")

    -- Accessory
    storedAccessory = RavenWitchHat
    storedAccessory.Parent = nil
    accessoryName = storedAccessory.Name
    
    -- Broom
    Broom.Transparency = 1
    BroomRigidConstraint.Attachment0 = BroomJointAttachment
    BroomRigidConstraint.Attachment1 = BroomAlignPart:WaitForChild("AlignPartAttachment")
    
    local BroomAttachment = Broom:WaitForChild("BroomAttachment")
    BroomAlignOrientation.Attachment0 = BroomAttachment

    BroomAntiGravity.Enabled = true
    BroomAntiGravity.Attachment0 = BroomAttachment

    AlignPartRigidConstraint.Attachment0 = BroomAlignPart:WaitForChild("AlignRootAttachment")
end

---------- Event functions ----------
local function onActionsServerEvent(caller: Player, mode: string, param1: any, ...)
    -- Validate caller
    if caller ~= User.Player then
        return
    end

    -- Call functions
    if mode == "Set Broom Riding" then
        onSetRiding(param1)
    elseif mode == "Set Broom Mounted" then
        onSetBroomMounted(param1)
    elseif mode == "Set Broom Stored" then
        onSetBroomStored(param1)
    elseif mode == "Thrust Ride" then
        onThrustRide()
    elseif mode == "Thrust" then
        onThrust()
    end
end

local function onActionsUnreliableServerEvent(caller: Player, mode: string, param1: any, ...)
    -- Validate caller
    if caller ~= User.Player then
        return
    end

    -- Call functions
    if mode == "Set Broom Joint CFrame" then
        onSetBroomJointCFrame(param1)
    end
end

local function onUserLoaded(currentUser: User.UserInfo)
    if currentUser.Humanoid then
        toolUser = currentUser

        -- Equip accessory
        if storedAccessory then
            currentUser.Humanoid:AddAccessory(storedAccessory)
        else
            storedAccessory = currentUser.Character:FindFirstChild(accessoryName)
        end

        -- Equip broom
        local HumanoidRootPart = currentUser.Character:FindFirstChild("HumanoidRootPart")
        local RootAttachment = HumanoidRootPart and HumanoidRootPart:FindFirstChild("RootAttachment")
        if RootAttachment then
            AlignPartRigidConstraint.Attachment1 = RootAttachment
        end
        Broom.Parent = currentUser.Character
    end
end

local function onUserUnloaded(currentUser: User.UserInfo)
    toolUser = currentUser

    -- Unequip accessory
    if storedAccessory and storedAccessory.Parent == currentUser.Character then
        storedAccessory.Parent = nil
    else
        storedAccessory = nil
    end

    -- Unequip broom
    Broom.Parent = nil
    AlignPartRigidConstraint.Attachment1 = nil

    BroomAlignOrientation.Enabled = false
    BroomAntiGravity.Force = Vector3.new()

    -- Reset broom velocity
    Handle.AssemblyLinearVelocity = Vector3.new()
    Handle.AssemblyAngularVelocity = Vector3.new()
    Broom.AssemblyLinearVelocity = Vector3.new()
    Broom.AssemblyAngularVelocity = Vector3.new()

    -- Dismount
    onSetBroomMounted(false, true)
    
    -- Dropped tool
    if Tool.Parent == workspace then
        -- Unstore broom
        task.delay(0.05, function()
            -- onSetBroomMounted(false, true)
            onSetBroomStored(false, true)
        end)
    end
end

---------- Calling / connecting functions ----------
ActionsRemoteEvent.OnServerEvent:Connect(onActionsServerEvent)
ActionsUnreliableRemoteEvent.OnServerEvent:Connect(onActionsUnreliableServerEvent)
User.UserLoaded.Event:Connect(onUserLoaded)
User.UserUnloaded.Event:Connect(onUserUnloaded)
initSetUp()
